import AppIntents
import Darwin
import SwiftUI
import WidgetKit

struct DevVPNConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Dev VPN"
    static var description = IntentDescription("Choose the Dev VPN shortcut this widget should run.")

    @Parameter(title: "Action")
    var shortcut: SystemShortcut?
}

private enum DevVPNState {
    /// LocalDevVPN uses a point-to-point utun interface in the 10.7.x.x range.
    /// Match both the interface family and address range so ordinary system or
    /// Proton VPN interfaces don't make this control look connected.
    static func isConnected() -> Bool {
        var first: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&first) == 0, let first else { return false }
        defer { freeifaddrs(first) }

        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let node = cursor {
            defer { cursor = node.pointee.ifa_next }
            guard let address = node.pointee.ifa_addr,
                  address.pointee.sa_family == UInt8(AF_INET) else { continue }

            let name = String(cString: node.pointee.ifa_name)
            guard name.hasPrefix("utun") else { continue }

            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let length = socklen_t(address.pointee.sa_len)
            guard getnameinfo(address, length, &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 else {
                continue
            }
            let ip = String(cString: host)
            if ip.hasPrefix("10.7.") { return true }
        }
        return false
    }
}

struct DevVPNEntry: TimelineEntry {
    let date: Date
    let connected: Bool
    let configuration: DevVPNConfigurationIntent
}

struct DevVPNProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> DevVPNEntry {
        DevVPNEntry(date: .now, connected: false, configuration: DevVPNConfigurationIntent())
    }

    func snapshot(for configuration: DevVPNConfigurationIntent, in context: Context) async -> DevVPNEntry {
        DevVPNEntry(date: .now, connected: DevVPNState.isConnected(), configuration: configuration)
    }

    func timeline(for configuration: DevVPNConfigurationIntent, in context: Context) async -> Timeline<DevVPNEntry> {
        let entry = DevVPNEntry(date: .now, connected: DevVPNState.isConnected(), configuration: configuration)
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60)))
    }
}

struct DevVPNWidgetView: View {
    let entry: DevVPNEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: entry.connected ? "network.badge.shield.half.filled" : "network.slash")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                Spacer()
                HStack(spacing: 5) {
                    Circle()
                        .fill(entry.connected ? Color.green : Color.secondary.opacity(0.45))
                        .frame(width: 8, height: 8)
                    Text(entry.connected ? "Connected" : "Off")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            Text("Dev VPN")
                .font(.headline)
            Text(entry.connected ? "Ready for SideStore" : "Tap when refreshing apps")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let shortcut = entry.configuration.shortcut {
                Button(intent: RunSystemShortcutIntent(shortcut: shortcut)) {
                    HStack(spacing: 10) {
                        Text(entry.connected ? "On" : "Off")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        ZStack(alignment: entry.connected ? .trailing : .leading) {
                            Capsule()
                                .fill(entry.connected ? Color.green : Color.secondary.opacity(0.28))
                                .frame(width: 50, height: 30)
                            Circle()
                                .fill(.white)
                                .frame(width: 26, height: 26)
                                .padding(2)
                                .shadow(radius: 1)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                HStack {
                    Text("Edit Widget")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct DevVPNWidget: Widget {
    static let kind = "com.openminis.ictrl.dev-vpn-widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: Self.kind,
            intent: DevVPNConfigurationIntent.self,
            provider: DevVPNProvider()
        ) { entry in
            DevVPNWidgetView(entry: entry)
        }
        .configurationDisplayName("Dev VPN")
        .description("A stateful LocalDevVPN switch for SideStore maintenance.")
        .supportedFamilies([.systemSmall])
    }
}
