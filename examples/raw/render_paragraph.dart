// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';
import 'package:sky/framework/app.dart';
import 'package:sky/framework/rendering/box.dart';
import 'package:sky/framework/rendering/object.dart';
import 'package:sky/framework/rendering/flex.dart';
import 'package:sky/framework/rendering/paragraph.dart';
import '../lib/solid_color_box.dart';

AppView app;

void main() {
  RenderFlex flexRoot = new RenderFlex(direction: FlexDirection.Vertical);

  RenderObject root = new RenderDecoratedBox(
    decoration: new BoxDecoration(backgroundColor: const Color(0xFF606060)),
    child: flexRoot
  );

  RenderObject child = new RenderSolidColorBox(const Color(0xFFFFFF00));
  flexRoot.add(child);
  child.parentData.flex = 2;

  // The internet is a beautiful place.  https://baconipsum.com/
  String meatyString = """Bacon ipsum dolor amet ham fatback tri-tip, prosciutto
porchetta bacon kevin meatball meatloaf pig beef ribs chicken. Brisket ribeye
andouille leberkas capicola meatloaf. Chicken pig ball tip pork picanha bresaola
alcatra. Pork pork belly alcatra, flank chuck drumstick biltong doner jowl.
Pancetta meatball tongue tenderloin rump tail jowl boudin.""";

  child = new RenderDecoratedBox(
    decoration: new BoxDecoration(backgroundColor: const Color(0xFFFFFFFF)),
    child: new RenderParagraph(text: meatyString, color: const Color(0xFF009900))
  );
  flexRoot.add(child);
  child.parentData.flex = 1;

  app = new AppView(root);
}
