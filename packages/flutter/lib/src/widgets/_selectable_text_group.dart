// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'basic.dart';
/// @docImport 'text.dart';
/// @docImport 'widget_span.dart';
library;

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'selectable_region.dart';

// In practice some selectables like widgetspan shift several pixels. So when
// the vertical position diff is within the threshold, compare the horizontal
// position to make the compareScreenOrder function more robust.
const double _kSelectableVerticalComparingThreshold = 3.0;

/// A [Selectable] that makes a [RenderParagraph] and the [Selectable]s in its
/// [WidgetSpan]s selectable as one piece of text.
///
/// A [RenderParagraph] splits its text into one [Selectable] per run of text
/// between placeholders. [RichText] registers those, and the [Selectable]s of
/// its [WidgetSpan] children, with [delegate] instead of its
/// [RichText.selectionRegistrar], and registers this group with the
/// [RichText.selectionRegistrar].
class SelectableTextGroup extends _SelectableTextGroupBase with Selectable, SelectionRegistrant {
  /// Creates a group for the [RenderParagraph] returned by `paragraph`.
  SelectableTextGroup(ValueGetter<RenderParagraph> paragraph)
    : _paragraph = paragraph,
      delegate = _SelectableTextContainerDelegate(paragraph);

  final ValueGetter<RenderParagraph> _paragraph;

  /// The [SelectionRegistrar] for the [Selectable]s of the paragraph and of
  /// its [WidgetSpan] children.
  final StaticSelectionContainerDelegate delegate;

  @override
  SelectionGeometry get value => delegate.value;

  @override
  void addListener(VoidCallback listener) => delegate.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => delegate.removeListener(listener);

  @override
  void pushHandleLayers(LayerLink? startHandle, LayerLink? endHandle) {
    delegate.pushHandleLayers(startHandle, endHandle);
  }

  @override
  SelectedContent? getSelectedContent() => delegate.getSelectedContent();

  @override
  SelectedContentRange? getSelection() => delegate.getSelection();

  @override
  SelectionResult dispatchSelectionEvent(SelectionEvent event) {
    return delegate.dispatchSelectionEvent(event);
  }

  @override
  int get contentLength => delegate.contentLength;

  @override
  Matrix4 getTransformTo(RenderObject? ancestor) => _paragraph().getTransformTo(ancestor);

  @override
  Size get size => _paragraph().size;

  @override
  List<Rect> get boundingBoxes => <Rect>[_paragraph().paintBounds];

  @override
  void dispose() {
    super.dispose();
    delegate.dispose();
  }
}

// Provides the concrete dispose that SelectionRegistrant.dispose calls.
abstract class _SelectableTextGroupBase {
  void dispose() {}
}

class _SelectableTextContainerDelegate extends StaticSelectionContainerDelegate {
  _SelectableTextContainerDelegate(this._paragraph);

  final ValueGetter<RenderParagraph> _paragraph;
  RenderParagraph get paragraph => _paragraph();

  @override
  Matrix4 getTransformFrom(Selectable child) => child.getTransformTo(paragraph);

  @override
  Matrix4 getTransformTo(RenderObject? ancestor) => paragraph.getTransformTo(ancestor);

  @override
  bool get hasSize => paragraph.hasSize;

  @override
  Size get containerSize => paragraph.size;

  @override
  SelectionResult handleSelectParagraph(SelectParagraphSelectionEvent event) {
    final SelectionResult result = _handleSelectParagraph(event);
    super.didReceiveSelectionBoundaryEvents();
    return result;
  }

