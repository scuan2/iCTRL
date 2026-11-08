import Foundation
import UIKit
import iCTRLIntents

enum PhoneControlController {
    static func setRunning(_ desired: Bool) async -> Bool {
        if await PhoneControlRunnerState.isRunning() == desired { return true }

        if desired {
            guard DeveloperDiskImage.status().isMounted else { return false }
            guard await openRunner() else { return false }
            return await PhoneControlRunnerState.wait(for: true, attempts: 40)
        }

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
}
