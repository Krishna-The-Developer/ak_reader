import 'dart:convert';

import 'package:flutter/material.dart';

class PageAnnotation {
  final int pageIndex;
  final String tool; // 'pen', 'pencil', 'highlighter'
  final int colorValue;
  final Rect boundingBox;
  final String text;
  final List<Offset> points;

  PageAnnotation({
    required this.pageIndex,
    required this.tool,
    required this.colorValue,
    required this.boundingBox,
    required this.text,
    this.points = const [],
  });

  String toHiveString() {
    final pts = points
        .map((p) => '${p.dx.toStringAsFixed(1)},${p.dy.toStringAsFixed(1)}')
        .join(';');
    final map = {
      'pageIndex': pageIndex,
      'tool': tool,
      'colorValue': colorValue,
      'left': boundingBox.left,
      'top': boundingBox.top,
      'width': boundingBox.width,
      'height': boundingBox.height,
      'text': text,
      'points': pts,
    };
    return jsonEncode(map);
  }

  static PageAnnotation? fromHiveString(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final ptsRaw = (map['points'] as String? ?? '');
      final List<Offset> parsedPts = [];
      if (ptsRaw.isNotEmpty) {
        for (final pair in ptsRaw.split(';')) {
          final parts = pair.split(',');
          if (parts.length == 2) {
            parsedPts.add(
              Offset(double.parse(parts[0]), double.parse(parts[1])),
            );
          }
        }
      }

      return PageAnnotation(
        pageIndex: map['pageIndex'] as int,
        tool: map['tool'] as String,
        colorValue: map['colorValue'] as int,
        boundingBox: Rect.fromLTWH(
          (map['left'] as num).toDouble(),
          (map['top'] as num).toDouble(),
          (map['width'] as num).toDouble(),
          (map['height'] as num).toDouble(),
        ),
        text: map['text'] as String? ?? '',
        points: parsedPts,
      );
    } catch (_) {
      return null;
    }
  }
}
