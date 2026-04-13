import SwiftUI
import PhotosUI

struct RecordingPage: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var videoURL: URL? = nil
    @State private var navigateToAnalyze = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Record or Import Your Swing")
                    .font(.title)
                    .padding()

                PhotosPicker("Import Video", selection: $selectedItem, matching: .videos)
                    .buttonStyle(.borderedProminent)

                // Trigger when a video is selected
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let url = saveTempVideo(data: data) {
                            videoURL = url
                            navigateToAnalyze = true
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $navigateToAnalyze) {
                if let url = videoURL {
                    SwingFrameCapture(videoURL: url)
                } else {
                    Text("No video available")
                }
            }
        }
    }

    func saveTempVideo(data: Data) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Error saving video: \(error)")
            return nil
        }
    }
}
// MARK: - Preview
#Preview {
    RecordingPage()
}