  SelectionResult _handleSelectParagraph(SelectParagraphSelectionEvent event) {
    if (event.absorb) {
      for (var index = 0; index < selectables.length; index += 1) {
        dispatchSelectionEventToChild(selectables[index], event);
      }
      currentSelectionStartIndex = 0;
      currentSelectionEndIndex = selectables.length - 1;
      return SelectionResult.next;
    }

    // First pass, if the position is on a placeholder then dispatch the selection
    // event to the [Selectable] at the location and terminate.
    for (var index = 0; index < selectables.length; index += 1) {
      final bool selectableIsPlaceholder = !paragraph.selectableBelongsToParagraph(
        selectables[index],
      );
      if (selectableIsPlaceholder && selectables[index].boundingBoxes.isNotEmpty) {
        for (final Rect rect in selectables[index].boundingBoxes) {
          final Rect globalRect = MatrixUtils.transformRect(
            selectables[index].getTransformTo(null),
            rect,
          );
          if (globalRect.contains(event.globalPosition)) {
            currentSelectionStartIndex = currentSelectionEndIndex = index;
            return dispatchSelectionEventToChild(selectables[index], event);
          }
        }
      }
    }

    SelectionResult? lastSelectionResult;
    var foundStart = false;
    int? lastNextIndex;
    for (var index = 0; index < selectables.length; index += 1) {
      if (!paragraph.selectableBelongsToParagraph(selectables[index])) {
        if (foundStart) {
          final SelectionEvent synthesizedEvent = SelectParagraphSelectionEvent(
            globalPosition: event.globalPosition,
            absorb: true,
          );
          final SelectionResult result = dispatchSelectionEventToChild(
            selectables[index],
            synthesizedEvent,
          );
          if (selectables.length - 1 == index) {
            currentSelectionEndIndex = index;
            _flushInactiveSelections();
            return result;
          }
        }
        continue;
      }
      final SelectionGeometry existingGeometry = selectables[index].value;
      lastSelectionResult = dispatchSelectionEventToChild(selectables[index], event);
      if (index == selectables.length - 1 && lastSelectionResult == SelectionResult.next) {
        if (foundStart) {
          currentSelectionEndIndex = index;
        } else {
          currentSelectionStartIndex = currentSelectionEndIndex = index;
        }
        return SelectionResult.next;
      }
      if (lastSelectionResult == SelectionResult.next) {
        if (selectables[index].value == existingGeometry && !foundStart) {
          lastNextIndex = index;
        }
        if (selectables[index].value != existingGeometry && !foundStart) {
          assert(selectables[index].boundingBoxes.isNotEmpty);
          assert(selectables[index].value.selectionRects.isNotEmpty);
          final bool selectionAtStartOfSelectable = selectables[index].boundingBoxes[0].overlaps(
            selectables[index].value.selectionRects[0],
          );
          var startIndex = 0;
          if (lastNextIndex != null && selectionAtStartOfSelectable) {
            startIndex = lastNextIndex + 1;
          } else {
            startIndex = lastNextIndex == null && selectionAtStartOfSelectable ? 0 : index;
          }
          for (var i = startIndex; i < index; i += 1) {
            final SelectionEvent synthesizedEvent = SelectParagraphSelectionEvent(
              globalPosition: event.globalPosition,
              absorb: true,
            );
            dispatchSelectionEventToChild(selectables[i], synthesizedEvent);
          }
          currentSelectionStartIndex = startIndex;
          foundStart = true;
        }
        continue;
      }
      if (index == 0 && lastSelectionResult == SelectionResult.previous) {
        return SelectionResult.previous;
      }
      if (selectables[index].value != existingGeometry) {
        if (!foundStart && lastNextIndex == null) {
          currentSelectionStartIndex = 0;
          for (var i = 0; i < index; i += 1) {
            final SelectionEvent synthesizedEvent = SelectParagraphSelectionEvent(
              globalPosition: event.globalPosition,
              absorb: true,
            );
            dispatchSelectionEventToChild(selectables[i], synthesizedEvent);
          }
        }
        currentSelectionEndIndex = index;
        // Geometry has changed as a result of select paragraph, need to clear the
        // selection of other selectables to keep selection in sync.
        _flushInactiveSelections();
      }
      return SelectionResult.end;
    }
    assert(lastSelectionResult == null);
    return SelectionResult.end;
  }

