import 'package:flutter/material.dart';

class PageAnnotation {
  final int pageIndex;
  final String tool; // 'pen', 'pencil', 'highlighter'
  final int colorValue;
  final Rect boundingBox;
  final String text;

  PageAnnotation({
    required this.pageIndex,
    required this.tool,
    required this.colorValue,
    required this.boundingBox,
    required this.text,
  });

  // Serialize to string for Hive: page|tool|color|left|top|width|height|text
  String toHiveString() {
    return '$pageIndex|$tool|$colorValue|${boundingBox.left.toStringAsFixed(1)}|${boundingBox.top.toStringAsFixed(1)}|${boundingBox.width.toStringAsFixed(1)}|${boundingBox.height.toStringAsFixed(1)}|$text';
  }

  static PageAnnotation? fromHiveString(String raw) {
    try {
      final parts = raw.split('|');
      if (parts.length < 8) return null;
      return PageAnnotation(
        pageIndex: int.parse(parts[0]),
        tool: parts[1],
        colorValue: int.parse(parts[2]),
        boundingBox: Rect.fromLTWH(
          double.parse(parts[3]),
          double.parse(parts[4]),
          double.parse(parts[5]),
          double.parse(parts[6]),
        ),
        text: parts.sublist(7).join('|'),
      );
    } catch (_) {
      return null;
    }
  }
}
