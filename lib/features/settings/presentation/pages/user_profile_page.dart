import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task_flow/core/theme/app_colors.dart';
import 'package:task_flow/core/utils/persian_number_formatter.dart';
import 'package:task_flow/features/settings/domain/entities/user_settings_entity.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_event.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_state.dart';
import 'package:task_flow/core/widgets/bouncing_tap.dart';

/// قالب‌های آواتار پروفایل کاربری با رنگ‌بندی و آیکون‌های متمایز و گرادیانت‌های زنده
class ProfileAvatarPreset {
  final IconData icon;
  final List<Color> gradientColors;
  final String label;

  const ProfileAvatarPreset({
    required this.icon,
    required this.gradientColors,
    required this.label,
  });

  static const List<ProfileAvatarPreset> presets = [
    ProfileAvatarPreset(
      icon: CupertinoIcons.sparkles,
      gradientColors: [Color(0xFF5E5CE6), Color(0xFF1E1B4B), Color(0xFF0A84FF)],
      label: 'کاسمیک ایندیگو',
    ),
    ProfileAvatarPreset(
      icon: CupertinoIcons.person_crop_circle_fill,
      gradientColors: [Color(0xFF0A84FF), Color(0xFF0D253F), Color(0xFF007AFF)],
      label: 'آبی اپل و نایت',
    ),
    ProfileAvatarPreset(
      icon: CupertinoIcons.shield_lefthalf_fill,
      gradientColors: [Color(0xFF6366F1), Color(0xFF2C2C2E), Color(0xFF18181B)],
      label: 'تیتانیوم کهکشانی',
    ),
    ProfileAvatarPreset(
      icon: CupertinoIcons.flame_fill,
      gradientColors: [Color(0xFF38BDF8), Color(0xFF1E293B), Color(0xFF0284C7)],
      label: 'سیان متالیک',
    ),
    ProfileAvatarPreset(
      icon: CupertinoIcons.rocket_fill,
      gradientColors: [Color(0xFF10B981), Color(0xFF064E3B), Color(0xFF1C1C1E)],
      label: 'کربن امرالد',
    ),
  ];

  static ProfileAvatarPreset ofIndex(int index) {
    final safeIndex = index.clamp(0, presets.length - 1);
    return presets[safeIndex];
  }

  /// Resolves an [ImageProvider] from [customAvatarPath] when a valid image file or URL exists.
  static ImageProvider? resolveAvatarImageProvider(String? customAvatarPath) {
    final trimmed = customAvatarPath?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return NetworkImage(trimmed);
    }
    final file = File(trimmed);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return null;
  }

  /// Builds a unified [CircleAvatar] representing either the user's custom gallery photo
  /// or their chosen [ProfileAvatarPreset], wrapped in a living premium [SweepGradient] ring
  /// and optionally a Golden Glowing Aura (`showGoldenAura`).
  static Widget buildUserCircleAvatar({
    Key? avatarKey,
    required int avatarIndex,
    required String? customAvatarPath,
    double radius = 26,
    bool showGoldenAura = false,
  }) {
    final preset = ofIndex(avatarIndex);
    final trimmed = customAvatarPath?.trim();
    final hasCustomPath = trimmed != null && trimmed.isNotEmpty;
    final imageProvider = resolveAvatarImageProvider(trimmed);

    final Widget coreAvatar = hasCustomPath
        ? CircleAvatar(
            key: avatarKey,
            radius: radius,
            backgroundColor: const Color(0xFF1C1C1E),
            backgroundImage: imageProvider,
            onBackgroundImageError: imageProvider != null ? (_, __) {} : null,
            child: imageProvider == null
                ? Icon(
                    CupertinoIcons.photo_fill,
                    color: Colors.white,
                    size: radius * 0.95,
                  )
                : null,
          )
        : CircleAvatar(
            key: avatarKey,
            radius: radius,
            backgroundColor: const Color(0xFF1C1C1E),
            child: Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.25, -0.3),
                  radius: 0.95,
                  colors: preset.gradientColors,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                preset.icon,
                color: Colors.white,
                size: radius * 1.05,
              ),
            ),
          );

    final Widget livingAvatar = Container(
      padding: EdgeInsets.all(radius > 30 ? 3.5 : 2.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            Color(0xFF0A84FF),
            Color(0xFF5E5CE6),
            Color(0xFF38BDF8),
            Color(0xFF1E1B4B),
            Color(0xFF0A84FF),
          ],
        ),
      ),
      child: coreAvatar,
    );

    if (!showGoldenAura) {
      return livingAvatar;
    }

    return Container(
      padding: const EdgeInsets.all(3.0),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFD97706),
      ),
      child: livingAvatar,
    );
  }
}

