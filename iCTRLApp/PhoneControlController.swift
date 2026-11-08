import ActivityKit
import Foundation
import UIKit
import iCTRLIntents

enum PhoneControlController {
    static func setRunning(_ desired: Bool) async -> Bool {
        if await PhoneControlRunnerState.isRunning() == desired {
            if desired { await ensureHeartbeatActivity() }
            else { await endHeartbeatActivity() }
            return true
        }

        if desired {
            guard DeveloperDiskImage.status().isMounted else { return false }
            await ensureHeartbeatActivity()
            guard await openRunner() else { return false }
            // Starting XCTest can require an iOS automation-password prompt.
            // Give the user enough time to approve it; once the runner is
            // genuinely reachable, the intent refreshes the widget from the
            // real state rather than guessing.
            let started = await PhoneControlRunnerState.wait(for: true, attempts: 240)
            if !started { await endHeartbeatActivity() }
            return started
        }

        let client = RunnerClient(port: 8200)
        guard client.isPaired else { return false }
        do {
            _ = try await client.call("config", ["stop_server": true])
        } catch {
            return false
        }
        let stopped = await PhoneControlRunnerState.wait(for: false, attempts: 20)
        if stopped { await endHeartbeatActivity() }
        return stopped
    }

    private static func ensureHeartbeatActivity() async {
        guard #available(iOS 17.0, *) else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            ictrlLog("Phone Control heartbeat Live Activity unavailable: disabled by system/user")
            return
        }
        if Activity<PhoneControlActivityAttributes>.activities.contains(where: { $0.activityState == .active }) {
            return
        }
        do {
            let content = ActivityContent(
                state: PhoneControlActivityAttributes.ContentState(running: true),
                staleDate: nil
            )
            _ = try Activity<PhoneControlActivityAttributes>.request(
                attributes: PhoneControlActivityAttributes(),
                content: content,
                pushType: nil
            )
            ictrlLog("Phone Control heartbeat Live Activity started")
        } catch {
            ictrlLog("Phone Control heartbeat Live Activity failed: \(error.localizedDescription)")
        }
    }

    private static func endHeartbeatActivity() async {
        guard #available(iOS 17.0, *) else { return }
        for activity in Activity<PhoneControlActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    @MainActor
    private static func openRunner() async -> Bool {
        guard let url = URL(string: "ictrl://start") else { return false }
        return await withCheckedContinuation { continuation in
            UIApplication.shared.open(url, options: [:]) { ok in
                continuation.resume(returning: ok)
            }
        }
    }
}
