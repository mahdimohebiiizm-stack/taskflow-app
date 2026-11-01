<div align="center">

# TaskFlow (زندگی‌ساز)
### Enterprise Offline-First Productivity Engine

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.4+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Clean_Architecture-Uncle_Bob-00C7B7?style=for-the-badge)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![State](https://img.shields.io/badge/State_Management-BLoC_8.1-blueviolet?style=for-the-badge&logo=bloc&logoColor=white)](https://bloclibrary.dev)
[![Encryption](https://img.shields.io/badge/Database-SQLCipher_AES--256-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://www.zetetic.net/sqlcipher/)
[![Security](https://img.shields.io/badge/Security-Hardware_KeyStore-success?style=for-the-badge)](https://developer.android.com/training/articles/keystore)

<p align="center">
  <a href="#-english-documentation"><b>🇬🇧 English Documentation</b></a> • 
  <a href="#-مستندات-جامع-معماری-فارسی"><b>🇮🇷 مستندات جامع معماری (فارسی)</b></a>
</p>

---

</div>

## 🇬🇧 English Documentation

### 1. Executive Summary & Core Philosophies

**TaskFlow (زندگی‌ساز)** is an enterprise-grade, mission-critical productivity and time-allocation platform engineered for deterministic execution across mobile, desktop, and web environments. Architected from inception on uncompromising engineering standards, TaskFlow eradicates cloud-latency dependencies by operating on a local relational state backed by SQLite Schema Version 10 and hardened with **AES-256 SQLCipher Encryption at Rest**.

#### Core Architectural Pillars
- **Zero-Debt Architecture:** Every feature adheres strictly to Clean Architecture boundaries. Temporary hacks, loose typings, and unverified workarounds are systematically forbidden.
- **Offline-First Resilience:** 100% of user capabilities—task scheduling, Pomodoro deep work, multi-line financial ledgers, and gamification—execute locally with zero network latency.
- **Strict Type Safety:** Exhaustive compile-time type verification across all layers. Domain entities, value objects, and Result monads prevent runtime exceptions.
- **Single Responsibility Principle (SRP):** High cohesion and loose coupling enforced across presentation widgets, business interactors, and persistence adapters.

---

### 2. Clean Architecture Data Flow

```mermaid
flowchart TD
    subgraph UI_Layer["Presentation Layer (Flutter & BLoC)"]
        UI["UI Screens & Widgets (Apple HIG / RTL)"]
        Bloc["BLoC State Machines (Unidirectional)"]
        UI -->|"Dispatches Events"| Bloc
        Bloc -->|"Emits Immutable State"| UI
    end

    subgraph Domain_Layer["Pure Domain Layer (Business Logic)"]
        UseCases["Domain UseCases & Interactors"]
        Entities["Entities & Value Objects (Money, Task)"]
        RepoContracts["Repository Interfaces (Abstract)"]
        Bloc -->|"Invokes UseCases"| UseCases
        UseCases -->|"Returns Result Types"| Bloc
        UseCases -->|"Accesses"| Entities
        UseCases -->|"Calls"| RepoContracts
    end

    subgraph Data_Layer["Data Layer (Persistence & Security)"]
        RepoImpl["Repository Implementations"]
        DataSources["Local DataSources (DAO Mapping)"]
        KeyMgr["DatabaseKeyManager (KeyStore / Keychain)"]
        SQLCipher["SQLCipher Engine (SQLite v10 / AES-256)"]
        RepoContracts -.->|"Implemented by"| RepoImpl
        RepoImpl --> DataSources
        KeyMgr -->|"Injects 256-bit Key"| SQLCipher
        DataSources -->|"ACID Queries & Transactions"| SQLCipher
    end

    classDef uiStyle fill:#0A84FF,stroke:#0056B3,color:#FFFFFF,stroke-width:2px;
    classDef domainStyle fill:#10B981,stroke:#059669,color:#FFFFFF,stroke-width:2px;
    classDef dataStyle fill:#6366F1,stroke:#4F46E5,color:#FFFFFF,stroke-width:2px;
    class UI,Bloc uiStyle;
    class UseCases,Entities,RepoContracts domainStyle;
    class RepoImpl,DataSources,KeyMgr,SQLCipher dataStyle;
```

---

### 3. Technology Stack Matrix

| Domain / Layer | Technology | Version | Architectural Purpose & Rationale |
| :--- | :--- | :--- | :--- |
| **Client Platform** | Flutter SDK (Dart) | `>=3.4.0 <4.0.0` | Cross-platform AOT compilation guaranteeing 60/120 FPS jank-free rendering. |
| **System Architecture** | Pure Clean Architecture | Enterprise Spec | Strict decoupled separation into Domain, Data, and Presentation layers. Zero framework leakage into domain. |
| **State Management** | BLoC (`flutter_bloc`) | `^8.1.6` | Event-driven reactive unidirectional data flow. Enforces predictable state transitions and full testability. |
| **Dependency Injection** | GetIt | `^8.0.0` | High-speed Service Locator managing thread-safe Singleton and Factory lifecycles across boundaries. |
| **Encrypted Persistence** | SQLCipher (`sqflite_sqlcipher`) | `^3.1.3` | AES-256 hardware-backed encrypted relational storage utilizing Schema Version 10. |
| **Hardware KeyStore** | Secure Storage | `^9.2.2` | Cryptographic hardware-backed key derivation via Android KeyStore & iOS Keychain. |
| **Identity Management** | Cryptographic UUID | `^4.5.0` | Universal UUID v4 primary keys ensuring collision-free offline record generation for distributed cloud synchronization. |
| **Financial Engine** | `Money` Value Object | Custom Domain | Integer minor-unit arithmetic (Rials). Strict eradication of IEEE-754 floating-point rounding hazards. |
| **Design System & RTL** | Apple HIG + Vazirmatn | Native Tokens | RTL-native pitch-dark visual tokens (`#090B10`), dynamic progress indicators, and Shamsi Jalali formatters. |
| **Local Notifications** | Flutter Local Notifications | `^17.2.2` | Timezone-aware local background alert scheduling decoupled from remote push dependencies. |

---

### 4. Repository Directory Architecture

```text
TaskFlow/
├── .github/                         # Continuous Integration & Delivery workflows
│   └── workflows/
│       └── release.yml              # Automated release pipeline (APK, AAB, Web, GitHub Release)
├── android/                         # Native Android platform configuration & Gradle scripts
├── assets/                          # Local asset bundle (brand logo, vector icons)
│   └── sounds/                      # Pre-cached WAV/MP3 auditory feedback buffers
├── ios/                             # Native iOS configuration, entitlements & Podfile
├── lib/                             # Core Application Source Code (Clean Architecture)
│   ├── main.dart                    # Application bootstrap, MultiBlocProvider & entry point
│   ├── core/                        # Cross-cutting enterprise infrastructure
│   │   ├── concurrency/             # Parallel bootstrapping & background Isolate workers
│   │   ├── di/                      # Dependency Injection container (injection_container.dart)
│   │   ├── error/                   # Failure contracts & strongly typed Exception hierarchy
│   │   ├── notifications/           # Timezone-aware local notification manager
│   │   ├── observability/           # Global BlocObserver for state audit trails & telemetry
│   │   ├── performance/             # Frame-rate optimization & repaint boundary hooks
│   │   ├── result/                  # Functional programming Monad Result<Success, Failure>
│   │   ├── security/                # Hardware key derivation (database_key_manager.dart)
│   │   ├── services/                # Backup, sound, haptic, and platform sync services
│   │   ├── sync/                    # Background sync abstraction & pending sync queue
│   │   ├── theme/                   # Pitch-dark visual tokens, dynamic layouts & RTL typography
│   │   ├── utils/                   # Shamsi Jalali formatters & Persian numeral localization
│   │   └── widgets/                 # Reusable atomic UI components (BouncingTap, Transitions)
│   └── features/                    # Feature Modules (Clean Architecture isolated)
│       ├── analytics/               # Visual heatmaps, daily expenditure ratios & summaries
│       ├── dashboard/               # Today timeline, priority grouping & signature layout
│       ├── gamification/            # XP progression, streak freeze economy & level tiers
│       ├── navigation/              # Main navigation shell & floating action navigation bar
│       ├── notifications/           # Persistent notification center & inbox models
│       ├── onboarding/              # First-launch interactive feature walkthrough
│       ├── settings/                # Preferences, vacation blur switch & technical inspect view
│       ├── splash/                  # Zero-flicker startup splash sequence
│       └── tasks/                   # Core task execution, subtasks, pomodoro & financial ledger
├── test/                            # Comprehensive Automated Test Suites (Unit, BLoC, Widget)
├── .gitignore                       # Sanitized Git ignore rules blocking binary & symbol leaks
├── analysis_options.yaml            # Strict Linter configurations & static analysis constraints
└── pubspec.yaml                     # Application manifest declaring dependencies & assets
```

---

### 5. Architectural Patterns & Security Hardening

#### Offline-First BLoC State Management
The presentation layer communicates with the business domain strictly through reactive unidirectional event pipelines. UI widgets dispatch immutable events to BLoCs; BLoCs interact with UseCases and emit immutable states. No database driver or SQL query is ever accessed directly from the UI layer.

#### Cryptographic Security & Hardware Key Derivation
- **AES-256 Encryption at Rest:** The SQLite database (`task_flow_v1.db`) is encrypted using SQLCipher with military-grade AES-256 encryption.
- **Hardware-Backed Key Derivation (`DatabaseKeyManager`):** The 256-bit encryption key is generated using `Random.secure()` (32 bytes of cryptographically secure entropy) and stored inside Android KeyStore (`encryptedSharedPreferences: true`) and iOS Keychain (`KeychainAccessibility.first_unlock`).
- **Distributed Primary Keys (UUID v4):** All entities utilize cryptographically generated UUID v4 identifiers (`TEXT PRIMARY KEY`), eliminating integer ID collisions and laying the foundation for conflict-free multi-client synchronization.
- **Relational Integrity:** Foreign keys are strictly enforced at runtime (`PRAGMA foreign_keys = ON`), ensuring atomic cascading operations (`ON DELETE CASCADE` for subtasks and expenses, `ON DELETE SET NULL` for focus sessions).
- **Exact Financial Precision:** Financial transactions are stored and calculated strictly using integer minor units (Rials) encapsulated inside the immutable `Money` Value Object, avoiding IEEE-754 floating-point rounding hazards.

---

### 6. Automated CI/CD Pipeline

The repository integrates an automated enterprise GitHub Actions release pipeline (`.github/workflows/release.yml`) triggered on semantic version tags (`v*.*.*`):
1. **Strict Quality Gate:** Clones the code on `ubuntu-latest`, initializes JDK 17 and Flutter 3.24.x, executes `flutter pub get`, runs static analysis (`flutter analyze --no-fatal-infos`) with zero-warning enforcement, and executes all unit and widget tests (`flutter test`).
2. **Multi-Platform Build:** Concurrently compiles release artifacts:
   - Android APK: `flutter build apk --release`
   - Android App Bundle (AAB): `flutter build appbundle --release`
   - Web Production Bundle: `flutter build web --release`
3. **Automated Publishing:** Generates a GitHub Release using `softprops/action-gh-release@v2`, packaging and attaching all 3 production artifacts with automated changelog notes.

---

### 7. Local Development Quick Start

#### Prerequisites
- **Flutter SDK:** `>= 3.4.0` (Stable channel)
- **Dart SDK:** `>= 3.4.0 < 4.0.0`
- **Toolchains:** Android Studio (SDK 34+) / Xcode (15+) / Windows C++ Build Tools (CMake)

```bash
# 1. Clone the secure repository
git clone https://github.com/<your-organization>/TaskFlow.git
cd TaskFlow

# 2. Fetch dependencies
flutter pub get

# 3. Verify static analysis (Zero tolerance for warnings)
flutter analyze --no-fatal-infos

# 4. Execute test suites
flutter test

# 5. Launch application in Debug mode
flutter run
```

---

### 8. Technical Authority & Authors

**TaskFlow Core Architecture Team**  
- **Lead System Architect & DevOps Master:** Principal Engineering & Anti-Gravity Architecture Group  
- **Product Ownership:** Commercial Product Owner  

---

<div dir="rtl">

## 🇮🇷 مستندات جامع معماری (فارسی)

### ۱. چکیده اجرایی و فلسفه مهندسی سیستم

**تسک‌فلو (زندگی‌ساز)** یک پلتفرم پیشرفته و تجاری در حوزه مدیریت زمان، انضباط فردی و مدیریت مالی است که برای پردازش بلادرنگ و بدون نقص در پلتفرم‌های موبایل، دسکتاپ و وب مهندسی شده است. این سیستم با هدف دستیابی به بالاترین سطح کیفیت نرم‌افزاری، بر پایه‌ ۴ اصل بنیادین مهندسی بنا شده است:

- **معماری بدون بدهی فنی (Zero-Debt Architecture):** تمامی فیچرها بدون استفاده از راه‌حل‌های موقتی، کدهای سست، یا میان‌برهای غیرفنی پیاده‌سازی شده و از استانداردهای سخت‌گیرانه Clean Architecture پیروی می‌کنند.
- **تاب‌آوری آفلاین‌محور (Offline-First Resilience):** تمامی قابلیت‌های حیاتی برنامه اعم از ثبت تسک‌ها، جلسات پومودورو، تراکنش‌های مالی و اقتصاد گیمیفیکیشن به طور ۱۰۰٪ آفلاین و بدون کوچک‌ترین وابستگی به شبکه اجرا می‌شوند.
- **ایمنی محض در لایه تایپ‌ها (Strict Type Safety):** اعتبارسنجی کامل داده‌ها در زمان کامپایل از طریق موجودیت‌های ایمیوتبل، شیء ارزش (Value Object) و ساختار تابعی Result Monad مانع از بروز خطاهای زمان اجرا در محیط پروداکشن می‌گردد.
- **اصل تک‌مسئولیتی (Single Responsibility Principle):** جداسازی کامل وظایف میان ویجت‌های رابط کاربری، تعامل‌گرهای تجاری (UseCases) و آداپتورهای پایگاه داده تضمین شده است.

---

### ۲. ماتریس فناوری‌های سیستم

| لایه معماری | فناوری انتخابی | نسخه | هدف فنی و دلیل انتخاب |
| :--- | :--- | :--- | :--- |
| **هسته کلاینت** | فریم‌ورک Flutter (Dart) | `>=3.4.0 <4.0.0` | کامپایل بومی AOT جهت ارائه رندرینگ ۶۰ و ۱۲۰ فریم بر ثانیه بدون افت فریم. |
| **الگوی معماری** | معماری تمیز (Clean Architecture) | استاندارد سازمانی | تفکیک کامل به لایه‌های Presentation، Domain و Data بدون نفوذ فریم‌ورک به هسته بیزینس. |
| **مدیریت وضعیت** | الگوی BLoC (`flutter_bloc`) | `^8.1.6` | جریان واکنشی داده‌ها به صورت یک‌طرفه با رفتار کاملاً قطعی و قابلیت تست‌پذیری حداکثری. |
| **تزریق وابستگی** | ابزار GetIt | `^8.0.0` | Service Locator پرسرعت برای مدیریت چرخه حیات سینگلتون‌ها و فکتوری‌ها در مرزهای لایه‌ها. |
| **دیتابیس محلی** | موتور SQLCipher (`sqflite_sqlcipher`)| `^3.1.3` | پایگاه‌داده رابطه‌ای امن با استاندارد ACID و رمزنگاری سخت‌افزاری AES-256 بر پایه اسکیما نسخه ۱۰. |
| **کلیدهای سخت‌افزاری**| حافظه امن (`flutter_secure_storage`)| `^9.2.2` | ذخیره‌سازی کلید رمزنگاری در بستر سخت‌افزاری Android KeyStore و iOS Keychain. |
| **مدیریت هویت** | شناسه یکتای UUID v4 | `^4.5.0` | تولید شناسه‌های تصادفی توزیع‌شده بدون تداخل جهت همگام‌سازی ابری آینده کلاینت‌ها. |
| **محاسبات مالی** | شیء ارزش `Money` | کلاس دامین اختصاصی | محاسبات مالی با واحدهای صحیح (ریال) و حذف کامل خطای محاسباتی ممیز شناور (IEEE-754). |
| **رابط کاربری و فونت**| دستورالعمل Apple HIG + وزیرمتن | طراحی Pitch-Dark | تم تیره اختصاصی (`#090B10`)، تایپوگرافی بومی راست‌به‌چپ (RTL) و فرمت‌کننده‌های تقویم جلالی. |
| **سامانه اعلانات** | اعلانات محلی فلاتر | `^17.2.2` | زمان‌بندی دقیق هشدارهای پس‌زمینه با آگاهی از تایم‌زون بدون نیاز به سرور پوش نوتیفیکیشن. |

---

### ۳. الگوهای معماری و امنیت داده‌ها

#### مدیریت وضعیت واکنشی آفلاین‌محور (BLoC Engine)
لایه ارائه (UI) منحصراً از طریق پایپ‌لاین‌های رویدادمحور با منطق تجاری در ارتباط است. ویجت‌ها ایونت‌های تغییرناپذیر صادر کرده و BLoC پس از پردازش از طریق UseCaseها، استیت‌های جدید را ساطع می‌کند. هیچ کامپوننتی در UI دسترسی مستقیم به پایگاه داده ندارد.

#### استحکامات رمزنگاری و حفاظت اطلاعات (Cryptographic Hardening)
۱. **رمزنگاری در حالت سکون با AES-256:** فایل محلی دیتابیس (`task_flow_v1.db`) به وسیله موتور SQLCipher با رمزنگاری نظامی محافظت شده و امکان استخراج داده‌ها در دستگاه‌های روت/جیلبریک‌شده وجود ندارد.  
۲. **مدیریت کلید در سطح سخت‌افزار (`DatabaseKeyManager`):** کلید ۲۵۶ بیتی به شکل کاملاً رمزنگاری‌شده توسط `Random.secure()` تولید و در Keystore سخت‌افزاری اندروید و Keychain سیستم‌عامل iOS ذخیره می‌شود.  
۳. **کلیدهای اصلی توزیع‌شده (UUID v4):** تمام جداول برنامه از کلیدهای متنی UUID v4 به عنوان کلید اصلی استفاده می‌کنند تا در فرآیند همگام‌سازی ابری هیچ تداخلی رخ ندهد.  
۴. **یکپارچگی رابطه‌ای دیتابیس:** فعال‌سازی اجباری `PRAGMA foreign_keys = ON` در زمان اتصال، اجرای اتمیک تراکنش‌ها و حذف آبشاری ساب‌تسک‌ها و هزینه‌ها را تضمین می‌کند.  
۵. **حذف خطای ممیز شناور در امور مالی:** مبالغ به صورت عدد صحیح ریال ذخیره شده و خطاهای رایج ممیز شناور را به صفر رسانده است.

---

### ۴. خط لوله خودکار انتشار (CI/CD Pipeline)

پروژه مجهز به یک پایپ‌لاین خودکار در بستر GitHub Actions (`.github/workflows/release.yml`) است که با تگ‌گذاری نگارش‌ها (`v*.*.*`) فعال می‌شود:
- **دروازه کنترل کیفیت (Quality Gate):** بررسی لود وابستگی‌ها، اجرای تحلیل ایستای کد (`flutter analyze --no-fatal-infos`) بدون اخطار و اجرای موفق تمامی تست‌های واحد و ویجت (`flutter test`).
- **کامپایل همزمان نسخه‌ها:** ساخت خروجی‌های رسمی Release شامل فایل APK، بسته اختصاصی گوگل‌پلی (AAB) و نسخه وب.
- **انتشار خودکار در گیت‌هاب:** بارگذاری و الصاق خودکار ۳ خروجی پروداکشن به صفحه انتشار رسمی GitHub Release.

---

### ۵. راهنمای راه‌اندازی سریع در محیط توسعه

```bash
# ۱. کلون کردن مخزن پروژه
git clone https://github.com/<your-organization>/TaskFlow.git
cd TaskFlow

# ۲. دریافت پکیج‌های تایید شده
flutter pub get

# ۳. اجرای تحلیل ایستای کد (تضمین صفر بودن خطاها)
flutter analyze --no-fatal-infos

# ۴. اجرای آزمون‌های خودکار
flutter test

# ۵. اجرای برنامه در حالت دیباگ
flutter run
```

---

### ۶. حاکمیت فنی و مالکیت پروژه

**تیم راهبری فنی TaskFlow**  
- **معمار ارشد سیستم و مدیر ارشد DevOps:** گروه مهندسی معماری Anti-Gravity  
- **مالکیت محصول:** Product Owner تجاری  

*تسک‌فلو نرم‌افزاری انحصاری و طراحی‌شده بر پایه‌ بالاترین استانداردهای مهندسی نرم‌افزار است. هرگونه تغییر در لایه‌های بنیادین بدون تاییدیه فنی اکیداً ممنوع می‌باشد.*

</div>
