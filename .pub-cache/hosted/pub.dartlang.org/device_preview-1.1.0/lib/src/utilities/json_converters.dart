import 'package:flutter/widgets.dart';
import 'package:json_annotation/json_annotation.dart';

/// A json converter for [Size].
class SizeJsonConverter implements JsonConverter<Size, Object?> {
  const SizeJsonConverter();

  @override
  Size fromJson(Object? json) {
    if (json == null) {
      return Size.zero;
    }

    if (json is Iterable) {
      final list = json.toList();

      if (list.length > 1) {
        final w = list[0];
        final h = list[1];
        if ((w is int || w is double) && (h is int || h is double)) {
          return Size(w.toDouble(), h.toDouble());
        }
      }
    }

    throw Exception('Failed to parse JSON as size');
  }

  @override
  Object? toJson(Size object) {
    return [object.width, object.height];
  }
}

class NullableEdgeInsetsJsonConverter
    implements JsonConverter<EdgeInsets?, Object?> {
  const NullableEdgeInsetsJsonConverter();

  @override
  EdgeInsets? fromJson(Object? json) {
    if (json == null) return null;
    return const EdgeInsetsJsonConverter().fromJson(json);
  }

  @override
  Object? toJson(EdgeInsets? object) {
    if (object == null) return null;
    return const EdgeInsetsJsonConverter().toJson(object);
  }
}

class EdgeInsetsJsonConverter implements JsonConverter<EdgeInsets, Object?> {
  const EdgeInsetsJsonConverter();

  @override
  EdgeInsets fromJson(Object? json) {
    if (json == null) {
      return EdgeInsets.zero;
    }

    if (json is Iterable) {
      final list = json.toList();

      if (list.length > 3) {
        final left = list[0];
        final top = list[1];
        final right = list[2];
        final bottom = list[3];
        if ((left is int || left is double) &&
            (top is int || top is double) &&
            (right is int || right is double) &&
            (bottom is int || bottom is double)) {
          return EdgeInsets.only(
            left: left,
            top: top,
            right: right,
            bottom: bottom,
          );
        }
      }
    }

    throw Exception('Failed to parse JSON as size');
  }

  @override
  Object? toJson(EdgeInsets object) {
    return [
      object.left,
      object.top,
      object.right,
      object.bottom,
    ];
  }
}
