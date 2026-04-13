import SwiftUI
import AVKit
import UIKit
import AVFoundation
import Foundation

// One frame per labeled stage
struct LabeledFrame: Identifiable {
    let id = UUID()
    let image: UIImage
    let label: String
}

struct SwingFrameCapture: View {
    let videoURL: URL

    @State private var player: AVPlayer
    @State private var capturedFrames: [LabeledFrame] = []
    @State private var currentLabel: String = "Setup"
    @State private var navigateToAnalyze = false

    // NEW: Club selection
    @State private var selectedClub: String = "7i"
    private let clubOptions = [
        "Driver", "3W", "5W", "7W", "Hybrid",
        "3i", "4i", "5i", "6i", "7i", "8i", "9i",
        "PW", "GW", "SW", "LW"
    ]

    // Enforce exactly these 5 stages
    private let requiredLabels = ["Setup", "Backswing", "Top of Swing", "Downswing", "Follow-through"]

    init(videoURL: URL) {
        self.videoURL = videoURL
        _player = State(initialValue: AVPlayer(url: videoURL))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    Text("Analyze Your Swing")
                        .font(.title2.weight(.semibold))
                        .padding(.top)

                    VideoPlayer(player: player)
                        .frame(height: 250)
                        .cornerRadius(12)

                    // CLUB PICKER
                    VStack(spacing: 8) {
                        HStack {
                            Text("Club")
                                .font(.headline)
                            Spacer()
                            Picker("Club", selection: $selectedClub) {
                                ForEach(clubOptions, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.menu)
                        }
                        HStack(spacing: 8) {
                            Text("Selected: \(selectedClub)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Text("Capture one frame for each stage: Setup, Backswing, Top of Swing, Downswing, Follow-through.")
                        .padding()
                        .multilineTextAlignment(.center)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)

                    // Progress + missing labels
                    VStack(spacing: 6) {
                        Text("Frames captured: \(uniqueCount())/5")
                            .font(.headline)
                        if !missingLabels().isEmpty {
                            Text("Missing: \(missingLabels().joined(separator: ", "))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Picker("Swing Position", selection: $currentLabel) {
                        ForEach(requiredLabels, id: \.self) { label in
                            Text(label).tag(label)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 110)
                    .clipped()
                    .padding(.horizontal)

                    HStack {
                        Button("Capture Frame") {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            captureCurrentFrame()
                        }
                        .buttonStyle(.borderedProminent)

                        if !capturedFrames.isEmpty {
                            Button("Clear") {
                                capturedFrames.removeAll()
                                navigateToAnalyze = false
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    if !capturedFrames.isEmpty {
                        Text("Captured Frames").font(.headline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(capturedFrames) { frame in
                                    VStack {
                                        Image(uiImage: frame.image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 120, height: 80)
                                            .cornerRadius(8)
                                        Text(frame.label)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Auto-navigate once all 5 unique stages are captured
                    NavigationLink(
                        destination: AnalyzePage(
                            videoURL: videoURL,
                            frames: orderedFrames(),
                            club: selectedClub // <-- pass club into analysis
                        ),
                        isActive: $navigateToAnalyze
                    ) { EmptyView() }
                    .hidden()
                }
                .padding()
            }
            .onDisappear { player.pause() }
        }
    }

    // Keep frames ordered consistently for AnalyzePage
    private func orderedFrames() -> [LabeledFrame] {
        let byLabel = Dictionary(uniqueKeysWithValues: capturedFrames.map { ($0.label, $0) })
        return requiredLabels.compactMap { byLabel[$0] }
    }

    private func uniqueCount() -> Int {
        Set(capturedFrames.map { $0.label }).count
    }

    private func missingLabels() -> [String] {
        let have = Set(capturedFrames.map { $0.label })
        return requiredLabels.filter { !have.contains($0) }
    }

    private func captureCurrentFrame() {
        let asset = AVAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter  = .zero

        let currentTime = player.currentTime()
        do {
            let cgImage = try generator.copyCGImage(at: currentTime, actualTime: nil)
            let uiImage = UIImage(cgImage: cgImage)

            // Resize to keep memory modest (bound by width)
            let maxW: CGFloat = 1024
            let resized: UIImage
            if uiImage.size.width > maxW {
                let h = maxW * uiImage.size.height / uiImage.size.width
                resized = resize(uiImage, to: CGSize(width: maxW, height: h))
            } else {
                resized = uiImage
            }

            // Replace existing frame for a label (enforce one per stage)
            if let idx = capturedFrames.firstIndex(where: { $0.label == currentLabel }) {
                capturedFrames[idx] = LabeledFrame(image: resized, label: currentLabel)
            } else {
                capturedFrames.append(LabeledFrame(image: resized, label: currentLabel))
            }

            // Navigate only when all 5 unique labels are present
            navigateToAnalyze = uniqueCount() == 5

            print("✅ Captured \(currentTime.seconds)s as \(currentLabel). Unique stages: \(uniqueCount())/5  | Club: \(selectedClub)")
        } catch {
            print("❌ Failed to capture frame: \(error.localizedDescription)")
        }
    }

    // Local resize helper (avoids needing a UIImage extension)
    private func resize(_ image: UIImage, to size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

#Preview {
    SwingFrameCapture(videoURL: URL(string: "https://example.com/fake.mp4")!)
}
