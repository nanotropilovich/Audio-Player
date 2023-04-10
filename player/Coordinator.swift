//
//  Coordinator.swift
//  player
//
//  Created by Ilya on 09.04.2023.
//

import Foundation
import UIKit
class Coordinator: NSObject, UIDocumentPickerDelegate {
    var parent: FileImporter

    init(_ parent: FileImporter) {
        self.parent = parent
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        parent.documentPicker(controller, didPickDocumentsAt: urls)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        parent.documentPickerWasCancelled(controller)
    }
}
