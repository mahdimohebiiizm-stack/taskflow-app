# TaskFlow — Project State Tracker

**Generated**: 2026-10-17  
**Architecture**: Clean Architecture (Presentation, Domain, Data) with BLoC State Management & SQLite Offline Storage  
**Database Schema Version**: v10 (Gamification Profile Table & Streak Freeze Economy)  

---

## 🚀 Engineering Phases Overview

### ✅ Phase 1: Core Clean Architecture & SQLite Foundation
- ACID-compliant SQLite schema with PRAGMA foreign keys (`tasks`, `sub_tasks`).
- Immutable entities (`TaskEntity`, `SubTaskEntity`) and DTO models (`TaskModel`, `SubTaskModel`).
- BLoC orchestration with optimistic UI updates and reactive state streams.

### ✅ Phase 2: Financial Expansion & Expense Tracking
- Multi-line expense tracking with integer minor units (`ExpenseItemEntity`, `ExpenseItemModel`).
- Zero floating-point arithmetic (`Money` value object).
- Relational cascading deletion (`ON DELETE CASCADE`).

### ✅ Phase 3: Gamification, Streaks & Engagement
- Streak counting and 7-day milestone shields (`سپر محافظ`).
- Dynamic user profile avatars and titles (`تازه‌کار`, `برنامه‌ریز`, `مبارز زمان`, `استاد بهره‌وری`).
- Non-linear Leveling and XP curve calculations.

### ✅ Phase 4: Time-Blocking & World-Class UI/UX
- Apple Human Interface Guidelines (HIG) aesthetic with Persian typography (Vazirmatn) and RTL alignment.
- Time-blocked timeline tasks (`_TimeBlockedTaskTile`) with custom painters, micro-interactions, and haptic feedback.
- Clean RTL timeline geometry with zero overflow.

### ✅ Phase 4.5 & Phase 5: Interactive UI + Core Business Logic & SQLite v8
- **Database Schema v8**:
  - `focus_sessions` table with task foreign key (`ON DELETE SET NULL`), duration, state, and earned XP.
  - `xp_ledger` table with append-only audit trail for all XP awards (`task_completion`, `pomodoro_session`, `streak_bonus`, `manual`).
  - Indexed for sub-millisecond querying (`idx_focus_sessions_task_id`, `idx_focus_sessions_started_at`, `idx_xp_ledger_created_at`, `idx_xp_ledger_source`).
- **FocusTimerBloc Engine**:
  - Isolated stream-based `Ticker` via `Stream.periodic`.
  - State machine: `FocusTimerInitial`, `FocusTimerRunning`, `FocusTimerPausedState`, `FocusTimerCompletedState`, `FocusTimerCancelledState`.
  - Strict reward invariants: `earnedXp = actualMinutes * 1` exclusively upon completion; `0 XP` when cancelled.
  - Seamlessly connected to `PomodoroFocusSheet` with automatic persistence in `focus_sessions` and `xp_ledger`.
- **Dopamine Economy Rules**:
  - Normal Task completion = `10 XP`.
  - High / Critical Priority Task completion = `20 XP`.
  - Non-linear dynamic leveling formula: `Target XP = ((Level - 1) * 100) ^ 1.2` (~250 XP for Level 2, ~1700 XP for Level 6/Level 5 cap).
- **Interactive Recovery Workflows**:
  - `dashboard_page.dart`: Clickable `BouncingTap` on `smart_group_header_overdue` opening blurred glass bottom sheet (`overdue_tasks_bottom_sheet`) with instant reschedule actions ("امروز", "فردا").
  - `reports_page.dart`: Interactive penalized day calendar cells in `penalized_day_history_sheet` with instant task rescheduling actions to today or tomorrow.

### ✅ Phase 5.5: Ultimate 360° UI/UX Master Audit & Surgical Polish (COMPLETED)
- **1. Dashboard Overdue Header & Bottom Shadow Bug (`dashboard_page.dart`)**:
  - Purged duplicate plain red text `۲ موعد گذشته` under "برنامه امروز". Preserved single interactive red pill badge (`smart_group_header_overdue`) wrapped in `BouncingTap`.
  - Removed hardcoded bottom spacer `const SizedBox(height: 112)` below timeline `Expanded`, eliminating last task clipping and harsh voids.
  - Updated `ReorderableListView` and empty state `ListView` to `bottom: 140` padding for seamless scroll clearance above the floating bottom navigation bar.
  - Added `padding: const EdgeInsets.symmetric(horizontal: 16)` and `clipBehavior: Clip.none` to `_WorkspaceAndTagsFilterBar` so edge chips are never sliced.
- **2. Overdue Bottom Sheet Redesign (`dashboard_page.dart`)**:
  - Completely purged borders (`Border.all`) from overdue task cards and the "فردا" button.
  - Implemented Apple HIG surface depth: `#1C1C1E` dark mode card surface, `#2C2C2E` for "فردا", and `#0A84FF` for "امروز".
  - Transformed overdue task cards into a single balanced horizontal row (RTL: icon + title/priority on right, action buttons on left) with zero awkward vertical gaps.
- **3. Pomodoro Focus Sheet UX Overhaul (`pomodoro_focus_sheet.dart`)**:
  - Replaced timer status background styling with clean typography and subtle opacity (`fontSize: 11.5, color: secondaryTextColor.withValues(alpha: 0.8)`).
  - Automatically hidden the bottom control row (`بازنشانی`, `شروع تمرکز`, `اتمام تمرکز`) via `if (!isFinished)` when session reaches `00:00` completion state.
  - Removed duplicate checkmark emoji `✅` from the "تیک زدن و اتمام تسک" button label while preserving clean vector `CupertinoIcons.check_mark_circled`.
- **4. Jalali (Shamsi) Date Consistency (`create_task_sheet.dart` & `reports_page.dart`)**:
  - Implemented standard `JalaliDateFormatter` utility (`lib/core/utils/jalali_date_formatter.dart`).
  - Replaced Gregorian `۲۰۲۶/۱۰/۱۷` in `create_task_sheet.dart` with localized Persian Jalali format (e.g. `امروز (۲۶ مهر)`).
  - Replaced raw Gregorian `در ماه ۲۰۲۶/۱۰` in `reports_page.dart` calendar subtitle with Jalali month and year (e.g. `در ماه مهر ۱۴۰۵`).
- **5. Create Task Sheet Borderless Input (`create_task_sheet.dart`)**:
  - Purged bright blue `OutlineInputBorder` from task title `TextFormField`, subtask, tags, and financial amount inputs.
  - Applied borderless surface design (`fillColor: fieldFill` `#2C2C2E` / `#F2F2F7`, `BorderRadius.circular(16)`, `borderSide: BorderSide.none`).
- **6. Settings Page Duplicate Title & Scroll Clearance (`settings_page.dart`, `reports_page.dart`, `financial_analytics_page.dart`)**:
  - Renamed outer section header in `settings_page.dart` from "پایگاه داده آفلاین محلی (SQLite)" to "مدیریت داده‌ها و پشتیبان‌گیری" to eliminate redundancy.
  - Enforced `140px` bottom padding across all main scroll views (`settings_page.dart`, `reports_page.dart`, and `financial_analytics_page.dart`) ensuring charts, cards, and floating nav bar co-exist with zero visual trapping.
- **Verification**: `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.

### ✅ Phase 4.9: Deep Modals, Input Theme & Interaction Audit (COMPLETED)
- **1. Purge Android Purple Text Selection (`app_theme.dart`)**:
  - Configured `textSelectionTheme: const TextSelectionThemeData(cursorColor: Color(0xFF0A84FF), selectionColor: Color(0x400A84FF), selectionHandleColor: Color(0xFF0A84FF))` across both dark and light themes.
  - Set `colorScheme.primary` to `#0A84FF` and defined explicit surface colors to eliminate any default Android purple artifacts.
- **2. Upgrade "Edit Task" Bottom Sheet (`dashboard_page.dart`)**:
  - Replaced basic sheet with an Apple HIG sheet featuring a clean header with title and circular close (`X`) button (`CupertinoIcons.xmark`).
  - Added borderless surface inputs (`#2C2C2E` in dark mode, `#F2F2F7` in light mode, radius 16).
  - Integrated a 4-tier priority selector pill row (پایین, متوسط, بالا, بحرانی).
  - Ensured fluid keyboard avoidance using `viewInsets` within a `SingleChildScrollView` and wrapped save action in `BouncingTap`.
- **3. Secondary Sheets & Dialogs Apple Polish (`dashboard_page.dart`)**:
  - Stripped all `Border.all` and `BorderSide` borders from `_showEndDayConfirmationDialog`, `_QuickAddBottomSheet`, and `_SpotlightSearchBar`.
  - Implemented Apple HIG surface depth (`#1C1C1E` background with `#2C2C2E` inputs), `BorderRadius.circular(24)`, and wrapped interactive controls in `BouncingTap`.
- **4. Floating Apple-Style SnackBars (`app_theme.dart`)**:
  - Configured `snackBarTheme` with `behavior: SnackBarBehavior.floating`, radius 16, `#2C2C2E` / `#1C1C1E` backgrounds, elevation 8, and Vazirmatn Persian typography.
- **5. Compact Top Banner Cards in Analytics (`reports_page.dart` & `financial_analytics_page.dart`)**:
  - Reduced vertical footprint of `_buildHeader` across reports and financial analytics (`padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)`).
  - Replaced oversized 48x48 default `IconButton` with sleek 32x32 rounded `BouncingTap` containers.
  - Reduced vertical spacing below header from 16 to 12 so key KPI cards sit higher in the viewport.
- **Verification**: `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.

### ✅ Phase 5.6: Overdue Logic Rescue, Edit Task Overhaul & Quick Add Redesign (COMPLETED)
- **1. The "Overdue" Logic Fix (`dashboard_page.dart`, `task_entity.dart`, `task_state.dart`)**:
  - Enforced strict overdue invariants: a task is overdue IF AND ONLY IF (1) its scheduled date/time is strictly in the past compared to `DateTime.now()`, and (2) its status is NOT `isDone` (`status != TaskStatus.done`).
  - Purged premature `task.isPenalized` classification bypass from `_classifyTaskSmartGroup`.
  - Added Persian-digit red count badge (`Key('overdue_count_badge')`) beside the `Key('smart_group_header_overdue')` header pill.
  - Ensured completed tasks and tasks scheduled for future times today never enter the overdue list or count badge.
- **2. Incomplete "Edit Task" Modal Overhaul (`dashboard_page.dart`, `task_event.dart`, `task_bloc.dart`)**:
  - Added interactive Workspace / Category chips (عمومی, شخصی, کاری, مالی) powered by `TaskWorkspaces.selectableWorkspaces`.
  - Added Date & Time card with Persian Jalali formatting (`JalaliDateFormatter.formatRelativeJalali`), all-day switch toggle (`Key('edit_task_all_day_switch')`), and start/end time pickers.
  - Added dual delete task triggers: subtle trash icon in header (`Key('edit_task_header_delete_button')`) and prominent Apple-style red danger action button (`Key('edit_task_delete_button')`) with heavy haptic feedback, permanently deleting the task via `TaskDeleted` in `TaskBloc`/SQLite.
  - Added `workspaceId`, `tags`, and `clearTimeBlock` support to `TaskEdited` in `TaskBloc`.
- **3. Quick Add ⚡ Sheet Redesign (`dashboard_page.dart`)**:
  - Eliminated squashed layout: `TextField` (`Key('dashboard_quick_add_field')`) now spans the full modal width with comfortable padding.
  - Integrated a sleek borderless circular submit action (`Key('dashboard_quick_add_submit')`) with upward arrow (`CupertinoIcons.arrow_up`) directly inside the `suffixIcon`.
  - Enables instant task submission directly from the keyboard or with a single tap on the suffix icon.
- **4. Verification & Test Suite**:
  - `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.
  - `flutter test` -> **75 / 75 tests passing (100% green)**.

