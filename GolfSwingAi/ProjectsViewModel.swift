import Foundation
import SwiftUI
import UIKit

struct SwingProject: Identifiable {
    let id = UUID()
    let analyzedAt: Date
    let club: String
    let videoURL: URL
    let labeledFrames: [LabeledFrame]
    let feedback: String

    init(club: String,
         videoURL: URL,
         labeledFrames: [LabeledFrame],
         feedback: String,
         analyzedAt: Date = Date()) {
        self.club = club
        self.videoURL = videoURL
        self.labeledFrames = labeledFrames
        self.feedback = feedback
        self.analyzedAt = analyzedAt
    }

    var title: String {
        let df = SwingProject.dateFormatter
        return "\(club) • \(df.string(from: analyzedAt))"
    }

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()
}

final class ProjectsViewModel: ObservableObject {
    @Published var projects: [SwingProject] = []

    func add(project: SwingProject) {
        projects.insert(project, at: 0) // newest first
    }

    func delete(_ project: SwingProject) {
        projects.removeAll { $0.id == project.id }
    }
}
