// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The results of diffing the current composition order with the active
/// composition order.
class ViewListDiffResult {
  /// Views which should be removed from the scene.
  final List<int> viewsToRemove;

  /// Views to add to the scene.
  final List<int> viewsToAdd;

  /// If `true`, [viewsToAdd] should be added at the beginning of the scene.
  /// Otherwise, they should be added at the end of the scene.
  final bool addToBeginning;

  /// If [addToBeginning] is `true`, then this is the id of the platform view
  /// to insert [viewsToAdd] before.
  ///
  /// `null` if [addToBeginning] is `false`.
  final int? viewToInsertBefore;

  const ViewListDiffResult(
      this.viewsToRemove, this.viewsToAdd, this.addToBeginning,
      {this.viewToInsertBefore});
}

/// Diff the composition order with the active composition order. It is
/// common for the composition order and active composition order to differ
/// only slightly.
///
/// Consider a scrolling list of platform views; from frame
/// to frame the composition order will change in one of two ways, depending
/// on which direction the list is scrolling. One or more views will be added
/// to the beginning of the list, and one or more views will be removed from
/// the end of the list, with the order of the unchanged middle views
/// remaining the same.
// TODO(hterkelsen): Refactor to use [longestIncreasingSubsequence] and logic
// similar to `Surface._insertChildDomNodes` to efficiently handle more cases,
// https://github.com/flutter/flutter/issues/89611.
ViewListDiffResult? diffViewList(List<int> active, List<int> next) {
  if (active.isEmpty || next.isEmpty) {
    return null;
  }

  // This is tried if the first element of the next list is contained in the
  // active list at `index`. If the active and next lists are in the expected
  // form, then we should be able to iterate from `index` to the end of the
  // active list where every element matches in the next list.
  ViewListDiffResult? lookForwards(int index) {
    for (int i = 0; i + index < active.length; i++) {
      if (active[i + index] != next[i]) {
        // An element in the next list didn't match. This isn't in the expected
        // form we can optimize.
        return null;
      }
      if (i == next.length - 1) {
        // The entire next list was contained in the active list.
        if (index == 0) {
          // If the first index of the next list is also the first index in the
          // active list, then the next list is the same as the active list with
          // views removed from the end.
          return ViewListDiffResult(
              active.sublist(i + 1), const <int>[], false);
        } else if (i + index == active.length - 1) {
          // If this is also the end of the active list, then the next list is
          // the same as the active list with some views removed from the
          // beginning.
          return ViewListDiffResult(
              active.sublist(0, index), const <int>[], false);
        } else {
          return null;
        }
      }
    }
    // We reached the end of the active list but have not reached the end of the
    // next list. The lists are in the expected form. We should remove the
    // elements from `0` to `index` in the active list from the DOM and add the
    // elements from `active.length - index` (the entire active list minus the
    // number of new elements at the beginning) to the end of the next list to
    // the DOM at the end of the list of platform views.
    final List<int> viewsToRemove = active.sublist(0, index);
    final List<int> viewsToAdd = next.sublist(active.length - index);

    return ViewListDiffResult(
      viewsToRemove,
      viewsToAdd,
      false,
    );
  }

  // This is tried if the last element of the next list is contained in the
  // active list at `index`. If the lists are in the expected form, we should be
  // able to iterate backwards from index to the beginning of the active list
  // and have every element match the corresponding element from the next list.
  ViewListDiffResult? lookBackwards(int index) {
    for (int i = 0; index - i >= 0; i++) {
      if (active[index - i] != next[next.length - 1 - i]) {
        // An element from the next list didn't match the coresponding element
        // from the active list. These lists aren't in the expected form.
        return null;
      }
      if (i == next.length - 1) {
        // The entire next list was contained in the active list.
        if (index == active.length - 1) {
          // If the last element of the next list is also the last element of
          // the active list, then the next list is just the active list with
          // some elements removed from the beginning.
          return ViewListDiffResult(
              active.sublist(0, active.length - i - 1), const <int>[], false);
        } else if (index == i) {
          // If we also reached the beginning of the active list, then the next
          // list is the same as the active list with some views removed from
          // the end.
          return ViewListDiffResult(
              active.sublist(index + 1), const <int>[], false);
        } else {
          return null;
        }
      }
    }

    // We reached the beginning of the active list but have not exhausted the
    // entire next list. The lists are in the expected form. We should remove
    // the elements from the end of the active list which come after the element
    // which matches the last index of the next list (everything after `index`).
    // We should add the elements from the next list which we didn't reach while
    // iterating above (the first `next.length - index` views).
    final List<int> viewsToRemove = active.sublist(index + 1);
    final List<int> viewsToAdd = next.sublist(0, next.length - 1 - index);

    return ViewListDiffResult(
      viewsToRemove,
      viewsToAdd,
      true,
      viewToInsertBefore: active.first,
    );
  }

  // If the [active] and [next] lists are in the expected form described above,
  // then either the first or last element of [next] will be in [active].
  final int firstIndex = active.indexOf(next.first);
  final int lastIndex = active.lastIndexOf(next.last);
  if (firstIndex != -1 && lastIndex != -1) {
    // Both the first element and the last element of the next list are in the
    // active list. Search in the direction that will result in the least
    // amount of deletions.
    if (firstIndex <= (active.length - lastIndex)) {
      return lookForwards(firstIndex);
    } else {
      return lookBackwards(lastIndex);
    }
  } else if (firstIndex != -1) {
    return lookForwards(firstIndex);
  } else if (lastIndex != -1) {
    return lookBackwards(lastIndex);
  } else {
    return null;
  }
}
