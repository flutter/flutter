// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets/basic.dart';

import '../resources/display_list.dart';

class ChildComponent extends Component {
  ChildComponent(this.size);

  final Size size;

  Widget build() {
    String text = "This text should be roughly centered";
    return new Positioned(child: new Text(text),
        top: size.height / 2.0, left: size.width / 2.0);
  }
}

class ParentComponent extends StatefulComponent {
  Size _size = new Size(100.0, 100.0);

  void syncFields(ParentComponent source) {
  }

  Widget build() {
    return new SizeObserver(
      child : new Stack([new ChildComponent(_size)]),
      callback : sizeCallback
    );
  }

  void sizeCallback(Size size) {
    setState(() {
      _size = size;
    });
  }
}

main() async {
  WidgetTester tester = new WidgetTester();

  await tester.test(() {
    return new ParentComponent();
  }, frameCount: 2);

  tester.endTest();
}
