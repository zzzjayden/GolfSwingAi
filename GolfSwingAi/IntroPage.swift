//#-learning-task(getStartedWithApps)
import SwiftUI

struct Intropage: View {
    @AppStorage("Name") private var name: String = ""
    @AppStorage("isSignedIn") private var isSignedIn: Bool = false
    @AppStorage("hasSeenIntro") private var hasSeenIntro: Bool = false

    @State private var goHome: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Text("Hello, Golfer!")
                    .font(.largeTitle).bold()
                    .foregroundColor(.purple)

                Image("App Icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .frame(maxWidth: 220)

                Text("Powered by ChatGPT")
                    .foregroundColor(.secondary)
                    .padding(.bottom)

                if !isSignedIn {
                    // First-time users (or signed out) go to Login
                    NavigationLink(destination: LoginPage()) {
                        Text("Get Started with GolfSwingAI")
                            .padding(10)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                } else {
                    // Signed in: show first-run intro once, then "Welcome back" on subsequent launches
                    if !hasSeenIntro {
                        // First time right after login
                        welcomeBlock(
                            title: name.isEmpty ? "Welcome!" : "Welcome, \(name)!",
                            subtitle: "Setting things up for you…",
                            delay: 1.4,
                            then: {
                                hasSeenIntro = true
                                goHome = true
                            }
                        )
                    } else {
                        // Second and future app opens
                        welcomeBlock(
                            title: name.isEmpty ? "Welcome back!" : "Welcome back, \(name)!",
                            subtitle: "Loading your dashboard…",
                            delay: 0.9,
                            then: { goHome = true }
                        )
                    }
                }
            }
            .padding()
            // Invisible programmatic navigation to Home
            .background(
                NavigationLink("",
                               destination: HomePage()
                                .navigationBarBackButtonHidden(true),
                               isActive: $goHome)
                .hidden()
            )
            .navigationTitle("Welcome")
        }
    }

    @ViewBuilder
    private func welcomeBlock(title: String, subtitle: String, delay: Double, then: @escaping () -> Void) -> some View {
        VStack(spacing: 8) {
            Text(title).font(.title2).bold()
            Text(subtitle).foregroundColor(.secondary)
            ProgressView().padding(.top, 6)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { then() }
        }
    }
}

#Preview {
    Intropage()
}