### ✅ Phase 6.5: Persistent Notification Center & In-Box (COMPLETED)
- **1. SQLite Schema v9 & Domain Architecture**:
  - Added table `app_notifications` (`id TEXT PRIMARY KEY`, `title TEXT NOT NULL`, `message TEXT NOT NULL`, `type TEXT NOT NULL`, `is_read INTEGER NOT NULL DEFAULT 0`, `timestamp TEXT NOT NULL`).
  - Added compound indices `idx_notifications_timestamp` (`timestamp DESC`) and `idx_notifications_is_read` (`is_read ASC`) for instant sub-millisecond retrieval.
  - Designed Clean Architecture layers: `AppNotificationEntity`, `AppNotificationModel`, `NotificationLocalDataSource`, and `NotificationRepository`.
  - Registered `NotificationBloc` in `injection_container.dart` and provided in `MultiBlocProvider` in `main.dart`.
- **2. Automated Domain Hooks & Persistent Audit Trail**:
  - **FocusTimerBloc**: Persists `reward` notification (+XP earned) on Pomodoro completion; persists `warning` notification (0 XP earned) on cancellation.
  - **TaskBloc**: Persists `reward` notification on task completion (+10 XP / +20 XP); persists `penalty` notification on end-of-day penalty; provides helper for overdue task alerts.
  - **SettingsBloc**: Persists `penalty` notification on daily streak failure / shield loss.
  - **GamificationBloc**: Connects level-ups and milestone rewards to the notification timeline.
- **3. Apple HIG Dashboard Bell & Unread Badge (`dashboard_page.dart`)**:
  - Borderless top app bar Bell icon (`_DashboardNotificationBellButton`, `Key('dashboard_notifications_button')`) located beside the dark mode toggle.
  - Reactive vibrant red circular badge (`Key('dashboard_notifications_unread_dot')`) visible dynamically whenever `unreadCount > 0`.
- **4. Apple Blurred Glass Notification Sheet (`notifications_bottom_sheet`)**:
  - Blurred glass bottom sheet (`Key('notifications_bottom_sheet')`) titled "پیام‌ها و اعلان‌ها" with clean typography.
  - Color-coded notification types: Green for rewards, Red for penalties, Orange for warnings, Blue for system info.
  - Persian Jalali relative timestamps via `_formatNotificationTimestamp`.
  - Swipe-to-dismiss (`Dismissible`) with instant deletion from SQLite.
  - Single-tap to mark as read, plus "خواندن همه" (Mark all as read) top action button.
- **5. Verification & Test Suite**:
  - `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.
  - `flutter test` -> **79 / 79 tests passing (100% green)**.

### ✅ Mandatory UI Hotfix: Edit Task Modal & Quick Add Sheet Overhaul (COMPLETED)
- **1. World-Class "Edit Task" Modal (`dashboard_page.dart`)**:
  - Completely aligned with the Apple HIG standard of the "Create Task" sheet.
  - **Category/Workspace**: Added selectable category chips (`TaskWorkspaces.selectableWorkspaces`: عمومی, شخصی, کاری, مالی) with `Key('edit_task_workspace_$ws')`.
  - **Priority**: Added 4-tier segmented priority pills (کم, متوسط, بالا, فوری) with color status dots (7x7) and active selection fill.
  - **Date & Time (Apple Date & Time Card)**: Integrated relative Jalali date formatting via `_formatDueDateLabel` (e.g. `امروز (۲۶ مهر)`, `فردا (۲۷ مهر)`), `Key('edit_task_due_date_button')`, `CupertinoSwitch` for all-day mode (`Key('edit_task_all_day_switch')`), and dedicated start/end time pickers (`Key('edit_task_start_time_button')`, `Key('edit_task_end_time_button')`) with RTL theme builders avoiding Android Material purple artifacts.
  - **Danger Zone**: Added dual delete triggers: top header circular trash icon (`Key('edit_task_header_delete_button')`) and an prominent red danger button (`Key('edit_task_delete_button')`) calling `TaskDeleted` with heavy haptic feedback.
  - **Directionality & Aesthetics**: Wrapped entire sheet in `Directionality(textDirection: TextDirection.rtl)` with seamless keyboard inset padding and 100% existing widget key preservation.
- **2. Redesigned "Quick Add ⚡" Sheet (`dashboard_page.dart`)**:
  - Purged any separate external action buttons.
  - `TextField` spans the entire modal width with standard `16px` margin padding (`EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset)`).
  - Embedded submission action directly inside `TextField.decoration.suffixIcon` as a borderless circular Apple Blue button (`Key('dashboard_quick_add_submit')`) with upward arrow (`CupertinoIcons.arrow_up`).
  - Added Electric Yellow bolt icon (`CupertinoIcons.bolt_fill`) in prefix and enforced RTL directionality for natural typing and submission.
- **3. Verification & Test Suite**:
  - `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.
  - `flutter test` -> **79 / 79 tests passing (100% green)**.

### ✅ Phase: Dashboard Declutter & iMessage-Style Quick Add (COMPLETED)
- **1. Declutter: Collapsible Filter Chips (`dashboard_page.dart`)**:
  - Hidden horizontal workspace & tags filter bar by default to maximize viewport focus on today's timeline.
  - Added a borderless Filter Toggle Button (`Key('dashboard_header_filter_toggle')`) in the top app bar using `CupertinoIcons.slider_horizontal_3` with `BouncingTap` micro-interaction and haptic feedback.
  - Wrapped `_WorkspaceAndTagsFilterBar` inside an `AnimatedCrossFade` widget (`Key('dashboard_filters_crossfade')`) driven by state boolean `_showFilters`.
  - Seamless zero-height collapse (`secondChild: SizedBox(width: double.infinity, height: 0)`) with smooth `Curves.easeOutCubic` 250ms transition.
- **2. Premium iMessage-Style Quick Add Bottom Sheet (`dashboard_page.dart`)**:
  - Implemented authentic frosted glass blur (`BackdropFilter(sigmaX: 25, sigmaY: 25)`) with Apple translucent background (`#EB1C1C1E` dark / `#EBFFFFFF` light).
  - Designed fluid pill container with `BorderRadius.circular(30)` and subtle contrast fill (`#2C2C2E` in dark mode, `#F2F2F7` in light mode).
  - Tightly embedded circular solid Apple Blue action button (`Key('dashboard_quick_add_submit')`) with upward arrow (`CupertinoIcons.arrow_up`) directly inside `TextField.decoration.suffixIcon`.
  - Added Electric Yellow bolt icon (`CupertinoIcons.bolt_fill`) in prefix with generous edge padding (`16px`) and automatic keyboard avoidance (`viewInsetsOf(context).bottom`).
  - Preserved 100% of all existing widget keys (`dashboard_quick_add_sheet`, `dashboard_quick_add_field`, `dashboard_quick_add_submit`) and tag/workspace parsing logic.
- **3. Verification & Test Suite**:
  - `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.
  - `flutter test` -> **79 / 79 tests passing (100% green)**.

### ✅ Phase: UX Flow & Spacing Masterclass (COMPLETED)
- **1. Pull-to-Reveal Filters (`dashboard_page.dart`)**:
  - Replaced the button toggle mechanism with an authentic iOS Spotlight pull-to-reveal experience.
  - Moved horizontal Workspace and Tags Filter Bar directly below `_SpotlightSearchBar` inside the animated pull-to-reveal header area (`AnimatedSize`, `Key('dashboard_filters_crossfade')`).
  - Pulling down the list or tapping search reveals both the Spotlight search bar and the filter chips simultaneously; closing search collapses both cleanly to 0 height.
  - Removed visible `slider_horizontal_3` toggle button and its gap from `_DashboardHeader` for an ultra-clean header, preserving widget keys offstage for 100% key compatibility.
- **2. Elevate "Quick Add ⚡" Modal (`dashboard_page.dart`)**:
  - Elevated the modal sheet with generous vertical padding (`padding: EdgeInsets.fromLTRB(16, 24, 16, bottomInset + 24)`).
  - Ensured the pill text field floats beautifully 24px ABOVE the software keyboard (`MediaQuery.viewInsetsOf(context).bottom + 24`) with ample breathing room.
  - Enhanced handle bar spacing (`SizedBox(height: 20)`) and capsule container padding (`4px` vertical).
- **3. Quick Add Lightning Button Spacing (`dashboard_page.dart`)**:
  - Added dedicated `SizedBox(height: 24)` spacing above the timeline header row containing `_QuickAddFloatingButton`.
  - The Quick Add lightning trigger now breathes freely and sits distinctly separated by 24px from any hero/CTA cards above it.
- **4. Verification & Test Suite**:
  - `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.
  - `flutter test` -> **79 / 79 tests passing (100% green)**.

### ✅ Global Masterclass Audit & Surgical Overhaul (COMPLETED)
- **1. Part 1: Floating Smart Island for "Quick Add ⚡" (`dashboard_page.dart`)**:
  - Rebuilt `_QuickAddBottomSheet` as a floating Smart Island card detached from the screen edges (`margin: EdgeInsets.all(16)`).
  - Configured `showModalBottomSheet` with `backgroundColor: Colors.transparent` and `isScrollControlled: true`.
  - Dynamically floats directly above the software keyboard using `padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom)`.
  - Added authentic Apple frosted glass blur (`BackdropFilter(sigmaX: 30, sigmaY: 30)`), translucent pill styling, and `BorderRadius.circular(32)`.
  - Embedded compact horizontal Smart Priority Chips (کم, متوسط, بالا, فوری) with status dots, active selection pills, and dedicated keys (`Key('quick_add_priority_${priority.name}')`).
  - Preserved 100% of existing widget keys (`dashboard_quick_add_sheet`, `dashboard_quick_add_field`, `dashboard_quick_add_submit`).
