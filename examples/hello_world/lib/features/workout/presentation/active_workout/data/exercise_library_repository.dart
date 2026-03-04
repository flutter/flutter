import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/exercise_library_item.dart';

class ExerciseLibraryRepository {
  static const String _assetPath = 'assets/data/styrketraening_oevelser.json';

  Future<List<ExerciseLibraryItem>> loadAll() async {
    final String raw = await rootBundle.loadString(_assetPath);
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((dynamic item) => ExerciseLibraryItem.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  ExerciseLibraryItem? bySlug(List<ExerciseLibraryItem> items, String slug) {
    for (final ExerciseLibraryItem item in items) {
      if (item.slug == slug) {
        return item;
      }
    }
    return null;
  }
}
