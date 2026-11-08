import AppIntents
import WidgetKit

/// Shortcut callback used after LocalDevVPN changes state.
///
/// `RunSystemShortcutIntent` is intentionally opaque to the widget, so the
/// shortcut itself calls this as its final action. WidgetKit then asks the
/// Dev VPN provider for a fresh entry, which reads the real 10.7.x.x tunnel
/// state instead of predicting whether the VPN toggle succeeded.
@available(iOS 17.0, *)
public struct RefreshDevVPNWidgetIntent: AppIntent {
    public static var title: LocalizedStringResource = "Refresh Dev VPN Widget"
    public static var description = IntentDescription(
        "Refreshes the Dev VPN Home Screen widget after LocalDevVPN changes state."
    )

    public init() {}

    public func perform() async throws -> some IntentResult {
        // Shortcuts' Set VPN action returns before NetworkExtension always
        // finishes publishing/removing the utun interface. Give that state a
        // brief moment to settle so the widget reload reads the real result
        // instead of the previous state.
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        WidgetCenter.shared.reloadTimelines(ofKind: "com.openminis.ictrl.dev-vpn-widget")
        return .result()
    }
}
