import SwiftUI
import AVKit
import TrailMarkCore

struct MemoDetailsView: View {
    @Environment(AppModel.self) private var model

    let memo: MediaMemo

    @State private var audioPlayer = AudioPlayer()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch memo.kind {
                case .video:
                    VideoPlayer(player: AVPlayer(url: model.media.url(for: memo)))
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                case .audio:
                    audioControls
                }
                metadata
            }
        }
    }

    private var audioControls: some View {
        VStack(spacing: 16) {
            AudioWaveformView(
                url: model.media.url(for: memo),
                barCount: 52,
                tint: .teal,
                isActive: audioPlayer.isPlaying,
                progress: audioPlayer.isPlaying ? audioPlayer.progress : nil
            )
            .frame(height: 96)

            Button {
                audioPlayer.isPlaying ?
                audioPlayer.stop() :
                audioPlayer.play(url: model.media.url(for: memo))
            } label: {
                Label(
                    audioPlayer.isPlaying ? "Stop" : "Play",
                    systemImage: audioPlayer.isPlaying ? "stop.circle.fill" :
                        "play.circle.fill"
                )
                .font(.title2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        .task(id: audioPlayer.isPlaying) {
            while audioPlayer.isPlaying && !Task.isCancelled {
                audioPlayer.tick()
                try? await Task.sleep(for: .seconds(0.05))
            }
        }
    }

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Recorded", value: memo.createdAt.formatted(date: .abbreviated,
                                                                      time: .shortened))
            LabeledContent("Duration", value: memo.durationText)
        }
        .font(.subheadline)
    }
}

struct AudioWaveformView: View {
    let url: URL
    var barCount = 36
    var tint: Color = .teal
    var isActive = false
    var progress: Double?
    var noiseFloor: CGFloat = 0.025
    var contrast: CGFloat = 1.35
    var minimumLevel: CGFloat = 0.04

    @State private var levels: [CGFloat] = []

    var body: some View {
        GeometryReader { proxy in
            let values = levels.isEmpty ? Array(repeating: minimumLevel, count: barCount) : levels
            let spacing: CGFloat = 3
            let barWidth = max((proxy.size.width - spacing * CGFloat(values.count - 1)) / CGFloat(values.count), 2)

            ZStack(alignment: .leading) {
                HStack(alignment: .center, spacing: spacing) {
                    ForEach(values.indices, id: \.self) { index in
                        RoundedRectangle(cornerRadius: barWidth / 2)
                            .fill(tint)
                            .frame(
                                width: barWidth,
                                height: max(proxy.size.height * values[index], 4)
                            )
                            .opacity(isActive ? 1 : 0.72)
                            .animation(.easeInOut(duration: 0.18), value: isActive)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                if let progress {
                    Capsule()
                        .fill(.primary.opacity(0.65))
                        .frame(width: 3, height: proxy.size.height)
                        .offset(x: min(max(proxy.size.width * progress, 0), proxy.size.width - 3))
                }
            }
        }
        .task(id: url) {
            levels = await Self.samples(
                from: url,
                count: barCount,
                noiseFloor: noiseFloor,
                contrast: contrast,
                minimumLevel: minimumLevel
            )
        }
    }

    private static func samples(
        from url: URL,
        count: Int,
        noiseFloor: CGFloat,
        contrast: CGFloat,
        minimumLevel: CGFloat
    ) async -> [CGFloat] {
        await Task.detached(priority: .userInitiated) {
            guard
                let file = try? AVAudioFile(forReading: url),
                let buffer = AVAudioPCMBuffer(
                    pcmFormat: file.processingFormat,
                    frameCapacity: AVAudioFrameCount(file.length)
                )
            else {
                return []
            }

            do {
                try file.read(into: buffer)
            } catch {
                return []
            }

            guard let channel = buffer.floatChannelData?[0] else {
                return []
            }

            let frameCount = Int(buffer.frameLength)
            guard frameCount > 0, count > 0 else {
                return []
            }

            let bucketSize = max(frameCount / count, 1)
            var output: [CGFloat] = []
            output.reserveCapacity(count)

            for bucket in 0..<count {
                let start = bucket * bucketSize
                let end = min(start + bucketSize, frameCount)
                guard start < end else { break }

                var sumOfSquares: Float = 0
                for index in start..<end {
                    let sample = channel[index]
                    sumOfSquares += sample * sample
                }

                let rms = sqrt(sumOfSquares / Float(end - start))
                output.append(CGFloat(rms))
            }

            let maxLevel = output.max() ?? 0
            guard maxLevel > 0 else {
                return Array(repeating: minimumLevel, count: count)
            }

            return output.map { level in
                let normalized = level / maxLevel
                let gated = normalized < noiseFloor ? 0 : normalized
                let shaped = pow(Double(gated), Double(contrast))
                return CGFloat(min(max(shaped, Double(minimumLevel)), 1))
            }
        }.value
    }
}
