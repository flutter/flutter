// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/dropdown_menu/dropdown_menu.customize_trailing_icon_button.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'The DropdownMenu should allow customization on how its trailing icon button being construct',
    (WidgetTester tester) async {
      const example.DropdownMenuExample dropdownMenuExample = example.DropdownMenuExample();

      await tester.pumpWidget(dropdownMenuExample);

      final IconButton trailingIconButton = tester.widget(find.byType(IconButton).first);

      // check if the padding and icon size of the trailing icon button in DropdownMenu is 0 and 12 respectively
      expect(trailingIconButton.padding, EdgeInsets.zero);
      expect(trailingIconButton.iconSize, 12);
    }
  );
}