- **2. Part 2: Core Domain Logic — All-Day Task Overdue Fix (`task_entity.dart`, `task_model.dart`, `task_entity_test.dart`)**:
  - Added `bool get isAllDay` to both `TaskEntity` and `TaskModel` (resolving true when `timeBlock == null` and both start/end times are absent).
  - Overhauled `scheduledEndDateTime` and `isOverdue`: all-day tasks are strictly NOT overdue at midday of their scheduled date; their effective end boundary is `23:59:59.999` of that day.
  - Added comprehensive unit test suite in `test/features/tasks/domain/entities/task_entity_test.dart` asserting midday, 23:59:59, next day rollover, and vacation mode invariance (8/8 tests passing).
- **3. Part 3: Proactive Reward Engine — Overdue Time Tracker (`task_bloc.dart`, `dashboard_page.dart`)**:
  - Implemented `TaskOverdueCheckRequested` event and `notifiedOverdueTaskIds` (`UnmodifiableListView<String>`) in `TaskState`.
  - Integrated 1-minute periodic ticker (guarded against test environments via `shouldTick`) and `AppLifecycleState.resumed` listener in `_DashboardPageState` via `WidgetsBindingObserver`.
  - Automatically dispatches warning notifications to SQLite persistent store (`app_notifications`) and `NotificationBloc`: `"تسک '[عنوان]' موعدش گذشت! سریعاً انجامش دهید."`.
- **4. Part 4: Global Apple HIG & Jalali Localization Sweep**:
  - Added `formatDate(DateTime date, {String separator = '/'})` to `JalaliDateFormatter`.
  - Replaced raw Gregorian dates in `task_card.dart` and `reports_page.dart` with localized Persian Jalali formatting (eliminating `2026/10` leaks).
  - Configured global `scrollBehavior` with `BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())` on `MaterialApp` in `lib/main.dart` for 100% Apple scroll bounce across all scroll views.
  - Purged raw `Border.all` from `_NotificationTileItem` in `dashboard_page.dart`, replacing it with soft Apple HIG shadow elevation and subtle fill depth.
- **5. Verification & Test Suite**:
  - `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.
  - `flutter test` -> **80 / 80 tests passing (100% green)**.

### ✅ Precision UI Hotfix: Bottom Navigation Bar Frosted Glass Blur Contour (`main_screen.dart`)
- **The Issue**: `BackdropFilter` was wrapped inside a standard `ClipRRect(borderRadius: BorderRadius.circular(28))`. The blur rendered as a rigid rectangle across `(0, 0, w, h)`, bleeding above the flat bar line (`top = 24.0`) and across the curved FAB cradle notch.
- **The Fix**:
  - Replaced `ClipRRect` by wrapping `BackdropFilter` directly within `ClipPath(clipper: const _NavBarClipper())`.
  - The frosted glass blur effect now strictly samples and blurs pixels inside the exact custom bezier path of the nav bar (cradle notch, lateral half-capsule arcs, and top offset).
  - Added `const` constructor to `_NavBarClipper` and attached `Key('dashboard_bottom_nav')` directly to `_GlassCurvedNavBar`.
- **Verification**:
  - `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.
  - `flutter test` -> **80 / 80 tests passing (100% green)**.





### ✅ Phase 7.5: Dynamic Multi-Theme & Accent Architecture (COMPLETED)
- **1. Dynamic Accent State & Domain Model (`app_accent_color.dart`, `user_settings_entity.dart`, `user_settings_model.dart`)**:
  - Created `AppAccentColor` enum (`blue`, `forestGreen`, `sunsetOrange`, `royalPurple`) with native colors: Apple Blue (`#0A84FF`), Forest Green (`#005C4A`), Sunset Orange (`#FF7043`), and Royal Purple (`#5E5CE6`).
  - Added `final AppAccentColor accentColor` to `UserSettingsEntity` and `UserSettingsModel` with persistent SQLite key-value serialization (`keyAccentColor = 'accent_color'`).
  - Backward and forward compatible default `AppAccentColor.blue` when key is absent.
- **2. BLoC Orchestration & Persistence (`settings_bloc.dart`, `settings_event.dart`, `settings_bloc_test.dart`)**:
  - Implemented `SettingsAccentColorChanged` event and handler in `SettingsBloc`, saving updated accent to SQLite and emitting new state.
  - Added automated unit test in `test/features/settings/presentation/bloc/settings_bloc_test.dart` asserting state emission and repository save on accent changes.
- **3. Dynamic Theme Engine (`app_theme.dart` & `main.dart`)**:
  - Refactored `AppTheme.lightTheme({Color primaryColor = defaultPrimaryColor})` and `AppTheme.darkTheme({Color primaryColor = defaultPrimaryColor})` to dynamically adapt primary brand color.
  - Dynamically configured `colorScheme.primary`, `primaryColor`, `textSelectionTheme` (cursor, selection, handle), `floatingActionButtonTheme`, `switchTheme`, and `progressIndicatorTheme`.
  - Connected `MaterialApp` in `lib/main.dart` via `BlocBuilder<SettingsBloc, SettingsState>` so changing the accent color instantly re-themes the application in real-time while preserving Light/Dark mode toggles.
- **4. Settings UI Accent Swatches (`settings_page.dart`)**:
  - Added "رنگ تم و برجسته‌سازی" card (`Key('settings_accent_color_card')`) under the Appearance section.
  - Horizontal row of circular color swatches (`Key('settings_accent_color_${accent.name}')`) with checkmark indicator on the active accent and spring haptic feedback.
- **5. Global Dynamic Accent Integration (`main_screen.dart`, `dashboard_page.dart`)**:
  - Dynamically resolved active tab indicator, tab icon tint, and central FAB color in `main_screen.dart` via `Theme.of(context).primaryColor`.
  - Updated Quick Add submit button and components to leverage dynamic `Theme.of(context).primaryColor`.
  - Preserved 100% of all existing widget keys across all screens and bottom sheets.
- **6. Verification & Test Suite**:
  - `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.
  - `flutter test` -> **81 / 81 tests passing (100% green)**.

### ✅ Phase 8: The Third Dimension — "Zen Mode" (تم آرامش) (COMPLETED)
- **1. Zen Palette Architecture (`app_theme.dart` & `app_colors.dart`)**:
  - Engineered `AppTheme.zenTheme({Color primaryColor = defaultPrimaryColor})` factory method.
  - Calming, warm sand paper background: `#F4F1EA` (`AppColors.backgroundZen`), creamy card surface `#FAF8F5` (`AppColors.surfaceZen`), and nav bar `#FDFBF7` (`AppColors.navBarZen`).
  - Deep warm espresso brown typography: `#3E3A39` (`AppColors.textZen`) and muted `#7A7471` (`AppColors.textZenSecondary`).
  - System-wide dynamic `primaryColor` propagation across text selection, FAB, switches, indicators, and snackbars.
- **2. Core Tri-State Theme State & Model Migration (`app_theme_mode.dart`, `user_settings_entity.dart`, `user_settings_model.dart`)**:
  - Upgraded binary dark mode to tri-state enum `AppThemeMode` (`light`, `dark`, `zen`).
  - Backwards-compatible SQLite persistence via `keyAppThemeMode = 'app_theme_mode'` while preserving `keyIsDarkMode = 'is_dark_mode'`.
  - Seamless migration: existing installations reading legacy `'true'`/`'false'` automatically resolve to `AppThemeMode.dark`/`AppThemeMode.light`.
  - Added accessors `isDarkMode`, `isZenMode`, `isLightMode` on `UserSettingsEntity` ensuring 100% backward compatibility.
- **3. BLoC Orchestration & Persistence (`settings_bloc.dart`, `settings_event.dart`, `settings_bloc_test.dart`)**:
  - Implemented `SettingsThemeModeChanged` event and handler in `SettingsBloc`, saving state to SQLite.
  - Maintained `SettingsThemeModeToggled` for legacy consumers.
  - Added unit test asserting Zen mode transitions and persistence (`82/82` tests passing).
- **4. Tri-State Animated Toggle Button (`main_screen.dart`)**:
  - Replaced binary Moon/Sun button in top app bar with cyclical Tri-State switcher:
    - State 1: Sun ☀️ (`CupertinoIcons.sun_max_fill`, `#FFA000`, `Key('icon_sun')`) -> transitions to Moon 🌙
    - State 2: Moon 🌙 (`CupertinoIcons.moon_stars_fill`, `#FFD54F`, `Key('icon_moon')`) -> transitions to Lotus/Leaf 🪷
    - State 3: Lotus/Leaf 🪷 (`Icons.spa_rounded`, `#2E7D32`, `Key('icon_zen')`) -> transitions to Sun ☀️
  - Animated with spring curves, 54° rotation, scale, and fade transitions (`Curves.easeOutBack`).
- **5. Dashboard & Shell Zen Integration (`main_screen.dart`, `dashboard_page.dart`, `settings_page.dart`)**:
  - Updated `_DashboardRefPalette` with static `zen` palette and `of(bool isDark, {bool isZen = false})`.
  - Passed `isZen` down through `DashboardPage`, `_DashboardHeader`, and `_GlassCurvedNavBar`.
  - Added segmented tri-state theme mode row in `settings_page.dart` with keys (`Key('settings_theme_mode_light')`, `Key('settings_theme_mode_dark')`, `Key('settings_theme_mode_zen')`).
- **6. Verification & Test Suite**:
  - `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.
  - `flutter test` -> **82 / 82 tests passing (100% green)**.

### ✅ Phase 9 & 10: Grand Unification — Part 1 (UI, Onboarding & Zen Refinement) (COMPLETED)
- **1. True Zen Mode Refinement (`app_colors.dart`, `app_theme.dart`, `dashboard_page.dart`)**:
  - Background updated to warm, soft sand: `#EFEAE1` (`AppColors.backgroundZen`).
  - Cards and surfaces updated to soft cream: `#F8F5EF` (`AppColors.surfaceZen`) with diffused warm shadows (`#1F4A4036`).
  - Typography fully purged of pure black: deep espresso `#5A554F` (`AppColors.textZen`) for primary and `#8C867C` (`AppColors.textZenSecondary`) for secondary.
  - Floating bottom nav updated to warm cream `#F5F0E8` (`AppColors.navBarZen`).
  - Updated `_DashboardRefPalette.zen` and `AppTheme.zenTheme()` with card theme elevation 1.5, custom shadow colors, and matching switch thumb/track colors.
- **2. Splash Screen & Programmatic Brand Logo (`splash_page.dart`)**:
  - Engineered `SplashPage` (`Key('splash_screen')`) with animated glowing bolt emblem (`Icons.bolt_rounded`, `#FFB300`), subtle halo pulses, and Vazirmatn typography ("زندگی‌ساز").
  - Seamless route resolution reading persistent SQLite flag `has_seen_onboarding`. If first time -> navigate to `OnboardingPage`; else -> `MainScreen`.
  - Added `autoNavigate` toggle for deterministic headless widget testing.
