import 'package:flutter/material.dart';

/// Reusable layout transition wrapper for seamless morphing between
/// the new ultra-minimalist 'Signature' UI design and the classic glassmorphic layout.
class DualLayoutTransition extends StatelessWidget {
  final bool isSignatureLayout;
  final Widget signatureChild;
  final Widget classicChild;
  final Duration duration;

  const DualLayoutTransition({
    super.key,
    required this.isSignatureLayout,
    required this.signatureChild,
    required this.classicChild,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final scaleAnimation = Tween<double>(begin: 0.97, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        );

        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
      child: isSignatureLayout
          ? KeyedSubtree(
              key: const ValueKey<String>('signature_layout'),
              child: signatureChild,
            )
          : KeyedSubtree(
              key: const ValueKey<String>('classic_layout'),
              child: classicChild,
            ),
    );
  }
}