/// صفحه مستقل پروفایل کاربری
/// شامل امکان انتخاب مستقیم عکس پروفایل از گالری گوشی (`image_picker`) و شخصی‌سازی اطلاعات کاربری
class UserProfilePage extends StatefulWidget {
  final bool isDark;
  final bool isZen;
  final Future<String?> Function(ImageSource source)? onPickImage;

  const UserProfilePage({
    super.key,
    required this.isDark,
    this.isZen = false,
    this.onPickImage,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final ImagePicker _imagePicker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _roleController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;
  late int _selectedAvatarIndex;
  String? _customAvatarPath;

  @override
  void initState() {
    super.initState();
    UserSettingsEntity current = UserSettingsEntity.defaults;
    try {
      current = context.read<SettingsBloc>().state.settings;
    } catch (_) {}

    _nameController = TextEditingController(text: current.userName);
    _roleController = TextEditingController(text: current.userRole);
    _emailController = TextEditingController(text: current.userEmail);
    _bioController = TextEditingController(text: current.userBio);
    _selectedAvatarIndex = current.avatarIndex;
    _customAvatarPath = current.customAvatarPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _syncProfileToBloc() {
    final trimmedName = _nameController.text.trim();
    try {
      context.read<SettingsBloc>().add(
            SettingsProfileUpdated(
              userName: trimmedName.isEmpty ? 'مهدی' : trimmedName,
              userRole: _roleController.text.trim(),
              userEmail: _emailController.text.trim(),
              userBio: _bioController.text.trim(),
              avatarIndex: _selectedAvatarIndex,
              customAvatarPath: _customAvatarPath,
            ),
          );
    } catch (_) {}
  }

  Future<void> _pickImage(
    ImageSource source, {
    StateSetter? setSheetState,
  }) async {
    try {
      final String? pickedPath;
      if (widget.onPickImage != null) {
        pickedPath = await widget.onPickImage!(source);
      } else {
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1024,
          maxHeight: 1024,
        );
        pickedPath = pickedFile?.path;
      }

      final trimmedPath = pickedPath?.trim();
      if (trimmedPath != null && trimmedPath.isNotEmpty && mounted) {
        setState(() {
          _customAvatarPath = trimmedPath;
        });
        setSheetState?.call(() {});
        _syncProfileToBloc();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'امکان دسترسی به گالری در حال حاضر وجود ندارد.',
            style: TextStyle(fontFamily: 'Vazirmatn'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openAvatarPickerSheet() {
    final isSignature = (() {
      try {
        return context.read<SettingsBloc>().state.settings.themeMode.isSignatureLayout;
      } catch (_) {
        return false;
      }
    })();
    final theme = Theme.of(context);
    final isZen = !isSignature && (widget.isZen || theme.scaffoldBackgroundColor == AppColors.backgroundZen);
    final isDark = widget.isDark || isSignature;
    final textColor = isSignature
        ? Colors.white
        : (isDark
            ? Colors.white
            : (isZen ? AppColors.textZen : const Color(0xFF0F172A)));
    final secondaryColor = isSignature
        ? const Color(0xFF8E95A5)
        : (isDark
            ? const Color(0xFF94A3B8)
            : (isZen ? AppColors.textZenSecondary : const Color(0xFF64748B)));

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final hasCustomPhoto = _customAvatarPath != null &&
                _customAvatarPath!.trim().isNotEmpty;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                child: isSignature
                    ? Container(
                        key: const Key('user_profile_photo_picker_sheet'),
                        padding: EdgeInsets.fromLTRB(
                          24,
                          16,
                          24,
                          MediaQuery.viewInsetsOf(context).bottom + 28,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFF090B10),
                          border: Border(top: BorderSide(color: Color(0xFF1E2330), width: 1.2)),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                        ),
                        child: _buildAvatarPickerContent(
                          context,
                          sheetContext,
                          setSheetState,
                          hasCustomPhoto,
                          textColor,
                          secondaryColor,
                          isDark,
                          isSignature,
                        ),
                      )
                    : BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          key: const Key('user_profile_photo_picker_sheet'),
                          padding: EdgeInsets.fromLTRB(
                            24,
                            16,
                            24,
                            MediaQuery.viewInsetsOf(context).bottom + 28,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1C1C1E)
                                : (isZen ? AppColors.surfaceZen : Colors.white),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(32),
                            ),
                          ),
                          child: _buildAvatarPickerContent(
                            context,
                            sheetContext,
                            setSheetState,
                            hasCustomPhoto,
                            textColor,
                            secondaryColor,
                            isDark,
                            isSignature,
                          ),
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAvatarPickerContent(
    BuildContext context,
    BuildContext sheetContext,
    StateSetter setSheetState,
    bool hasCustomPhoto,
    Color textColor,
    Color secondaryColor,
    bool isDark,
    bool isSignature,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: secondaryColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'انتخاب تصویر و آواتار پروفایل',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'عکس پروفایل خود را مستقیماً از گالری گوشی انتخاب کنید یا یکی از آواتارهای اختصاصی را برگزینید:',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12,
            color: secondaryColor,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                key: const Key('pick_avatar_from_gallery_button'),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  foregroundColor: const Color(0xFF0A84FF),
                  backgroundColor: isSignature
                      ? const Color(0xFF12151E)
                      : (isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFE5E5EA)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: isSignature
                        ? const BorderSide(color: Color(0xFF1E2330), width: 1.0)
                        : BorderSide.none,
                  ),
                ),
                onPressed: () => _pickImage(
                  ImageSource.gallery,
                  setSheetState: setSheetState,
                ),
                icon: const Icon(
                  CupertinoIcons.photo_on_rectangle,
                  size: 19,
                ),
                label: const Text(
                  'انتخاب از گالری گوشی',
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                key: const Key('pick_avatar_from_camera_button'),
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  foregroundColor: textColor,
                                  backgroundColor: isDark
                                      ? const Color(0xFF2C2C2E)
                                      : const Color(0xFFE5E5EA),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () => _pickImage(
                                  ImageSource.camera,
                                  setSheetState: setSheetState,
                                ),
                                icon: const Icon(
                                  CupertinoIcons.camera_fill,
                                  size: 17,
                                ),
                                label: const Text(
                                  'دوربین',
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (hasCustomPhoto) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.checkmark_seal_fill,
                                  color: Color(0xFF10B981),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'عکس پروفایل از گالری انتخاب شد',
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  key: const Key('clear_custom_avatar_button'),
                                  onTap: () {
                                    setState(() => _customAvatarPath = null);
                                    setSheetState(() {});
                                    _syncProfileToBloc();
                                  },
                                  child: const Text(
                                    'حذف عکس',
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 88,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: ProfileAvatarPreset.presets.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 14),
                            itemBuilder: (context, index) {
                              final preset = ProfileAvatarPreset.presets[index];
                              final isSelected = _selectedAvatarIndex == index &&
                                  !hasCustomPhoto;
                              return GestureDetector(
                                key: Key('avatar_preset_option_$index'),
                                onTap: () {
                                  setState(() {
                                    _selectedAvatarIndex = index;
                                    _customAvatarPath = null;
                                  });
                                  setSheetState(() {});
                                  _syncProfileToBloc();
                                },
                                child: Column(
                                  children: [
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: preset.gradientColors.first,
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF0A84FF)
                                              : Colors.transparent,
                                          width: 2.5,
                                        ),
                                      ),
                                      child: Icon(
                                        preset.icon,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      preset.label,
                                      style: TextStyle(
                                        fontFamily: 'Vazirmatn',
                                        fontSize: 10.5,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? const Color(0xFF0A84FF)
                                            : secondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            key: const Key('confirm_avatar_selection_button'),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: const Color(0xFF0A84FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              _syncProfileToBloc();
                              Navigator.of(sheetContext).pop();
                            },
                            child: const Text(
                              'تایید تصویر پروفایل',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
  }

  void _saveProfile() {
    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لطفاً نام کاربری را وارد کنید.',
            style: TextStyle(fontFamily: 'Vazirmatn'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      context.read<SettingsBloc>().add(
            SettingsProfileUpdated(
              userName: trimmedName,
              userRole: _roleController.text.trim(),
              userEmail: _emailController.text.trim(),
              userBio: _bioController.text.trim(),
              avatarIndex: _selectedAvatarIndex,
              customAvatarPath: _customAvatarPath,
            ),
          );
    } catch (_) {}

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          key: Key('user_profile_saved_snackbar'),
          content: Text(
            'اطلاعات پروفایل کاربری با موفقیت ذخیره شد ✨',
            style: TextStyle(fontFamily: 'Vazirmatn'),
          ),
          backgroundColor: Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final isSignature = state.settings.themeMode.isSignatureLayout;
        final theme = Theme.of(context);
        final isZen = !isSignature && (widget.isZen || theme.scaffoldBackgroundColor == AppColors.backgroundZen);
        final isDark = widget.isDark || isSignature;
        final bgColor = isSignature
            ? const Color(0xFF090B10)
            : (isDark
                ? const Color(0xFF000000)
                : (isZen ? AppColors.backgroundZen : const Color(0xFFF2F2F7)));
        final surfaceColor = isSignature
            ? const Color(0xFF12151E)
            : (isDark
                ? const Color(0xFF1C1C1E)
                : (isZen ? AppColors.surfaceZen : Colors.white));
        final cardBorder = isSignature
            ? Border.all(color: const Color(0xFF1E2330), width: 1.0)
            : null;
        final itemBg = isSignature
            ? const Color(0xFF1A1F2C)
            : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA));
        final itemBorder = isSignature
            ? Border.all(color: const Color(0xFF1E2330), width: 1.0)
            : null;
        final textColor = isSignature
            ? Colors.white
            : (isDark ? AppColors.textDark : (isZen ? AppColors.textZen : AppColors.textLight));
        final secondaryColor = isSignature
            ? const Color(0xFF8E95A5)
            : (isDark
                ? const Color(0xFFEBEBF5)
                : (isZen ? AppColors.textZenSecondary : const Color(0xFF64748B)));

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            key: const Key('user_profile_page'),
            backgroundColor: bgColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                key: const Key('user_profile_back_button'),
                icon: Icon(
                  CupertinoIcons.back,
                  color: textColor,
                ),
                onPressed: () {
                  ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
                  Navigator.of(context).maybePop();
                },
              ),
              title: Text(
                'پروفایل کاربری',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ۱. بخش انتخاب و تغییر عکس/آواتار پروفایل
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(24),
                      border: cardBorder,
                    ),
                    child: Column(
                      children: [
                        BouncingTap(
                          key: const Key('user_profile_avatar_picker'),
                          onTap: _openAvatarPickerSheet,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 104,
                                height: 104,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFF5E5CE6).withValues(alpha: 0.28),
                                      const Color(0xFF0A84FF).withValues(alpha: 0.12),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              Stack(
                                alignment: Alignment.bottomLeft,
                                children: [
                                  ProfileAvatarPreset.buildUserCircleAvatar(
                                    avatarKey:
                                        const Key('user_profile_circle_avatar'),
                                    avatarIndex: _selectedAvatarIndex,
                                    customAvatarPath: _customAvatarPath,
                                    radius: 46,
                                    showGoldenAura:
                                        state.settings.hasActiveGoldenAura,
                                  ),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0A84FF),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: surfaceColor,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.camera_fill,
                                      color: Colors.white,
                                      size: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // نمایش لقب، مدال و سطح گیمیفیکیشن زیر آواتار پروفایل
                        Container(
                          key: const Key('user_profile_title_badge'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: itemBg,
                            borderRadius: BorderRadius.circular(20),
                            border: itemBorder,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.settings.titleMedal,
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                state.settings.userTitle,
                                key: const Key('user_profile_title_text'),
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFFEBEBF5)
                                      : textColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                toPersianDigits('• سطح ${state.settings.userLevel}'),
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: secondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              key: const Key(
                                'user_profile_gallery_direct_button',
                              ),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                foregroundColor: const Color(0xFF0A84FF),
                                backgroundColor: itemBg,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: isSignature
                                      ? const BorderSide(color: Color(0xFF1E2330), width: 1.0)
                                      : BorderSide.none,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                              ),
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(
                                CupertinoIcons.photo_on_rectangle,
                                size: 16,
                                color: Color(0xFF0A84FF),
                              ),
                              label: const Text(
                                'انتخاب از گالری گوشی',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0A84FF),
                                ),
                              ),
                            ),
                            TextButton.icon(
                              key: const Key('user_profile_change_photo_button'),
                              onPressed: _openAvatarPickerSheet,
                              icon: const Icon(
                                CupertinoIcons.photo_camera,
                                size: 16,
                                color: Color(0xFF0A84FF),
                              ),
                              label: const Text(
                                'تغییر عکس پروفایل',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0A84FF),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_customAvatarPath != null &&
                            _customAvatarPath!.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              'تصویر پروفایل از گالری انتخاب شده است ✨',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF30D158),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        // انتخابگر سریع آواتارها
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            ProfileAvatarPreset.presets.length,
                            (index) {
                              final item = ProfileAvatarPreset.presets[index];
                              final selected = _selectedAvatarIndex == index &&
                                  (_customAvatarPath == null ||
                                       _customAvatarPath!.isEmpty);
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: GestureDetector(
                                  key: Key('avatar_preset_$index'),
                                  onTap: () {
                                    setState(() {
                                      _selectedAvatarIndex = index;
                                      _customAvatarPath = null;
                                    });
                                    _syncProfileToBloc();
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    width: selected ? 40 : 34,
                                    height: selected ? 40 : 34,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: item.gradientColors.first,
                                      border: Border.all(
                                        color: selected
                                            ? const Color(0xFF0A84FF)
                                            : Colors.transparent,
                                        width: 2.2,
                                      ),
                                    ),
                                    child: Icon(
                                      item.icon,
                                      color: Colors.white,
                                      size: selected ? 20 : 16,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ۱.۵. کارت ارتقای سطح، القاب، استمرار ۷ روزه و سپر محافظ (Axes 5 & 6)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    key: const Key('user_profile_gamification_card'),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(24),
                      border: cardBorder,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'سطح و القاب قهرمانی (XP & Streak)',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Container(
                              key: const Key('user_profile_xp_text'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A84FF).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                toPersianDigits('${state.settings.effectiveXp} XP'),
                                style: const TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0A84FF),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            key: const Key('user_profile_xp_progress_bar'),
                            value: state.settings.tierProgressRatio,
                            minHeight: 7,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF0A84FF),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                key: const Key('user_profile_streak_box'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: itemBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: itemBorder,
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      '🔥',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            toPersianDigits('${state.settings.streakCount} روز متوالی'),
                                            key: const Key(
                                              'user_profile_streak_text',
                                            ),
                                            style: TextStyle(
                                              fontFamily: 'Vazirmatn',
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                          Text(
                                            'استمرار روزانه',
                                            style: TextStyle(
                                              fontFamily: 'Vazirmatn',
                                              fontSize: 10.5,
                                              color: secondaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                key: const Key(
                                  'user_profile_freeze_shield_box',
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: itemBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: itemBorder,
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      '🛡️',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            toPersianDigits('${state.settings.streakFreezeCount} سپر محافظ'),
                                            key: const Key(
                                              'user_profile_freeze_shield_text',
                                            ),
                                            style: TextStyle(
                                              fontFamily: 'Vazirmatn',
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                          Text(
                                            'جایزه ۷ روز موفق',
                                            style: TextStyle(
                                              fontFamily: 'Vazirmatn',
                                              fontSize: 10.5,
                                              color: secondaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (state.settings.isGoldenAuraUnlocked) ...[
                          const SizedBox(height: 12),
                          SwitchListTile.adaptive(
                            key: const Key('user_profile_golden_aura_switch'),
                            contentPadding: EdgeInsets.zero,
                            activeTrackColor: const Color(0xFFF59E0B),
                            title: Text(
                              'هاله درخشان طلایی دور آواتار 🥇',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            subtitle: Text(
                              'ویژه استاد بهرهوری (۳۰+ روز موفق)',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 11,
                                color: secondaryColor,
                              ),
                            ),
                            value: state.settings.isGoldenAuraEnabled,
                            onChanged: (enabled) {
                              context.read<SettingsBloc>().add(
                                    SettingsGoldenAuraToggled(enabled),
                                  );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ۲. فرم اطلاعات کاربری
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(24),
                      border: cardBorder,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اطلاعات شخصی و حرفه‌ای',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildProfileTextField(
                          fieldKey: const Key('user_profile_name_field'),
                          controller: _nameController,
                          label: 'نام و نام خانوادگی',
                          hint: 'مثال: مهدی',
                          icon: CupertinoIcons.person_fill,
                          isDark: isDark,
                          isSignature: isSignature,
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                        ),
                        const SizedBox(height: 16),
                        _buildProfileTextField(
                          fieldKey: const Key('user_profile_role_field'),
                          controller: _roleController,
                          label: 'عنوان شغلی / تخصص',
                          hint: 'مثال: مدیر سیستم • سازماندهی پروژه‌ها',
                          icon: CupertinoIcons.briefcase_fill,
                          isDark: isDark,
                          isSignature: isSignature,
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                        ),
                        const SizedBox(height: 16),
                        _buildProfileTextField(
                          fieldKey: const Key('user_profile_email_field'),
                          controller: _emailController,
                          label: 'ایمیل یا شماره همراه',
                          hint: 'mahdi@taskflow.ir',
                          icon: CupertinoIcons.mail_solid,
                          isDark: isDark,
                          isSignature: isSignature,
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                        ),
                        const SizedBox(height: 16),
                        _buildProfileTextField(
                          fieldKey: const Key('user_profile_bio_field'),
                          controller: _bioController,
                          label: 'هدف و بیوگرافی کوتاه',
                          hint: 'تمرکز بر بهره‌وری روزانه و نظم شخصی',
                          icon: CupertinoIcons.text_quote,
                          isDark: isDark,
                          isSignature: isSignature,
                          textColor: textColor,
                          secondaryColor: secondaryColor,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ۳. دکمه ذخیره اطلاعات پروفایل
                  BouncingTap(
                    onTap: _saveProfile,
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        key: const Key('user_profile_save_button'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A84FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: _saveProfile,
                        icon: const Icon(
                          CupertinoIcons.checkmark_alt_circle_fill,
                          size: 22,
                        ),
                        label: const Text(
                          'ذخیره تغییرات پروفایل',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileTextField({
    required Key fieldKey,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    required bool isSignature,
    required Color textColor,
    required Color secondaryColor,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    final isZen = !isSignature &&
        (widget.isZen || theme.scaffoldBackgroundColor == AppColors.backgroundZen);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: secondaryColor,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: fieldKey,
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 14,
            color: textColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 13,
              color: secondaryColor.withValues(alpha: 0.6),
            ),
            prefixIcon: Icon(
              icon,
              size: 18,
              color: const Color(0xFF0A84FF),
            ),
            filled: true,
            fillColor: isSignature
                ? const Color(0xFF12151E)
                : (isDark
                    ? const Color(0xFF2C2C2E)
                    : (isZen ? const Color(0xFFE2DDD2) : const Color(0xFFF2F2F7))),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: isSignature
                  ? const BorderSide(color: Color(0xFF1C202B), width: 1.0)
                  : BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: isSignature
                  ? const BorderSide(color: Color(0xFF1C202B), width: 1.0)
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF0A84FF),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
