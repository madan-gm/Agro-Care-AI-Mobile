# 🌱 Agro Care AI

### AI-Based Crop Disease Detection and Advisory System

Agro Care AI is a Flutter-based mobile application that helps farmers identify possible crop diseases from leaf images and access useful farming guidance. It combines on-device AI, weather information, bilingual voice advisory, and an AI farming assistant to support better crop management decisions.

## 🎯 Problem Statement

Identifying crop diseases at an early stage can be difficult for farmers. Incorrect identification and unsuitable treatments can affect crop productivity, increase costs, and harm the environment.

Agro Care AI aims to make crop disease identification and farming information more accessible through a simple, AI-powered mobile application.

## ✨ Features

- **AI-Based Disease Detection:** Analyzes crop leaf images using a TensorFlow Lite model.
- **Multiple Crop Support:** Supports Tomato, Potato, and Corn disease classes included in the trained model.
- **Crop Disease Advisory:** Provides available treatment, prevention, and crop care guidance.
- **English and Kannada Support:** Offers bilingual interface and advisory content where available.
- **Voice Advisory:** Reads farming advice aloud with Listen, Pause, and Stop controls.
- **Weather Information:** Displays weather conditions and forecasts using the Open-Meteo API.
- **AI Farming Assistant:** Provides conversational farming guidance using Firebase AI integration.
- **Scan History:** Saves previous scans locally, including prediction details, confidence, images, timestamps, and available advisory information.
- **Farmer Dashboard:** Summarizes total scans and healthy or non-healthy predictions based on saved scan results.

## 🛠️ Technologies Used

| Technology | Purpose |
|---|---|
| Flutter and Dart | Mobile application development |
| MobileNetV2 | Crop disease classification model |
| TensorFlow Lite | On-device model inference |
| SQLite and sqflite | Local scan history storage |
| Flutter TTS | Voice advisory |
| Open-Meteo API | Weather information |
| Geolocator | Location access where configured |
| Firebase AI | AI farming assistant |
| Git and GitHub | Version control |

## 🏗️ Project Structure

```text
agro_care_ai_mobile/
├── android/
├── assets/
│   ├── advisory/
│   ├── models/
│   └── classes.json
├── lib/
│   ├── main.dart
│   ├── ai_service.dart
│   ├── dashboard_page.dart
│   ├── farming_chat_page.dart
│   ├── gemini_chat_service.dart
│   ├── scan_history_page.dart
│   ├── scan_history_service.dart
│   ├── weather_page.dart
│   └── other service and language files
├── ios/
├── macos/
├── web/
├── windows/
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

## ⚙️ Installation and Setup

### Prerequisites

- Flutter SDK and Dart SDK
- Android Studio or Visual Studio Code
- An Android device or emulator
- Git
- Internet access for weather and Firebase-powered features

### 1. Clone the repository

```bash
git clone https://github.com/madan-gm/Agro-Care-AI-Mobile.git
```

### 2. Open the project folder

```bash
cd Agro-Care-AI-Mobile
```

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Configure Firebase

The AI Farming Assistant requires Firebase configuration.

1. Open the Firebase Console and select or create a Firebase project.
2. Register the Android application using the package name configured in the project.
3. Add the required Firebase configuration file to `android/app/`.
4. Configure Firebase AI and the necessary service permissions.

Keep private credentials and Firebase App Check debug tokens out of the repository. Use your own Firebase configuration when setting up the application.

### 5. Check the Flutter environment

```bash
flutter doctor
```

### 6. Run the application

Connect an Android device with USB debugging enabled or start an emulator, then run:

```bash
flutter run
```

## ⚠️ Limitations

- Prediction results depend on the trained model and input image quality.
- Performance may vary under real-world field conditions.
- Advisory content is limited to the available dataset.
- Weather and AI assistant features require the relevant services and internet connectivity.
- Scan history is stored locally and does not automatically synchronize across devices.
- Dashboard statistics reflect AI predictions, not professionally confirmed diagnoses.

The application provides decision-support information and should not replace advice from qualified agricultural professionals.

## 🚀 Future Improvements

- Improve model performance using diverse real-world crop images.
- Add support for more crops and disease classes.
- Expand Kannada advisory content.
- Improve personalized farming recommendations.
- Explore offline support and reliable background weather alerts.
- Add downloadable and shareable scan reports.

## 👨‍💻 Developer

**Madan G M**  
RNS Institute of Technology (RNSIT), Bengaluru

- GitHub Profile: https://github.com/madan-gm
- Project Repository: https://github.com/madan-gm/Agro-Care-AI-Mobile

## 📄 License

No license has been specified yet.


## Demo and Downloads

- **Demo Video:** [Watch Agro Care AI Demo](https://drive.google.com/file/d/14tPjAdihy7OFb9ot_jXO_WgMuBF_2K4j/view?usp=sharing)
- **Download Android APK:** [Download Agro Care AI](https://drive.google.com/file/d/1jpXEmbG6UVM3VkoHHNWDCAt-jl1QiDc5/view?usp=sharing)
