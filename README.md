# 🌱 Agro Care AI – AI-Powered Crop Disease Detection and Farming Assistant

**AI-Based Crop Disease Detection and Advisory System for Sustainable Farming**

Agro Care AI is a Flutter-based mobile application designed to help farmers identify possible crop diseases, understand weather conditions, and access practical farming guidance. It combines on-device AI inference with weather information, bilingual voice advisory, scan history, and an AI farming assistant to support informed and sustainable farming decisions.

The project aims to make crop health information more accessible through a simple mobile application.

## 🎯 Problem Statement

Farmers may struggle to identify crop diseases at an early stage and choose suitable treatments. Incorrect identification and unnecessary pesticide use can affect crop productivity, increase costs, and harm the environment.

Agro Care AI addresses this problem by providing AI-based leaf image analysis, relevant advisory information, and digital farming support through a mobile application.

## ✨ Key Features

### 🌿 1. AI-Based Crop Disease Detection
- Uses a trained MobileNetV2 model converted to TensorFlow Lite.
- Analyzes crop leaf images directly on the device.
- Displays the predicted disease class and model confidence score.
- Supports Tomato, Potato, and Corn classes included in the configured model.

### 🩺 2. Crop Disease Advisory
- Displays treatment, prevention, and crop care guidance from the available advisory dataset.
- Helps users understand the recommended next steps after a scan.
- Provides advisory information in English and Kannada where translations are available.

### 🔊 3. Bilingual Voice Advisory
- Supports English and Kannada language selection.
- Uses text-to-speech to read farming advice aloud.
- Provides Listen, Pause, and Stop controls.

### 🌦️ 4. Weather Information
- Retrieves weather information using the Open-Meteo API.
- Supports location-based weather information where location access is configured.
- Displays current weather conditions and forecast information through the weather page.
- Helps users consider weather conditions when planning farming activities.

### 🤖 5. AI Farming Assistant
- Provides a chat interface for general farming questions.
- Uses Firebase AI integration for AI-generated responses.
- Helps users access farming information through a conversational interface.

### 📋 6. Scan History
- Saves previous crop scans in a local SQLite database.
- Stores the crop name, predicted disease, confidence score, scan image, timestamp, and available advisory information.
- Allows users to review and delete previous scan records.

### 📊 7. Farmer Dashboard
- Displays the total number of saved scans.
- Summarizes predictions classified as healthy and non-healthy.
- Provides a quick overview of the scan history.
- Supports refreshing the dashboard statistics.

**Note:** Dashboard statistics are based on model predictions stored in scan history. They do not represent laboratory-confirmed diagnoses.

## 🛠️ Technologies Used

| Technology | Purpose |
|---|---|
| Flutter and Dart | Mobile application development |
| TensorFlow Lite | On-device AI inference |
| MobileNetV2 | Crop disease classification model |
| SQLite and sqflite | Local scan history storage |
| Flutter TTS | Voice advisory |
| Open-Meteo API | Weather information |
| Geolocator | Location access, where configured |
| Firebase AI | AI farming assistant |
| Git and GitHub | Version control and source code hosting |

## 🏗️ Project Structure

```text
agro_care_ai_mobile/
├── android/
├── assets/
│   ├── advisory/
│   │   └── advisory.json
│   ├── models/
│   │   └── mobilenetv2_finetuned.tflite
│   ├── test/
│   └── classes.json
├── lib/
│   ├── main.dart
│   ├── ai_service.dart
│   ├── app_language.dart
│   ├── dashboard_page.dart
│   ├── farming_chat_page.dart
│   ├── gemini_chat_service.dart
│   ├── scan_history_page.dart
│   ├── scan_history_service.dart
│   ├── weather_page.dart
│   └── [other application and service files]
├── ios/
├── macos/
├── web/
├── windows/
├── pubspec.yaml
├── pubspec.lock
├── firebase.json
├── .firebaserc
└── README.md
```

The project also contains platform-specific configuration and generated Flutter files. Exact file availability may vary by development environment.

## ⚙️ Installation and Setup

### Prerequisites

- Flutter SDK and Dart SDK
- Android Studio or Visual Studio Code
- Android device or emulator
- Git
- Internet connection for weather information and Firebase-powered AI features

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

1. Open the Firebase Console and select the appropriate Firebase project or create a new one.
2. Register the Android application using the package name configured in the project.
3. Download the Android `google-services.json` configuration file.
4. Place it in:

```text
android/app/google-services.json
```

5. Configure Firebase AI and any required access permissions for the selected Firebase project.

Do not commit private credentials, service-account keys, or Firebase App Check debug tokens to the repository. Each developer should configure their own required local Firebase settings.

### 5. Check the Flutter environment

```bash
flutter doctor
```

Resolve any required environment setup issues before running the application.

### 6. Run the application

Connect an Android device with USB debugging enabled or start an emulator, then run:

```bash
flutter run
```

## 🌦️ Weather and Location

Agro Care AI uses the Open-Meteo API for weather information. Location-based features require the relevant permissions and a working location service. An internet connection is needed to retrieve updated weather data.

Weather information and recommendations should be considered supporting information, not a guarantee of future weather conditions or crop outcomes.

## 🧠 AI Model and Limitations

- Prediction quality depends on the trained model, its supported classes, and the quality of the input image.
- Images taken in real farming environments may produce different results from images used during model training.
- The application identifies possible diseases; its predictions are not a substitute for confirmation by an agricultural expert.
- Advisory content is limited to the information available in the configured advisory dataset.
- Weather and AI assistant features require the relevant external services and configuration.
- Scan history is stored locally on the device and may not automatically synchronize across devices.
- Dashboard statistics reflect saved AI predictions, not verified crop health measurements.

Users should consult qualified agricultural professionals before making significant crop treatment decisions.

## 🌍 Sustainable Development Goals (SDGs)

Agro Care AI supports the following Sustainable Development Goals:

- **SDG 2 – Zero Hunger:** Supports crop health awareness and informed farming decisions.
- **SDG 12 – Responsible Consumption and Production:** Encourages informed treatment decisions and awareness of unnecessary pesticide use.
- **SDG 13 – Climate Action:** Provides weather information that can help farmers consider environmental conditions in their planning.

These are the project's intended contributions; actual impact depends on how the application is used and validated.

## 🚀 Future Enhancements

- Improve model accuracy using diverse field images and additional validation.
- Expand supported crops and disease classes.
- Improve Kannada advisory coverage.
- Add downloadable or shareable crop scan reports.
- Enhance farming recommendations using crop, location, and weather context.
- Evaluate reliable background weather alerts and offline capabilities.
- Conduct field testing with farmers and agricultural experts.

## 👨‍💻 Developer

**Madan G M**  
RNS Institute of Technology (RNSIT), Bengaluru

- GitHub: https://github.com/madan-gm
- Project Repository: https://github.com/madan-gm/Agro-Care-AI-Mobile

## 📸 Application Screenshots and Demo

Add screenshots of the following application screens to help reviewers understand the project:

1. Home screen
2. Crop disease detection result
3. Disease advisory and voice controls
4. Farmer Dashboard
5. Scan History
6. Weather page
7. AI Farming Assistant

**Demo Video:** Add your NEURA X demonstration video link here after uploading it.

## 📄 License

A license has not yet been specified for this project. Add an appropriate open-source license if you intend to distribute the source code under specific reuse terms.
