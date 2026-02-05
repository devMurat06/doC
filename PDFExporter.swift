import Foundation
import PDFKit
import UIKit
import SwiftUI

// MARK: - PDF Exporter
class PDFExporter {
    static let shared = PDFExporter()
    
    // MARK: - Single Document to PDF
    func createPDF(from image: UIImage, metadata: (category: String, date: Date, amount: String?)? = nil) -> URL? {
        let pdfDocument = PDFDocument()
        
        guard let pdfPage = PDFPage(image: image) else {
            return nil
        }
        
        pdfDocument.insert(pdfPage, at: 0)
        
        // Add metadata if provided
        if let meta = metadata {
            // PDFKit attributes - use simple approach without specific attributes
            pdfDocument.documentAttributes = [
                "Title": "doC - \(meta.category)",
                "Creator": "doC Scanner",
                "CreationDate": meta.date
            ] as [String: Any]
        }
        
        // Create temporary file
        let fileName = "doc_\(UUID().uuidString).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        // Write PDF
        if pdfDocument.write(to: tempURL) {
            return tempURL
        }
        
        return nil
    }
    
    // MARK: - Multiple Documents to PDF
    func createPDF(from images: [UIImage], title: String = "Documents") -> URL? {
        let pdfDocument = PDFDocument()
        
        for (index, image) in images.enumerated() {
            guard let pdfPage = PDFPage(image: image) else {
                continue
            }
            pdfDocument.insert(pdfPage, at: index)
        }
        
        // Add metadata
        pdfDocument.documentAttributes = [
            "Title": "doC - \(title)",
            "Creator": "doC Scanner",
            "CreationDate": Date()
        ] as [String: Any]
        
        // Create temporary file
        let fileName = "\(title.replacingOccurrences(of: " ", with: "_"))_\(UUID().uuidString).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        // Write PDF
        if pdfDocument.write(to: tempURL) {
            return tempURL
        }
        
        return nil
    }
    
    // MARK: - Save to Files
    func savePDFToFiles(url: URL, completion: @escaping (Bool) -> Void) {
        // Copy to Documents directory
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsPath.appendingPathComponent(url.lastPathComponent)
        
        do {
            // Remove if exists
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            // Copy file
            try fileManager.copyItem(at: url, to: destinationURL)
            completion(true)
        } catch {
            print("Error saving PDF: \(error)")
            completion(false)
        }
    }
}

// MARK: - Share Sheet for SwiftUI
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