- **3. Apple-Style Onboarding Experience (`onboarding_page.dart`)**:
  - Built 3 swipeable slides (`PageView`) featuring Apple HIG iconography and category pills:
    1. "بوم سفید شما" (Empty Canvas & Smart Task Management)
    2. "تمرکز عمیق" (Deep Work, Pomodoro & Zen Mode)
    3. "رشد و پاداش" (Gamification, Streaks & Rial Rewards)
  - Interactive pagination dots, RTL swipe support, and primary "شروع" button (`Key('onboarding_get_started_button')`) that persists `has_seen_onboarding = true`.
  - Added "راهنمای تعاملی و امکانات" card in `settings_page.dart` (`Key('settings_reopen_onboarding_card')`) enabling users to re-launch Onboarding at any time.
- **4. Apple-Style Empty States & Routing Audit (`dashboard_page.dart`, `main_screen.dart`, `settings_page.dart`)**:
  - Empty state for Dashboard tasks: Tinted `CupertinoIcons.sparkles` with circular glowing container, Persian typography "روز جدید، بوم سفید" and "برای شروع، یک تسک جدید اضافه کنید".
  - Empty state for Notification Inbox (`Key('notifications_empty_state')`): Tinted `CupertinoIcons.sparkles`, matching typography and clean Apple aesthetic.
  - Completely purged default `MaterialPageRoute` across navigation shell, settings, and profile pages, transitioning exclusively to `CupertinoPageRoute`.
- **5. Verification & Test Suite**:
  - `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.
  - `flutter test` -> **85 / 85 tests passing (100% green)**.
  - Executed confirmation chime script via PowerShell.

### ✅ Phase 9 & 10: Grand Unification — Part 2 (Finance, Confetti & Gamification) (COMPLETED)
- **1. The Celebration Engine (Confetti & Frosted Glass Dialog)**:
  - Integrated `confetti` package (`^0.7.0`) with a screen-wide `ConfettiWidget` (`Key('main_screen_confetti_widget')`) mounted in `MainScreen`'s root `Stack`.
  - Listen to `GamificationBloc` level increases (`curr.level > prev.level`) via `BlocListener` to trigger a 3-second celebratory confetti explosion.
  - Engineered bouncy frosted-glass celebration dialog via `showGeneralDialog` with `BackdropFilter` (sigma 18), spring elastic scaling curve (`Curves.elasticOut`), radial golden trophy halo badge (`Icons.emoji_events_rounded`), level indicator (`Key('level_up_dialog_level')`), user title (`Key('level_up_dialog_user_title')`), motivational reward text, and Apple dismiss action (`Key('level_up_dialog_dismiss_button')`).
  - Formatted level numbers with `toPersianDigits` and wrapped titles in `Flexible` with `TextOverflow.ellipsis` to ensure zero layout overflows on any screen dimension.
  - Proper disposal of `ConfettiController` inside `_MainScreenState.dispose()` to prevent memory leaks.
- **2. The Financial Bridge (Tasks == Budget)**:
  - Added `copyWith` method to `RialFinancialSummaryEntity` for immutable state manipulation.
  - Created `FinancialAnalyticsBudgetAdjusted(deltaRials, reason)` event in `FinancialAnalyticsEvent` and corresponding handler in `FinancialAnalyticsBloc`, updating `totalBudgetRials = (totalBudgetRials + deltaRials).clamp(0, ...)`.
  - Injected `FinancialAnalyticsBloc` and `GamificationBloc` into `TaskBloc` via constructor and registered dependencies in `injection_container.dart`.
  - **Task Completion Reward**: Dispatches +50,000 Rials to `FinancialAnalyticsBloc` and +10/+20 XP to `GamificationBloc` on transition to `TaskStatus.done`.
  - **Task Overdue / Day-End Penalty**: Dispatches -10,000 Rials per penalized task to `FinancialAnalyticsBloc` and negative gamification trigger to `GamificationBloc` on `DayEnded` and `TaskOverdueCheckRequested`.
- **3. Fluid Budget Animation in Financial Analytics (`financial_analytics_page.dart`)**:
  - Rebuilt "جریان‌های مالی و بودجه" card (`Key('rial_financial_analytics_card')`) with `AnimatedSwitcher` (350ms duration, fade + scale curve) for dynamic budget number transitions.
  - Wrapped progress indicator in `AnimatedFractionallySizedBox` (450ms duration, `Curves.easeOutCubic`) for fluid budget consumption visualization.
- **4. Verification & Test Suite**:
  - `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.
  - `flutter test` -> **89 / 89 tests passing (100% green)** across all 21 test suites.
  - Automated unit and widget tests in `celebration_and_financial_bridge_test.dart` and smoke test in `widget_test.dart` fully green.

### ✅ Phase 11: True Zen Mode Global Aesthetic Overhaul (COMPLETED)
- **1. Palette Architecture & Colors (`app_colors.dart`, `app_theme.dart`)**:
  - `backgroundZen`: `#E8E2D5` (Warm, earthy kraft paper tone system-wide; purged cold grays/whites).
  - `surfaceZen` & `navBarZen`: `#F2EFE8` (Warm latte/cream surface for cards and floating nav).
  - `textZen`: `#4A443A` (Deep espresso/sepia typography; purged 100% of pure blacks).
  - `textZenSecondary`: `#8E867A` (Muted earthy clay for captions, icons, and secondary info).
  - Diffused warm drop shadows: `Color(0x1A4A4036)` applied across `cardTheme`, `dialogTheme`, `bottomSheetTheme`, and custom shadow painters.
- **2. Global Theme & Semantic Color Enforcement (`dashboard_page.dart`)**:
  - Overhauled `_DashboardRefPalette.zen`:
    - `bg`: `AppColors.backgroundZen` (`#E8E2D5`)
    - `s1`: `AppColors.surfaceZen` (`#F2EFE8`)
    - `s2`: `Color(0xFFE2DDD2)` (warm kraft contrast fill for inputs, pills, and filter chips)
    - `tx`: `AppColors.textZen` (`#4A443A`)
    - `mu`: `AppColors.textZenSecondary` (`#8E867A`)
    - `sub`: `Color(0xFF6B6458)`
    - `ok`: `Color(0xFF6B8E6B)` (Soft sage green)
    - `hot`: `Color(0xFFC66B5D)` (Muted dusty terracotta)
- **3. Screen-Wide & Modal Zen Reach**:
  - `MainScreen`: Passes `isZen` to `DashboardPage`, `ReportsPage`, `SettingsPage`, `FinancialAnalyticsPage`, `UserProfilePage`, and `CreateTaskSheet`.
  - Floating Bottom Navigation (`_GlassCurvedNavBar`): Custom glass fill `#F2EFE8`, warm inactive icons `#8E867A`, and warm shadow `Color(0x1A4A4036)`.
  - Level-Up Dialog: Surface `#F2EFE8` with deep espresso typography `#4A443A`.
  - `DashboardPage`: Quick Add Bottom Sheet (`_QuickAddBottomSheet`), Quick Add Floating Button (`_QuickAddFloatingButton`), Edit Task Bottom Sheet (`_EditTaskBottomSheet`), End Day Confirmation Dialog, Overdue Recovery Sheet, and Notifications Sheet (`_NotificationsSheetContent`) all fully themed to Zen palette with `0xFFE2DDD2` input fills and `0x1A4A4036` diffused shadows.
  - `ReportsPage`: Monthly habit calendar and penalized day history sheet styled with `surfaceZen` and `textZen`.
  - `FinancialAnalyticsPage`: Glass cards and metric boxes styled with `surfaceZen` and `0xFFE2DDD2` fills.
  - `SettingsPage` & `UserProfilePage`: Minimal cards, SQLite sync row, backup dialog, and profile text fields fully styled with Zen cream surfaces and kraft fills.
- **4. Verification & Test Suite**:
  - `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.
  - `flutter test` -> **89 / 89 tests passing (100% green)** across all test suites.
  - All existing widget `Key`s 100% preserved.

### ✅ Phase 12: The Symphony & Sound Design (Enterprise Audio Architecture) (COMPLETED)
- **1. Audio Architecture (Clean, Modular & Decoupled)**:
  - Integrated `audioplayers` with decoupled `SoundAndHapticService` registered in Service Locator (`injection_container.dart`).
  - Added semantic sound effect methods:
    - `playSuccessChime()`: Short, crisp, satisfying chime (+XP/Rials) on task completion with light haptic feedback.
    - `playLevelUpFanfare()`: Triumphant celebratory fanfare upon leveling up with heavy haptic feedback.
    - `playSoftTick()`: Subtle mechanical click/tick for micro-interactions (e.g. changing themes) with selection haptic feedback.
    - `playErrorBuzz()`: Low-frequency buzz alert for overdue penalty or deduction events with heavy haptic feedback.
  - Retained full backward compatibility with previous API (`playTaskCompletionFeedback`, `playDailyVictoryFeedback`, `playPomodoroCompletedFeedback`).
  - Added proper lifecycle memory hygiene (`dispose()` to stop and release native player channels and resources).
- **2. Audio Asset Placeholder & Graceful Offline Synthesis**:
  - Structured physical audio directory `assets/sounds/` with README documentation and defined standard paths (`success_chime.mp3`, `level_up_fanfare.mp3`, `soft_tick.mp3`, `error_buzz.mp3`, `pomodoro_chime.mp3`).
  - Graceful degradation: attempts physical asset loading via `AssetSource`; on `assetErr` or in headless/offline environments, falls back seamlessly to synthesized PCM RIFF WAV buffers via `BytesSource` without throwing exceptions or blocking UI.
  - Implemented 16-bit mono PCM synthesizers:
    - `generatePopDingWav()`: Dual-tone chime (A5 880Hz + E6 1318.5Hz, ~110ms).
    - `generateVictorySuccessWav()`: Celebratory C-major arpeggio (C5, E5, G5, C6, ~360ms).
    - `generatePomodoroGentleChimeWav()`: Gentle bell chime (E5 659.25Hz + B5 987.77Hz, ~240ms).
    - `generateSoftTickWav()`: High-frequency click (1600Hz, ~35ms).
    - `generateErrorBuzzWav()`: Dissonant low buzz (130Hz + 195Hz, ~160ms).
  - Parallel background synthesis caching via `Future.wait` and optional isolate offloading.
- **3. Event-Driven Injection (Zero UI Blocking)**:
  - Registered `SoundAndHapticService.instance` in Service Locator and injected into `TaskBloc`.
  - Non-blocking execution with `unawaited(...)` to ensure smooth 60/120fps UI rendering.
  - Integrated `playSuccessChime()` into `TaskBloc._onTaskStatusTransitioned` on task completion (`TaskStatus.done`).
  - Integrated `playErrorBuzz()` into `TaskBloc._onDayEnded` and `TaskBloc._onTaskOverdueCheckRequested` on overdue task penalties.
  - Integrated `playLevelUpFanfare()` into `MainScreen._triggerLevelUpCelebration` alongside confetti and frosted dialog.
  - Integrated `playSoftTick()` into `MainScreen` theme mode toggle button and `SettingsPage` theme selector.
- **4. Verification & Test Suite**:
  - `flutter analyze --no-fatal-infos` -> **0 errors (100% clean)**.
  - `flutter test` -> **92 / 92 tests passing (100% green)** across all 21 test suites.
  - Added new unit and BLoC tests in `gamification_streak_and_titles_test.dart` and `task_bloc_test.dart` validating semantic audio calls, counter increments, and WAV header integrity.

---

### Phase 13: Secure Cloud-Ready Backup & Restore
- **Status**: Completed
- **1. Test Deferral Directive**:
  - Per Product Owner directive, Rule 5 (Test-Driven Mindset) was temporarily deferred. Zero test files were created or modified in `test/`. Focus was 100% on feature implementation and static analysis clean pass.
- **2. Decoupled Service Layer (`lib/core/services/backup_service.dart`)**:
  - Registered lazy singleton `BackupService` in `lib/core/di/injection_container.dart`.
  - Added dependencies `path_provider: ^2.1.6`, `share_plus: ^13.3.1`, `file_picker: ^13.1.0`.
  - Export: Generates structured, timestamped JSON export (`taskflow_backup_YYYYMMDD_HHMMSS.json`) containing metadata, version 1, schema verification, and complete records across all 7 database tables (`tasks`, `sub_tasks`, `task_expenses`, `app_settings`, `focus_sessions`, `xp_ledger`, `app_notifications`). Invokes native system share sheet via `SharePlus.instance.share` for direct saving to Google Drive, iCloud, Files, or messaging apps.
  - Import/Restore: Prompts file selection via `FilePicker.pickFile` (`.json`, `.taskflow`, `.db`, `.sqlite`). Validates payload integrity, schema structure, and executes an atomic SQLite transaction to replace table rows without leaving database in inconsistent state.
- **3. Apple HIG UI Integration (`SettingsPage`)**:
  - Added dedicated section "فضای ابری و پشتیبانگیری" (Cloud & Backup) adhering to iOS 17 / macOS HIG.
  - Added "تهیه نسخه پشتیبان" button with key `Key('settings_create_backup_button')` and `CupertinoIcons.cloud_upload`.
  - Added "بازیابی اطلاعات" button with key `Key('settings_restore_backup_button')` and `CupertinoIcons.cloud_download`.
  - Added full-screen frosted glass blur overlay (`BackdropFilter` with `ImageFilter.blur(sigmaX: 5, sigmaY: 5)`) with animated spinner and status message during backup and restore operations.
  - Triggered full app-wide BLoC reload upon restore: `SettingsLoadRequested`, `TasksLoadRequested`, `FinancialAnalyticsLoadRequested`, `NotificationsLoadRequested`.
- **4. Sensory Integration**:
  - Invokes `SoundAndHapticService.instance.playSuccessChime()` upon successful backup export or restore completion.
- **5. Verification**:
  - `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.

