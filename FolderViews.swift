import SwiftUI

// MARK: - Folder Management View
struct FolderManagementView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    @State private var showAddFolder = false
    @State private var newFolderName = ""
    @State private var selectedIcon = "folder.fill"
    @State private var selectedColor = "blue"
    
    let availableIcons = ["folder.fill", "doc.text.fill", "person.text.rectangle", "rectangle.portrait.fill", "briefcase.fill", "building.2.fill"]
    let availableColors = ["blue", "purple", "pink", "green", "orange", "red", "cyan"]
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Existing Folders
                        ForEach(dataManager.folders) { folder in
                            FolderCard(folder: folder)
                        }
                        
                        // Add Folder Button
                        Button(action: { showAddFolder = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("Yeni Klasör Ekle")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.cyan.opacity(0.2))
                            .foregroundColor(.cyan)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Klasörler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(textColor)
                }
            }
            .sheet(isPresented: $showAddFolder) {
                AddFolderSheet(
                    folderName: $newFolderName,
                    selectedIcon: $selectedIcon,
                    selectedColor: $selectedColor,
                    availableIcons: availableIcons,
                    availableColors: availableColors,
                    onSave: {
                        let newFolder = DocumentFolder(
                            name: newFolderName,
                            icon: selectedIcon,
                            color: selectedColor
                        )
                        dataManager.addFolder(newFolder)
                        newFolderName = ""
                        showAddFolder = false
                    }
                )
                .environmentObject(dataManager)
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: dataManager.settings.isDarkMode ?
                [Color(red: 0.1, green: 0.2, blue: 0.45), Color(red: 0.2, green: 0.1, blue: 0.35)] :
                [Color(red: 0.95, green: 0.97, blue: 1.0), Color(red: 0.90, green: 0.93, blue: 0.98)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var textColor: Color {
        dataManager.settings.isDarkMode ? .white : .black
    }
}

// MARK: - Folder Card
struct FolderCard: View {
    let folder: DocumentFolder
    @EnvironmentObject var dataManager: DataManager
    @State private var showDeleteAlert = false
    
    var documentCount: Int {
        dataManager.documentsInFolder(folder).count
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: folder.icon)
                .font(.title)
                .foregroundColor(Color(folder.color))
                .frame(width: 50, height: 50)
                .background(Color(folder.color).opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(folder.name)
                    .font(.headline)
                    .foregroundColor(textColor)
                
                Text("\(documentCount) belge")
                    .font(.caption)
                    .foregroundColor(textColor.opacity(0.6))
            }
            
            Spacer()
            
            // Delete button
            Button(action: { showDeleteAlert = true }) {
                Image(systemName: "trash.fill")
                    .foregroundColor(.red.opacity(0.7))
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(strokeColor, lineWidth: 1)
        )
        .padding(.horizontal)
        .alert("Klasörü Sil", isPresented: $showDeleteAlert) {
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                dataManager.deleteFolder(folder)
            }
        } message: {
            Text("\(folder.name) klasörü silinecek. Devam etmek istiyor musunuz?")
        }
    }
    
    private var textColor: Color {
        dataManager.settings.isDarkMode ? .white : .black
    }
    
    private var cardBackground: Color {
        dataManager.settings.isDarkMode ? Color.white.opacity(0.05) : Color.white.opacity(0.7)
    }
    
    private var strokeColor: Color {
        dataManager.settings.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.05)
    }
}

// MARK: - Add Folder Sheet
struct AddFolderSheet: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    
    @Binding var folderName: String
    @Binding var selectedIcon: String
    @Binding var selectedColor: String
    
    let availableIcons: [String]
    let availableColors: [String]
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                Form {
                    Section("Klasör Adı") {
                        TextField("Klasör adı girin", text: $folderName)
                    }
                    
                    Section("İkon Seç") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button(action: { selectedIcon = icon }) {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundColor(selectedIcon == icon ? .cyan : textColor.opacity(0.5))
                                        .frame(width: 60, height: 60)
                                        .background(selectedIcon == icon ? Color.cyan.opacity(0.2) : Color.clear)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                    
                    Section("Renk Seç") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                            ForEach(availableColors, id: \.self) { color in
                                Button(action: { selectedColor = color }) {
                                    Circle()
                                        .fill(Color(color))
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedColor == color ? Color.white : Color.clear, lineWidth: 3)
                                        )
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Yeni Klasör")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                        .foregroundColor(textColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        onSave()
                        dismiss()
                    }
                    .disabled(folderName.isEmpty)
                    .foregroundColor(textColor)
                }
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: dataManager.settings.isDarkMode ?
                [Color(red: 0.1, green: 0.2, blue: 0.45), Color(red: 0.2, green: 0.1, blue: 0.35)] :
                [Color(red: 0.95, green: 0.97, blue: 1.0), Color(red: 0.90, green: 0.93, blue: 0.98)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var textColor: Color {
        dataManager.settings.isDarkMode ? .white : .black
    }
}

// MARK: - Folder Picker
struct FolderPickerView: View {
    @EnvironmentObject var dataManager: DataManager
    let document: ScannedDocument
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                List {
                    Section("Klasör Seç") {
                        // No folder option
                        Button(action: {
                            dataManager.moveDocument(document, to: nil)
                            isPresented = false
                        }) {
                            HStack {
                                Image(systemName: "folder.badge.minus")
                                    .foregroundColor(.gray)
                                Text("Klasörsüz")
                                    .foregroundColor(textColor)
                            }
                        }
                        
                        // Folders
                        ForEach(dataManager.folders) { folder in
                            Button(action: {
                                dataManager.moveDocument(document, to: folder)
                                isPresented = false
                            }) {
                                HStack {
                                    Image(systemName: folder.icon)
                                        .foregroundColor(Color(folder.color))
                                    Text(folder.name)
                                        .foregroundColor(textColor)
                                    
                                    if document.folderID == folder.id {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.cyan)
                                    }
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Klasöre Taşı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { isPresented = false }
                        .foregroundColor(textColor)
                }
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: dataManager.settings.isDarkMode ?
                [Color(red: 0.1, green: 0.2, blue: 0.45), Color(red: 0.2, green: 0.1, blue: 0.35)] :
                [Color(red: 0.95, green: 0.97, blue: 1.0), Color(red: 0.90, green: 0.93, blue: 0.98)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var textColor: Color {
        dataManager.settings.isDarkMode ? .white : .black
    }
}

#Preview {
    FolderManagementView()
        .environmentObject(DataManager())
}
