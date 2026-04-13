import SwiftUI
import UIKit

// MARK: - Projects Page (with header spacing)
struct ProjectsPage: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Projects")
                        .font(.largeTitle.weight(.bold))
                        .padding(.top, 8)

                    if projectsVM.projects.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 52))
                                .foregroundStyle(.secondary)
                            Text("No projects yet")
                                .font(.title3.weight(.semibold))
                            Text("Analyze a swing to create your first project tile.")
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 48)
                    } else {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(projectsVM.projects) { project in
                                ProjectTile(project: project)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - Tile (long-press to delete)
private struct ProjectTile: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    let project: SwingProject

    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationLink {
            ProjectDetailView(project: project)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    if let first = project.labeledFrames.first {
                        Image(uiImage: first.image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 110)
                            .clipped()
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                            .frame(height: 110)
                            .overlay {
                                Image(systemName: "figure.golf")
                                    .font(.system(size: 32, weight: .regular))
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text(project.title)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                    .foregroundStyle(.primary)

                Text("Frames: \(project.labeledFrames.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(Rectangle()) // ensures whole card is the hit area
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete this project?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { projectsVM.delete(project) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }
}

// MARK: - Detail + full-screen gallery
struct ProjectDetailView: View {
    let project: SwingProject
    @State private var showGallery = false
    @State private var galleryIndex = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.title)
                        .font(.title2.weight(.semibold))
                    Text(project.videoURL.lastPathComponent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !project.labeledFrames.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(project.labeledFrames.enumerated()), id: \.offset) { idx, frame in
                                Button {
                                    galleryIndex = idx
                                    showGallery = true
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(uiImage: frame.image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 150, height: 96)
                                            .clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        Text(frame.label)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }

                Text("Feedback")
                    .font(.headline)
                Text(project.feedback)
                    .font(.body)
                    .textSelection(.enabled)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding()
        }
        .navigationTitle("Project")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showGallery) {
            ImageGalleryView(
                images: project.labeledFrames.map { $0.image },
                labels: project.labeledFrames.map { $0.label },
                startIndex: galleryIndex
            )
        }
    }
}

// MARK: - Full-screen swipeable gallery with pinch-to-zoom
private struct ImageGalleryView: View {
    let images: [UIImage]
    let labels: [String]
    let startIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var index: Int = 0

    var body: some View {
        ZStack {
            TabView(selection: $index) {
                ForEach(images.indices, id: \.self) { i in
                    ZoomableImage(image: images[i])
                        .tag(i)
                        .ignoresSafeArea()
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .automatic))
            .onAppear { index = startIndex }

            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(8)
                    }
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.horizontal, 8)
                Spacer()
            }

            VStack {
                Spacer()
                if labels.indices.contains(index) {
                    Text(labels[index])
                        .font(.callout.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.bottom, 24)
                }
            }
        }
        .background(Color.black)
    }
}

// MARK: - Pinch-to-zoom using UIScrollView
private struct ZoomableImage: UIViewRepresentable {
    let image: UIImage
    func makeUIView(context: Context) -> UIScrollView {
        let scroll = UIScrollView()
        scroll.minimumZoomScale = 1.0
        scroll.maximumZoomScale = 4.0
        scroll.bouncesZoom = true
        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        scroll.backgroundColor = .black

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false

        scroll.addSubview(imageView)
        context.coordinator.imageView = imageView

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            imageView.centerXAnchor.constraint(equalTo: scroll.frameLayoutGuide.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: scroll.frameLayoutGuide.centerYAnchor)
        ])

        return scroll
    }
    func updateUIView(_ scroll: UIScrollView, context: Context) {
        context.coordinator.imageView?.image = image
    }
    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator: NSObject, UIScrollViewDelegate {
        weak var imageView: UIImageView?
        func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
    }
}

// MARK: - Previews
#Preview("Projects Page") {
    let vm = ProjectsViewModel()
    let img = UIImage(systemName: "figure.golf") ?? UIImage()
    let frames = [
        LabeledFrame(image: img, label: "Setup"),
        LabeledFrame(image: img, label: "Backswing"),
        LabeledFrame(image: img, label: "Top of Swing"),
        LabeledFrame(image: img, label: "Downswing"),
        LabeledFrame(image: img, label: "Follow-through"),
    ]
    vm.add(project: SwingProject(club: "7i",
                                 videoURL: URL(string: "https://example.com/a.mp4")!,
                                 labeledFrames: frames,
                                 feedback: "Sample feedback…"))
    vm.add(project: SwingProject(club: "Driver",
                                 videoURL: URL(string: "https://example.com/b.mp4")!,
                                 labeledFrames: frames,
                                 feedback: "Sample feedback…"))
    return ProjectsPage().environmentObject(vm)
}

#Preview("Project Detail") {
    let vm = ProjectsViewModel()
    let img = UIImage(systemName: "figure.golf") ?? UIImage()
    let frames = [
        LabeledFrame(image: img, label: "Setup"),
        LabeledFrame(image: img, label: "Backswing"),
        LabeledFrame(image: img, label: "Top of Swing"),
        LabeledFrame(image: img, label: "Downswing"),
        LabeledFrame(image: img, label: "Follow-through"),
    ]
    let p = SwingProject(club: "PW",
                         videoURL: URL(string: "https://example.com/clip.mp4")!,
                         labeledFrames: frames,
                         feedback: "Preview feedback text…")
    vm.add(project: p)
    return NavigationStack { ProjectDetailView(project: p) }
        .environmentObject(vm)
}