---

### Phase 14 (Phase 3): Home Screen Widgets (Apple HIG & Native Sync)
- **Status**: Completed
- **1. Native Widget Bridge (`home_widget`)**:
  - Added dependency `home_widget: ^0.10.0` to `pubspec.yaml`.
  - Created decoupled `WidgetSyncService` in `lib/core/services/widget_sync_service.dart` with `HomeWidgetDriver` abstraction for testability and graceful degradation.
  - Serializes core state into native shared container (`group.com.example.taskFlow` for iOS, SharedPreferences for Android):
    - Streak Count (`streak_count`)
    - Daily Budget (`daily_budget_rials`, `daily_budget_formatted`)
    - Top 3 Highest Priority Pending Tasks (`task_1_title`, `task_1_priority`, `task_2_title`, `task_2_priority`, `task_3_title`, `task_3_priority`)
    - JSON task payload (`pending_tasks_json`) and pending count (`pending_tasks_count`)
  - Calls `HomeWidget.saveWidgetData` and signals native widgets via `HomeWidget.updateWidget(name: 'TaskFlowWidget', androidName: 'TaskFlowWidgetProvider', iOSName: 'TaskFlowWidget')`.
- **2. Event-Driven Reactive Sync**:
  - Registered `WidgetSyncService` as singleton in `lib/core/di/injection_container.dart` and injected into `TaskBloc`.
  - Non-blocking background sync using `unawaited(_syncHomeWidget())` in `TaskBloc` triggered upon:
    - Task status transitions (especially to `done`, recalculating rewards and budget).
    - Task creation, editing, rescheduling, and deletion.
    - Day ended / overdue penalty checks.
  - Linked daily streak updates in `SettingsBloc` (`SettingsDailyStreakSucceeded`, `SettingsDailyStreakFailed`, `SettingsLoadRequested`) directly to `WidgetSyncService.instance.updateStreak`.
- **3. Native Implementation Guide**:
  - Generated `native_widgets_guide.md` in the project root containing exact copy-pasteable SwiftUI/WidgetKit code (`TaskFlowWidget.swift`) and Android Glance/AppWidgetProvider code (`TaskFlowWidgetProvider.kt`, metadata XML, and manifest registration).
- **4. Unit Testing**:
  - Created `test/core/services/widget_sync_service_test.dart` verifying serialization, priority sorting (Critical > High > Medium > Low), completed task exclusion, partial task padding, and graceful degradation on bridge errors.
- **5. Verification**:
  - `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.

---

### Phase 15 (Phase 4): The Gamification Dashboard (UI/UX & Animation)
- **Status**: Completed
- **1. Executive Dashboard (`lib/features/tasks/presentation/widgets/gamification_dashboard_widget.dart`)**:
  - Engineered `GamificationDashboardWidget` adhering to Apple Human Interface Guidelines and frosted glass aesthetics (`BackdropFilter` with blur `sigmaX: 12, sigmaY: 12`).
  - Integrated into the executive top section of `DashboardPage` (`lib/features/dashboard/dashboard_page.dart`).
  - Implemented `GamificationDashboardSliverDelegate` supporting pinned header scrolling (`SliverPersistentHeader`).
- **2. Core Visual Components**:
  - **Level & XP Bar (`_XpProgressBar`)**: Shows current level and honorary title (`_LevelAndTitleHeader`), with a dynamic `LinearProgressIndicator` and smooth `TweenAnimationBuilder<double>` progress and count-up animation (`$current / 50 XP`).
  - **The Streak Flame (`_StreakFlameBadge`)**: Dynamic 🔥 emoji logic. If active ($> 3$), shows flame glow with fire badge (`Key('gamification_streak_hot')`); if 0, renders a cold/ice visual (`Key('gamification_streak_cold')`); if 1..3, renders focus lightning badge (`Key('gamification_streak_neutral')`).
  - **Daily Budget Matrix (`_BudgetMatrixCard`)**: Dynamic counting up of today's budget in Rials via `TweenAnimationBuilder<double>` with comma separation and Persian digits (`toPersianDigits`).
- **3. Tri-State Reactive Theming**:
  - Implemented `DashboardTriState` (`cold`, `neutral`, `hot`) with reactive color palette `_TriStatePalette`:
    - *Cold (Procrastination)*: Deep blue gradient, ice blue borders, and frosty soft glow.
    - *Neutral (Focus)*: Minimalist Apple monochrome gradient with subtle elevation shadows.
    - *Hot (Momentum/Streak > 3)*: Fiery red/orange sunset gradient, vibrant borders, and glowing drop shadow.
- **4. Strict TDD Widget Test Suite**:
  - Created `test/features/tasks/presentation/widgets/gamification_dashboard_widget_test.dart` testing Cold State, Hot State, Neutral State, dynamic TriState calculation from streak, and `SliverPersistentHeader` integration.
- **5. Verification**:
  - `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.

---

### Phase 16 (Phase 5): UI Refinement & Feature Discovery (Onboarding)
- **Status**: Completed
- **1. Dashboard Cleanup & Separation of Concerns (`lib/features/tasks/presentation/widgets/gamification_dashboard_widget.dart`)**:
  - Completely removed the Daily Budget/Financial card ("بودجه امروز") from the Home dashboard. Financial analytics and budget matrices now live exclusively in the Financial feature tab.
  - Re-adjusted internal padding (`EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0)`) and sliver delegate extent (`minExtent: 112.0`, `maxExtent: 112.0`), restoring Apple HIG proportions without whitespace or layout imbalance.
  - Isolated dependency imports by removing `financial_analytics_bloc.dart` from the gamification dashboard widget.
- **2. Feature Discovery & Gestures Guide (`lib/features/dashboard/widgets/dashboard_gestures_guide_widget.dart`)**:
  - Implemented `DashboardGesturesGuideWidget` teaching hidden gestures and tools using Persian localization and intuitive icons:
    - ➡️ **Swipe Right on a task (`gesture_guide_swipe_right`)**: Reveals Focus Timer (شروع تمرکز ⏱️) & Add Subtask (افزودن زیرتسک ➕).
    - ⬅️ **Swipe Left on a task (`gesture_guide_swipe_left`)**: Reveals Edit (ویرایش ✏️) & Delete (حذف تسک 🗑️).
    - 🔍 **Hidden Tools (`gesture_guide_search_filter`)**: Explains Search (جستجوی هوشمند 🔍) and Filter features in the top app bar.
  - Dual presentation support:
    - Inline dismissible card placed smoothly beneath the gamification header when `has_seen_tutorial == false`.
    - Modal bottom sheet invoked via `DashboardGesturesGuideWidget.showModal(context)` and triggered anytime by the new header guide button (`Key('dashboard_header_help_button')`).
- **3. Decoupled Persistence Layer (`lib/core/services/feature_discovery_service.dart`)**:
  - Added dependency `shared_preferences: ^2.5.5` to `pubspec.yaml`.
  - Created `FeatureDiscoveryService` and `FeatureDiscoveryServiceImpl` using local storage key `has_seen_tutorial`.
  - Registered `FeatureDiscoveryService` as lazy singleton in `lib/core/di/injection_container.dart`.
  - Dismissing the guide (via "متوجه شدم، بزن بریم!" button or top close button) sets `has_seen_tutorial = true` so the tutorial card does not re-appear on subsequent launches.
- **4. Strict TDD Verification & Automated Test Suites**:
  - Updated `test/features/tasks/presentation/widgets/gamification_dashboard_widget_test.dart` asserting that the budget card and 'ریال' are completely absent from the Home Dashboard (5 / 5 tests green).
  - Added `test/core/services/feature_discovery_service_test.dart` testing default status, persistence on dismissal, and resetting (3 / 3 tests green).
  - Added `test/features/dashboard/widgets/dashboard_gestures_guide_widget_test.dart` testing Persian typography, icons, dismiss button callbacks, close icon callbacks, and modal bottom sheet display (4 / 4 tests green).
  - Fixed generic mock signatures in `test/core/services/widget_sync_service_test.dart` (6 / 6 tests green).
  - Scoped level-up celebration dialog assertions in `test/features/gamification/celebration_and_financial_bridge_test.dart` (4 / 4 tests green).
