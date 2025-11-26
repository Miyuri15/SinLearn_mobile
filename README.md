# 📱 **SinLearn Mobile – Flutter Frontend**

### **Sinhala Educational Assistant (Mobile + Web)**

SinLearn is a conversational Sinhala educational assistant built with Flutter.
This repository contains the **Frontend application**, supporting both **Mobile (Android/iOS)** and **Web**, with features such as:

* Sinhala + English UI
* Chat-based learning mode
* Answer evaluation mode
* Voice input support
* File uploads (PDF, images)
* Dark/Light themes
* Offline mode
* Mobile + Web adaptive layouts

This project is the official frontend foundation used by the SinLearn development team.

---

# 🚀 **Features**

## ✔ Learning Mode

* Ask questions in Sinhala (text or voice)
* Upload documents or images for context
* Receive summaries + explanations + Q&A
* Age-level response generation (Grade levels)

## ✔ Answer Evaluation Mode

* Upload answer sheets and questions
* Select or upload marking rubrics
* Automated feedback: coverage, accuracy, clarity
* Sinhala feedback + scoring
* Structured evaluation card blocks

## ✔ Core UI Features

* Chat interface (user/system bubbles)
* Summary cards
* Evaluation cards
* Prompt bar (text, upload, microphone)
* Chat history
* Sharing support

## ✔ Technical Features

* Sinhala + English localization
* Light & Dark themes
* Offline mode detection
* Mobile/Web responsive layouts
* Clean modular folder structure

---

# 📦 **Project Structure**

```
lib/
 ├─ layouts/
 │   ├─ mobile/
 │   ├─ web/
 ├─ features/
 │   ├─ chat/
 │   ├─ evaluation/
 │   ├─ upload/
 │   ├─ settings/
 ├─ widgets/
 ├─ services/
 │   ├─ api_service.dart
 │   ├─ storage_service.dart
 ├─ providers/
 ├─ models/
 ├─ localization/
 ├─ main.dart

assets/
 ├─ languages/
 │   ├─ en.json
 │   ├─ si.json
 ├─ fonts/
 │   ├─ NotoSansSinhala-Regular.ttf
 ├─ icons/
 ├─ images/
```

---

# 🛠 **Technologies Used**

| Component         | Technology        |
| ----------------- | ----------------- |
| Framework         | Flutter 3.24+     |
| Localization      | easy_localization |
| State Management  | Riverpod          |
| HTTP Client       | http              |
| Voice Recording   | record            |
| Offline Detection | connectivity_plus |
| File Uploads      | file_picker       |

---

# 📥 **How to Run This Project**

### **1. Clone the repository**

```sh
git clone <repo-url>
cd sinlearn_mobile
```

### **2. Install dependencies**

```sh
flutter pub get
```

### **3. Run on Web**

```sh
flutter run -d chrome
```

### **4. Run on Android**

```sh
flutter run -d <android-device-id>
```

### **5. Run on iOS (Mac only)**

```sh
flutter run -d <ios-device-id>
```

---

# 🌐 **Localization Setup (English + Sinhala)**

Localization files are stored in:

```
assets/languages/en.json
assets/languages/si.json
```

### Use translated text in widgets:

```dart
Text(tr("send"))
```

---

# 🎨 **Themes (Light + Dark)**

Theme configuration:

```dart
theme: ThemeData.light(),
darkTheme: ThemeData.dark(),
```

Custom theme files will be added later.

---

# 📡 **API Integration**

API calls live inside:

```
lib/services/api_service.dart
```

Backend supports:

* Learning mode query
* Evaluation request
* File upload
* Voice transcription
* Chat history

---

# 🌩 **Offline Mode**

The app uses **connectivity_plus** to detect online/offline states.

### When offline:

* Offline banner appears
* Send/upload/voice features are disabled
* Old chats remain visible

---

# 🤝 **Contribution Workflow**

## **Branch Strategy**

```
main    → Stable production-ready code
dev     → Development staging branch
feature/<feature-name> → Individual feature branches
```

### **Creating a new feature branch**

```sh
git checkout -b feature/chat-ui
```

### **Committing code**

```sh
git add .
git commit -m "Implemented chat bubble widget"
```

### **Pushing work**

```sh
git push origin feature/chat-ui
```

---

# 📄 **Coding Standards**

* No hardcoded Sinhala or English text (use localization keys).
* Follow folder structure strictly.
* Reuse widgets from `/widgets` (no duplicates).
* Keep logic in `/providers` and `/services`.
* Write clean, readable commit messages.

---

# 📌 **Current Status**

✔ Project skeleton completed
✔ Localization enabled
✔ Fonts integrated
✔ Themes added
✔ Folder structure created
✔ App runs on Chrome
⬜ UI screens to be implemented
⬜ API integration pending
⬜ Voice input implementation pending
⬜ Evaluation logic pending

---

# 📞 **Contact**

For questions or clarifications, contact the **SinLearn development team lead**.

---

# ⭐ **Thank You for Contributing to SinLearn!**

This repository is maintained as part of the final-year project
**“SinLearn – Sinhala Educational Assistant.”**

---

