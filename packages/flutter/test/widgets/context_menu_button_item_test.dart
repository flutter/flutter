// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file intentionally exercises the deprecated ContextMenuButtonType API.
// ignore_for_file: deprecated_member_use

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to custom', () {
    final item = ContextMenuButtonItem(onPressed: () {});
    expect(item.kind, ContextMenuButtonKind.custom);
    expect(item.type, ContextMenuButtonType.custom);
  });

  test('every ContextMenuButtonType maps to a kind and back', () {
    for (final ContextMenuButtonType type in ContextMenuButtonType.values) {
      final item = ContextMenuButtonItem(onPressed: null, type: type);
      expect(item.type, type);
      expect(item.kind.name, type.name);
    }
  });

  test('kinds with a matching type report that type', () {
    for (final ContextMenuButtonKind kind in ContextMenuButtonKind.values) {
      final item = ContextMenuButtonItem(onPressed: null, kind: kind);
      expect(item.kind, kind);
      if (kind == ContextMenuButtonKind.translate) {
        continue;
      }
      expect(item.type.name, kind.name);
    }
  });

  test('kinds without a matching type report custom', () {
    const item = ContextMenuButtonItem(onPressed: null, kind: ContextMenuButtonKind.translate);
    expect(item.type, ContextMenuButtonType.custom);
  });

  test('items created with type or kind are equal', () {
    const fromType = ContextMenuButtonItem(onPressed: null, type: ContextMenuButtonType.copy);
    const fromKind = ContextMenuButtonItem(onPressed: null, kind: ContextMenuButtonKind.copy);
    expect(fromType, fromKind);
    expect(fromType.hashCode, fromKind.hashCode);
  });

  test('copyWith accepts type or kind', () {
    const item = ContextMenuButtonItem(onPressed: null, kind: ContextMenuButtonKind.copy);
    expect(item.copyWith(kind: ContextMenuButtonKind.paste).kind, ContextMenuButtonKind.paste);
    expect(item.copyWith(type: ContextMenuButtonType.cut).kind, ContextMenuButtonKind.cut);
    expect(item.copyWith(label: 'hi').kind, ContextMenuButtonKind.copy);
  });

  test('switches on kind work with constant patterns', () {
    String describe(ContextMenuButtonKind kind) {
      return switch (kind) {
        ContextMenuButtonKind.copy => 'copy',
        ContextMenuButtonKind.translate => 'translate',
        _ => 'other',
      };
    }

    expect(describe(ContextMenuButtonKind.copy), 'copy');
    expect(describe(ContextMenuButtonKind.translate), 'translate');
    expect(describe(ContextMenuButtonKind.paste), 'other');
  });
}
