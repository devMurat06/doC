import SwiftUI
import AVFoundation

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    @State private var showPINSetup = false
    @State private var showRemovePINAlert = false
    
    var body: some View {
        ZStack {
            // Background gradient based on theme
            backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ayarlar")
                                .font(.largeTitle.bold())
                                .foregroundColor(textColor)
                            
                            Text("Uygulamayı özelleştir")
                                .font(.subheadline)
                                .foregroundColor(textColor.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(textColor.opacity(0.6))
                        }
                    }
                    .padding(.top, 20)
                    
                    // Appearance Section
                    SettingsSection(title: "Görünüm", icon: "paintbrush.fill") {
                        SettingsToggle(
                            icon: "moon.fill",
                            title: "Koyu Tema",
                            subtitle: "Karanlık arayüz kullan",
                            isOn: Binding(
                                get: { dataManager.settings.isDarkMode },
                                set: { value in
                                    var settings = dataManager.settings
                                    settings.isDarkMode = value
                                    dataManager.updateSettings(settings)
                                }
                            ),
                            iconColor: .indigo
                        )
                    }
                    
                    // Security Section
                    SettingsSection(title: "Güvenlik", icon: "lock.shield.fill") {
                        VStack(spacing: 12) {
                            if dataManager.settings.pinEnabled {
                                // PIN enabled
                                SettingsButton(
                                    icon: "lock.open.fill",
                                    title: "PIN Kodunu Kaldır",
                                    subtitle: "Uygulama kilidini kapat",
                                    iconColor: .red,
                                    action: {
                                        showRemovePINAlert = true
                                    }
                                )
                            } else {
                                // PIN disabled
                                SettingsButton(
                                    icon: "lock.fill",
                                    title: "PIN Kodu Ayarla",
                                    subtitle: "Uygulamayı PIN ile kilitle",
                                    iconColor: .cyan,
                                    action: {
                                        showPINSetup = true
                                    }
                                )
                            }
                        }
                    }
                    
                    // Feedback Section
                    SettingsSection(title: "Geri Bildirim", icon: "speaker.wave.3.fill") {
                        VStack(spacing: 12) {
                            SettingsToggle(
                                icon: "speaker.wave.2.fill",
                                title: "Ses Efektleri",
                                subtitle: "Tarama başarılı sesi",
                                isOn: Binding(
                                    get: { dataManager.settings.soundEnabled },
                                    set: { value in
                                        var settings = dataManager.settings
                                        settings.soundEnabled = value
                                        dataManager.updateSettings(settings)
                                    }
                                ),
                                iconColor: .green
                            )
                            
                            SettingsToggle(
                                icon: "hand.tap.fill",
                                title: "Titreşim",
                                subtitle: "Dokunmatik geri bildirim",
                                isOn: Binding(
                                    get: { dataManager.settings.hapticEnabled },
                                    set: { value in
                                        var settings = dataManager.settings
                                        settings.hapticEnabled = value
                                        dataManager.updateSettings(settings)
                                    }
                                ),
                                iconColor: .orange
                            )
                        }
                    }
                    
                    // About Section
                    SettingsSection(title: "Hakkında", icon: "info.circle.fill") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Versiyon")
                                    .foregroundColor(textColor.opacity(0.7))
                                Spacer()
                                Text("1.0.0")
                                    .foregroundColor(textColor)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Toplam Belge")
                                    .foregroundColor(textColor.opacity(0.7))
                                Spacer()
                                Text("\(dataManager.documents.count)")
                                    .foregroundColor(textColor)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Klasör Sayısı")
                                    .foregroundColor(textColor.opacity(0.7))
                                Spacer()
                                Text("\(dataManager.folders.count)")
                                    .foregroundColor(textColor)
                            }
                        }
                        .font(.subheadline)
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showPINSetup) {
            PINSetupView()
                .environmentObject(dataManager)
        }
        .alert("PIN Kodunu Kaldır", isPresented: $showRemovePINAlert) {
            Button("İptal", role: .cancel) { }
            Button("Kaldır", role: .destructive) {
                var settings = dataManager.settings
                settings.pinEnabled = false
                settings.pinCode = nil
                dataManager.updateSettings(settings)
            }
        } message: {
            Text("PIN kodu kaldırılacak. Devam etmek istiyor musunuz?")
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

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.cyan)
                Text(title)
                    .font(.headline)
                    .foregroundColor(textColor)
            }
            
            VStack(spacing: 0) {
                content
            }
            .padding(16)
            .background(cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(strokeColor, lineWidth: 1)
            )
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

// MARK: - Settings Toggle
struct SettingsToggle: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let iconColor: Color
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(textColor)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(textColor.opacity(0.6))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.cyan)
        }
    }
    
    private var textColor: Color {
        dataManager.settings.isDarkMode ? .white : .black
    }
}

// MARK: - Settings Button
struct SettingsButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let action: () -> Void
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(textColor)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(textColor.opacity(0.3))
            }
        }
    }
    
    private var textColor: Color {
        dataManager.settings.isDarkMode ? .white : .black
    }
}

// MARK: - Sound Manager
class SoundManager {
    static let shared = SoundManager()
    private var audioPlayer: AVAudioPlayer?
    
    func playSuccessSound() {
        // Create success sound programmatically using system sound
        let systemSoundID: SystemSoundID = 1057 // SMS Received tone
        AudioServicesPlaySystemSound(systemSoundID)
    }
    
    func playSound(named: String, withExtension ext: String = "mp3") {
        guard let url = Bundle.main.url(forResource: named, withExtension: ext) else {
            print("Sound file not found")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error playing sound: \(error)")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataManager())
}
