import SwiftUI

@main
struct MyApp: App {
    @StateObject private var projectsVM = ProjectsViewModel()

    var body: some Scene {
        WindowGroup {
            Intropage()
                .environmentObject(projectsVM) 
        }
    }
}

#Preview {
    Intropage()
        .environmentObject(ProjectsViewModel())
}