- **5. Verification Results**:
  - `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.
  - `flutter test` -> **110 / 110 tests passing (100% green across all test suites)**.

---

### Phase 17 (Phase 5.1): Move Tutorial to Initial Onboarding Flow
- **Status**: Completed
- **1. Dashboard Eradication & Pure Focus**:
  - Completely removed `DashboardGesturesGuideWidget`, help button (`dashboard_header_help_button`), and tutorial state from `dashboard_page.dart` and `_DashboardHeader`.
  - The Home Dashboard is now 100% focused strictly on Tasks, Level/XP, and Streak with zero UI clutter or potential overflow.
- **2. Integrated into Initial Onboarding (`lib/features/onboarding/onboarding_page.dart`)**:
  - Added dedicated 3rd slide: "Gestures & Tools" (راهنمای ژست‌های حرکتی و ابزارها) to the 4-slide onboarding flow.
  - Included exact educational content with Apple HIG cards:
    - ➡️ **Swipe Right on a task (`onboarding_gesture_swipe_right`)**: Reveals Focus Timer (شروع تمرکز ⏱️) & Add Subtask (افزودن زیرتسک ➕).
    - ⬅️ **Swipe Left on a task (`onboarding_gesture_swipe_left`)**: Reveals Edit (ویرایش ✏️) & Delete (حذف تسک 🗑️).
    - 🔍 **Hidden Tools (`onboarding_gesture_search_filter`)**: Explains Search (جستجوی هوشمند 🔍) and Filter features in the top app bar.
- **3. Architectural Cleanup & Redundant Code Deletion**:
  - Relies completely on the app's standard onboarding flag (`SettingsOnboardingCompleted` -> `has_seen_onboarding` in UserSettings / SQLite).
  - Deleted redundant service `lib/core/services/feature_discovery_service.dart` and its test `test/core/services/feature_discovery_service_test.dart`.
  - Deleted redundant widget `lib/features/dashboard/widgets/dashboard_gestures_guide_widget.dart` and its test `test/features/dashboard/widgets/dashboard_gestures_guide_widget_test.dart`.
  - Cleaned up dependency injection in `lib/core/di/injection_container.dart`.
- **4. Strict TDD Verification**:
  - Updated `test/features/onboarding/onboarding_and_splash_test.dart` to verify all 4 slides, gesture cards, and onboarding completion (3 / 3 test groups green).
  - Updated `test/widget_test.dart` to verify that no gestures guide or help buttons appear on the clean dashboard.
- **5. Verification Results**:
  - `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.
  - `flutter test` -> **103 / 103 tests passing (100% green across all test suites)**.

---

### Phase 18 (Phase 5.2): Migrate Player Profile to Settings Tab
- **Status**: Completed
- **1. Dashboard Eradication & Pure Focus on Tasks (`lib/features/tasks/presentation/widgets/gamification_dashboard_widget.dart` & `dashboard_page.dart`)**:
  - Completely removed the bulky Player Profile card (Level, XP progress bar, and Streak Flame) from the main dashboard UI.
  - Refactored `GamificationDashboardWidget` into an ultra-clean, minimal header displaying ONLY the current Day/Date and a subtle greeting with NO large cards.
  - The Home Dashboard is now 100% focused strictly on tasks, eliminating vertical clutter and maximizing task visibility.
- **2. Inject Player Profile Card into Settings Tab (`lib/features/settings/presentation/widgets/player_profile_card.dart` & `settings_page.dart`)**:
  - Engineered `PlayerProfileCard` adhering strictly to Apple Human Interface Guidelines:
    - Frosted glassmorphism with `BackdropFilter` (blur sigma 12), smooth gradient, and glowing elevation border.
    - Top Level & Title row (`Key('gamification_level_title')`): Displays level pill badge (e.g., "سطح ۱") and honorary title (e.g., "تازه‌کار" / "استاد بهره‌وری").
    - Dynamic Streak Flame badge:
      - 🔥 Hot state (`Key('gamification_streak_hot')`): Streak > 3 with fiery red/orange styling and energetic glow.
      - ❄️ Cold state (`Key('gamification_streak_cold')`): Zero streak with cool frosted ice styling ("استمرار غیرفعال").
      - ⚡ Neutral state (`Key('gamification_streak_neutral')`): Streak 1..3 with sleek monochrome focus styling.
    - XP Progress Bar (`Key('gamification_xp_bar')`): Fluid count-up animation (`$current / 50 XP`) and smooth `LinearProgressIndicator`.
  - Injected `const PlayerProfileCard()` at the VERY TOP of the `ListView` in `SettingsPage` (`Key('settings_player_profile_card')`).
  - Seamless reactive integration: dynamically reads state from `GamificationBloc` and `SettingsBloc` without UI blocking.
- **3. Strict TDD Verification & Automated Test Suites**:
  - Updated `test/features/tasks/presentation/widgets/gamification_dashboard_widget_test.dart`:
    - Asserts that Day/Date and simple greeting are rendered.
    - Asserts that Level & Title header, XP progress bar, Streak Flame badges, and budget cards are completely absent from the dashboard.
    - Verified `GamificationDashboardSliverDelegate` integration.
  - Created `test/features/settings/presentation/widgets/player_profile_card_test.dart`:
    - Verified Cold, Neutral, and Hot momentum states.
    - Verified dynamic TriState automatic computation from streak count.
    - Verified Level, Title, and XP progress bar rendering.
  - Updated `test/widget_test.dart`:
    - Verified `settings_player_profile_card` renders properly when navigating to the Settings tab in the app smoke test.
- **4. Verification Results**:
  - `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.
  - `flutter test` -> **104 / 104 tests passing (100% green across all test suites)**.

---

### Phase 19 (Phase 6): The Reward Loop (Confetti & Micro-Interactions) & Fresh Install Onboarding Fix
- **Status**: Completed
- **1. Visual Celebration Layer (`confetti: ^0.7.0` & `dashboard_page.dart`)**:
  - Safely added stable `confetti: ^0.7.0` dependency to `pubspec.yaml`.
  - Mounted `ConfettiWidget` inside the root `Stack` of `DashboardPage` body with `Key('dashboard_confetti_widget')`.
  - Wrapped `ConfettiWidget` inside `IgnorePointer(ignoring: true)` so confetti particles never obstruct touch gestures or task interactions.
  - Configured `ConfettiController` with 1200ms duration, non-looping, blast direction downward (`pi / 2`), emission frequency 0.05, 20 particles per burst, gravity 0.15, and Apple celebration palette (Electric Blue, Green, Amber, Orange, Purple, Red).
  - Ensured proper lifecycle disposal in `dispose()`.
- **2. Event-Driven Micro-Interactions (Tasks & Level-Up)**:
  - **Task Completion Celebration**: In `_DashboardPageState`, added reactive diff tracking (`_previousDoneTaskIds`). When any task transitions to `TaskStatus.done`, fires `_confettiController.play()` and triggers `HapticFeedback.lightImpact()`.
  - **Level-Up Extravaganza**: Wrapped dashboard in `BlocListener<GamificationBloc, GamificationState>`. When `state.userProfile.level > _previousLevel`, fires celebratory confetti burst and triggers `HapticFeedback.heavyImpact()`.
- **3. Fresh Install Onboarding Routing Fix**:
  - Guaranteed `has_seen_onboarding` strictly defaults to `false` on initial installation across `UserSettingsEntity.defaults`, `UserSettingsModel.fromKeyValueMap`, and `SettingsLocalDataSourceImpl.defaultSettings`.
  - Updated `SplashPage._navigateNext()` to inspect `SettingsBloc` state and seamlessly route fresh users to `OnboardingPage` (`/onboarding`), transitioning existing users directly to `MainScreen` (`/main`).
  - Updated `main.dart` fallback home logic to dynamically evaluate `hasSeenOnboarding`.
- **4. Strict TDD Verification & Automated Test Suites**:
  - Created `test/features/dashboard/reward_loop_confetti_test.dart` verifying:
    - `ConfettiWidget` overlay presence and `IgnorePointer` touch isolation.
    - Confetti blast trigger upon task completion transition.
    - Confetti blast trigger upon `GamificationLevelUpTriggered` event.
  - Updated `test/features/onboarding/onboarding_and_splash_test.dart` asserting fresh install defaults and `SplashPage` routing directly to `OnboardingPage`.
  - Updated `test/features/settings/data/repositories/settings_repository_impl_test.dart` verifying fresh database defaults.
  - Updated `test/widget_test.dart` with explicit onboarding flag setup.
- **5. Verification Results**:
  - `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.

---

### Phase 20: UI/UX Refinement (Vacation Blur & Settings Toggle)
- **Status**: Completed
- **1. Fix Theme Selection Redundancy (`lib/features/settings/presentation/pages/settings_page.dart`)**:
  - Completely eradicated the redundant `CupertinoSwitch` toggle from the "پوسته کلی برنامه" (App Theme) card.
  - The card now relies exclusively on the 3 Apple-styled segmented buttons (`Key('settings_theme_mode_light')`, `Key('settings_theme_mode_dark')`, `Key('settings_theme_mode_zen')`).
- **2. Full-Screen Vacation Blur (`lib/features/dashboard/dashboard_page.dart`)**:
  - When `isVacationMode == true`, normal dashboard components (stats, gamification header, focus CTA, timeline, and task tiles) are rendered underneath.
  - The entire dashboard body below the top app bar is wrapped inside an `Expanded Stack` overlay featuring:
    - `ClipRRect(borderRadius: BorderRadius.circular(24))` with `BackdropFilter(filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0))`.
    - `AbsorbPointer(absorbing: true)` touch barrier ensuring underlying tasks/buttons cannot be interacted with during vacation.
    - Centered, non-clipped Vacation Mode Card (`_VacationModeBlurOverlay`) displaying "شما در حال استراحت هستید 🌴" with generous padding.
  - The top app bar (`_DashboardHeader`) remains visible and crisp.
- **3. Strict TDD Verification & Automated Test Suite**:
  - Created `test/features/dashboard/vacation_blur_and_theme_toggle_test.dart` testing:
    - App Theme card has zero switches and switches theme via segmented buttons.
    - Dashboard renders normally without overlay when vacation mode is false.
    - Dashboard wraps body with 5.0 sigma blur, blocks touches with `AbsorbPointer`, and centers vacation card when vacation mode is true.
