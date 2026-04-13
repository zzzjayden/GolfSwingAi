import SwiftUI

struct LoginPage: View {
    // Stored values (same keys you already use)
    @AppStorage("Name") private var name: String = ""
    @State private var email: String = ""
    @AppStorage("user_api_key") private var storedAPIKey: String = ""

    // One-time sign-in flag
    @AppStorage("isSignedIn") private var isSignedIn: Bool = false

    // UI state
    @State private var showAPIKeyInfo = false
    @State private var showKey = false
    @State private var errorMessage: String? = nil
    @State private var showIntroFlow = false

    var body: some View {
        VStack(spacing: 14) {
            Text("Enter some Details below")
                .font(.largeTitle)

            // Name
            Text("Please enter your Name below")
                .foregroundColor(.purple)
                .padding(.top, 4)

            TextField("Name", text: $name)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)

            // Email
            Text("Please enter your Email below")
                .foregroundColor(.purple)
                .padding(.top, 6)

            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)

            // API Key
            Text("Please enter your API Key below")
                .foregroundColor(.purple)
                .padding(.top, 6)

            HStack(spacing: 8) {
                if showKey {
                    TextField("sk-...", text: $storedAPIKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                } else {
                    SecureField("sk-...", text: $storedAPIKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                }

                Button {
                    showKey.toggle()
                } label: {
                    Image(systemName: showKey ? "eye.slash" : "eye")
                }

                Button {
                    showAPIKeyInfo = true
                } label: {
                    Image(systemName: "questionmark.circle")
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal)

            HStack {
                Button {
                    if let clip = UIPasteboard.general.string {
                        storedAPIKey = clip.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                } label: {
                    Label("Paste API Key", systemImage: "doc.on.clipboard")
                        .font(.subheadline)
                }

                Spacer()

                Button(role: .destructive) {
                    storedAPIKey = ""
                } label: {
                    Label("Clear", systemImage: "trash")
                        .font(.subheadline)
                }
            }
            .padding(.horizontal)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(.top, 4)
                    .padding(.horizontal)
            }

            // Sign In
            Button {
                signIn()
            } label: {
                Text("Press to save details")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.top, 6)
            .disabled(!canSignIn)

            Spacer(minLength: 8)
        }
        .padding()
        .navigationTitle("Login Page")
        .alert("How to Find Your API Key", isPresented: $showAPIKeyInfo) {
            Button("Open Link") {
                if let url = URL(string: "https://platform.openai.com/account/api-keys") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Get your key from OpenAI. Keep it private.")
        }
        // If already signed in, skip straight to the intro→home flow
        .onAppear {
            if isSignedIn { showIntroFlow = true }
        }
        // After sign-in, show Intro then Home
        .fullScreenCover(isPresented: $showIntroFlow) {
            PostLoginIntroFlow()
        }
    }

    private var canSignIn: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !storedAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func signIn() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKey = storedAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter your name."
            return
        }
        guard !trimmedKey.isEmpty else {
            errorMessage = "Please enter your OpenAI API key."
            return
        }

        name = trimmedName
        storedAPIKey = trimmedKey
        isSignedIn = true
        errorMessage = nil
        showIntroFlow = true
    }
}

// Wrapper that shows your Intro page briefly, then moves to Home.
// (No need to change your existing Intropage/HomePage files.)
private struct PostLoginIntroFlow: View {
    @State private var showHome = false

    var body: some View {
        NavigationStack {
            Group {
                if showHome {
                    HomePage()
                        .navigationBarBackButtonHidden(true)
                        .transition(.opacity)
                } else {
                    Intropage()
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                                withAnimation { showHome = true }
                            }
                        }
                }
            }
        }
    }
}

#Preview {
    LoginPage()
}
