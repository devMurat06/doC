# doC Scanner 📱

<div align="center">

![iOS](https://img.shields.io/badge/iOS-26.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-green.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

**Premium AI-Powered Document Scanner & Organizer**

Intelligent document scanning with automatic categorization, OCR text extraction, URL detection, amount recognition, and PDF export.

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Screenshots](#-screenshots) • [Tech Stack](#-tech-stack)

</div>

---

## ✨ Features

### 🤖 Intelligent Classification
- **AI-Powered Categorization** - Automatically classifies documents as invoices, IDs, business cards, or general documents
- **OCR Text Extraction** - Extracts all text from scanned documents with high accuracy
- **Confidence Scoring** - Visual indicator showing classification confidence (75-85%)

### 💰 Smart Detection
- **Amount Recognition** - Automatically detects prices and totals from invoices
  - Turkish format: `1.234,56 TL` or `1.234,56 ₺`
  - International: `1,234.56 $` or `1,234.56 USD`
  - Euro: `1.234,56 €` or `1.234,56 EUR`
- **URL Detection** - Finds and extracts web addresses from documents
  - One-tap Safari opening
  - Multiple URL support
- **Email & Phone** - Contact information extraction (coming soon)

### 📁 Folder Organization
- **Smart Folders** - Default categories (Invoices, IDs, Business Cards, Other)
- **Custom Folders** - Create your own with 6 icons × 7 colors
- **Easy Organization** - Drag-and-drop style document moving
- **Quick Filters** - Filter documents by folder with one tap

### 📄 PDF Export
- **High-Quality PDFs** - Export documents as professional PDFs
- **Metadata Support** - Includes category, date, and amount information
- **Share Anywhere** - Email, AirDrop, Files app, or any share target
- **Batch Export** - Multiple documents to single PDF (coming soon)

### 🔐 Security & Privacy
- **PIN Protection** - 4-digit PIN lock for app access
- **Secure Setup** - PIN creation with confirmation flow
- **Haptic Feedback** - Physical feedback for security actions
- **Local Storage** - All data stored on device

### 🎨 Premium UI/UX
- **Dark/Light Mode** - Adaptive theme with smooth transitions
- **Glassmorphism Design** - Modern frosted glass effects
- **Gradient Backgrounds** - Beautiful blue-purple gradients
- **Sound Effects** - Success sounds with toggle control
- **Haptic Feedback** - Tactile responses throughout the app

### 🔍 Advanced Features
- **Dual Scanner** - Native camera scanner + photo library picker
- **Simulator Support** - Full functionality in iOS Simulator
- **Data Persistence** - UserDefaults + FileManager storage
- **Document Management** - View, organize, move, and delete documents

---

## 📸 Screenshots

### Main Interface
- Clean, modern scanner interface
- Real-time classification results
- Confidence score visualization
- Smart detection panels (Amount, URLs)

### Document Management
- Folder-based organization
- Filter chips for quick access
- Document cards with preview
- Swipe actions (move, delete)

### Settings & Security
- PIN setup and lock screens
- Theme toggle (Dark/Light)
- Sound and haptic controls
- App statistics display

---

## 🚀 Installation

### Requirements
- **Xcode:** 16.0+
- **iOS:** 26.0+
- **Swift:** 6.0
- **Frameworks:** SwiftUI, VisionKit, Vision, Core ML, PDFKit

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd doC
   ```

2. **Open in Xcode**
   ```bash
   open doC.xcodeproj
   ```

3. **Build and Run**
   - Select target device or simulator (iPhone 17 Pro recommended)
   - Press `Cmd + R` to build and run
   - Grant camera permissions when prompted

### First Launch

1. App opens without PIN (first time)
2. Navigate to **Settings** (gear icon)
3. Set up **PIN Code** for security
4. Choose **Dark/Light** theme preference
5. Start scanning documents!

---

## 📖 Usage

### Scanning a Document

**On Real Device:**
1. Tap **"Tara"** (Scan) button
2. Position document in frame
3. Capture with camera
4. AI automatically classifies
5. Review detected data (amount, URLs)
6. **Export PDF** or **Save** to folder

**On Simulator:**
1. Tap **"Fotoğraf Seç"** (Select Photo)
2. Choose image from library
3. Processing happens automatically
4. Same review and save flow

### Organizing Documents

**Create Folder:**
1. Tap folder count badge in header
2. Tap **"Yeni Klasör Ekle"** (Add New Folder)
3. Enter name, choose icon and color
4. Save

**Move Document:**
1. Find document in list
2. Tap folder icon on document card
3. Select destination folder
4. Document moved instantly

**Filter by Folder:**
1. Use filter chips at top of document list
2. Tap folder name to filter
3. Tap **"Tümü"** (All) to clear filter

### Exporting to PDF

**Single Document:**
1. After scanning, tap **"PDF"** button
2. Share sheet appears
3. Choose destination:
   - **Mail** - Email as attachment
   - **AirDrop** - Send to nearby device
   - **Files** - Save to iCloud/local storage
   - **Other apps** - WhatsApp, Telegram, etc.

**With Metadata:**
- PDF includes category, date, and amount (if detected)
- High-quality image rendering
- Professional document format

### Using Detected Data

**Detected Amount:**
- Displayed in green badge
- Shows currency symbol
- Always picks highest amount from document

**Detected URLs:**
- Each URL shown as clickable button
- Tap to open in Safari
- Multiple URLs supported

**Extracted Text:**
- Stored with document
- Used for classification
- Searchable (coming soon)

---

## 🛠 Tech Stack

### Frameworks & APIs

| Framework | Purpose |
|-----------|---------|
| **SwiftUI** | Modern declarative UI |
| **VisionKit** | Native document camera |
| **Vision** | OCR text recognition |
| **Core ML** | ML model integration |
| **PDFKit** | PDF generation |
| **AVFoundation** | Sound playback |
| **Combine** | Reactive state management |

### Architecture

```
doC/
├── Models.swift              # Data models & DataManager
├── TextExtractor.swift       # OCR & pattern matching
├── PDFExporter.swift         # PDF generation
├── DocumentScannerView.swift # Main scanner interface
├── FolderViews.swift         # Folder management UI
├── SettingsView.swift        # App settings
├── PINViews.swift           # Security screens
└── Assets/                   # Images & colors
```

### Key Components

**Data Models:**
- `ScannedDocument` - Document with OCR data, URLs, amounts
- `DocumentFolder` - Custom folder with icon/color
- `AppSettings` - User preferences (PIN, theme, sound)
- `DataManager` - Centralized state management

**Utilities:**
- `TextExtractor` - Regex-based URL & amount detection
- `PDFExporter` - PDF creation with metadata
- `SoundManager` - Audio feedback system

**UI Components:**
- `DocumentScannerView` - Main scanning interface
- `FolderManagementView` - Folder CRUD operations
- `PINLockView` - Security authentication
- `SettingsView` - User preferences

---

## 🎯 Future Roadmap

### Planned Features
- [ ] Email & phone number detection
- [ ] Date recognition & reminders
- [ ] QR code & barcode scanning
- [ ] Multi-document PDF export
- [ ] iCloud sync
- [ ] Advanced search (OCR text search)
- [ ] Dashboard with statistics
- [ ] Widget support
- [ ] Siri shortcuts

### Nice to Have
- [ ] Apple Watch companion
- [ ] Mac Catalyst version
- [ ] Document editing (crop, rotate)
- [ ] OCR language selection
- [ ] Export to Excel/CSV (for expense tracking)

---

## 📊 Performance

- **Scan Speed:** ~2-3 seconds per document
- **OCR Accuracy:** 80-95% (depends on image quality)
- **Classification Accuracy:** 75-85% confidence
- **PDF Generation:** < 1 second
- **Memory Usage:** Optimized with image compression
- **Storage:** Images saved as JPEG (0.8 quality)

---

## 🔐 Privacy & Security

- **Local Storage:** All data stored on device
- **No Cloud Uploads:** Documents never leave your device
- **PIN Protection:** Optional 4-digit PIN lock
- **Secure Image Storage:** App sandbox directory
- **No Tracking:** No analytics or data collection

> **Note:** For production, consider moving PIN storage from UserDefaults to Keychain for enhanced security.

---

## 🤝 Contributing

Contributions welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 👨‍💻 Author

**Murat NAR**

- GitHub: [@muratnar](https://github.com/muratnar)
- Website: [muratnar.netlify.app](https://muratnar.netlify.app)

---

## 🙏 Acknowledgments

- VisionKit for amazing document scanning
- Core ML for intelligent classification
- Apple Design Guidelines for UI inspiration
- SwiftUI community for resources and support

---

<div align="center">

**⭐ Star this repo if you find it useful! ⭐**

Made with ❤️ using SwiftUI

</div>
N❤️ 
