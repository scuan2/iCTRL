import AppIntents
import WidgetKit

/// Shortcut callback used after LocalDevVPN changes state.
///
/// `RunSystemShortcutIntent` is intentionally opaque to the widget, so the
/// shortcut itself calls this as its final action. WidgetKit then asks the
/// Dev VPN provider for a fresh entry, which reads the real 10.7.x.x tunnel
/// state instead of predicting whether the VPN toggle succeeded.
@available(iOS 27.0, *)
public struct RefreshDevVPNWidgetIntent: AppIntent {
    public static var title: LocalizedStringResource = "Refresh Dev VPN Widget"
    public static var description = IntentDescription(
        "Refreshes the Dev VPN Home Screen widget after LocalDevVPN changes state."
    )
    public static var allowedExecutionTargets: IntentExecutionTargets { .main }
    public static var supportedModes: IntentModes { [.background] }

    public init() {}

    public func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadTimelines(ofKind: "com.openminis.ictrl.dev-vpn-widget")
        return .result()
    }
}
