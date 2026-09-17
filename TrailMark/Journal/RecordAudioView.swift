import SwiftUI
import TrailMarkCore

struct RecordAudioView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var recorder = AudioRecorder()
    @State private var errorMessages: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                Text(timeString(recorder.elapsedTime))
                    .font(.system(size: 56, design: .rounded)).monospacedDigit()
                    .contentTransition(.numericText())

                LiveRecordingWaveformView(
                    level: CGFloat(recorder.level),
                    isRecording: recorder.isRecording
                )
                .frame(width: 112, height: 112)

                Spacer()

                Button {
                    recorder.isRecording ? finish() : begin()
                } label: {
                    Text(recorder.isRecording ? " Stop & Save" : "Start Recording")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            recorder.isRecording ? Color.red : Color.accentColor,
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .foregroundStyle(.white)
                }

                if let errorMessages {
                    Text(errorMessages).font(.footnote).foregroundStyle(.red)
                }
            }
            .padding()
            .navigationTitle("Voice Memo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task(id: recorder.isRecording) {
                while recorder.isRecording && !Task.isCancelled {
                    recorder.tick()
                    try? await Task.sleep(for: .seconds(0.1))
                }
            }
        }
    }

    private func begin() {
        do { try recorder.start() }
        catch { errorMessages = error.localizedDescription }
    }

    private func finish() {
        guard let result = recorder.stop() else { return }
        model.media.add(
            kind: .audio,
            movingFileFrom: result.url,
            duration: result.duration,
        )
        dismiss()
    }

    private func timeString(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60

        return String(format: "%02d:%02d", minutes, seconds) // 00:00
    }
}

private struct LiveRecordingWaveformView: View {
    let level: CGFloat
    let isRecording: Bool

    @State private var levels = Array(repeating: CGFloat(0.2), count: 7)

    var body: some View {
        ZStack {
            Circle()
                .fill(isRecording ? Color.red : Color.secondary)

            if isRecording {
                HStack(alignment: .center, spacing: 7) {
                    ForEach(levels.indices, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.white)
                            .frame(width: 7, height: max(22, 72 * levels[index]))
                    }
                }
                .animation(.easeOut(duration: 0.1), value: levels)
            } else {
                Image(systemName: "mic.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
            }
        }
        .onChange(of: level) { _, newValue in
            guard isRecording else { return }
            levels.removeFirst()
            levels.append(min(max(newValue, 0.12), 1))
        }
        .onChange(of: isRecording) { _, newValue in
            if !newValue {
                levels = Array(repeating: CGFloat(0.2), count: levels.count)
            }
        }
    }
}
