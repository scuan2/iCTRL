import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit
import iCTRLIntents

@available(iOSApplicationExtension 27.0, *)
struct PhoneControlControl: ControlWidget {
    static let kind = "com.openminis.ictrl.phone-control"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind, provider: Provider()) { running in
            ControlWidgetToggle(
                "Phone Control",
                isOn: running,
                action: SetPhoneControlIntent()
            ) { isOn in
                Label(
                    isOn ? "Phone Control On" : "Phone Control Off",
                    systemImage: isOn ? "iphone.gen3.radiowaves.left.and.right" : "iphone.gen3"
                )
            }
        }
        .displayName("Phone Control")
        .description("Make this iPhone available to ChatGPT only when you want it.")
    }

    struct Provider: ControlValueProvider {
        let previewValue = false

        func currentValue() async throws -> Bool {
            await PhoneControlRunnerState.isRunning()
        }
    }
}

struct PhoneControlEntry: TimelineEntry {
    let date: Date
    let running: Bool
}

struct PhoneControlProvider: TimelineProvider {
    func placeholder(in context: Context) -> PhoneControlEntry {
        PhoneControlEntry(date: .now, running: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (PhoneControlEntry) -> Void) {
        Task {
            completion(PhoneControlEntry(date: .now, running: await PhoneControlRunnerState.isRunning()))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PhoneControlEntry>) -> Void) {
        Task {
            let running = await PhoneControlRunnerState.isRunning()
            completion(Timeline(
                entries: [PhoneControlEntry(date: .now, running: running)],
                policy: .after(Date().addingTimeInterval(60))
            ))
        }
    }
}

@available(iOSApplicationExtension 27.0, *)
struct PhoneControlWidgetView: View {
    let entry: PhoneControlEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: entry.running
                      ? "iphone.gen3.radiowaves.left.and.right"
                      : "iphone.gen3")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                Spacer()
                HStack(spacing: 5) {
                    Circle()
                        .fill(entry.running ? Color.green : Color.secondary.opacity(0.45))
                        .frame(width: 8, height: 8)
                    Text(entry.running ? "Ready" : "Off")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            Text("Phone Control")
                .font(.headline)
            Text(entry.running ? "ChatGPT can connect" : "Tap when you need it")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Text(entry.running ? "On" : "Off")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button(intent: SetPhoneControlIntent(value: !entry.running)) {
                    ZStack(alignment: entry.running ? .trailing : .leading) {
                        Capsule()
                            .fill(entry.running ? Color.green : Color.secondary.opacity(0.28))
                            .frame(width: 50, height: 30)
                        Circle()
                            .fill(.white)
                            .frame(width: 26, height: 26)
                            .padding(2)
                            .shadow(radius: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

@available(iOSApplicationExtension 27.0, *)
struct PhoneControlWidget: Widget {
    static let kind = "com.openminis.ictrl.phone-control-widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: PhoneControlProvider()) { entry in
            PhoneControlWidgetView(entry: entry)
        }
        .configurationDisplayName("Phone Control")
        .description("One-tap access for ChatGPT phone control.")
        .supportedFamilies([.systemSmall])
    }
}

@available(iOSApplicationExtension 26.0, *)
struct PhoneControlLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PhoneControlActivityAttributes.self) { _ in
            HStack(spacing: 8) {
                Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                Text("Phone Control")
                    .font(.headline)
                Spacer()
                heartbeatButton
            }
            .padding(.horizontal)
            .activityBackgroundTint(.black.opacity(0.88))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { _ in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    heartbeatButton
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Phone Control")
                        .font(.caption)
                }
            } compactLeading: {
                Image(systemName: "iphone.gen3")
                    .font(.caption2)
            } compactTrailing: {
                heartbeatButton
            } minimal: {
                heartbeatButton
            }
            .keylineTint(.clear)
        }
    }

    private var heartbeatButton: some View {
        Button(intent: PhoneControlHeartbeatIntent()) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6, weight: .regular))
                .foregroundStyle(.secondary)
                .frame(width: 20, height: 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("iCTRL Heartbeat")
        .accessibilityIdentifier("ictrl-heartbeat")
    }
}

@main
@available(iOSApplicationExtension 27.0, *)
struct PhoneControlBundle: WidgetBundle {
    var body: some Widget {
        PhoneControlWidget()
        DevVPNWidget()
        PhoneControlControl()
        PhoneControlLiveActivity()
    }
}

