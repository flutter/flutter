// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';

class SemanticsConfiguration {
  SemanticsPreference communePreference = SemanticsPreference.communeWithParentAndChildren;

  final Map<SemanticsAction, VoidCallback> _actions = <SemanticsAction, VoidCallback>{};

  Map<SemanticsAction, VoidCallback> get actions => _actions;

  void addAction(SemanticsAction action, VoidCallback handler) {
    _actions[action] = handler;
    _isEmpty = false;
  }

  // TODO(goderbauer): should there just be one setLabel(label, textDirection)?
  String _label = '';
  String get label => _label;
  set label(String label) {
    _label = label;
    _isEmpty = false;
  }

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection textDirection) {
    _textDirection = textDirection;
    _isEmpty = false;
  }

  set isSelected(bool value) {
    _setFlag(SemanticsFlags.isSelected, value);
  }

  set isChecked(bool value) {
    _setFlag(SemanticsFlags.hasCheckedState, true);
    _setFlag(SemanticsFlags.isChecked, value);
  }

  set isDisabled(bool value) {
    // TODO(goderbauer): implement in engine.
  }

  int _flags = 0;

  int get flags => _flags;

  void _setFlag(SemanticsFlags flag, bool value) {
    if (value) {
      _flags |= flag.index;
    } else {
      _flags &= ~flag.index;
    }
    _isEmpty = false;
  }

  bool dropsSemanticsOfPreviouslyPaintedNodes = false;

  bool communeCompatibleWith(SemanticsConfiguration other) {
    if (other == null)
      return true;
    if (_actions.keys.toSet().intersection(other._actions.keys.toSet()).isNotEmpty)
      return false;
    if ((_flags & other._flags) != 0)
      return false;
    return true;
  }

  void absorb(SemanticsConfiguration other) {
    _actions.addAll(other.actions);
    _flags |= other._flags;

    textDirection ??= other.textDirection;
    if (other.label.isNotEmpty) {
      String nestedLabel = other.label;
      if (textDirection != other.textDirection && other.textDirection != null) {
        switch (other.textDirection) {
          case TextDirection.rtl:
            nestedLabel = '${Unicode.RLE}$nestedLabel${Unicode.PDF}';
            break;
          case TextDirection.ltr:
            nestedLabel = '${Unicode.LRE}$nestedLabel${Unicode.PDF}';
            break;
        }
      }
      if (label.isEmpty)
        label = nestedLabel;
      else
        label = '$label\n$nestedLabel';
    }

    _isEmpty = false;
  }

  bool get isSemanticBoundary {
    return communePreference != SemanticsPreference.communeWithParentAndChildren;
  }

  @override
  String toString() {
    return 'SemanticsConfiguration($label, $communePreference)';
  }

  bool get isEmpty => _isEmpty;
  bool _isEmpty = true;
}

enum SemanticsPreference {
  noCommune, // is a semantics boundary
  communeWithChildren, // is a semantics boundary
  communeWithParentAndChildren,
}
