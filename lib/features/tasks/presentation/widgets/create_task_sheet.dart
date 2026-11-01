import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/core/theme/app_colors.dart';
import 'package:task_flow/core/utils/jalali_date_formatter.dart';
import 'package:task_flow/core/utils/persian_number_formatter.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_priority.dart';

/// Callback signature for submitting a newly configured task from [CreateTaskSheet].
typedef OnCreateTaskSubmitted = void Function({
  required String title,
  required String description,
  required TaskPriority priority,
  required DateTime? dueDate,
  String? startTime,
  String? endTime,
  String? parentTaskId,
  String workspaceId,
  List<String> tags,
  String? recurrenceRule,
  DateTime? reminderDateTime,
  required List<String> subTaskTitles,
  int? initialExpenseMinorUnits,
  Currency initialExpenseCurrency,
});

/// پنجره پایینی سبک و هوشمند (World-Class Smart Bottom Sheet)
/// مجهز به انتخابگر پوشه/اکانت (`workspace_id`)، تگ‌ها (`tags`)، تکرار (`recurrence_rule`)،
/// یادآور آلارم (`reminder_date_time`)، زیرتسک‌ها و بازه زمانی
class CreateTaskSheet extends StatefulWidget {
  final OnCreateTaskSubmitted onSubmitted;
  final bool isDark;
  final String? initialParentTaskId;
  final String? initialParentTaskTitle;
  final String initialWorkspaceId;
  final bool? isSignature;

  const CreateTaskSheet({
    super.key,
    required this.onSubmitted,
    this.isDark = true,
    this.isZen = false,
    this.initialParentTaskId,
    this.initialParentTaskTitle,
    this.initialWorkspaceId = TaskWorkspaces.defaultWorkspace,
    this.isSignature,
  });

  final bool isZen;

  @override
  State<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<CreateTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _tagsController = TextEditingController();
  final _subTaskInputController = TextEditingController();
  final _expenseController = TextEditingController();

