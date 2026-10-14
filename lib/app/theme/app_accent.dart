import 'package:flutter/material.dart';

enum AppAccent {
  blue('blue', Color(0xFF0068FF), 'Xanh dương'),
  burgundy('burgundy', Color(0xFF9B2335), 'Đỏ đô'),
  amber('amber', Color(0xFFC47B17), 'Vàng hổ phách');

  const AppAccent(this.storageKey, this.seed, this.label);

  final String storageKey;
  final Color seed;
  final String label;

  static AppAccent fromStorageKey(String? key) {
    for (final value in AppAccent.values) {
      if (value.storageKey == key) return value;
    }
    return AppAccent.blue;
  }
}
