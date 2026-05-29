//
//  AnalysisExportDocument.swift
//  SentimentAnalyzer
//
//  Created by Karabelnikov Stepan on 06.02.2026.
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI

struct AnalysisExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText, .pdf] }

    let data: Data
    let contentType: UTType

    init(data: Data, contentType: UTType) {
        self.data = data
        self.contentType = contentType
    }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
        self.contentType = configuration.contentType
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        .init(regularFileWithContents: data)
    }
}
