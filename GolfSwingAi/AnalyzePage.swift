import SwiftUI
import UIKit
import AVFoundation
import Foundation

struct AnalyzePage: View {
    let videoURL: URL
    let frames: [LabeledFrame]
    let club: String // passed in from capture

    @AppStorage("user_api_key") private var apiKey: String = ""
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var projectsVM: ProjectsViewModel   // make sure MyApp injects this

    @State private var feedback: String = "Analyzing your swing..."
    @State private var isProcessing = true
    @State private var copyToast = false
    @State private var goHome = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Analysis")
                    .font(.largeTitle.weight(.semibold))
                Spacer()
                Button {
                    UIPasteboard.general.string = feedback
                    withAnimation { copyToast = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation { copyToast = false }
                    }
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
            }

            HStack {
                Text("Club: \(club)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }

            if isProcessing {
                Spacer()
                ProgressView("Generating Feedback")
                    .padding(.bottom, 8)
                Text("This can take 5–15 seconds.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ScrollView {
                    Text(feedback)
                        .font(.body)
                        .lineSpacing(4)
                        .textSelection(.enabled)
                        .padding(16)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button("Done") {
                    // Save a project tile with club + date in the title
                    let project = SwingProject(
                        club: club,
                        videoURL: videoURL,
                        labeledFrames: frames,
                        feedback: feedback
                    )
                    projectsVM.add(project: project)
                    goHome = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .overlay(alignment: .top) {
            if copyToast {
                Text("Copied")
                    .font(.caption)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(
            NavigationLink(
                destination: HomePage().navigationBarBackButtonHidden(true),
                isActive: $goHome
            ) { EmptyView() }
            .hidden()
        )
        .onAppear { analyzeSelectedFrames() }
    }

    // MARK: - Analyze the captured frames (expects 5 stages)
    private func analyzeSelectedFrames() {
        isProcessing = true

        Task {
            guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                await setError("❌ API key is missing. Add it on the Login page.")
                return
            }

            let desiredOrder = ["Setup", "Backswing", "Top of Swing", "Downswing", "Follow-through"]
            var picked: [String: UIImage] = [:]
            for frame in frames {
                if picked[frame.label] == nil { picked[frame.label] = frame.image }
            }

            let ordered: [(String, UIImage)] = desiredOrder.compactMap { label in
                picked[label].map { (label, $0) }
            }

            guard ordered.count == 5 else {
                await setError("❌ Please capture all five stages: Setup, Backswing, Top of Swing, Downswing, Follow-through.")
                return
            }

            var content: [[String: Any]] = [
                [
                    "type": "text",
                    "text":
"""
You are a professional golf swing coach. Analyze the swing with the following labeled images and the stated club.

Club in use: \(club)

Adjust observations and drills to the specific club (driver/woods vs hybrids/long irons vs mid/short irons & wedges).

IMPORTANT FORMAT RULES:
• Do not use asterisks.
• Use the bullet character "•" for lists.
• Use headings exactly as: Setup, Backswing, Top of Swing, Downswing, Follow-Through, and Key Priorities.
• Keep it concise plain text.

• Include a 2 sentence summary, professionally hyping up the golfer, and giving positive feedback. For example "This looks solid..." or maybe you can use some golf slang so the golfer can feel more comfortable. Nothing too outrageous but you are a golf coach. 

STRUCTURE:
Setup
• Strengths: ...
• Weaknesses: ...
• Drills: ...

Backswing
• Strengths: ...
• Weaknesses: ...
• Drills: ...

Top of Swing
• Strengths: ...
• Weaknesses: ...
• Drills: ...

Downswing
• Strengths: ...
• Weaknesses: ...
• Drills: ...

Follow-Through
• Strengths: ...
• Weaknesses: ...
• Drills: ...

Key Priorities
• 1.
• 2.
• 3.
"""
                ]
            ]

            // Attach all 5 images (resized + base64)
            for (label, ui) in ordered {
                let resized = resizedForNetwork(ui, maxSide: 768)
                guard let jpg = resized.jpegData(compressionQuality: 0.7) else { continue }
                let base64 = jpg.base64EncodedString()

                content.append(["type": "text", "text": "\(label):"])
                content.append([
                    "type": "image_url",
                    "image_url": ["url": "data:image/jpeg;base64,\(base64)"]
                ])
            }

            let body: [String: Any] = [
                "model": "gpt-4o-mini",
                "messages": [
                    ["role": "user", "content": content]
                ],
                "max_tokens": 1200
            ]

            do {
                guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
                    await setError("❌ Invalid API URL.")
                    return
                }

                var req = URLRequest(url: url)
                req.httpMethod = "POST"
                req.timeoutInterval = 60
                req.addValue("application/json", forHTTPHeaderField: "Content-Type")
                req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

                let (data, resp) = try await URLSession.shared.data(for: req)

                if let http = resp as? HTTPURLResponse, http.statusCode != 200 {
                    let serverMsg = String(data: data, encoding: .utf8) ?? ""
                    await setError("❌ API error (\(http.statusCode)). \(serverMsg)")
                    return
                }

                guard
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let choices = json["choices"] as? [[String: Any]],
                    let message = choices.first?["message"] as? [String: Any]
                else {
                    await setError("❌ Unexpected API response shape.")
                    return
                }

                let raw = (message["content"] as? String) ??
                          (message["content"] as? [[String: Any]])?.compactMap { $0["text"] as? String }.joined(separator: "\n") ??
                          ""

                await setFeedback(raw.isEmpty ? "❌ Empty response." : raw)
            } catch {
                await setError("❌ Network error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Formatting helpers
    private func formatAnalysis(_ s: String) -> String {
        var t = s.replacingOccurrences(of: "\r\n", with: "\n")
        t = t.replacingOccurrences(of: #"Follow[\-\u2011 ]?Through"#,
                                   with: "Follow-Through",
                                   options: .regularExpression)
        t = t.replacingOccurrences(of: #"(?m)^[\-\*]\s+"#, with: "• ", options: .regularExpression)
        t = t.replacingOccurrences(of: #"(?<!\n)•\s*"#, with: "\n• ", options: .regularExpression)
        t = t.replacingOccurrences(of: "(?i)(?<!\\A)\\s*(Setup|Backswing|Top of Swing|Downswing|Follow-Through|Key Priorities)\\s*[:：]?",
                                   with: "\n\n$1\n", options: .regularExpression)
        t = t.replacingOccurrences(of: #"(?m)^(Setup|Backswing|Top of Swing|Downswing|Follow-Through|Key Priorities)\s*[:：]?\s*"#,
                                   with: "$1\n", options: .regularExpression)
        t = t.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Utilities
    private func resizedForNetwork(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        let w = image.size.width, h = image.size.height
        if max(w, h) <= maxSide { return image }
        let scale = (w > h) ? (maxSide / w) : (maxSide / h)
        let newSize = CGSize(width: floor(w * scale), height: floor(h * scale))

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    @MainActor private func setFeedback(_ text: String) {
        self.feedback = formatAnalysis(text)
        self.isProcessing = false
    }

    @MainActor private func setError(_ text: String) {
        self.feedback = text
        self.isProcessing = false
    }
}

#Preview {
    // Minimal preview (no API call) just to verify layout after analysis:
    let vm = ProjectsViewModel()
    let img = UIImage(systemName: "figure.golf") ?? UIImage()
    let sampleFrames = [
        LabeledFrame(image: img, label: "Setup"),
        LabeledFrame(image: img, label: "Backswing"),
        LabeledFrame(image: img, label: "Top of Swing"),
        LabeledFrame(image: img, label: "Downswing"),
        LabeledFrame(image: img, label: "Follow-through"),
    ]
    return AnalyzePage(
        videoURL: URL(string: "https://example.com/fake.mp4")!,
        frames: sampleFrames,
        club: "7i"
    )
    .environmentObject(vm)
}
