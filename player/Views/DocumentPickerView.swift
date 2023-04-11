//
//  URLListView.swift
//  player
//
//  Created by Ilya on 11.04.2023.
//

import Foundation
import SwiftUI
struct DocumentPickerView: UIViewControllerRepresentable {
    let fileImporter: FileImporter

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: fileImporter.allowedContentTypes)
        picker.delegate = context.coordinator as? UIDocumentPickerDelegate
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        uiViewController.allowsMultipleSelection = false
        uiViewController.shouldShowFileExtensions = true

        if #available(iOS 14.0, *) {
            uiViewController.allowsMultipleSelection = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(fileImporter: fileImporter)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let fileImporter: FileImporter

        init(fileImporter: FileImporter) {
            self.fileImporter = fileImporter
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            fileImporter.selectedFileURL = url
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            fileImporter.selectedFileURL = nil
            fileImporter.isPresented = false
        }
    }
}
