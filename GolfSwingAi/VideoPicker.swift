//
//  VideoPicker.swift
//  GolfSwingAi
//
//  Created by Jayden Perkins on 6/30/25.
//

import SwiftUI
import PhotosUI

struct VideoPicker: UIViewControllerRepresentable {
    @Binding var videoURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: VideoPicker

        init(_ parent: VideoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let itemProvider = results.first?.itemProvider,
                  itemProvider.hasItemConformingToTypeIdentifier("public.movie") else { return }

            itemProvider.loadFileRepresentation(forTypeIdentifier: "public.movie") { url, error in
                if let url = url {
                    // Copy the file to a safe location so it doesn’t get deleted
                    let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let destURL = documents.appendingPathComponent(url.lastPathComponent)

                    try? FileManager.default.copyItem(at: url, to: destURL)
                    DispatchQueue.main.async {
                        self.parent.videoURL = destURL
                    }
                }
            }
        }
    }
}
