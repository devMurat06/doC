import SwiftUI

// MARK: - PIN Entry View
struct PINEntryView: View {
    @Binding var pin: String
    let title: String
    let subtitle: String
    let onComplete: (String) -> Void
    let onCancel: (() -> Void)?
    
    @State private var enteredDigits: [String] = []
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // PIN Dots
            HStack(spacing: 20) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index < enteredDigits.count ? Color.cyan : Color.white.opacity(0.2))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: index < enteredDigits.count ? 0 : 2)
                        )
                        .scaleEffect(index == enteredDigits.count - 1 ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: enteredDigits.count)
                }
            }
            .padding(.vertical, 20)
            
            // Number Pad
            VStack(spacing: 16) {
                ForEach(0..<3) { row in
                    HStack(spacing: 16) {
                        ForEach(1..<4) { col in
                            let number = row * 3 + col
                            NumberButton(number: "\(number)") {
                                addDigit("\(number)")
                            }
                        }
                    }
                }
                
                HStack(spacing: 16) {
                    // Cancel button (if provided)
                    if let onCancel = onCancel {
                        Button(action: onCancel) {
                            Text("İptal")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 80, height: 80)
                        }
                    } else {
                        Spacer()
                            .frame(width: 80, height: 80)
                    }
                    
                    NumberButton(number: "0") {
                        addDigit("0")
                    }
                    
                    Button(action: deleteDigit) {
                        Image(systemName: "delete.left.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 80, height: 80)
                    }
                }
            }
        }
        .padding()
        .onAppear {
            enteredDigits = []
        }
    }
    
    private func addDigit(_ digit: String) {
        guard enteredDigits.count < 4 else { return }
        
        enteredDigits.append(digit)
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        if enteredDigits.count == 4 {
            let pinCode = enteredDigits.joined()
            
            // Delay for visual feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onComplete(pinCode)
                enteredDigits = []
            }
        }
    }
    
    private func deleteDigit() {
        guard !enteredDigits.isEmpty else { return }
        enteredDigits.removeLast()
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Number Button
struct NumberButton: View {
    let number: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.title.bold())
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - PIN Setup View
struct PINSetupView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    
    @State private var step: SetupStep = .create
    @State private var firstPIN: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    enum SetupStep {
        case create, confirm
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.45),
                    Color(red: 0.2, green: 0.1, blue: 0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if step == .create {
                PINEntryView(
                    pin: $firstPIN,
                    title: "PIN Kodu Oluştur",
                    subtitle: "4 haneli bir PIN kodu girin",
                    onComplete: { pin in
                        firstPIN = pin
                        step = .confirm
                    },
                    onCancel: {
                        dismiss()
                    }
                )
            } else {
                PINEntryView(
                    pin: .constant(""),
                    title: "PIN Kodunu Onayla",
                    subtitle: "PIN kodunu tekrar girin",
                    onComplete: { pin in
                        if pin == firstPIN {
                            // Save PIN
                            var settings = dataManager.settings
                            settings.pinEnabled = true
                            settings.pinCode = pin
                            dataManager.updateSettings(settings)
                            
                            // Success haptic
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            
                            dismiss()
                        } else {
                            // Error
                            errorMessage = "PIN kodları eşleşmiyor!"
                            showError = true
                            
                            // Error haptic
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.error)
                            
                            // Reset
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                step = .create
                                firstPIN = ""
                                showError = false
                            }
                        }
                    },
                    onCancel: {
                        step = .create
                        firstPIN = ""
                    }
                )
            }
            
            // Error overlay
            if showError {
                VStack {
                    Spacer()
                    Text(errorMessage)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(12)
                        .padding()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: showError)
    }
}

// MARK: - PIN Lock View
struct PINLockView: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var isUnlocked: Bool
    
    @State private var attempts = 0
    @State private var showError = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.45),
                    Color(red: 0.2, green: 0.1, blue: 0.35),
                    Color(red: 0.15, green: 0.15, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                // App Logo/Name
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("doC Scanner")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.top, 60)
                
                Spacer()
                
                PINEntryView(
                    pin: .constant(""),
                    title: "Kilidi Aç",
                    subtitle: "PIN kodunuzu girin",
                    onComplete: { pin in
                        if pin == dataManager.settings.pinCode {
                            // Success
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            
                            withAnimation {
                                isUnlocked = true
                            }
                        } else {
                            // Failed
                            attempts += 1
                            showError = true
                            
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.error)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                showError = false
                            }
                        }
                    },
                    onCancel: nil
                )
                
                if showError {
                    Text("Hatalı PIN! Kalan deneme: \(3 - attempts)")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding()
                        .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
            }
        }
        .animation(.spring(), value: showError)
    }
}

#Preview {
    PINSetupView()
        .environmentObject(DataManager())
}
