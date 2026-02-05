import Foundation
import Vision
import UIKit

// MARK: - Text Extractor
class TextExtractor {
    static let shared = TextExtractor()
    
    // MARK: - URL Extraction
    func extractURLs(from text: String) -> [String] {
        let urlPattern = "(https?://[\\w\\-._~:/?#\\[\\]@!$&'()*+,;=%]+)"
        
        guard let regex = try? NSRegularExpression(pattern: urlPattern, options: .caseInsensitive) else {
            return []
        }
        
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        return matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range])
        }
    }
    
    // MARK: - Amount Extraction
    func extractAmount(from text: String) -> (amount: Double?, currency: String?) {
        // Patterns for different currency formats
        let patterns = [
            // Turkish: 1.234,56 TL or 1.234,56 ₺
            "(\\d{1,3}(?:\\.\\d{3})*(?:,\\d{2})?)\\s*(TL|₺)",
            // International: 1,234.56 $ or 1,234.56 USD
            "(\\d{1,3}(?:,\\d{3})*(?:\\.\\d{2})?)\\s*(\\$|USD|EUR|€)",
            // Simple: 123.45 TL or 123,45 TL
            "(\\d+[.,]\\d{2})\\s*(TL|₺|\\$|USD|EUR|€)",
            // With keywords: Toplam: 123.45 TL
            "(?:toplam|total|tutar|amount)[:\\s]+(\\d{1,3}(?:[.,]\\d{3})*(?:[.,]\\d{2})?)\\s*(TL|₺|\\$|USD|EUR|€)"
        ]
        
        var highestAmount: Double?
        var currency: String?
        
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                continue
            }
            
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            for match in matches {
                if match.numberOfRanges >= 3 {
                    // Extract amount string
                    if let amountRange = Range(match.range(at: 1), in: text) {
                        var amountStr = String(text[amountRange])
                        
                        // Normalize: Replace comma with period for parsing
                        // If both exist, assume European format (1.234,56 -> 1234.56)
                        if amountStr.contains(",") && amountStr.contains(".") {
                            amountStr = amountStr.replacingOccurrences(of: ".", with: "")
                                                 .replacingOccurrences(of: ",", with: ".")
                        } else if amountStr.contains(",") {
                            amountStr = amountStr.replacingOccurrences(of: ",", with: ".")
                        }
                        
                        if let amount = Double(amountStr) {
                            if highestAmount == nil || amount > highestAmount! {
                                highestAmount = amount
                                
                                // Extract currency
                                if let currencyRange = Range(match.range(at: 2), in: text) {
                                    currency = String(text[currencyRange])
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return (highestAmount, currency)
    }
    
    // MARK: - Full OCR
    func performOCR(on image: UIImage, completion: @escaping (String, [String], Double?, String?) -> Void) {
        guard let ciImage = CIImage(image: image) else {
            completion("", [], nil, nil)
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion("", [], nil, nil)
                return
            }
            
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            // Extract URLs
            let urls = self.extractURLs(from: recognizedText)
            
            // Extract amount
            let (amount, currency) = self.extractAmount(from: recognizedText)
            
            DispatchQueue.main.async {
                completion(recognizedText, urls, amount, currency)
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["tr-TR", "en-US"]
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("OCR Error: \(error)")
                DispatchQueue.main.async {
                    completion("", [], nil, nil)
                }
            }
        }
    }
}
