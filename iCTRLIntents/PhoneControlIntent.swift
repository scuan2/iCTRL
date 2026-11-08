import AppIntents
import Foundation
import WidgetKit

/// Live runner state shared by the main app and WidgetKit extension.
public enum PhoneControlRunnerState {
    private static let schemaURL = URL(string: "http://127.0.0.1:8200/schema")!

    public static func isRunning(timeout: TimeInterval = 0.7) async -> Bool {
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

    public static func wait(for desired: Bool, attempts: Int) async -> Bool {
        for _ in 0..<attempts {
            if await isRunning() == desired { return true }
            try? await Task.sleep(nanoseconds: 250_000_000)
        }
        return await isRunning() == desired
    }
}

/// Main-app implementation injected into the shared intent at app launch.
/// Keeping the implementation behind this small dependency lets the exact same
/// AppIntent type be linked by both the app and widget extension while only the
/// main app touches UIKit, DDI mounting and the authenticated RunnerClient.
public struct PhoneControlService: Sendable {
    public let setRunning: @Sendable (Bool) async -> Bool

    public init(setRunning: @escaping @Sendable (Bool) async -> Bool) {
        self.setRunning = setRunning
    }
}

public enum PhoneControlIntentError: LocalizedError {
    case failed

    public var errorDescription: String? {
        "Phone Control could not change the runner state."
    }
}

@available(iOS 27.0, *)
public struct SetPhoneControlIntent: SetValueIntent {
    public static var title: LocalizedStringResource = "Phone Control"
    public static var description = IntentDescription("Turn iCTRL remote phone control on or off.")
    public static var allowedExecutionTargets: IntentExecutionTargets { .main }
    public static var supportedModes: IntentModes { [.background, .foreground(.dynamic)] }

    @Parameter(title: "Phone Control")
    public var value: Bool

    @Dependency
    private var service: PhoneControlService

    public init() {}

    public func perform() async throws -> some IntentResult {
        // Starting XCTest needs UIApplication to launch the runner. Move into
        // the foreground only for ON; stopping an already-running runner remains
        // a quiet background action.
        if value, systemContext.currentMode == .background {
            guard systemContext.currentMode.canContinueInForeground else {
                throw PhoneControlIntentError.failed
            }
            try await continueInForeground(nil, alwaysConfirm: false)
        }

        guard await service.setRunning(value) else {
            throw PhoneControlIntentError.failed
        }

        if #available(iOS 18.0, *) {
            ControlCenter.shared.reloadControls(ofKind: "com.openminis.ictrl.phone-control")
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "com.openminis.ictrl.phone-control-widget")
        return .result()
    }
}

public struct iCTRLIntentsPackage: AppIntentsPackage {}
