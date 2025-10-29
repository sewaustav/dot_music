
<div align="center">

# Dot Music

**Open-source music player built with Flutter**  
Clean, fast, and fully offline — your music, your way.

<br/>



![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![just_audio](https://img.shields.io/badge/just_audio-4CAF50?style=for-the-badge&logo=audiomack&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)

</div>

---

## 🚀 Beta Available Now!

**Android** and **iOS** beta versions are live!  
**Linux** and **Windows** builds — *coming soon*.

---

## 📱 Build from Source

### Prerequisites

Make sure you have **Flutter** installed:

```bash
# Install Flutter (if not already)
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"
flutter doctor
```

> Follow [official Flutter installation guide](https://docs.flutter.dev/get-started/install) if needed.

---

### Android Build

```bash
git clone https://github.com/sewaustav/dot_music.git dot_music
cd dot_music
flutter pub get
flutter build apk --release --flavor prod
```

> APK will be at: `build/app/outputs/flutter-apk/app-prod-release.apk`

---

### iOS Build (macOS only)

```bash
git clone https://github.com/sewaustav/dot_music.git dot_music
cd dot_music
flutter pub get
cd ios
pod install
cd ..
flutter build ios --release --flavor prod
```

> Then open `ios/Runner.xcworkspace` in Xcode → Select device → **Product → Archive**

---

## 🛠 Tech Stack

| Component               | Package                     |
|-------------------------|-----------------------------|
| Audio Playback          | `just_audio` + `just_audio_background` |
| Local Database          | `sqflite`                   |
| File System             | `path_provider` + `path`    |
| Permissions             | `permission_handler`        |
| Routing                 | `go_router`                 |
| State Management        | `provider`                  |
| Logging                 | `logger`                    |

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

Made with ❤️ and loud music

</div>
```

---

**P.S.** No extra setup needed on other devices — just `flutter pub get` and build!  
Drop a ⭐ if you like it — helps a ton!  
```