  SelectionResult _adjustSelection(SelectionEdgeUpdateEvent event, {required bool isEnd}) {
    assert(() {
      if (isEnd) {
        assert(currentSelectionEndIndex < selectables.length && currentSelectionEndIndex >= 0);
        return true;
      }
      assert(currentSelectionStartIndex < selectables.length && currentSelectionStartIndex >= 0);
      return true;
    }());
    SelectionResult? finalResult;
    // Determines if the edge being adjusted is within the current viewport.
    //  - If so, we begin the search for the new selection edge position at the
    //    currentSelectionEndIndex/currentSelectionStartIndex.
    //  - If not, we attempt to locate the new selection edge starting from
    //    the opposite end.
    //  - If neither edge is in the current viewport, the search for the new
    //    selection edge position begins at 0.
    //
    // This can happen when there is a scrollable child and the edge being adjusted
    // has been scrolled out of view.
    final isCurrentEdgeWithinViewport = isEnd
        ? value.endSelectionPoint != null
        : value.startSelectionPoint != null;
    final isOppositeEdgeWithinViewport = isEnd
        ? value.startSelectionPoint != null
        : value.endSelectionPoint != null;
    int newIndex = switch ((isEnd, isCurrentEdgeWithinViewport, isOppositeEdgeWithinViewport)) {
      (true, true, true) => currentSelectionEndIndex,
      (true, true, false) => currentSelectionEndIndex,
      (true, false, true) => currentSelectionStartIndex,
      (true, false, false) => 0,
      (false, true, true) => currentSelectionStartIndex,
      (false, true, false) => currentSelectionStartIndex,
      (false, false, true) => currentSelectionEndIndex,
      (false, false, false) => 0,
    };
    bool? forward;
    late SelectionResult currentSelectableResult;
    // This loop sends the selection event to one of the following to determine
    // the direction of the search.
    //  - currentSelectionEndIndex/currentSelectionStartIndex if the current edge
    //    is in the current viewport.
    //  - The opposite edge index if the current edge is not in the current viewport.
    //  - Index 0 if neither edge is in the current viewport.
    //
    // If the result is `SelectionResult.next`, this loop look backward.
    // Otherwise, it looks forward.
    //
    // The terminate condition are:
    // 1. the selectable returns end, pending, none.
    // 2. the selectable returns previous when looking forward.
    // 2. the selectable returns next when looking backward.
    while (newIndex < selectables.length && newIndex >= 0 && finalResult == null) {
      currentSelectableResult = dispatchSelectionEventToChild(selectables[newIndex], event);
      switch (currentSelectableResult) {
        case SelectionResult.end:
        case SelectionResult.pending:
        case SelectionResult.none:
          finalResult = currentSelectableResult;
        case SelectionResult.next:
          if (forward == false) {
            newIndex += 1;
            finalResult = SelectionResult.end;
          } else if (newIndex == selectables.length - 1) {
            finalResult = currentSelectableResult;
          } else {
            forward = true;
            newIndex += 1;
          }
        case SelectionResult.previous:
          if (forward ?? false) {
            newIndex -= 1;
            finalResult = SelectionResult.end;
          } else if (newIndex == 0) {
            finalResult = currentSelectableResult;
          } else {
            forward = false;
            newIndex -= 1;
          }
      }
    }
    if (isEnd) {
      final bool forwardSelection = currentSelectionEndIndex >= currentSelectionStartIndex;
      if (forward != null &&
          ((!forwardSelection && forward && newIndex >= currentSelectionStartIndex) ||
              (forwardSelection && !forward && newIndex <= currentSelectionStartIndex))) {
        currentSelectionStartIndex = currentSelectionEndIndex;
      }
      currentSelectionEndIndex = newIndex;
    } else {
      final bool forwardSelection = currentSelectionEndIndex >= currentSelectionStartIndex;
      if (forward != null &&
          ((!forwardSelection && !forward && newIndex <= currentSelectionEndIndex) ||
              (forwardSelection && forward && newIndex >= currentSelectionEndIndex))) {
        currentSelectionEndIndex = currentSelectionStartIndex;
      }
      currentSelectionStartIndex = newIndex;
    }
    _flushInactiveSelections();
    return finalResult!;
  }

