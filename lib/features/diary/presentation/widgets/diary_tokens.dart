import 'package:flutter/material.dart';

abstract final class DiaryTokens {
  static const feedBg = Color(0xFFF0F2F5);
  static const like = Color(0xFFE53935);
  static const comment = Color(0xFF1E88E5);
  static const photo = Color(0xFF43A047);
  static const moment = Color(0xFF7E57C2);
  static const memory = Color(0xFFFB8C00);

  static const bannerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFB9D6EA),
      Color(0xFF8FBF9A),
      Color(0xFF5E8F62),
    ],
  );
}
