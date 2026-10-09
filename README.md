# 🌱 Agro Care AI – Mobile App

### AI-Based Crop Disease Detection and Advisory System for Sustainable Farming

Agro Care AI is a Flutter-based mobile application designed to help farmers identify crop diseases, understand weather conditions, and access practical farming guidance. It combines on-device AI inference with weather forecasts to support more informed and sustainable farming decisions.

## 🎯 Problem Statement

Farmers may struggle to identify crop diseases at an early stage and choose suitable treatments. Incorrect identification and unnecessary pesticide use can affect crop health, productivity, and the environment.

Agro Care AI aims to make crop disease identification and farming advice more accessible through a mobile application.

## ✨ Features

- **AI-Based Disease Detection:** Analyze crop leaf images using a TensorFlow Lite model.
- **Multiple Crop Support:** Supports the crop disease classes included in the trained model.
- **Bilingual Advisory:** Provides farming guidance in English and Kannada where available.
- **Weather Forecasts:** Displays current weather conditions and a seven-day forecast.
- **Weather Notifications:** Provides weather alerts when configured conditions are met.
- **Farming Recommendations:** Offers weather-related suggestions to support farming decisions.

## 🛠️ Technologies Used

- **Frontend:** Flutter and Dart
- **AI Model:** MobileNetV2
- **Model Inference:** TensorFlow Lite
- **Weather Data:** Open-Meteo API
- **Location:** Geolocator
- **Notifications:** Flutter Local Notifications
- **Version Control:** Git and GitHub

## 📱 Application Screenshots

Screenshots of the application will be added here.

## 🏗️ Project Structure

```text
agro_care_ai_mobile/
├── android/
├── assets/
│   ├── advisory/
│   ├── models/
│   ├── test/
│   └── classes.json
├── ios/
├── lib/
│   ├── main.dart
│   ├── ai_service.dart
│   ├── location_service.dart
│   ├── weather_service.dart
│   ├── weather_page.dart
│   └── notification_service.dart
├── web/
├── windows/
├── pubspec.yaml
└── README.md
```

## ⚙️ Installation and Setup

### Prerequisites

- Flutter SDK
- Dart SDK (included with Flutter)
- Android Studio or Visual Studio Code
- An Android device or emulator
- Internet access for weather forecasts

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

### 4. Check the Flutter environment

```bash
flutter doctor
```

### 5. Run the application

Connect an Android device with USB debugging enabled or start an emulator, then run:

```bash
flutter run
```

## 🌦️ Weather Data

The application uses the Open-Meteo API to retrieve weather information based on the selected location's coordinates. An internet connection is required to fetch updated weather forecasts.

## ⚠️ Limitations

- Disease prediction accuracy depends on the model and the quality of the input image.
- Performance in real-world field conditions may differ from performance on laboratory-style datasets.
- Weather alerts are evaluated when weather data is loaded or refreshed; continuous background monitoring is not currently implemented.
- Weather forecasts and AI predictions should be treated as decision-support information, not a replacement for professional agricultural advice.

## 🚀 Future Enhancements

- Improve disease detection using field images from different lighting and background conditions.
- Expand crop and disease coverage.
- Enhance Kannada advisory content.
- Add carefully evaluated, location-aware farming recommendations.
- Explore reliable background weather alerts and offline support.

## 👨‍💻 Developer

**Madan G M**

RNS Institute of Technology (RNSIT), Bengaluru

GitHub: [madan-gm](https://github.com/madan-gm)

## 📄 License

A license has not yet been specified for this project.
