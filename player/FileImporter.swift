import SwiftUI
import UniformTypeIdentifiers
import MobileCoreServices

class FileImporter: NSObject, ObservableObject, UIDocumentPickerDelegate {
    let allowedContentTypes: [UTType]
    let presentingViewController: UIViewController?
    let completion: (URL) -> Void

    @Published var isPresented = false
    @Published var selectedFileURL: URL?

    var urlStore = URLStore()

    init(allowedContentTypes: [UTType], presentingViewController: UIViewController? = nil, completion: @escaping (URL) -> Void) {
        self.allowedContentTypes = allowedContentTypes
        self.presentingViewController = presentingViewController
        self.completion = completion
    }

    func present(from viewController: UIViewController) {
        let picker = UIDocumentPickerViewController(documentTypes: allowedContentTypes.map(\.identifier), in: .import)
        picker.delegate = self
        viewController.present(picker, animated: true)
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            return
        }

        selectedFileURL = url
        urlStore.urls.append(url)
        completion(url) // добавляем эту строчку для вызова переданного замыкания при выборе файла
        isPresented = false
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        isPresented = false
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let fileImporter: FileImporter

        init(_ fileImporter: FileImporter) {
            self.fileImporter = fileImporter
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            fileImporter.documentPicker(controller, didPickDocumentsAt: urls)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            fileImporter.documentPickerWasCancelled(controller)
        }
    }
}
