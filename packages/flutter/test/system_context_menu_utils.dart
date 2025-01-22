// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Returns a [IOSSystemContextMenuItem] of the correct subclass given its
/// json data.
IOSSystemContextMenuItem systemContextMenuItemDataFromJson(Map<String, dynamic> json) {
  final String? type = json['type'] as String?;
  final String? title = json['title'] as String?;
  final VoidCallback? onPressed = json['onPressed'] as VoidCallback?;
  return switch (type) {
    'copy' => const IOSSystemContextMenuItemCopy(),
    'cut' => const IOSSystemContextMenuItemCut(),
    'paste' => const IOSSystemContextMenuItemPaste(),
    'selectAll' => const IOSSystemContextMenuItemSelectAll(),
    'searchWeb' => IOSSystemContextMenuItemSearchWeb(title: title),
    'share' => IOSSystemContextMenuItemShare(title: title),
    'lookUp' => IOSSystemContextMenuItemLookUp(title: title),
    'custom' => IOSSystemContextMenuItemCustom(title: title!, onPressed: onPressed!),
    _ => throw FlutterError('Invalid json for IOSSystemContextMenuItem.type $type.'),
  };
}
