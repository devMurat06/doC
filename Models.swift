import SwiftUI
import Combine

// MARK: - Document Model
struct ScannedDocument: Identifiable, Codable {
    let id: UUID
    let imagePath: String // Store path instead of UIImage
    let category: String
    let confidence: Double
    let date: Date
    var folderID: UUID?
    var tags: [String]
    var extractedText: String?
    var detectedURLs: [String]
    var detectedAmount: Double?
    var detectedCurrency: String?
    
    init(id: UUID = UUID(), imagePath: String, category: String, confidence: Double, date: Date, folderID: UUID? = nil, tags: [String] = [], extractedText: String? = nil, detectedURLs: [String] = [], detectedAmount: Double? = nil, detectedCurrency: String? = nil) {
        self.id = id
        self.imagePath = imagePath
        self.category = category
        self.confidence = confidence
        self.date = date
        self.folderID = folderID
        self.tags = tags
        self.extractedText = extractedText
        self.detectedURLs = detectedURLs
        self.detectedAmount = detectedAmount
        self.detectedCurrency = detectedCurrency
    }
}

// MARK: - Folder Model
struct DocumentFolder: Identifiable, Codable {
    let id: UUID
    var name: String
    var icon: String
    var color: String
    let createdDate: Date
    
    init(id: UUID = UUID(), name: String, icon: String = "folder.fill", color: String = "blue", createdDate: Date = Date()) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.createdDate = createdDate
    }
}

// MARK: - App Settings
struct AppSettings: Codable {
    var isDarkMode: Bool
    var pinEnabled: Bool
    var pinCode: String?
    var soundEnabled: Bool
    var hapticEnabled: Bool
    
    init(isDarkMode: Bool = true, pinEnabled: Bool = false, pinCode: String? = nil, soundEnabled: Bool = true, hapticEnabled: Bool = true) {
        self.isDarkMode = isDarkMode
        self.pinEnabled = pinEnabled
        self.pinCode = pinCode
        self.soundEnabled = soundEnabled
        self.hapticEnabled = hapticEnabled
    }
}

// MARK: - Storage Manager
class DataManager: ObservableObject {
    @Published var folders: [DocumentFolder] = []
    @Published var documents: [ScannedDocument] = []
    @Published var settings: AppSettings = AppSettings()
    
    private let foldersKey = "saved_folders"
    private let documentsKey = "saved_documents"
    private let settingsKey = "app_settings"
    
    init() {
        loadData()
        createDefaultFolders()
    }
    
    func loadData() {
        // Load folders
        if let data = UserDefaults.standard.data(forKey: foldersKey),
           let decoded = try? JSONDecoder().decode([DocumentFolder].self, from: data) {
            folders = decoded
        }
        
        // Load documents
        if let data = UserDefaults.standard.data(forKey: documentsKey),
           let decoded = try? JSONDecoder().decode([ScannedDocument].self, from: data) {
            documents = decoded
        }
        
        // Load settings
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        }
    }
    
    func saveData() {
        // Save folders
        if let encoded = try? JSONEncoder().encode(folders) {
            UserDefaults.standard.set(encoded, forKey: foldersKey)
        }
        
        // Save documents
        if let encoded = try? JSONEncoder().encode(documents) {
            UserDefaults.standard.set(encoded, forKey: documentsKey)
        }
        
        // Save settings
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }
    
    func createDefaultFolders() {
        if folders.isEmpty {
            folders = [
                DocumentFolder(name: "Faturalar", icon: "doc.text.fill", color: "blue"),
                DocumentFolder(name: "Kimlikler", icon: "person.text.rectangle", color: "purple"),
                DocumentFolder(name: "Kartvizitler", icon: "rectangle.portrait.fill", color: "pink"),
                DocumentFolder(name: "Diğer", icon: "folder.fill", color: "gray")
            ]
            saveData()
        }
    }
    
    func addFolder(_ folder: DocumentFolder) {
        folders.append(folder)
        saveData()
    }
    
    func deleteFolder(_ folder: DocumentFolder) {
        folders.removeAll { $0.id == folder.id }
        // Remove folder reference from documents
        documents = documents.map { doc in
            var updatedDoc = doc
            if updatedDoc.folderID == folder.id {
                updatedDoc.folderID = nil
            }
            return updatedDoc
        }
        saveData()
    }
    
    func addDocument(_ document: ScannedDocument) {
        documents.insert(document, at: 0)
        saveData()
    }
    
    func deleteDocument(_ document: ScannedDocument) {
        documents.removeAll { $0.id == document.id }
        // Delete image file
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagePath = documentsPath.appendingPathComponent(document.imagePath)
        try? fileManager.removeItem(at: imagePath)
        saveData()
    }
    
    func moveDocument(_ document: ScannedDocument, to folder: DocumentFolder?) {
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            var updatedDoc = documents[index]
            updatedDoc.folderID = folder?.id
            documents[index] = updatedDoc
            saveData()
        }
    }
    
    func documentsInFolder(_ folder: DocumentFolder?) -> [ScannedDocument] {
        if let folder = folder {
            return documents.filter { $0.folderID == folder.id }
        } else {
            return documents.filter { $0.folderID == nil }
        }
    }
    
    func updateSettings(_ settings: AppSettings) {
        self.settings = settings
        saveData()
    }
    
    func saveImage(_ image: UIImage) -> String? {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "\(UUID().uuidString).jpg"
        let filePath = documentsPath.appendingPathComponent(fileName)
        
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: filePath)
            return fileName
        }
        return nil
    }
    
    func loadImage(from path: String) -> UIImage? {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsPath.appendingPathComponent(path)
        
        if let data = try? Data(contentsOf: filePath) {
            return UIImage(data: data)
        }
        return nil
    }
}
