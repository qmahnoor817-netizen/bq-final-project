# Notes App 📝

A Flutter-based notes application with Firebase backend, featuring rich text editing, AI summaries, voice notes, PDF export, dark mode, and sharing.

## ✨ Features

### Core Features
- **Firebase Authentication** - Secure user login/signup with email & password
- **Rich Text Editor** - Full formatting support using `flutter_quill` (bold, italic, lists, etc.)
- **Pin Notes** - Keep important notes at the top
- **Edit Notes** - can update your notes
- **Color Coding** - Assign colors to notes for easy organization
- **Tags** - Add multiple tags and filter notes by tag
- **Real-time Search** - Search through note titles and content instantly
- **Cloud Sync** - All notes stored in Firestore, synced across devices
- **Swipe to Delete** - Dismissible notes with delete confirmation

### Feature: Voice Notes
- Record audio notes using `record` package
- Request microphone permission at runtime with `permission_handler`
- Save recordings locally with `path_provider`
- Playback and attach recordings to notes
- Android/iOS only - not supported on web

### Feature: PDF Export
- Export any note to PDF using `pdf` + `printing` packages
- Preserves title, content, tags, and timestamp
- Share or save PDF directly from the app
- Works offline

### Feature: Share Notes
- Share note content via native share sheet
- Supports WhatsApp, Email, Messages, and other apps
- Automatically converts Quill Delta to plain text
- Includes title, content, and tags in shared text

### Feature: Dark Mode
- Toggle between light and dark themes from AppBar
- Global theme management using `StatefulWidget` in `main.dart`
- Consistent theming across all screens

### Feature: AI Summary
- Generate 3-bullet point summaries using Google Gemini 1.5 Flash API
- Automatic fallback to local extractive summary if API fails/offline
- Truncates content to 2000 chars for faster API response
- 8-second timeout prevents UI blocking
- Loading overlay with progress indicator

### UI/UX Fixes
- **Responsive Card Layout** - Dynamic height cards prevent tag overflow
- **Error Handling** - Graceful fallbacks for network failures
- **Loading States** - CircularProgressIndicator for async operations

## 🛠️ Tech Stack

| Technology | Purpose |
| --- | --- |
| **Flutter 3.x** | Cross-platform UI framework |
| **Firebase Auth** | User authentication |
| **Cloud Firestore** | NoSQL database for notes |
| **flutter_quill 10.x** | Rich text editor |
| **share_plus 10.x** | Native share functionality |
| **http 1.2.x** | API calls to Gemini |
| **Google Gemini API** | AI-powered note summarization |
| **record 5.1.4** | Voice recording |
| **permission_handler 11.3.1** | Runtime permissions |
| **path_provider 2.1.3** | File system access |
| **pdf 3.10.7** | PDF generation |
| **printing 5.11.3** | Print & share PDFs |

## 📦 Setup Instructions

### 1. Prerequisites
- Flutter SDK >= 3.11.0
- Dart SDK >= 3.11.0
- Firebase project with Authentication & Firestore enabled
- Google Gemini API key from [Google AI Studio](https://aistudio.google.com/app/apikey)
- Android device/emulator for voice recording

### 2. Install Dependencies
```yaml
dependencies:
  flutter_quill: ^10.4.0
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.0
  cloud_firestore: ^5.4.4
  share_plus: ^10.0.2
  http: ^1.2.2
  record: ^5.1.4
  permission_handler: ^11.3.1
  path_provider: ^2.1.3
  pdf: ^3.10.7
  printing: ^5.11.3
