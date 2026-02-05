import SwiftUI
import VisionKit
import Vision
import PhotosUI
import AVFoundation

struct DocumentScannerView: View {
    @EnvironmentObject var dataManager: DataManager
    
    @State private var showScanner = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var scannedImage: UIImage?
    @State private var classificationResult = ""
    @State private var confidence: Double = 0.0
    @State private var isAnalyzing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSettings = false
    @State private var showFolderManagement = false
    @State private var selectedFolder: DocumentFolder?
    @State private var showFolderPicker = false
    @State private var selectedDocument: ScannedDocument?
    
    // New feature states
    @State private var extractedText: String = ""
    @State private var detectedURLs: [String] = []
    @State private var detectedAmount: Double?
    @State private var detectedCurrency: String?
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    
    var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                
                ScrollView {
                    VStack(spacing: 24) {
                        actionButtonsSection
                        
                        if let image = scannedImage {
                            scannedDocumentCard(image: image)
                        } else {
                            emptyStateView
                        }
                        
                        // Folder filter
                        folderFilterSection
                        
                        // Documents list
                        if !filteredDocuments.isEmpty {
                            savedDocumentsSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            
            if isAnalyzing {
                loadingOverlay
            }
        }
        .sheet(isPresented: $showScanner) {
            DocumentScannerRepresentable { result in
                switch result {
                case .success(let scan):
                    processScan(scan)
                case .failure(let error):
                    errorMessage = "Tarama hatası: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showFolderManagement) {
            FolderManagementView()
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showFolderPicker) {
            if let doc = selectedDocument {
                FolderPickerView(document: doc, isPresented: $showFolderPicker)
                    .environmentObject(dataManager)
            }
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam") { showError = false }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - UI Components
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: dataManager.settings.isDarkMode ?
                [Color(red: 0.1, green: 0.2, blue: 0.45), Color(red: 0.2, green: 0.1, blue: 0.35), Color(red: 0.15, green: 0.15, blue: 0.3)] :
                [Color(red: 0.95, green: 0.97, blue: 1.0), Color(red: 0.90, green: 0.93, blue: 0.98), Color(red: 0.85, green: 0.88, blue: 0.95)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var textColor: Color {
        dataManager.settings.isDarkMode ? .white : .black
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("doC Scanner")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                
                Spacer()
                
                // Settings Button
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(textColor.opacity(0.7))
                }
            }
            
            HStack {
                Text(isSimulator ? "📱 Simulator" : "📷 Cihaz")
                    .font(.caption)
                    .foregroundColor(textColor.opacity(0.6))
                
                Spacer()
                
                // Folder management
                Button(action: { showFolderManagement = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                        Text("\(dataManager.folders.count) klasör")
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.cyan.opacity(0.2))
                    .cornerRadius(12)
                    .foregroundColor(.cyan)
                }
                
                if !dataManager.documents.isEmpty {
                    Text("\(dataManager.documents.count) belge")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background((dataManager.settings.isDarkMode ? Color.white : Color.black).opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(textColor.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background((dataManager.settings.isDarkMode ? Color.black : Color.white).opacity(0.2))
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            if isSimulator {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    ActionButton(
                        icon: "photo.on.rectangle",
                        title: "Fotoğraf Seç",
                        subtitle: "Galeriden doküman yükle",
                        gradient: [.blue, .cyan],
                        isDarkMode: dataManager.settings.isDarkMode
                    )
                }
                .onChange(of: selectedItem) { oldValue, newValue in
                    loadSelectedPhoto(newValue)
                }
            } else {
                HStack(spacing: 12) {
                    Button(action: { showScanner = true }) {
                        ActionButton(
                            icon: "doc.text.viewfinder",
                            title: "Tara",
                            subtitle: "Kamera ile",
                            gradient: [.blue, .purple],
                            isCompact: true,
                            isDarkMode: dataManager.settings.isDarkMode
                        )
                    }
                    
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        ActionButton(
                            icon: "photo",
                            title: "Seç",
                            subtitle: "Galeriden",
                            gradient: [.purple, .pink],
                            isCompact: true,
                            isDarkMode: dataManager.settings.isDarkMode
                        )
                    }
                    .onChange(of: selectedItem) { oldValue, newValue in
                        loadSelectedPhoto(newValue)
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [textColor.opacity(0.3), textColor.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            Text("Doküman Taramaya Başla")
                .font(.title3.bold())
                .foregroundColor(textColor.opacity(0.8))
            
            Text("Faturalar, kimlikler ve kartvizitleri otomatik kategorize et")
                .font(.subheadline)
                .foregroundColor(textColor.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 60)
    }
    
    private func scannedDocumentCard(image: UIImage) -> some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill((dataManager.settings.isDarkMode ? Color.white : Color.black).opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(textColor.opacity(0.1), lineWidth: 1)
                    )
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(16)
                    .padding(8)
            }
            .frame(maxHeight: 300)
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            
            if !classificationResult.isEmpty {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: categoryIcon(for: classificationResult))
                            .font(.title2)
                            .foregroundColor(.cyan)
                        
                        Text(classificationResult)
                            .font(.title2.bold())
                            .foregroundColor(textColor)
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Güven Skoru")
                                .font(.caption)
                                .foregroundColor(textColor.opacity(0.6))
                            
                            Spacer()
                            
                            Text("\(Int(confidence * 100))%")
                                .font(.caption.bold())
                                .foregroundColor(confidenceColor(confidence))
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(textColor.opacity(0.1))
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [confidenceColor(confidence), confidenceColor(confidence).opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * confidence)
                            }
                        }
                        .frame(height: 8)
                    }
                    
                    // Amount Detection Display
                    if let amount = detectedAmount, let currency = detectedCurrency {
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.title3)
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Tespit Edilen Tutar")
                                    .font(.caption)
                                    .foregroundColor(textColor.opacity(0.6))
                                
                                Text("\(String(format: "%.2f", amount)) \(currency)")
                                    .font(.title3.bold())
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // URL Detection Display
                    if !detectedURLs.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "link.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Tespit Edilen URL'ler")
                                    .font(.caption.bold())
                                    .foregroundColor(textColor.opacity(0.7))
                            }
                            
                            ForEach(detectedURLs, id: \.self) { url in
                                Button(action: {
                                    if let urlObject = URL(string: url) {
                                        UIApplication.shared.open(urlObject)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "safari")
                                            .font(.caption)
                                        Text(url)
                                            .font(.caption)
                                            .lineLimit(1)
                                        Spacer()
                                        Image(systemName: "arrow.up.right.square")
                                            .font(.caption)
                                    }
                                    .padding(8)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(12)
                        .background((dataManager.settings.isDarkMode ? Color.white : Color.black).opacity(0.05))
                        .cornerRadius(12)
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        // PDF Export
                        Button(action: exportPDF) {
                            HStack {
                                Image(systemName: "doc.fill")
                                Text("PDF")
                                    .font(.subheadline.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.orange, .orange.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        // Save Document
                        Button(action: saveDocument) {
                            HStack {
                                Image(systemName: "arrow.down.doc")
                                Text("Kaydet")
                                    .font(.subheadline.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(20)
                .background((dataManager.settings.isDarkMode ? Color.white : Color.black).opacity(0.05))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(textColor.opacity(0.1), lineWidth: 1)
                )
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
    
    private var folderFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All documents
                FilterChip(
                    icon: "doc.fill",
                    title: "Tümü",
                    count: dataManager.documents.count,
                    isSelected: selectedFolder == nil,
                    isDarkMode: dataManager.settings.isDarkMode
                ) {
                    selectedFolder = nil
                }
                
                // Folders
                ForEach(dataManager.folders) { folder in
                    FilterChip(
                        icon: folder.icon,
                        title: folder.name,
                        count: dataManager.documentsInFolder(folder).count,
                        isSelected: selectedFolder?.id == folder.id,
                        color: Color(folder.color),
                        isDarkMode: dataManager.settings.isDarkMode
                    ) {
                        selectedFolder = folder
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var filteredDocuments: [ScannedDocument] {
        if let folder = selectedFolder {
            return dataManager.documentsInFolder(folder)
        } else {
            return dataManager.documents
        }
    }
    
    private var savedDocumentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(.cyan)
                Text(selectedFolder?.name ?? "Tüm Belgeler")
                    .font(.headline)
                    .foregroundColor(textColor)
                
                Spacer()
                
                Text("\(filteredDocuments.count)")
                    .font(.subheadline.bold())
                    .foregroundColor(.cyan)
            }
            
            VStack(spacing: 10) {
                ForEach(filteredDocuments) { doc in
                    if let image = dataManager.loadImage(from: doc.imagePath) {
                        SavedDocumentRow(
                            document: doc,
                            image: image,
                            isDarkMode: dataManager.settings.isDarkMode,
                            onMoveToFolder: {
                                selectedDocument = doc
                                showFolderPicker = true
                            },
                            onDelete: {
                                dataManager.deleteDocument(doc)
                            }
                        )
                    }
                }
            }
        }
        .padding(.top, 8)
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.cyan)
                
                Text("Analiz ediliyor...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("AI model dokümanı kategorize ediyor")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(32)
            .background(Color.white.opacity(0.1))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Helper Functions
    
    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case let c where c.contains("fatura") || c.contains("invoice"):
            return "doc.text.fill"
        case let c where c.contains("kimlik") || c.contains("id"):
            return "person.text.rectangle"
        case let c where c.contains("kartvizit") || c.contains("card"):
            return "rectangle.portrait.fill"
        default:
            return "doc.fill"
        }
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 { return .green }
        else if confidence >= 0.5 { return .yellow }
        else { return .orange }
    }
    
    // MARK: - Data Processing
    
    private func loadSelectedPhoto(_ item: PhotosPickerItem?) {
        Task {
            if let data = try? await item?.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    scannedImage = image
                    classifyImage(image)
                }
            }
        }
    }
    
    func processScan(_ scan: VNDocumentCameraScan) {
        guard scan.pageCount > 0 else { return }
        scannedImage = scan.imageOfPage(at: 0)
        
        if let image = scannedImage {
            classifyImage(image)
        }
    }
    
    func classifyImage(_ image: UIImage) {
        isAnalyzing = true
        classificationResult = ""
        confidence = 0
        
        // Haptic feedback
        if dataManager.settings.hapticEnabled {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let ciImage = CIImage(image: image) else {
                DispatchQueue.main.async {
                    self.errorMessage = "Görsel işlenemedi"
                    self.showError = true
                    self.isAnalyzing = false
                }
                return
            }
            
            // Fallback classification using OCR
            self.fallbackClassification(image: image)
        }
    }
    
    private func fallbackClassification(image: UIImage) {
        // Use TextExtractor for comprehensive OCR
        TextExtractor.shared.performOCR(on: image) { text, urls, amount, currency in
            var category = "Doküman"
            var score = 0.6
            
            let lowercasedText = text.lowercased()
            
            if lowercasedText.contains("fatura") || lowercasedText.contains("invoice") ||
               lowercasedText.contains("tutar") || lowercasedText.contains("toplam") {
                category = "Fatura"
                score = 0.85
            } else if lowercasedText.contains("tc") || lowercasedText.contains("kimlik") ||
                      lowercasedText.contains("t.c.") || lowercasedText.contains("doğum") {
                category = "Kimlik"
                score = 0.80
            } else if lowercasedText.contains("tel") || lowercasedText.contains("email") ||
                      lowercasedText.contains("@") || lowercasedText.contains("gsm") {
                category = "Kartvizit"
                score = 0.75
            }
            
            // Store extracted data
            self.extractedText = text
            self.detectedURLs = urls
            self.detectedAmount = amount
            self.detectedCurrency = currency
            
            self.classificationResult = category
            self.confidence = score
            self.isAnalyzing = false
            self.playSuccessSound()
        }
    }
    
    private func playSuccessSound() {
        if dataManager.settings.soundEnabled {
            SoundManager.shared.playSuccessSound()
        }
        
        if dataManager.settings.hapticEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    func saveDocument() {
        guard let image = scannedImage,
              let imagePath = dataManager.saveImage(image) else { return }
        
        let newDoc = ScannedDocument(
            imagePath: imagePath,
            category: classificationResult,
            confidence: confidence,
            date: Date(),
            folderID: nil,
            tags: [],
            extractedText: extractedText.isEmpty ? nil : extractedText,
            detectedURLs: detectedURLs,
            detectedAmount: detectedAmount,
            detectedCurrency: detectedCurrency
        )
        
        dataManager.addDocument(newDoc)
        
        // Haptic
        if dataManager.settings.hapticEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        
        withAnimation {
            scannedImage = nil
            classificationResult = ""
            confidence = 0
            // Clear extracted data
            extractedText = ""
            detectedURLs = []
            detectedAmount = nil
            detectedCurrency = nil
        }
    }
    
    func exportPDF() {
        guard let image = scannedImage else { return }
        
        let metadata: (category: String, date: Date, amount: String?)? = (
            category: classificationResult,
            date: Date(),
            amount: detectedAmount != nil && detectedCurrency != nil ?
                "\(String(format: "%.2f", detectedAmount!)) \(detectedCurrency!)" : nil
        )
        
        if let pdfURL = PDFExporter.shared.createPDF(from: image, metadata: metadata) {
            self.pdfURL = pdfURL
            showShareSheet = true
            
            // Haptic feedback
            if dataManager.settings.hapticEnabled {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        } else {
            errorMessage = "PDF oluşturulamadı"
            showError = true
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let icon: String
    let title: String
    let count: Int
    var isSelected: Bool
    var color: Color = .cyan
    var isDarkMode: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline.bold())
                Text("(\(count))")
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? color : (isDarkMode ? SwiftUI.Color.white : SwiftUI.Color.black).opacity(0.05))
            .foregroundColor(isSelected ? SwiftUI.Color.white : (isDarkMode ? SwiftUI.Color.white : SwiftUI.Color.black).opacity(0.7))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? color : (isDarkMode ? SwiftUI.Color.white : SwiftUI.Color.black).opacity(0.1), lineWidth: 1)
            )
        }
    }
}

// MARK: - Saved Document Row
struct SavedDocumentRow: View {
    let document: ScannedDocument
    let image: UIImage
    let isDarkMode: Bool
    let onMoveToFolder: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke((isDarkMode ? Color.white : Color.black).opacity(0.2), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(document.category)
                    .font(.subheadline.bold())
                    .foregroundColor(isDarkMode ? Color.white : Color.black)
                
                Text(document.date, style: .date)
                    .font(.caption)
                    .foregroundColor((isDarkMode ? Color.white : Color.black).opacity(0.6))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(document.confidence * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(.cyan)
                
                HStack(spacing: 8) {
                    Button(action: onMoveToFolder) {
                        Image(systemName: "folder.badge.plus")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: { showDeleteAlert = true }) {
                        Image(systemName: "trash.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(12)
        .background((isDarkMode ? Color.white : Color.black).opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke((isDarkMode ? Color.white : Color.black).opacity(0.1), lineWidth: 1)
        )
        .alert("Belgeyi Sil", isPresented: $showDeleteAlert) {
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive, action: onDelete)
        } message: {
            Text("Bu belge kalıcı olarak silinecek.")
        }
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    var isCompact: Bool = false
    var isDarkMode: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: isCompact ? 24 : 32, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(isCompact ? .subheadline.bold() : .headline)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(isCompact ? .caption2 : .caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            if !isCompact {
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(isCompact ? 16 : 20)
        .frame(maxWidth: isCompact ? nil : .infinity)
        .background(
            LinearGradient(
                colors: gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: gradient.first?.opacity(0.3) ?? .clear, radius: 10, x: 0, y: 5)
    }
}

// MARK: - Document Scanner Wrapper
struct DocumentScannerRepresentable: UIViewControllerRepresentable {
    let completion: (Result<VNDocumentCameraScan, Error>) -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let completion: (Result<VNDocumentCameraScan, Error>) -> Void
        
        init(completion: @escaping (Result<VNDocumentCameraScan, Error>) -> Void) {
            self.completion = completion
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            completion(.success(scan))
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            completion(.failure(error))
            controller.dismiss(animated: true)
        }
    }
}

#Preview {
    DocumentScannerView()
        .environmentObject(DataManager())
}
