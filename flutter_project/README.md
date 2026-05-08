# Notes App 📝

A Flutter-based notes application with Firebase backend, featuring rich text editing, AI summaries, dark mode, and sharing.

## ✨ Features

### Core Features
- **Firebase Authentication** - Secure user login/signup with email & password
- **Rich Text Editor** - Full formatting support using `flutter_quill` (bold, italic, lists, etc.)
- **Pin Notes** - Keep important notes at the top
- **Color Coding** - Assign colors to notes for easy organization
- **Tags** - Add multiple tags and filter notes by tag
- **Real-time Search** - Search through note titles and content instantly
- **Cloud Sync** - All notes stored in Firestore, synced across devices
- **Swipe to Delete** - Dismissible notes with delete confirmation

### Feature : Share Notes
- Share note content via native share sheet
- Supports WhatsApp, Email, Messages, and other apps
- Automatically converts Quill Delta to plain text
- Includes title, content, and tags in shared text

### Feature : Dark Mode
- Toggle between light and dark themes from AppBar
- Global theme management using `StatefulWidget` in `main.dart`
- Consistent theming across all screens

### Feature : AI Summary
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

## 📦 Setup Instructions

### 1. Prerequisites
- Flutter SDK >= 3.10.0
- Firebase project with Authentication & Firestore enabled
- Google Gemini API key from [Google AI Studio](https://aistudio.google.com/app/apikey)