  TaskPriority _selectedPriority = TaskPriority.medium;
  late String _selectedWorkspaceId;
  String _selectedRecurrenceRule = TaskRecurrenceRules.none;
  DateTime? _reminderDateTime;
  final List<String> _subTasks = <String>[];
  bool _isFinancialTask = false;
  bool _isAllDay = false;
  static const Currency _selectedCurrency = Currency.irt;
  DateTime _selectedDueDate = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _selectedWorkspaceId = widget.initialWorkspaceId == TaskWorkspaces.all
        ? TaskWorkspaces.defaultWorkspace
        : widget.initialWorkspaceId;
    final now = TimeOfDay.now();
    _startTime = now;
    _endTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: now.minute);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    _subTaskInputController.dispose();
    _expenseController.dispose();
    super.dispose();
  }

  static String _formatDueDateLabel(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;

    final jalaliShort = JalaliDateFormatter.formatShort(date);

    if (isToday) {
      return 'امروز ($jalaliShort)';
    }
    if (isTomorrow) {
      return 'فردا ($jalaliShort)';
    }
    return jalaliShort;
  }

  static String _formatReminderLabel(DateTime dt) {
    final local = dt.toLocal();
    final datePart = JalaliDateFormatter.formatShort(local);
    final timePart =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$datePart - ساعت ${toPersianDigits(timePart)}';
  }

  void _toggleQuickReminder() {
    setState(() {
      if (_reminderDateTime != null) {
        _reminderDateTime = null;
      } else {
        final effectiveTime = _startTime ?? const TimeOfDay(hour: 9, minute: 0);
        _reminderDateTime = DateTime(
          _selectedDueDate.year,
          _selectedDueDate.month,
          _selectedDueDate.day,
          effectiveTime.hour,
          effectiveTime.minute,
        );
      }
    });
  }

  Future<void> _pickCustomReminderDateTime() async {
    final baseDate = _reminderDateTime ?? _selectedDueDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: baseDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (pickedDate == null || !mounted) return;

    final baseTime = _reminderDateTime != null
        ? TimeOfDay.fromDateTime(_reminderDateTime!)
        : (_startTime ?? const TimeOfDay(hour: 9, minute: 0));
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: baseTime,
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _reminderDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        final isDark = widget.isDark;
        return Theme(
          data: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryBlue,
              brightness: isDark ? Brightness.dark : Brightness.light,
              primary: AppColors.primaryBlue,
              surface: isDark ? AppColors.navBarDark : Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  static String _formatTime(TimeOfDay? time) {
    if (time == null) return 'انتخاب نشده';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return toPersianDigits('$h:$m');
  }

  static String? _timeOfDayToRaw(TimeOfDay? time) {
    if (time == null) return null;
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 9, minute: 30),
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  List<String> _parseTags() {
    final raw = _tagsController.text.trim();
    if (raw.isEmpty) return const <String>[];
    return raw
        .split(RegExp(r'[,،\s]+'))
        .map((e) => e.replaceAll('#', '').trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  void _addSubTaskDraft() {
    final text = _subTaskInputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subTasks.add(text);
      _subTaskInputController.clear();
    });
  }

  int? _parseExpenseMinorUnits() {
    if (!_isFinancialTask) {
      return null;
    }
    final raw = PersianNumberFormatter.toEnglishDigits(_expenseController.text)
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();
    if (raw.isEmpty) {
      return null;
    }
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed * _selectedCurrency.minorUnitsPerMajor;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    widget.onSubmitted(
      title: _titleController.text.trim(),
      description: '',
      priority: _selectedPriority,
      dueDate: _selectedDueDate,
      startTime: _isAllDay ? null : _timeOfDayToRaw(_startTime),
      endTime: _isAllDay ? null : _timeOfDayToRaw(_endTime),
      parentTaskId: widget.initialParentTaskId,
      workspaceId: _isFinancialTask
          ? TaskWorkspaces.financial
          : _selectedWorkspaceId,
      tags: _parseTags(),
      recurrenceRule: TaskRecurrenceRules.normalize(_selectedRecurrenceRule),
      reminderDateTime: _reminderDateTime,
      subTaskTitles: List<String>.unmodifiable(_subTasks),
      initialExpenseMinorUnits: _parseExpenseMinorUnits(),
      initialExpenseCurrency: _selectedCurrency,
    );
    Navigator.of(context).pop();
  }

  static String _priorityLabelFa(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.low => 'کم',
      TaskPriority.medium => 'متوسط',
      TaskPriority.high => 'بالا',
      TaskPriority.critical => 'فوری',
    };
  }

  static Color _priorityColor(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.low => const Color(0xFF34D399),
      TaskPriority.medium => AppColors.primaryBlue,
      TaskPriority.high => const Color(0xFFFBBF24),
      TaskPriority.critical => const Color(0xFFF87171),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isZen = widget.isZen || theme.scaffoldBackgroundColor == AppColors.backgroundZen;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isDark = widget.isDark;

    final bool isSignature = widget.isSignature ??
        (() {
          try {
            return context.watch<SettingsBloc>().state.settings.themeMode.isSignatureLayout;
          } catch (_) {
            try {
              return sl<SettingsBloc>().state.settings.themeMode.isSignatureLayout;
            } catch (_) {
              return false;
            }
          }
        }());

    final textColor = isSignature
        ? Colors.white
        : (isDark ? AppColors.textDark : (isZen ? AppColors.textZen : AppColors.textLight));
    final sheetBg = isSignature
        ? const Color(0xFF090B10)
        : (isDark ? const Color(0xFF1C1C1E) : (isZen ? AppColors.surfaceZen : Colors.white));
    final fieldFill = isSignature
        ? const Color(0xFF12151E)
        : (isDark ? const Color(0xFF2C2C2E) : (isZen ? const Color(0xFFE2DDD2) : const Color(0xFFF2F2F7)));
    final subtleBorder = isSignature
        ? Border.all(color: const Color(0xFF1E2330), width: 1.0)
        : null;
    final subtleBorderSide = isSignature
        ? const BorderSide(color: Color(0xFF1E2330), width: 1.0)
        : BorderSide.none;

    final Widget formContent = Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: isSignature
            ? const Border(top: BorderSide(color: Color(0xFF1E2330), width: 1.2))
            : null,
      ),
      padding: EdgeInsets.fromLTRB(22, 16, 22, 32 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isSignature
                        ? const Color(0xFF2C3242)
                        : AppColors.textSecondary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // هدر فرم
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.initialParentTaskId != null
                              ? 'افزودن زیرتسک جدید'
                              : 'ایجاد تسک جدید',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        if (widget.initialParentTaskTitle != null)
                          Text(
                            'زیرمجموعه: ${widget.initialParentTaskTitle}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 11.5,
                              color: AppColors.primaryBlueGlow,
                            ),
                          ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: fieldFill,
                        border: subtleBorder,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ۱. فیلد نام تسک
              TextFormField(
                key: const Key('create_task_title_field'),
                controller: _titleController,
                autofocus: true,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 14.5,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: 'عنوان کار (مثلاً: مطالعه فصل ۳ معماری تمیز)...',
                  hintStyle: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                  prefixIcon: const Icon(
                    CupertinoIcons.sparkles,
                    size: 18,
                    color: Color(0xFF0A84FF),
                  ),
                  filled: true,
                  fillColor: fieldFill,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: subtleBorderSide,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: subtleBorderSide,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF0A84FF),
                      width: 1.2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'لطفاً نام تسک را وارد کنید';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // ۲. انتخاب پوشه / فضای کاری (Workspace)
              Row(
                children: TaskWorkspaces.selectableWorkspaces.map((ws) {
                  final isSelected = _selectedWorkspaceId == ws;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: ws == TaskWorkspaces.financial ? 0 : 6,
                      ),
                      child: GestureDetector(
                        key: Key('create_task_workspace_$ws'),
                        onTap: () =>
                            setState(() => _selectedWorkspaceId = ws),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSignature
                                ? (isSelected
                                    ? const Color(0xFF0A84FF).withValues(alpha: 0.15)
                                    : Colors.transparent)
                                : (isSelected
                                    ? const Color(0xFF0A84FF)
                                    : fieldFill),
                            borderRadius: BorderRadius.circular(12),
                            border: isSignature
                                ? Border.all(
                                    color: isSelected
                                        ? const Color(0xFF0A84FF)
                                        : const Color(0xFF1E2330),
                                    width: 1.0,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              TaskWorkspaces.labelFa(ws),
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSignature
                                    ? (isSelected
                                        ? const Color(0xFF0A84FF)
                                        : const Color(0xFF8E95A5))
                                    : (isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? const Color(0xFFEBEBF5)
                                            : AppColors.textSecondary)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(growable: false),
              ),
              const SizedBox(height: 18),

              // ۳. اولویت (Segmented Priority Pills)
              Row(
                children: TaskPriority.values.map((priority) {
                  final isSelected = _selectedPriority == priority;
                  final pColor = _priorityColor(priority);
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: priority == TaskPriority.critical ? 0 : 6,
                      ),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedPriority = priority),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSignature
                                ? (isSelected
                                    ? pColor.withValues(alpha: 0.15)
                                    : Colors.transparent)
                                : (isSelected
                                    ? pColor
                                    : fieldFill),
                            borderRadius: BorderRadius.circular(12),
                            border: isSignature
                                ? Border.all(
                                    color: isSelected
                                        ? pColor
                                        : const Color(0xFF1E2330),
                                    width: 1.0,
                                  )
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSignature
                                      ? (isSelected
                                          ? pColor
                                          : pColor.withValues(alpha: 0.5))
                                      : (isSelected ? Colors.white : pColor),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _priorityLabelFa(priority),
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSignature
                                      ? (isSelected
                                          ? pColor
                                          : const Color(0xFF8E95A5))
                                      : (isSelected
                                          ? Colors.white
                                          : (isDark
                                              ? const Color(0xFFEBEBF5)
                                              : AppColors.textSecondary)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(growable: false),
              ),
                  const SizedBox(height: 18),

                  // ۴. فیلد تگ‌ها و چک‌لیست سریع
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('create_task_tags_field'),
                          controller: _tagsController,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 12.5,
                            color: textColor,
                          ),
                          decoration: InputDecoration(
                            hintText: 'تگ‌ها (مثلاً: مهم، پروژه)',
                            hintStyle: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 11.5,
                              color: AppColors.textSecondary.withValues(alpha: 0.7),
                            ),
                            prefixIcon: const Icon(
                              CupertinoIcons.tag_fill,
                              size: 15,
                              color: AppColors.primaryBlueGlow,
                            ),
                            filled: true,
                            fillColor: fieldFill,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: subtleBorderSide,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: subtleBorderSide,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF0A84FF),
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          key: const Key('create_task_subtask_field'),
                          controller: _subTaskInputController,
                          onFieldSubmitted: (_) => _addSubTaskDraft(),
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 12.5,
                            color: textColor,
                          ),
                          decoration: InputDecoration(
                            hintText: 'افزودن زیرکار +',
                            hintStyle: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 11.5,
                              color: AppColors.textSecondary.withValues(alpha: 0.7),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                CupertinoIcons.add_circled_solid,
                                size: 18,
                                color: Color(0xFF30D158),
                              ),
                              onPressed: _addSubTaskDraft,
                            ),
                            filled: true,
                            fillColor: fieldFill,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: subtleBorderSide,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: subtleBorderSide,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF0A84FF),
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_subTasks.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_subTasks.length, (i) {
                        return Chip(
                          backgroundColor: fieldFill,
                          side: subtleBorderSide,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          label: Text(
                            _subTasks[i],
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 11.5,
                              color: textColor,
                            ),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () =>
                              setState(() => _subTasks.removeAt(i)),
                        );
                      }),
                    ),
                  ],
                  const SizedBox(height: 18),

                  // ۵. انتخابگر زمان و کلید تمام‌روز (All-day)
                  Container(
                    key: const Key('create_task_time_blocking_container'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: fieldFill,
                      borderRadius: BorderRadius.circular(18),
                      border: subtleBorder,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              key: const Key('create_task_due_date_button'),
                              onTap: _pickDueDate,
                              child: Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.calendar,
                                    size: 17,
                                    color: Color(0xFF0A84FF),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDueDateLabel(_selectedDueDate),
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'تمام‌روز',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 11.5,
                                color: isDark ? const Color(0xFFEBEBF5) : textColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CupertinoSwitch(
                              key: const Key('all_day_task_switch'),
                              activeTrackColor: const Color(0xFF0A84FF),
                              value: _isAllDay,
                              onChanged: (value) {
                                setState(() => _isAllDay = value);
                              },
                            ),
                          ],
                        ),
                        if (!_isAllDay) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  key: const Key('pick_start_time_button'),
                                  onTap: _pickStartTime,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSignature
                                          ? Colors.transparent
                                          : (isDark
                                              ? const Color(0xFF3A3A3C)
                                              : Colors.white),
                                      borderRadius: BorderRadius.circular(12),
                                      border: isSignature
                                          ? Border.all(color: const Color(0xFF1E2330), width: 1.0)
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'شروع: ${_formatTime(_startTime)}',
                                        style: TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  key: const Key('pick_end_time_button'),
                                  onTap: _pickEndTime,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSignature
                                          ? Colors.transparent
                                          : (isDark
                                              ? const Color(0xFF3A3A3C)
                                              : Colors.white),
                                      borderRadius: BorderRadius.circular(12),
                                      border: isSignature
                                          ? Border.all(color: const Color(0xFF1E2330), width: 1.0)
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'پایان: ${_formatTime(_endTime)}',
                                        style: TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ۵.۵. انتخابگر تکرارشونده (Recurring Rule) و یادآور آلارم (Reminder DateTime)
                  Container(
                    key: const Key('create_task_recurrence_selector'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: fieldFill,
                      borderRadius: BorderRadius.circular(18),
                      border: subtleBorder,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.repeat,
                              size: 16,
                              color: Color(0xFF0A84FF),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'تکرار خودکار:',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children:
                              TaskRecurrenceRules.selectableRules.map((rule) {
                            final isSelected = _selectedRecurrenceRule == rule;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: rule == TaskRecurrenceRules.monthly
                                      ? 0
                                      : 6,
                                ),
                                child: GestureDetector(
                                  key: Key('create_task_recurrence_$rule'),
                                  onTap: () => setState(
                                    () => _selectedRecurrenceRule = rule,
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSignature
                                          ? (isSelected
                                              ? const Color(0xFF0A84FF).withValues(alpha: 0.15)
                                              : Colors.transparent)
                                          : (isSelected
                                              ? const Color(0xFF0A84FF)
                                              : (isDark
                                                  ? const Color(0xFF3A3A3C)
                                                  : const Color(0xFFE5E5EA))),
                                      borderRadius: BorderRadius.circular(10),
                                      border: isSignature
                                          ? Border.all(
                                              color: isSelected
                                                  ? const Color(0xFF0A84FF)
                                                  : const Color(0xFF1E2330),
                                              width: 1.0,
                                            )
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        TaskRecurrenceRules.labelFa(rule),
                                        style: TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          fontSize: 11,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: isSignature
                                              ? (isSelected
                                                  ? const Color(0xFF0A84FF)
                                                  : const Color(0xFF8E95A5))
                                              : (isSelected
                                                  ? Colors.white
                                                  : (isDark
                                                      ? const Color(0xFFEBEBF5)
                                                      : AppColors.textSecondary)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(growable: false),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                key: const Key('create_task_reminder_button'),
                                onTap: _toggleQuickReminder,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _reminderDateTime != null
                                        ? const Color(0xFFF59E0B)
                                            .withValues(alpha: 0.18)
                                        : (isSignature
                                            ? Colors.transparent
                                            : (isDark
                                                ? const Color(0xFF3A3A3C)
                                                : const Color(0xFFE5E5EA))),
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSignature
                                        ? Border.all(
                                            color: _reminderDateTime != null
                                                ? const Color(0xFFF59E0B)
                                                : const Color(0xFF1E2330),
                                            width: 1.0,
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _reminderDateTime != null
                                            ? CupertinoIcons.bell_fill
                                            : CupertinoIcons.bell,
                                        size: 15,
                                        color: _reminderDateTime != null
                                            ? const Color(0xFFF59E0B)
                                            : (isDark
                                                ? const Color(0xFFEBEBF5)
                                                : AppColors.textSecondary),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _reminderDateTime != null
                                              ? 'یادآور: ${_formatReminderLabel(_reminderDateTime!)}'
                                              : 'افزودن یادآور و آلارم دقیق',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: 'Vazirmatn',
                                            fontSize: 11.5,
                                            fontWeight:
                                                _reminderDateTime != null
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                            color: _reminderDateTime != null
                                              ? const Color(0xFFFBBF24)
                                              : textColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              key: const Key('create_task_reminder_pick_custom'),
                              onTap: _pickCustomReminderDateTime,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSignature
                                      ? Colors.transparent
                                      : (isDark
                                          ? const Color(0xFF3A3A3C)
                                          : const Color(0xFFE5E5EA)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSignature
                                      ? Border.all(color: const Color(0xFF1E2330), width: 1.0)
                                      : null,
                                ),
                                child: const Icon(
                                  CupertinoIcons.clock_fill,
                                  size: 15,
                                  color: Color(0xFF0A84FF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ۶. سوئیچ تسک مالی
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: _isFinancialTask
                          ? const Color(0xFF0A84FF).withValues(alpha: 0.12)
                          : fieldFill,
                      borderRadius: BorderRadius.circular(18),
                      border: subtleBorder,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.creditcard_fill,
                          size: 16,
                          color: Color(0xFF0A84FF),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'تسک مالی است؟ (نمایش در تب تراز مالی)',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        CupertinoSwitch(
                          key: const Key('financial_task_switch'),
                          activeTrackColor: const Color(0xFF0A84FF),
                          value: _isFinancialTask,
                          onChanged: (value) {
                            setState(() {
                              _isFinancialTask = value;
                              if (!value) {
                                _expenseController.clear();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_isFinancialTask) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('create_task_expense_field'),
                      controller: _expenseController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 14,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: toPersianDigits('مبلغ هزینه (تومان -> تبدیل خودکار به ریال)'),
                        hintStyle: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                        ),
                        filled: true,
                        fillColor: fieldFill,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: subtleBorderSide,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: subtleBorderSide,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF0A84FF),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // دکمه ثبت
                  GestureDetector(
                    key: const Key('create_task_submit_button'),
                    onTap: _submit,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A84FF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(
                        child: Text(
                          'ذخیره در برنامه',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: isSignature
          ? formContent
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: formContent,
            ),
    );
  }
}
