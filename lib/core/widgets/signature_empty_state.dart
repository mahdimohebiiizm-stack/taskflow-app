import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// ویجت نمایش وضعیت خالی در چیدمان اختصاصی (Signature Layout)
class SignatureEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subMessage;
  final EdgeInsetsGeometry padding;

  const SignatureEmptyState({
    super.key,
    this.icon = CupertinoIcons.wind,
    required this.message,
    this.subMessage,
    this.padding = const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: const Color(0xFF3A3F50),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9CA3AF),
              ),
            ),
            if (subMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                subMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12.5,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