### Phase 21 (Phase 7): Profile Transformation & XP Economy
- **Status**: Completed
- **1. Transform Settings into "My Profile" (پروفایل من)**:
  - Renamed Tab 2 in `MainScreen` bottom navigation bar from `'تنظیمات'` to `'پروفایل'`.
  - Transformed `SettingsPage` (`lib/features/settings/presentation/pages/settings_page.dart`) into a clean, player-centric view:
    - Top header: "پروفایل من" with gear icon button (`Key('profile_technical_settings_button')`) opening `TechnicalSettingsView`.
    - Prominently features `PlayerProfileCard` (`Key('settings_player_profile_card')`) at the top with level, XP progress bar, and streak flame.
    - Features `XpStoreCard` (`Key('xp_store_card')`) right below `PlayerProfileCard`.
    - Minimal user account card (`Key('settings_user_profile_card')`) navigating to `UserProfilePage`.
  - **Eradicated Clutter**: Extracted ALL technical toggles (App Theme, Smart Render, Backup, Vacation Mode, SQLite details, Technical Specs, Onboarding Guide) out of the main profile view.
- **2. TechnicalSettingsView (`lib/features/settings/presentation/pages/technical_settings_view.dart`)**:
  - Created standalone `TechnicalSettingsView` accessed strictly via `Key('profile_technical_settings_button')` in the profile header.
  - Contains:
    - App Theme Mode segmented buttons (`Key('settings_theme_mode_card')`, `light`, `dark`, `zen`).
    - Brand Accent Color picker (`Key('settings_accent_color_card')`).
    - Manual Vacation Mode toggle (`Key('settings_vacation_mode_switch')`).
    - Smart Render Engine 60fps toggle (`Key('settings_smart_render_switch')`).
    - Interactive Onboarding / Tour guide button (`Key('settings_reopen_onboarding_card')`).
    - Cloud & Backup export/restore (`Key('settings_cloud_backup_card')`, `settings_create_backup_button`, `settings_restore_backup_button`).
    - Offline SQLite database status & experimental backup sheet (`Key('settings_add_device_button')`).
    - System technical specifications (`_buildTechRow`).
- **3. In-App XP Economy & Streak Freeze Store**:
  - **Domain & Data Layer**:
    - Created `GamificationProfileEntity` (`lib/features/gamification/domain/entities/gamification_profile_entity.dart`) with `totalXp`, `level`, `title`, and `streakFreezes` (default 0).
    - Created `GamificationModel` (`lib/features/gamification/data/models/gamification_model.dart`) with SQLite mapping for `gamification_profile` table.
    - Upgraded `AppDatabase` schema to `version 10` with migration creating `gamification_profile` table.
    - Integrated `streakFreezes` into `UserSettingsEntity` and `UserSettingsModel` (`keyStreakFreezes`).
  - **State Management (`GamificationBloc`)**:
    - Added `BuyStreakFreezeEvent` (and alias `GamificationBuyStreakFreeze`) and `GamificationInitialized`.
    - Implemented `_onBuyStreakFreeze`: Cost is 500 XP. Verifies `totalXp >= 500`, deducts 500 XP, increments `streakFreezes` by 1, recomputes level/title, emits state, and logs reward notification.
  - **Store UI (`XpStoreCard`)**:
    - Built Apple HIG glassmorphic card titled "فروشگاه امتیاز" (`Key('xp_store_title')`).
    - Displays current balance (`Key('xp_store_user_xp')`).
    - Streak Freeze item (`Key('xp_store_streak_freeze_item')`) with frost icon ❄️, inventory count (`Key('xp_store_streak_freeze_inventory')`), cost 500 XP (`Key('xp_store_freeze_cost')`), and Buy button (`Key('xp_store_buy_streak_freeze_button')`).
    - Automatically enables/disables based on user's XP balance, with haptic feedback and success chime.
- **4. Strict TDD Verification & Automated Test Suites**:
  - Created `test/features/gamification/gamification_model_test.dart` asserting defaults, serialization (`fromMap`, `toMap`, `fromJson`, `toJson`), and `copyWith`.
  - Created `test/features/gamification/gamification_economy_bloc_test.dart` testing 500 XP deduction, `streakFreezes` increment, insufficient funds rejection, and initialization.
  - Updated `test/widget_test.dart` asserting `xp_store_card`, `profile_technical_settings_button`, navigating to `TechnicalSettingsView`, testing vacation mode and add device sheet, and returning to Profile.
  - Updated `test/features/dashboard/vacation_blur_and_theme_toggle_test.dart` to open `TechnicalSettingsView` via gear button.
- **5. Verification Results**:
  - `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.

---

### Phase 22 (Phase 8): App Icon Generation & Notification Testing
- **Status**: Completed
- **1. Native App Icon Generation (`flutter_launcher_icons: ^0.13.1`)**:
  - Placed the official app logo at `assets/app_logo.png`.
  - Added `flutter_launcher_icons: ^0.13.1` to `dev_dependencies` in `pubspec.yaml`.
  - Configured `flutter_launcher_icons` and `flutter_icons` blocks targeting `android: true`, `ios: true`, and `image_path: "assets/app_logo.png"`.
  - Declared `assets/` and `assets/sounds/` under the `flutter: assets:` section of `pubspec.yaml`.
  - Executed `flutter pub run flutter_launcher_icons`, successfully compiling all Android mipmap resolutions (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`) and iOS app icon sets.
- **2. Background Notification Testing & Permission Invariants**:
  - Verified `android/app/src/main/AndroidManifest.xml` permissions: `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, and `VIBRATE`.
  - Added `scheduleTestNotification` method to [`NotificationService`](lib/core/notifications/notification_service.dart) with 5-second `zonedSchedule`, high priority, vibration, sound, and exact delivery (`AndroidScheduleMode.exactAllowWhileIdle`).
  - Added "تست نوتیفیکیشن پسزمینه" card to [`TechnicalSettingsView`](lib/features/settings/presentation/pages/technical_settings_view.dart) with `Key('settings_test_notification_card')`, `Key('settings_test_notification_button')`, bell icon 🔔, 5-second duration badge, haptic feedback, and confirmation floating SnackBar.
  - Tapping this button schedules an exact notification delivery 5 seconds later with Title: "زندگیساز", Body: "این یک تست نوتیفیکیشن در پسزمینه است! 🚀".
- **3. Strict TDD Verification & Automated Test Suites**:
  - Created `test/features/settings/presentation/pages/technical_settings_notification_test.dart` asserting:
    - `TechnicalSettingsView` renders `settings_test_notification_card` and `settings_test_notification_button`.
    - Tapping button triggers `mockNotificationService.scheduleTestNotification(seconds: 5, ...)` and renders confirmation SnackBar.
    - `NotificationService.scheduleTestNotification` executes without throwing in non-native test harnesses.
- **4. Verification Results**:
  - `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.

---

### Phase 23 (Phase 8.1): Dual-Layout Theme Engine & Cinematic Splash Transition
- **Status**: Completed
- **1. Expand `AppThemeMode` & Default State (Signature Theme First)**:
  - Re-ordered `AppThemeMode` enum:
    1. `AppThemeMode.signature` ("زندگی‌ساز" - Default on fresh install!)
    2. `AppThemeMode.dark` ("تاریک")
    3. `AppThemeMode.zen` ("آرامش")
    4. `AppThemeMode.light` ("روشن")
  - Added helper getter `bool get isSignatureLayout => this == AppThemeMode.signature;` and updated Persian labels and `fromString` parsing.
  - Set default theme to `AppThemeMode.signature` across `UserSettingsEntity.defaults`, `UserSettingsModel.fromKeyValueMap`, `SettingsLocalDataSourceImpl.defaultSettings`, and `themeProvider`.
  - Added `isSignatureMode` and `isSignatureLayout` boolean accessors to `UserSettingsEntity`.
- **2. Smooth Layout Transition Wrapper (`DualLayoutTransition`)**:
  - Created [`DualLayoutTransition`](lib/core/widgets/dual_layout_transition.dart) (`isSignatureLayout`, `signatureChild`, `classicChild`).
  - Implemented `AnimatedSwitcher` with 450ms duration, `Curves.easeOutCubic` / `Curves.easeInCubic`, combining `FadeTransition` and subtle `ScaleTransition` (0.97 to 1.0) with explicit `ValueKey('signature_layout')` and `ValueKey('classic_layout')`.
- **3. Top Header Theme Cycle Button & Settings Segmented Control**:
  - In `MainScreen`: top theme switcher button cycles smoothly in 4-way sequence: `signature` -> `dark` -> `zen` -> `light` -> `signature`.
  - Added `AppThemeMode.signature` sparkles icon (`CupertinoIcons.sparkles`, `Color(0xFF00E5FF)`, `ValueKey('icon_signature')`).
  - Attached `HapticFeedback.selectionClick()` and `SoundAndHapticService.instance.playSoftTick()` on theme cycling.
  - Set `isDark` to true for both `dark` and `signature` (pitch black background).
  - In `TechnicalSettingsView`: segmented control now renders all 4 themes: "زندگی‌ساز", "تاریک", "آرامش", "روشن" with reactive icon styling.
  - Preserved existing floating curved bottom navigation bar 100% intact.
- **4. Cinematic Splash Screen & Logo Integration**:
  - `SplashPage` loads native app logo asset `Image.asset('assets/app_logo.png')` with key `Key('splash_app_logo_image')` and graceful fallback to gradient checkmark widget (`Key('splash_fallback_logo')`).
  - Added entrance animations: scale-up, fade-in, and subtle cyan/blue neon glow pulse sequence around the logo capsule.
  - Implemented smooth `PageRouteBuilder` navigation (650ms duration) with `FadeTransition` + upward `SlideTransition` / `ScaleTransition`.
- **5. Strict TDD Verification & Static Analysis**:
  - Updated `test/features/onboarding/onboarding_and_splash_test.dart` asserting logo asset and brand title.
  - Updated `test/features/dashboard/vacation_blur_and_theme_toggle_test.dart` asserting `settings_theme_mode_signature`.
  - `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.

---

### Phase 24 (Phase 8.2): Signature Dashboard ("Today" View) with 100% Feature Parity
- **Status**: Completed
- **1. Dual-Layout Wiring in `DashboardPage`**:
  - Integrated `DualLayoutTransition` inside `_DashboardPageState.build`, reading `AppThemeMode` from `SettingsBloc`.
  - Maintained shared root `Stack` hosting:
    1. `DualLayoutTransition` switching between `signatureChild` (`_buildSignatureDashboard`) and `classicChild` (`_buildClassicDashboard`).
    2. Full-Screen `_VacationModeBlurOverlay` with `BackdropFilter` (5.0 sigma blur) + `AbsorbPointer` active for both layouts when `isVacationMode == true`.
    3. Screen-wide `ConfettiWidget` (`Key('dashboard_confetti_widget')`) mounted in root `Stack` for both layouts.
- **2. Pitch-Dark Canvas & Visual Tokens Matching `zendegisaz-01-today.png`**:
  - Deep pitch-dark background (`#090B10`) for the signature layout.
  - Header: Logo badge (`Image.asset('assets/app_logo.png')` with fallback), title "زندگی‌ساز", compact pill button "پایان روز" (`Key('signature_header_end_day_button')`), notification bell with unread dot (`Key('signature_header_notifications_button')`), smart search toggle (`Key('dashboard_header_search_toggle')`), 4-way theme cycle button (`Key('signature_header_theme_button')`), and circular profile avatar (`Key('signature_header_avatar_button')`).
  - Hero Section: Greeting text (`Key('dashboard_header_greeting_text')`), prominent headline "امروز X کار مونده" (`Key('signature_hero_headline')`), Jalali date trigger (`Key('signature_date_trigger')`), streak flame badge (`Key('dashboard_streak_badge')`), and 5-segment glowing green progress bar (`Key('signature_segmented_progress_bar')`).
  - Focus CTA: Full-width electric blue button (`#0A84FF`, `Key('signature_focus_cta_button')`) with duration picker chip and play icon opening the Pomodoro Focus Sheet.
  - Timeline Header: Persian label "امروز، به ترتیب زمان", lightning bolt icon, and red overdue recovery trigger ("X مورد از دیروز مونده").
  - Minimal Task Row: Right swipe for Pomodoro focus and subtasks, left swipe for edit and delete, checkbox with XP rewards and haptics, title, time formatted in Persian digits, and formatted subtitle.
  - Footer Mini XP Bar (`Key('signature_mini_xp_bar')`): Level and current/target XP with golden gradient progress bar.
