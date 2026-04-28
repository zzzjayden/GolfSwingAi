import SwiftUI

struct Settings: View {
    @AppStorage("Name") private var name: String = ""
    @AppStorage("user_api_key") private var apiKey: String = ""
    @AppStorage("isSignedIn") private var isSignedIn: Bool = true

    @State private var showKey: Bool = false
    @State private var isTesting: Bool = false
    @State private var testResult: String? = nil
    @State private var showAPIHelp: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Profile")) {
                    TextField("Your name", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }

                Section(header: HStack {
                    Text("OpenAI API")
                    Spacer()
                    Button {
                        showAPIHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("How to find your API key")
                }) {
                    HStack {
                        if showKey {
                            TextField("sk-...", text: $apiKey)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.system(.body, design: .monospaced))
                        } else {
                            SecureField("sk-...", text: $apiKey)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.system(.body, design: .monospaced))
                        }

                        Button {
                            showKey.toggle()
                        } label: {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                        }
                        .accessibilityLabel(showKey ? "Hide API key" : "Show API key")
                    }

                    HStack {
                        Button {
                            if let clip = UIPasteboard.general.string {
                                apiKey = clip.trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                        } label: {
                            Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                        }

                        Spacer()

                        Button(role: .destructive) {
                            apiKey = ""
                        } label: {
                            Label("Clear", systemImage: "trash")
                        }
                    }

                    if let testResult {
                        Text(testResult)
                            .font(.footnote)
                            .foregroundStyle(testResult.hasPrefix("✅") ? .green : .red)
                            .padding(.top, 4)
                    }

                    Button {
                        Task { await testAPIKey() }
                    } label: {
                        if isTesting {
                            ProgressView().padding(.vertical, 6)
                        } else {
                            Label("Test API Key", systemImage: "wifi")
                        }
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section(footer: Text("Changes are saved automatically.")) {
                    Button {
                        UIPasteboard.general.string = apiKey
                    } label: {
                        Label("Copy API Key", systemImage: "doc.on.doc")
                    }
                    .disabled(apiKey.isEmpty)
                }

                Section {
                    Button(role: .destructive) {
                        isSignedIn = false
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("How to Find Your API Key", isPresented: $showAPIHelp) {
                Button("Open Link") {
                    if let url = URL(string: "https://platform.openai.com/account/api-keys") {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Get your key from OpenAI. Keep it private.")
            }
        }
    }

    // MARK: - API Key Test (lightweight check)
    private func testAPIKey() async {
        isTesting = true
        testResult = nil
        defer { isTesting = false }

        guard let url = URL(string: "https://api.openai.com/v1/models") else {
            testResult = "❌ Invalid URL."
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = 20
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            let (_, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse {
                if http.statusCode == 200 {
                    testResult = "✅ Key looks valid."
                } else if http.statusCode == 401 {
                    testResult = "❌ Unauthorized. Check that the key is correct and active."
                } else {
                    testResult = "❌ Server responded with \(http.statusCode)."
                }
            } else {
                testResult = "❌ Unexpected response."
            }
        } catch {
            testResult = "❌ Network error: \(error.localizedDescription)"
        }
    }
}

#Preview {
    Settings()
}
