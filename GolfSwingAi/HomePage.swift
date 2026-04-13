import SwiftUI

struct HomePage: View {
    @State private var selectedTab = 0
    @AppStorage("Name") private var name = ""
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // 🏠 HOME TAB
            NavigationStack {
                HomeDashboard()
                    .navigationTitle("Home")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(0)
            
            // 📂 PROJECTS TAB
            ProjectsPage()
                .tabItem { Label("Projects", systemImage: "folder") }
                .tag(1)
            
            // 📷 RECORD TAB
            RecordingPage()
                .tabItem { Label("Record", systemImage: "camera") }
                .tag(2)
            
            // 🎯 DRILLS TAB
            Drillspage()
                .tabItem { Label("Drills", systemImage: "target") }
                .tag(3)
            
            // ⚙️ SETTINGS TAB
            Settings()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(4)
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Dashboard
private struct HomeDashboard: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @AppStorage("Name") private var name = ""
    @AppStorage("user_api_key") private var apiKey: String = ""
    
    // State
    @State private var question: String = ""
    @State private var aiAnswer: String = ""
    @State private var isAsking = false
    @State private var copyToast = false
    @State private var errorText: String?
    
    @FocusState private var isQuestionFocused: Bool
    
    // Tips
    private let tips: [Tip] = [
        Tip(title: "Driver Setup: Tee Height", text: "Half the ball above the crown helps you hit up on it—reduce spin and launch it higher."),
        Tip(title: "Trail Elbow on Backswing", text: "Keep it more down and connected to avoid lifting the arms and steepening the shaft."),
        Tip(title: "Tempo Cue: 3:1", text: "Count ‘one-two-three’ to the top, ‘one’ down through impact. Smooth back, athletic through."),
        Tip(title: "Face Control with Wedges", text: "Quiet hands, turn your chest through the ball to control loft and contact."),
    ]
    @State private var tipIndex: Int = Int.random(in: 0..<4)
    
    private let sectionSpacing: CGFloat = 36
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: sectionSpacing) {
                
                // Greeting
                VStack(alignment: .leading, spacing: 8) {
                    Text(name.isEmpty ? "Welcome back!" : "Welcome back, \(name)!")
                        .font(.title2.weight(.semibold))
                    Text("Your Golf Coach on Demand")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 2)
                
                aiQuestionBox
                
                recentAnalysis
                
                tipOfDay
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 40)
            .contentShape(Rectangle())
            .onTapGesture { isQuestionFocused = false }
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isQuestionFocused = false }
            }
        }
    }
    
    // MARK: - Components
    
    private var aiQuestionBox: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text("Ask GolfSwingAI Anything ⛳️")
                    .font(.headline)
                Spacer(minLength: 8)
                if isAsking { ProgressView() }
            }
            
            HStack(spacing: 10) {
                TextField("e.g., Why do I slice my driver?", text: $question, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .focused($isQuestionFocused)
                    .submitLabel(.go)
                    .onSubmit { askAI() }
                
                Button(action: askAI) {
                    Image(systemName: "paperplane.fill")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAsking)
            }
            
            if let errorText {
                Text(errorText)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            
            if !aiAnswer.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(aiAnswer)
                        .font(.body)
                        .textSelection(.enabled)
                    
                    HStack {
                        Spacer()
                        Button {
                            UIPasteboard.general.string = aiAnswer
                            withAnimation { copyToast = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                withAnimation { copyToast = false }
                            }
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(18)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(alignment: .top) {
            if copyToast {
                Text("Copied")
                    .font(.caption)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.top, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private var recentAnalysis: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Recent Analysis")
                    .font(.headline)
                Spacer()
                NavigationLink("View All") { ProjectsPage() }
                    .font(.subheadline)
            }
            
            if projectsVM.projects.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                    Text("Analyze a swing to create your first project.")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                .padding(.vertical, 6)
            } else {
                ForEach(Array(projectsVM.projects.prefix(2))) { p in
                    NavigationLink {
                        ProjectDetailView(project: p)
                    } label: {
                        HStack(spacing: 16) {
                            if let img = p.labeledFrames.first?.image {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 92, height: 60)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.secondarySystemBackground))
                                    .frame(width: 92, height: 60)
                                    .overlay {
                                        Image(systemName: "figure.golf")
                                            .foregroundStyle(.secondary)
                                    }
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text(p.title)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(2)
                                Text("Frames: \(p.labeledFrames.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var tipOfDay: some View {
        let tip = tips[tipIndex % tips.count]
        return VStack(alignment: .leading, spacing: 10) {
            Text("Tip of the Day")
                .font(.headline)
            Text(tip.title)
                .font(.subheadline.weight(.semibold))
            Text(tip.text)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    // MARK: - Ask AI
    private func askAI() {
      
        isQuestionFocused = false
        
        errorText = nil
        aiAnswer = ""
        let q = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            setError("❌ API key is missing. Add it on the Login page.")
            return
        }
        isAsking = true
        
        Task {
            do {
                let body: [String: Any] = [
                    "model": "gpt-4o-mini",
                    "messages": [
                        ["role": "system", "content": "You are a professional golf coach. Give concise, practical answers with 2–4 bullet points when helpful."],
                        ["role": "user", "content": q]
                    ],
                    "max_tokens": 500
                ]
                
                guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
                    setError("❌ Invalid API URL.")
                    return
                }
                var req = URLRequest(url: url)
                req.httpMethod = "POST"
                req.timeoutInterval = 45
                req.addValue("application/json", forHTTPHeaderField: "Content-Type")
                req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
                
                let (data, resp) = try await URLSession.shared.data(for: req)
                if let http = resp as? HTTPURLResponse, http.statusCode != 200 {
                    let serverMsg = String(data: data, encoding: .utf8) ?? ""
                    setError("❌ API error (\(http.statusCode)). \(serverMsg)")
                    return
                }
                guard
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let choices = json["choices"] as? [[String: Any]],
                    let message = choices.first?["message"] as? [String: Any],
                    let content = message["content"] as? String
                else {
                    setError("❌ Unexpected API response.")
                    return
                }
                setAnswer(formatBullets(content))
            } catch {
                setError("❌ Network error: \(error.localizedDescription)")
            }
        }
    }
    
    private func formatBullets(_ s: String) -> String {
        var t = s.replacingOccurrences(of: "\r\n", with: "\n")
        t = t.replacingOccurrences(of: #"(?m)^[\-\*]\s+"#, with: "• ", options: .regularExpression)
        t = t.replacingOccurrences(of: #"(?<!\n)•\s*"#, with: "\n• ", options: .regularExpression)
        t = t.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func setAnswer(_ text: String) {
        DispatchQueue.main.async {
            self.aiAnswer = text
            self.isAsking = false
        }
    }
    private func setError(_ text: String) {
        DispatchQueue.main.async {
            self.errorText = text
            self.isAsking = false
        }
    }
    
    private struct Tip {
        let title: String
        let text: String
    }
}

// MARK: - Preview
#Preview {
    let vm = ProjectsViewModel()
    let img = UIImage(systemName: "figure.golf") ?? UIImage()
    let frames = [
        LabeledFrame(image: img, label: "Setup"),
        LabeledFrame(image: img, label: "Backswing"),
        LabeledFrame(image: img, label: "Top of Swing"),
        LabeledFrame(image: img, label: "Downswing"),
        LabeledFrame(image: img, label: "Follow-through"),
    ]
    vm.add(project: SwingProject(club: "Driver",
                                 videoURL: URL(string: "https://example.com/clip.mp4")!,
                                 labeledFrames: frames,
                                 feedback: "Sample feedback…"))
    vm.add(project: SwingProject(club: "7i",
                                 videoURL: URL(string: "https://example.com/clip2.mp4")!,
                                 labeledFrames: frames,
                                 feedback: "Sample feedback…"))
    return HomePage()
        .environmentObject(vm)
}