  /// The compare function this delegate used for determining the selection
  /// order of the [Selectable]s.
  ///
  /// Sorts the [Selectable]s by their top left [Rect].
  @override
  Comparator<Selectable> get compareOrder => _compareScreenOrder;

  static int _compareScreenOrder(Selectable a, Selectable b) {
    // Attempt to sort the selectables under a [_SelectableTextContainerDelegate]
    // by the top left rect.
    final Rect rectA = MatrixUtils.transformRect(a.getTransformTo(null), a.boundingBoxes.first);
    final Rect rectB = MatrixUtils.transformRect(b.getTransformTo(null), b.boundingBoxes.first);
    final int result = _compareVertically(rectA, rectB);
    if (result != 0) {
      return result;
    }
    return _compareHorizontally(rectA, rectB);
  }

  /// Compares two rectangles in the screen order solely by their vertical
  /// positions.
  ///
  /// Returns positive if a is lower, negative if a is higher, 0 if their
  /// order can't be determine solely by their vertical position.
  static int _compareVertically(Rect a, Rect b) {
    // The rectangles overlap so defer to horizontal comparison.
    if ((a.top - b.top < _kSelectableVerticalComparingThreshold &&
            a.bottom - b.bottom > -_kSelectableVerticalComparingThreshold) ||
        (b.top - a.top < _kSelectableVerticalComparingThreshold &&
            b.bottom - a.bottom > -_kSelectableVerticalComparingThreshold)) {
      return 0;
    }
    if ((a.top - b.top).abs() > _kSelectableVerticalComparingThreshold) {
      return a.top > b.top ? 1 : -1;
    }
    return a.bottom > b.bottom ? 1 : -1;
  }

  /// Compares two rectangles in the screen order by their horizontal positions
  /// assuming one of the rectangles enclose the other rect vertically.
  ///
  /// Returns positive if a is lower, negative if a is higher.
  static int _compareHorizontally(Rect a, Rect b) {
    // a encloses b.
    if (a.left - b.left < precisionErrorTolerance && a.right - b.right > -precisionErrorTolerance) {
      return -1;
    }
    // b encloses a.
    if (b.left - a.left < precisionErrorTolerance && b.right - a.right > -precisionErrorTolerance) {
      return 1;
    }
    if ((a.left - b.left).abs() > precisionErrorTolerance) {
      return a.left > b.left ? 1 : -1;
    }
    return a.right > b.right ? 1 : -1;
  }

  /// This method calculates a local [SelectedContentRange] based on the list
  /// of [selections] that are accumulated from the [Selectable] children under this
  /// delegate. This calculation takes into account the accumulated content
  /// length before the active selection, and returns null when either selection
  /// edge has not been set.
  SelectedContentRange? _calculateLocalRange(List<_SelectionInfo> selections) {
    if (currentSelectionStartIndex == -1 || currentSelectionEndIndex == -1) {
      return null;
    }
    var startOffset = 0;
    var endOffset = 0;
    var foundStart = false;
    bool forwardSelection = currentSelectionEndIndex >= currentSelectionStartIndex;
    if (currentSelectionEndIndex == currentSelectionStartIndex) {
      // Determining selection direction is inaccurate if currentSelectionStartIndex == currentSelectionEndIndex.
      // Use the range from the selectable within the selection as the source of truth for selection direction.
      final SelectedContentRange rangeAtSelectableInSelection =
          selectables[currentSelectionStartIndex].getSelection()!;
      forwardSelection =
          rangeAtSelectableInSelection.endOffset >= rangeAtSelectableInSelection.startOffset;
    }
    for (var index = 0; index < selections.length; index++) {
      final _SelectionInfo selection = selections[index];
      if (selection.range == null) {
        if (foundStart) {
          return SelectedContentRange(
            startOffset: forwardSelection ? startOffset : endOffset,
            endOffset: forwardSelection ? endOffset : startOffset,
          );
        }
        startOffset += selection.contentLength;
        endOffset = startOffset;
        continue;
      }
      final int selectionStartNormalized = min(
        selection.range!.startOffset,
        selection.range!.endOffset,
      );
      final int selectionEndNormalized = max(
        selection.range!.startOffset,
        selection.range!.endOffset,
      );
      if (!foundStart) {
        // Because a RenderParagraph may split its content into multiple selectables
        // we have to consider at what offset a selectable starts at relative
        // to the RenderParagraph, when the selectable is not the start of the content.
        final bool shouldConsiderContentStart =
            index > 0 && paragraph.selectableBelongsToParagraph(selectables[index]);
        startOffset +=
            (selectionStartNormalized -
                    (shouldConsiderContentStart
                        ? paragraph
                              .getPositionForOffset(
                                selectables[index].boundingBoxes.first.centerLeft,
                              )
                              .offset
                        : 0))
                .abs();
        endOffset = startOffset + (selectionEndNormalized - selectionStartNormalized).abs();
        foundStart = true;
      } else {
        endOffset += (selectionEndNormalized - selectionStartNormalized).abs();
      }
    }
    assert(
      foundStart,
      'The start of the selection has not been found despite this selection delegate having an existing currentSelectionStartIndex and currentSelectionEndIndex.',
    );
    return SelectedContentRange(
      startOffset: forwardSelection ? startOffset : endOffset,
      endOffset: forwardSelection ? endOffset : startOffset,
    );
  }

