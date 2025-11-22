import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class SliverIndexedItemPosition {
  final int index;
  final double itemLeadingEdge;
  final double itemTrailingEdge;

  const SliverIndexedItemPosition({
    required this.index,
    required this.itemLeadingEdge,
    required this.itemTrailingEdge,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SliverIndexedItemPosition &&
        other.index == index &&
        other.itemLeadingEdge == itemLeadingEdge &&
        other.itemTrailingEdge == itemTrailingEdge;
  }

  @override
  int get hashCode => Object.hash(index, itemLeadingEdge, itemTrailingEdge);
}

class ItemPositionsListener {
  final ValueNotifier<Iterable<SliverIndexedItemPosition>> positionsNotifier;
  ItemPositionsListener._(this.positionsNotifier);
  factory ItemPositionsListener.create() =>
      ItemPositionsListener._(ValueNotifier<Iterable<SliverIndexedItemPosition>>([]));
  ValueListenable<Iterable<SliverIndexedItemPosition>> get itemPositions => positionsNotifier;
}

@immutable
class SliverIndexAnchor {
  final int index;
  final double alignment;

  const SliverIndexAnchor({required this.index, this.alignment = 0.0});

  static const SliverIndexAnchor zero = SliverIndexAnchor(index: 0, alignment: 0.0);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SliverIndexAnchor && other.index == index && other.alignment == alignment;
  }

  @override
  int get hashCode => Object.hash(index, alignment);
}

class IndexedScrollAPI {
  double? Function(int index, double alignment) calculateTargetOffset = (_, __) => null;
  bool get isAttached => calculateTargetOffset(0, 0) != null;
}

class IndexedScrollController extends ScrollController {
  final IndexedScrollAPI api = IndexedScrollAPI();

  void jumpToIndex(int index, {double alignment = 0.0}) {
    final offset = api.calculateTargetOffset(index, alignment);
    if (offset != null) {
      jumpTo(offset);
    }
  }

  Future<void> animateToIndex(
    int index, {
    required Duration duration,
    required Curve curve,
    double alignment = 0.0,
  }) async {
    final offset = api.calculateTargetOffset(index, alignment);
    if (offset != null) {
      await animateTo(offset, duration: duration, curve: curve);
    }
  }
}
