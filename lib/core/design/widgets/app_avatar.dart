// lib/core/design/widgets/app_avatar.dart
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// Round identity chip with initials or an image, for household members.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.color,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final Color? color;

  static const _palette = [
    (AppColors.blue100, AppColors.blue700),
    (AppColors.todaySoft, AppColors.sun600),
    (AppColors.rescheduleSoft, AppColors.coral600),
    (AppColors.doneSoft, AppColors.green600),
  ];

  String get _initials {
    final words = name.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    return words.take(2).map((w) => w[0]).join().toUpperCase();
  }

  (Color, Color) get _tint {
    if (color != null) return (color!, AppColors.white);
    var h = 0;
    for (final c in name.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return _palette[h % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _tint;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: bg,
                  alignment: Alignment.center,
                  child: Text(
                    _initials,
                    style: TextStyle(
                      fontFamily: AppTypography.fontSans,
                      fontWeight: AppTypography.bold,
                      fontSize: (size * 0.4).roundToDouble(),
                      color: fg,
                    ),
                  ),
                ),
              )
            : Container(
                color: bg,
                alignment: Alignment.center,
                child: Text(
                  _initials,
                  style: TextStyle(
                    fontFamily: AppTypography.fontSans,
                    fontWeight: AppTypography.bold,
                    fontSize: (size * 0.4).roundToDouble(),
                    color: fg,
                  ),
                ),
              ),
      ),
    );
  }
}