  /// Returns a [SelectedContentRange] considering the [SelectedContentRange]
  /// from each [Selectable] child managed under this delegate.
  ///
  /// When nothing is selected or either selection edge has not been set,
  /// this method will return `null`.
  @override
  SelectedContentRange? getSelection() {
    final selections = <_SelectionInfo>[
      for (final Selectable selectable in selectables)
        (contentLength: selectable.contentLength, range: selectable.getSelection()),
    ];
    return _calculateLocalRange(selections);
  }

  // From [SelectableRegion].

  // Clears the selection on all selectables not in the range of
  // currentSelectionStartIndex..currentSelectionEndIndex.
  //
  // If one of the edges does not exist, then this method will clear the selection
  // in all selectables except the existing edge.
  //
  // If neither of the edges exist this method immediately returns.
  void _flushInactiveSelections() {
    if (currentSelectionStartIndex == -1 && currentSelectionEndIndex == -1) {
      return;
    }
    if (currentSelectionStartIndex == -1 || currentSelectionEndIndex == -1) {
      final int skipIndex = currentSelectionStartIndex == -1
          ? currentSelectionEndIndex
          : currentSelectionStartIndex;
      for (var i = 0; i < selectables.length; i++) {
        if (i == skipIndex) {
          continue;
        }
        dispatchSelectionEventToChild(selectables[i], const ClearSelectionEvent());
      }
      return;
    }
    final int skipStart = min(currentSelectionStartIndex, currentSelectionEndIndex);
    final int skipEnd = max(currentSelectionStartIndex, currentSelectionEndIndex);
    for (var index = 0; index < selectables.length; index += 1) {
      if (index >= skipStart && index <= skipEnd) {
        continue;
      }
      dispatchSelectionEventToChild(selectables[index], const ClearSelectionEvent());
    }
  }

  @override
  SelectionResult handleSelectionEdgeUpdate(SelectionEdgeUpdateEvent event) {
    if (event.granularity != TextGranularity.paragraph) {
      return super.handleSelectionEdgeUpdate(event);
    }
    updateLastSelectionEdgeLocation(
      globalSelectionEdgeLocation: event.globalPosition,
      forEnd: event.type == SelectionEventType.endEdgeUpdate,
    );
    if (event.type == SelectionEventType.endEdgeUpdate) {
      return currentSelectionEndIndex == -1
          ? super.handleSelectionEdgeUpdate(event)
          : _adjustSelection(event, isEnd: true);
    }
    return currentSelectionStartIndex == -1
        ? super.handleSelectionEdgeUpdate(event)
        : _adjustSelection(event, isEnd: false);
  }
}

/// The length of the content that can be selected, and the range that is
/// selected.
typedef _SelectionInfo = ({int contentLength, SelectedContentRange? range});
