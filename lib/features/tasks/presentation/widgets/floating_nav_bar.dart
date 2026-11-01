import 'package:flutter/material.dart';
import 'package:task_flow/core/theme/app_colors.dart';

/// Legacy placeholder kept compatible with [AppColors]; active navigation is handled by [MainScreen].
class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navBarDark,
      height: 68,
    );
  }
}
