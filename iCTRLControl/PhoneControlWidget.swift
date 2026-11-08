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
                Toggle(isOn: entry.running, intent: SetPhoneControlIntent()) {
                    Text("Phone Control")
                }
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(.green)
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

@main
@available(iOSApplicationExtension 27.0, *)
struct PhoneControlBundle: WidgetBundle {
    var body: some Widget {
        PhoneControlWidget()
        DevVPNWidget()
        PhoneControlControl()
    }
}

