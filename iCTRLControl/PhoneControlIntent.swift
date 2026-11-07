import AppIntents
import Foundation

#if ICTRL_MAIN_APP
import UIKit
#endif

/// Small shared probe used by both the WidgetKit provider and the intent that
/// executes in iCTRL's main-app process.
enum PhoneControlRunnerState {
    private static let schemaURL = URL(string: "http://127.0.0.1:8200/schema")!

    static func isRunning(timeout: TimeInterval = 0.7) async -> Bool {
        var request = URLRequest(url: schemaURL)
        request.timeoutInterval = timeout
        request.cachePolicy = .reloadIgnoringLocalCacheData
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    static func wait(for desired: Bool, attempts: Int) async -> Bool {
        for _ in 0..<attempts {
            if await isRunning() == desired { return true }
            try? await Task.sleep(nanoseconds: 250_000_000)
        }
        return await isRunning() == desired
    }
}

/// The system invokes this from the Control Center toggle / interactive widget,
/// but iOS 27's execution-target API deliberately runs the implementation in
/// the main iCTRL process. That lets us reuse the existing, authenticated
/// RunnerClient instead of putting credentials or private launch APIs in the
/// widget extension.
@available(iOS 27.0, *)
struct SetPhoneControlIntent: SetValueIntent {
    static var title: LocalizedStringResource = "Phone Control"
    static var description = IntentDescription("Turn iCTRL remote phone control on or off.")
    static var allowedExecutionTargets: IntentExecutionTargets { .main }
    static var supportedModes: IntentModes { [.background, .foreground(.dynamic)] }

    @Parameter(title: "Phone Control")
    var value: Bool

    func perform() async throws -> some IntentResult {
#if ICTRL_MAIN_APP
        _ = await setRunnerRunning(value)
#endif
        return .result()
    }

#if ICTRL_MAIN_APP
    private func setRunnerRunning(_ desired: Bool) async -> Bool {
        if await PhoneControlRunnerState.isRunning() == desired { return true }

        if desired {
            // XCUITest cannot launch without the DDI. Do not bounce the user
            // through a doomed runner launch after a reboot.
            guard DeveloperDiskImage.status().isMounted else { return false }

            // Opening the runner is a UIKit operation. Ask App Intents to move
            // this main-app execution into the foreground only when necessary;
            // alwaysConfirm:false avoids an extra confirmation for this direct
            // user gesture whenever the system permits it.
            if systemContext.currentMode == .background {
                guard systemContext.currentMode.canContinueInForeground else { return false }
                do {
                    try await continueInForeground(nil, alwaysConfirm: false)
                } catch {
                    return false
                }
            }

            let opened = await Self.openRunner()
            guard opened else { return false }
            return await PhoneControlRunnerState.wait(for: true, attempts: 40)
        }

        // OFF is intentionally authenticated. The companion already pairs once
        // with the runner and keeps that credential in its Keychain; the widget
        // never receives or stores it.
        let client = RunnerClient(port: 8200)
        guard client.isPaired else { return false }
        do {
            _ = try await client.call("config", ["stop_server": true])
        } catch {
            return false
        }
        return await PhoneControlRunnerState.wait(for: false, attempts: 20)
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
#endif
}

