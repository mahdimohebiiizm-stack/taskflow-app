# TaskFlow (زندگی‌ساز) — Enterprise Offline-First Productivity Engine

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.4+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-00C7B7)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![State Management](https://img.shields.io/badge/State-BLoC%208.1-blueviolet)](https://bloclibrary.dev)
[![Database](https://img.shields.io/badge/Database-SQLite%20v10%20%7C%20SQLCipher%20AES--256-003B57?logo=sqlite&logoColor=white)](https://www.zetetic.net/sqlcipher/)
[![Security](https://img.shields.io/badge/Security-Hardware%20KeyStore%20%2F%20Keychain-success)](#4-architectural-patterns--security-hardening)
[![License](https://img.shields.io/badge/License-Commercial%20Enterprise-black)](#7-authors--technical-governance)

---

## 1. Executive Summary & Ecosystem Overview

### English
**TaskFlow (زندگی‌ساز)** is an enterprise-grade, mission-critical productivity platform engineered for high-performance execution across mobile, desktop, and omnichannel environments. Built upon the uncompromising pillars of **Zero-Debt Architecture**, **Offline-First Resilience**, **Strict Type Safety**, and the **Single Responsibility Principle (SRP)**, TaskFlow delivers deterministic performance, 120 FPS jank-free rendering, and bulletproof transactional integrity.

By eliminating network-latency dependencies at its foundation, TaskFlow operates an ACID-compliant local relational state powered by SQLite Schema Version 10 hardened with **AES-256 SQLCipher Encryption at Rest**. The system features a non-linear dopamine economy (Pomodoro deep work with append-only XP Ledgers), exact integer minor-unit financial ledger computations, and an Apple Human Interface Guidelines (HIG) pitch-dark visual canvas localized natively for Right-to-Left (RTL) Persian typography.

---

<div dir="rtl">

### فارسی (چکیده اجرایی و مرور اکوسیستم)
**تسک‌فلو (زندگی‌ساز)** یک پلتفرم سازمانی و ماموریت‌محور در حوزه مدیریت زمان، انضباط فردی و مدیریت مالی است که برای پردازش بلادرنگ و با کارایی بالا در سیستم‌عامل‌های موبایل و دسکتاپ مهندسی شده است. این سیستم بر پایه‌ ۴ اصل مهندسی غیرقابل‌مذاکره بنا شده است: **«معماری با بدهی فنی صفر (Zero-Debt Architecture)»**، **«تاب‌آوری آفلاین‌محور (Offline-First Resilience)»**، **«ایمنی محض در لایه تایپ‌ها (Strict Type Safety)»** و **«اصل تک‌مسئولیتی (Single Responsibility Principle)»**.

این نرم‌افزار با حذف کامل وابستگی به شبکه، وضعیت داده‌ها را در یک پایگاه داده رابطه‌ای سازگار با استاندارد ACID (نسخه اسکیما ۱۰ SQLite) نگهداری کرده و با **رمزنگاری سطح نظامی AES-256 SQLCipher در حالت سکون** محافظت می‌کند. از ویژگی‌های بارز سیستم می‌توان به اقتصاد دوپامین غیرخطی (جلسات تمرکز عمیق پومودورو همراه با دفتر کل امتیازات XP)، محاسبات دقیق تراکنش‌های مالی بدون خطای ممیز شناور (واحدهای صحیح ریال) و طراحی روان تاریک (Pitch-Dark) منطبق با دستورالعمل‌های اپل (Apple HIG) و بومی‌سازی شده برای تایپوگرافی راست‌به‌چپ (RTL) زبان فارسی اشاره نمود.

</div>

---

## 2. Technology Stack Matrix

| Domain / Layer | Technology | Architectural Purpose |
| :--- | :--- | :--- |
| **Client Platform** | Flutter SDK (`Dart >=3.4.0 <4.0.0`) | Cross-platform native AOT compilation with 60/120 FPS frame budget enforcement. |
| **System Architecture** | Pure Clean Architecture | Strict decoupling into Domain, Data, and Presentation tiers with zero framework leakage. |
| **State Management** | BLoC Pattern (`flutter_bloc ^8.1.6`) | Predictable, event-driven reactive state transitions with unidirectional data flow. |
| **Dependency Injection** | Service Locator (`get_it ^8.0.0`) | Thread-safe dependency resolution with strict Singleton vs. Factory lifecycle separation. |
| **Encrypted Persistence** | SQLCipher (`sqflite_sqlcipher ^3.1.3`) | AES-256 hardware-backed encrypted relational storage utilizing Schema Version 10. |
| **Hardware KeyStore** | Secure Storage (`flutter_secure_storage ^9.2.2`) | Cryptographic storage of database keys via Android Keystore & iOS Keychain. |
| **Identity Management** | Cryptographic UUID (`uuid ^4.5.0`) | Collision-free UUID v4 primary keys ensuring deterministic multi-client cloud synchronization. |
| **Financial Precision** | `Money` Value Object (Integer Minor Units) | Strict zero floating-point arithmetic preventing IEEE-754 calculation rounding errors. |
| **Design System & Typography**| Apple HIG + Persian Vazirmatn | RTL-native pitch-dark theme (`#090B10`), dynamic progress indicators, and Shamsi Jalali formatters. |
| **Local Notifications** | Flutter Local Notifications (`^17.2.2`) | Timezone-aware local background alert scheduling decoupled from external push servers. |

---

## 3. Repository Directory Architecture

```text
TaskFlow/
├── android/                         # Native Android configuration, ProGuard rules & Gradle build scripts
├── assets/                          # Local assets bundle (app_logo.png, localized vector icons)
│   └── sounds/                      # Pre-cached low-latency WAV/MP3 auditory feedback buffers
├── ios/                             # Native iOS configuration, entitlements & CocoaPods specification
├── lib/                             # Core Application Source Code (Clean Architecture)
│   ├── main.dart                    # Application bootstrap, MultiBlocProvider orchestration & entry point
│   ├── core/                        # Cross-cutting enterprise infrastructure
│   │   ├── concurrency/             # Parallel bootstrapping & background Isolate workers
│   │   ├── di/                      # Dependency Injection container (injection_container.dart)
│   │   ├── error/                   # Failure contracts & strongly typed Exception hierarchy
│   │   ├── notifications/           # Timezone-aware local notification manager
│   │   ├── observability/           # Global BlocObserver for state audit trails & lifecycle telemetry
│   │   ├── performance/             # Smart render engine & repaint boundary optimizations
│   │   ├── result/                  # Functional programming Monad Result<Success, Failure>
│   │   ├── security/                # Hardware key derivation (database_key_manager.dart)
│   │   ├── services/                # Local backup/restore, audio buffers, and widget sync services
│   │   ├── sync/                    # Offline-first sync abstraction & pending operation queues
│   │   ├── theme/                   # Pitch-dark visual tokens, dynamic layouts & RTL typography
│   │   ├── utils/                   # Jalali date formatters & Persian numeral localization
│   │   └── widgets/                 # Atomic design components (BouncingTap, DualLayoutTransition)
│   └── features/                    # Modular Feature Domains (Domain / Data / Presentation)
│       ├── analytics/               # Visual completion heatmaps, Rial balance charts & KPI metrics
│       ├── dashboard/               # Today timeline, smart overdue pill & signature layout
│       ├── gamification/            # Dopamine leveling engine, streak shields & XP audit ledger
│       ├── navigation/              # Floating bottom navigation bar & screen shell orchestration
│       ├── notifications/           # Persistent notification inbox & alert history
│       ├── onboarding/              # Interactive first-launch user onboarding sequence
│       ├── settings/                # Profile management, vacation mode blur & technical inspector
│       ├── splash/                  # Zero-flicker native startup splash screen
│       └── tasks/                   # Core task execution, subtasks, pomodoro timer & expense tracking
├── test/                            # Comprehensive Automated Test Suites (Unit, BLoC, Widget contracts)
├── .gitignore                       # Sanitized Git ignore rules blocking binary & symbol leaks
├── analysis_options.yaml            # Strict static analysis rules & linter constraints
└── pubspec.yaml                     # Application manifest & verified dependency declarations
```

---

## 4. Architectural Patterns & Security Hardening

### Offline-First BLoC State Management
- **Unidirectional Reactive Streams:** Every user interaction emits an immutable `BlocEvent`. BLoCs process events asynchronously, map results through Domain UseCases, and yield immutable `BlocState` models.
- **Optimistic UI Updates:** Interface state transitions instantly with micro-haptic feedback while persistence commits asynchronously in SQLite, ensuring zero perceived latency.
- **Decoupled Architecture:** Presentation widgets never communicate directly with SQLite or external drivers; all operations pass through Domain Interactors returning functional `Result<Success, Failure>` types.

### Cryptographic Security & Data Protection
- **AES-256 SQLCipher Encryption at Rest:** The entire local database file (`task_flow_v1.db`) is encrypted using SQLCipher. 
- **Hardware-Backed Key Derivation (`DatabaseKeyManager`):** The 256-bit cryptographic encryption key is generated using `Random.secure()` (32 bytes of cryptographically secure entropy) and stored inside Android KeyStore (`encryptedSharedPreferences: true`) and iOS Keychain (`KeychainAccessibility.first_unlock`).
- **Distributed Identity (UUID v4):** Every database record across all tables (`tasks`, `sub_tasks`, `expense_items`, `focus_sessions`, `xp_ledger`) utilizes cryptographically generated UUID v4 strings as primary keys (`TEXT PRIMARY KEY`), preventing auto-increment ID collisions during future multi-device cloud synchronization.
- **Relational Integrity:** SQLite enforces relational invariants at runtime (`PRAGMA foreign_keys = ON`) with cascading deletions (`ON DELETE CASCADE`) for subtasks/expenses and `ON DELETE SET NULL` for focus sessions.
- **Zero Floating-Point Financial Arithmetic:** Financial amounts are strictly stored and computed in integer minor units (Rials) encapsulated within the immutable `Money` Value Object, eliminating IEEE-754 floating-point errors.

---

## 5. CI/CD & DevOps Pipeline

The repository integrates a robust GitHub Actions automated release pipeline (`.github/workflows/release.yml`) enforcing zero-debt delivery:

```yaml
name: TaskFlow Enterprise CI/CD Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  audit-and-test:
    name: Code Quality & Security Audit
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Codebase
        uses: actions/checkout@v4

      - name: Setup Java Toolchain
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Setup Flutter Environment
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: 'stable'
          cache: true

      - name: Fetch Dependencies
        run: flutter pub get

      - name: Verify Static Analysis & Zero Warnings
        run: flutter analyze --no-fatal-infos

      - name: Execute Automated Test Suites
        run: flutter test --coverage

  build-release:
    name: Build Production Artifacts
    needs: audit-and-test
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Codebase
        uses: actions/checkout@v4

      - name: Setup Flutter Environment
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: 'stable'

      - name: Fetch Dependencies
        run: flutter pub get

      - name: Compile Release Android App Bundle (AAB)
        run: flutter build appbundle --release

      - name: Compile Release Android APK
        run: flutter build apk --release

      - name: Upload Production Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: taskflow-production-builds
          path: |
            build/app/outputs/bundle/release/*.aab
            build/app/outputs/flutter-apk/*.apk
```

---

## 6. Local Development Quick Start

### Prerequisites
- **Flutter SDK:** `>= 3.4.0` (Stable channel)
- **Dart SDK:** `>= 3.4.0 < 4.0.0`
- **Toolchains:** Android Studio (SDK 34+) / Xcode (15+) / Windows C++ Build Tools (CMake)

### 1. Clone the Repository
```bash
git clone https://github.com/<your-organization>/TaskFlow.git
cd TaskFlow
```

### 2. Fetch Verified Dependencies
```bash
flutter pub get
```

### 3. Verify Code Quality & Linter Compliance
Ensure zero analyzer warnings or errors exist:
```bash
flutter analyze --no-fatal-infos
```

### 4. Execute Automated Contract & Unit Tests
```bash
flutter test
```

### 5. Launch Application in Development Mode
```bash
# Debug Mode
flutter run

# Profile Mode (Benchmark rendering and memory performance)
flutter run --profile
```

---

## 7. Authors & Technical Governance

**TaskFlow Core Architecture Team**  
- **Lead System Architect & DevOps Master:** Principal Engineering & Anti-Gravity Architecture Group  
- **Product Ownership:** Commercial Product Owner  

*TaskFlow is proprietary software engineered under strict Clean Architecture standards. Direct modification of domain entities or circumvention of cryptographic invariants without architectural clearance is strictly prohibited.*