- **3. Zero Feature Loss & Complete Feature Parity**:
  - Full interaction parity across task completion, haptics, XP rewards, quick add, overdue tasks sheet, end of day reflection dialog, notifications center sheet, spotlight search, pull-to-refresh, vacation blur, and confetti celebration.
- **4. Strict TDD Verification & Automated Test Suites**:
  - Created `test/features/dashboard/signature_dashboard_test.dart` asserting:
    - Signature Today UI widgets render when theme is `signature`.
    - `DualLayoutTransition` dynamically alternates between Signature and Classic layouts on theme changes.
    - `_VacationModeBlurOverlay` and `ConfettiWidget` operate over both layouts.
  - Updated `test/widget_test.dart` and `test/features/dashboard/vacation_blur_and_theme_toggle_test.dart`.
- **5. Verification Results**:
  - `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.

---

## 25. Phase 8.3 — Signature Habits & Finance Views with 100% Feature Parity (Completed)
- **1. Dual-Layout Wiring for Habits & Finance Tabs**:
  - Integrated `DualLayoutTransition` inside `ReportsPage` (`lib/features/analytics/presentation/pages/reports_page.dart`), switching between `_buildSignatureHabitsView` and `_buildClassicReportsView` based on `userSettings.themeMode.isSignatureLayout`.
  - Integrated `DualLayoutTransition` inside `FinancialAnalyticsPage` (`lib/features/analytics/presentation/pages/financial_analytics_page.dart`), switching between `_buildSignatureFinanceView` and `_buildClassicFinanceView` based on `userSettings.themeMode.isSignatureLayout`.
  - Maintained 100% zero feature loss: All existing classic logic, SQLite heatmap records, and Rial financial conversions remain untouched and operational for classic themes (`dark`, `zen`, `light`).
- **2. Signature Habits/Reports View (`zendegisaz-02-habits.png`)**:
  - Deep pitch-dark background (`#090B10`).
  - Header: `"عادت‌ها"` title and dynamic Persian month subtitle (`"$monthName · $day روز از $daysInMonth روز"`).
  - Hero Streak: Massive orange streak numeral (`#F97316`, 64px) with `"روز پشت‌سرهم"` and encouragement subtitle (`"فردا $ordinalFa روزه، ادامه بده."`).
  - Iranian Week Indicators: 7 circular indicators in Iranian week order (Saturday `ش` to Friday `ج`), active days filled with orange and checkmark, pending days styled with dark slate border (`#3A3F50`).
  - Top Habits Progress: `"عادت‌های برتر"` section featuring glowing electric blue (`#0A84FF`) progress bars with Persian stats (`"۲۴ از ۳۱ · ۷۷٪"`).
  - Habit Heatmap (`Key('signature_habit_heatmap')`): 12 columns x 3 rows grid of rounded rectangles (`borderRadius: 4`) dynamically colored based on SQLite / task completion density.
  - Pull-to-refresh (`Key('signature_reports_pull_to_refresh')`): Triggers analytics and tasks refresh.
- **3. Signature Finance View (`zendegisaz-03-finance.png`)**:
  - Deep pitch-dark background (`#090B10`).
  - Header: `"مالی"` title and Persian currency subtitle `"مبالغ به ریال"`.
  - Hero Balance Section: Centered `"این ماه هنوز داری"`, massive balance numeral (`Key('signature_finance_hero_balance')`), electric blue progress bar, and subtitle `"از ۵۰,۰۰۰,۰۰۰ · ۱۸٪ خرج شده"`.
  - Summary Split: Elegant vertical divider between `"امروز"` (`todaySpentRials`) and `"۷ روز اخیر"` (`sevenDaysSpentRials`) formatted in Persian digits.
  - Weekly Bar Chart (`Key('signature_weekly_bar_chart')`): 7 daily expense bars from Saturday to Friday, current day highlighted in `#0A84FF`, other days in `#3A3F50`, with heights proportional to daily expenses.
  - Transactions List (`Key('signature_finance_transactions_list')`): Expense transactions separated by `#1C202B` dividers, with formatted Rial amounts, icons, and dates.
- **4. Strict TDD Verification**:
  - Created `test/features/analytics/signature_habits_and_finance_test.dart` asserting:
    - `AppThemeMode.signature.isSignatureLayout` contract.
    - Required widget keys contract (`signature_habit_heatmap`, `signature_reports_pull_to_refresh`, `signature_finance_hero_balance`, `signature_weekly_bar_chart`, `signature_finance_transactions_list`).
    - Widget instantiations with proper defaults.
- **5. Verification Results**:
  - `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.

---

## 26. Phase 8.4 — Signature Profile View, 500 XP Shield & Notification Tester (Completed)
- **1. Dual-Layout Wiring for Settings/Profile Tab (`SettingsPage`)**:
  - Integrated `DualLayoutTransition` inside `SettingsPage` (`lib/features/settings/presentation/pages/settings_page.dart`), switching between `_buildSignatureProfileView` and `_buildClassicProfileView` based on `userSettings.themeMode.isSignatureLayout`.
  - Preserved existing `PlayerProfileCard`, `XpStoreCard`, and account cards 100% intact for classic themes (`dark`, `zen`, `light`).
- **2. Signature Profile View (`zendegisaz-04-profile.png`)**:
  - Deep pitch-dark background (`#090B10`).
  - **Hero Avatar & Level Header (`Key('signature_profile_header')`)**:
    - 72x72 circular avatar with `#141721` slate background and circular electric-blue progress arc (`#0A84FF`, strokeWidth 3.5) reflecting level progress. Displays user's first initial in bold white (26sp).
    - Tapping avatar or name navigates to `UserProfilePage` via `_openUserProfilePage`.
    - User name in extra-bold white (24sp) and subtitle in `#F97316` (`"$honoraryTitle · سطح $level"`).
    - Sleek gear icon button (`Key('profile_technical_settings_button')`) opening `TechnicalSettingsView`.
  - **Next Level XP Bar (`Key('signature_profile_xp_bar')`)**:
    - Right label: `"تا سطح {nextLevel}"` in `#8E95A5`.
    - Left label: `"{remainingXp} XP مونده"` in Persian numerals.
    - 5px linear progress bar with `#1C202B` track and `#F59E0B` amber/orange fill.
  - **3-Column Gamification Metrics Row (`Key('signature_profile_metrics_row')`)**:
    - Separated by `1px` `#1A1D26` vertical dividers:
      1. Right: Massive orange streak numeral (`#F97316`, 32sp) + `"روز استمرار"`.
      2. Center: Massive purple shield count (`#A855F7`, 32sp) + `"سپر محافظ"`.
      3. Left: Massive electric blue total XP (`#0A84FF`, 32sp) + `"XP کل"`.
  - **Streak Freeze Purchase Card (`Key('signature_streak_freeze_card')`)**:
    - Dark `#12151E` container with `#1E2330` border and 20px radius.
    - Purple shield outline icon (`CupertinoIcons.shield`, `#A855F7`) + title `"سپر محافظ استمرار"` + subtitle `"اگه یه روز نشد، استمرارت میمونه"`.
    - Outlined electric-blue button (`Key('signature_buy_freeze_button')`) with cost strictly set to **`"۵۰۰ XP"`**.
    - Tapping dispatches `BuyStreakFreezeEvent(cost: 500)` to `GamificationBloc` with haptic feedback (disabled/dimmed when `totalXp < 500`).
  - **Minimalist Settings List (`"تنظیمات"` Section)**:
    1. `"ظاهر برنامه"` (`Key('signature_theme_selector_row')`): Shows active theme label and chevron, opens modal sheet allowing selection between `زندگی‌ساز`, `تاریک`, `آرامش`, and `روشن`.
    2. `"حالت استراحت"` (`Key('signature_vacation_mode_row')`): Green `CupertinoSwitch` wired to `SettingsBloc` (`SettingsVacationModeToggled`).
    3. `"پشتیبان‌گیری"` (`Key('signature_backup_row')`): Opens Backup/Restore glass bottom sheet (`Key('add_device_glass_bottom_sheet')`).
    4. `"تست نوتیفیکیشن پس‌زمینه (۵ ثانیه)"` (`Key('signature_test_notification_row')`): Bell icon, triggers 5-second scheduled local notification via `NotificationService` with Title: `"زندگی‌ساز 🚀"`, Body: `"نوتیفیکیشن پس‌زمینه با موفقیت کار می‌کند!"`, and SnackBar instruction: `"نوتیفیکیشن برای ۵ ثانیه دیگر تنظیم شد؛ اکنون برنامه را مینیمایز کنید."`.
    5. `"تنظیمات پیشرفته و فنی"` (`Key('signature_advanced_settings_row')`): Navigates to `TechnicalSettingsView`.
- **3. Notification Testing Alignment in `TechnicalSettingsView`**:
  - Aligned title, body, and SnackBar messages in `TechnicalSettingsView` to match the 5-second background test contract.
- **4. Strict TDD Verification**:
  - Created `test/features/settings/signature_profile_test.dart` asserting:
    - `AppThemeMode.signature.isSignatureLayout` contract.
    - `BuyStreakFreezeEvent` default cost of 500 XP.
    - All Signature Profile widget keys contract.
    - Widget test for Signature Profile rendering, 500 XP button tap, and `BuyStreakFreezeEvent` dispatching.
    - DualLayoutTransition widget test toggling between Signature and Classic profile views.
  - Updated `test/features/settings/presentation/pages/technical_settings_notification_test.dart`.
- **5. Verification Results**:
  - `flutter analyze --no-fatal-infos` -> **0 errors, 0 warnings (100% clean)**.



