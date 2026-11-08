import ActivityKit
import AppIntents

public struct PhoneControlActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var running: Bool

        public init(running: Bool) {
            self.running = running
        }
    }

    public init() {}
}

/// Intentionally inert. Its only purpose is to give the Dynamic Island a real,
/// system-owned interactive control that XCTest can target without delivering a
/// touch to the foreground application underneath the hardware cutout.
@available(iOS 26.0, *)
public struct PhoneControlHeartbeatIntent: AppIntent {
    public static var title: LocalizedStringResource = "Phone Control Heartbeat"
    public static var description = IntentDescription("Marks Phone Control as active without changing app state.")
    public static var supportedModes: IntentModes { [.background] }

    public init() {}

    public func perform() async throws -> some IntentResult {
        .result()
    }
}
