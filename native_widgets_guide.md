# Native Home Screen Widgets Implementation Guide (iOS & Android)

This guide provides the complete, production-ready native implementation code to render Apple HIG-style Home Screen Widgets on **iOS (WidgetKit & SwiftUI)** and **Android (Jetpack Glance & AppWidgetProvider)**.

Data is automatically synchronized from Flutter using the `home_widget` bridge via [`WidgetSyncService`](file:///lib/core/services/widget_sync_service.dart).

---

## 1. Unified Shared Data Contract

The Flutter layer serializes the following keys to the shared container:

| Key | Type | Description |
| :--- | :--- | :--- |
| `streak_count` | `Int` | Active daily streak count (e.g. `7`) |
| `daily_budget_rials` | `Int` | Today's budget in Iranian Rials (e.g. `150000`) |
| `daily_budget_formatted` | `String` | Formatted budget with currency label (e.g. `150,000 ریال`) |
| `pending_tasks_count` | `Int` | Total count of incomplete pending tasks |
| `task_1_title` | `String` | Highest priority pending task title |
| `task_1_priority` | `String` | Priority name (`critical`, `high`, `medium`, `low`) |
| `task_2_title` | `String` | Second highest priority pending task title |
| `task_2_priority` | `String` | Priority name |
| `task_3_title` | `String` | Third highest priority pending task title |
| `task_3_priority` | `String` | Priority name |
| `pending_tasks_json` | `String` | JSON array containing `{id, title, priority, dueDate}` |
| `last_synced_at` | `String` | ISO 8601 UTC timestamp of last sync |

- **iOS App Group ID**: `group.com.example.taskFlow`
- **iOS Widget Kind**: `TaskFlowWidget`
- **Android Widget Provider**: `TaskFlowWidgetProvider`

---

## 2. iOS Widget Implementation (SwiftUI & WidgetKit)

### Step 2.1: Xcode Configuration
1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select **File > New > Target...**, choose **Widget Extension**, and name it `TaskFlowWidgetExtension`. Uncheck "Include Live Activity" and "Include Configuration App Intent".
3. Under **Signing & Capabilities** for both `Runner` and `TaskFlowWidgetExtension`, click **+ Capability** and add **App Groups**.
4. Add and check `group.com.example.taskFlow` in both targets.

### Step 2.2: Complete Swift Source Code
Replace `ios/TaskFlowWidgetExtension/TaskFlowWidget.swift` with the following:

```swift
import WidgetKit
import SwiftUI

// MARK: - Data Models
struct TaskItem: Identifiable, Codable {
    let id: String
    let title: String
    let priority: String
    let dueDate: String?
}

struct TaskFlowWidgetEntry: TimelineEntry {
    let date: Date
    let streakCount: Int
    let budgetFormatted: String
    let pendingCount: Int
    let tasks: [TaskItem]
}

// MARK: - Timeline Provider
struct TaskFlowTimelineProvider: TimelineProvider {
    let appGroupId = "group.com.example.taskFlow"
    
    func placeholder(in context: Context) -> TaskFlowWidgetEntry {
        TaskFlowWidgetEntry(
            date: Date(),
            streakCount: 5,
            budgetFormatted: "150,000 ریال",
            pendingCount: 3,
            tasks: [
                TaskItem(id: "1", title: "طراحی رابط کاربری ویجت", priority: "critical", dueDate: nil),
                TaskItem(id: "2", title: "تست همگام‌سازی داده‌ها", priority: "high", dueDate: nil),
                TaskItem(id: "3", title: "بررسی کدهای Native", priority: "medium", dueDate: nil)
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskFlowWidgetEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskFlowWidgetEntry>) -> Void) {
        let entry = readEntry()
        // Refresh every 30 minutes or when triggered via Flutter HomeWidget.updateWidget
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func readEntry() -> TaskFlowWidgetEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        let streak = defaults?.integer(forKey: "streak_count") ?? 0
        let budget = defaults?.string(forKey: "daily_budget_formatted") ?? "0 ریال"
        let pending = defaults?.integer(forKey: "pending_tasks_count") ?? 0
        
        var taskList: [TaskItem] = []
        if let jsonString = defaults?.string(forKey: "pending_tasks_json"),
           let data = jsonString.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([TaskItem].self, from: data) {
            taskList = decoded
        } else {
            // Fallback to individual keys
            for i in 1...3 {
                if let title = defaults?.string(forKey: "task_\(i)_title"), !title.isEmpty {
                    let priority = defaults?.string(forKey: "task_\(i)_priority") ?? "medium"
                    taskList.append(TaskItem(id: "\(i)", title: title, priority: priority, dueDate: nil))
                }
            }
        }
        
        return TaskFlowWidgetEntry(
            date: Date(),
            streakCount: streak,
            budgetFormatted: budget,
            pendingCount: pending,
            tasks: taskList
        )
    }
}

// MARK: - Apple HIG SwiftUI View
struct TaskFlowWidgetEntryView: View {
    var entry: TaskFlowTimelineProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            // Subtle warm background with dark/light mode adaptability
            Color(UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0)
                    : UIColor(red: 0.96, green: 0.95, blue: 0.93, alpha: 1.0)
            })
            
            VStack(alignment: .trailing, spacing: 8) {
                // Header: Streak & Budget Pills
                HStack(spacing: 8) {
                    // Budget Pill
                    HStack(spacing: 4) {
                        Text(entry.budgetFormatted)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Image(systemName: "banknote.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    // Streak Pill
                    HStack(spacing: 4) {
                        Text("\(entry.streakCount)")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundColor(.orange)
                        Text("🔥")
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
                }
                
                Divider().opacity(0.4)
                
                // Tasks List (RTL Friendly)
                if entry.tasks.isEmpty {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                            Text("همه تسک‌ها انجام شدند!")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    Spacer()
                } else {
                    VStack(alignment: .trailing, spacing: 6) {
                        ForEach(entry.tasks.prefix(family == .systemSmall ? 2 : 3)) { task in
                            HStack(spacing: 6) {
                                // Priority dot
                                Circle()
                                    .fill(priorityColor(task.priority))
                                    .frame(width: 6, height: 6)
                                
                                Text(task.title)
                                    .font(.system(size: 11, weight: .medium))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundColor(.primary)
                                
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.primary.opacity(0.04))
                            .cornerRadius(6)
                        }
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(12)
        }
    }
    
    private func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "critical": return .red
        case "high": return .orange
        case "medium": return .blue
        default: return .gray
        }
    }
}

// MARK: - Widget Bundle & Main Entry
@main
struct TaskFlowWidget: Widget {
    let kind: String = "TaskFlowWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskFlowTimelineProvider()) { entry in
            TaskFlowWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("تسک‌فلو: وضعیت روزانه")
        .description("مشاهده سریع استریک، بودجه و ۳ تسک مهم روز.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
```

---

## 3. Android Widget Implementation (Glance & Kotlin)

### Step 3.1: Android Dependencies
Ensure Jetpack Glance is available in `android/app/build.gradle.kts`:

```kotlin
dependencies {
    implementation("androidx.glance:glance-appwidget:1.1.0")
    implementation("androidx.glance:glance-material3:1.1.0")
}
```

### Step 3.2: Widget Provider XML Definition
Create `android/app/src/main/res/xml/task_flow_widget_info.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="180dp"
    android:minHeight="110dp"
    android:targetCellWidth="3"
    android:targetCellHeight="2"
    android:updatePeriodMillis="1800000"
    android:description="@string/widget_description"
    android:initialLayout="@layout/task_flow_widget_fallback"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen">
</appwidget-provider>
```

### Step 3.3: AppWidgetProvider Receiver
Create `android/app/src/main/kotlin/com/example/task_flow/TaskFlowWidgetProvider.kt`:

```kotlin
package com.example.task_flow

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

class TaskFlowWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.task_flow_widget_layout).apply {
                // Streak
                val streak = widgetData.getInt("streak_count", 0)
                setTextViewText(R.id.widget_streak_text, "$streak 🔥")

                // Daily Budget
                val budget = widgetData.getString("daily_budget_formatted", "0 ریال") ?: "0 ریال"
                setTextViewText(R.id.widget_budget_text, budget)

                // Task 1
                val task1 = widgetData.getString("task_1_title", "")
                setTextViewText(R.id.widget_task_1, if (!task1.isNullOrEmpty()) "• $task1" else "")

                // Task 2
                val task2 = widgetData.getString("task_2_title", "")
                setTextViewText(R.id.widget_task_2, if (!task2.isNullOrEmpty()) "• $task2" else "")

                // Task 3
                val task3 = widgetData.getString("task_3_title", "")
                setTextViewText(R.id.widget_task_3, if (!task3.isNullOrEmpty()) "• $task3" else "")
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
```

### Step 3.4: Register in `AndroidManifest.xml`
In `android/app/src/main/AndroidManifest.xml`, add the receiver inside `<application>`:

```xml
<receiver
    android:name=".TaskFlowWidgetProvider"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/task_flow_widget_info" />
</receiver>
```

---

## 4. Verification Workflow

1. **Flutter Trigger**: Whenever a task is marked `done`, created, or deleted, `TaskBloc` dispatches:
   ```dart
   WidgetSyncService.instance.syncSnapshot(...)
   ```
2. **Native Response**:
   - On iOS, `HomeWidget.updateWidget(iOSName: 'TaskFlowWidget')` triggers WidgetKit's `TimelineProvider.getTimeline`, reloading the SwiftUI card instantly.
   - On Android, `HomeWidget.updateWidget(androidName: 'TaskFlowWidgetProvider')` sends `ACTION_APPWIDGET_UPDATE`, refreshing the `RemoteViews`.
