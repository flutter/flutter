// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

const List<BoxShadow> shadow = const <BoxShadow>[
  const BoxShadow(offset: const Offset(0.0, 3.0), blurRadius: 1.0, spreadRadius: -2.0, color: const Color(0x33000000)),
  const BoxShadow(offset: const Offset(0.0, 2.0), blurRadius: 2.0, spreadRadius:  0.0, color: const Color(0x24000000)),
  const BoxShadow(offset: const Offset(0.0, 1.0), blurRadius: 5.0, spreadRadius:  0.0, color: const Color(0x1F000000)),
];

void main() {
  RenderDecoratedBox box1, box2, box3;
  new RenderingFlutterBinding(root: new RenderPadding(
    padding: const EdgeDims.all(40.0),
    child: new RenderViewport(
      child: new RenderDecoratedBox(
        decoration: const BoxDecoration(
          backgroundColor: const Color(0xFFFFFFFF)
        ),
        child: new RenderBlock(
          children: <RenderBox>[
            new RenderPadding(
              padding: const EdgeDims.all(40.0),
              child: new RenderPointerListener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (PointerDownEvent event) {
                  box1.decoration = const BoxDecoration(
                    gradient: const RadialGradient(
                      center: Point.origin, radius: 500.0,
                      colors: const <Color>[const Color(0x20F0D0B0), const Color(0xD0C0FFFF)]
                    ),
                    borderRadius: 20.0
                  );
                  RenderPadding innerBox1 = box1.child;
                  innerBox1.padding *= 1.5;
                  innerBox1.child = new RenderParagraph(
                    const StyledTextSpan(
                      const TextStyle(
                        color: const Color(0xFF000000),
                        fontSize: 20.0,
                        fontWeight: FontWeight.w900,
                        textAlign: TextAlign.center
                      ),
                      const <TextSpan>[ const PlainTextSpan('Hello World!') ]
                    )
                  );
                  RenderBlock block = box3.parent.parent;
                  block.remove(box3.parent);
                  RenderPadding innerBox2 = box2.child;
                  innerBox2.child = box3.parent;
                  RenderPointerListener listener = box1.parent;
                  listener.onPointerDown = null;
                },
                child: box1 = new RenderDecoratedBox(
                  decoration: const BoxDecoration(
                    backgroundColor: const Color(0xFFFFFF00),
                    boxShadow: shadow
                  ),
                  child: new RenderPadding(
                    padding: const EdgeDims.all(40.0)
                  )
                )
              )
            ),
            new RenderPadding(
              padding: const EdgeDims.all(40.0),
              child: box2 = new RenderDecoratedBox(
                decoration: const BoxDecoration(
                  backgroundColor: const Color(0xFF00FFFF),
                  boxShadow: shadow
                ),
                child: new RenderPadding(
                  padding: const EdgeDims.all(40.0)
                )
              )
            ),
            new RenderPadding(
              padding: const EdgeDims.all(40.0),
              child: box3 = new RenderDecoratedBox(
                decoration: const BoxDecoration(
                  backgroundColor: const Color(0xFF33FF33),
                  boxShadow: shadow
                ),
                child: new RenderPadding(
                  padding: const EdgeDims.all(40.0)
                )
              )
            ),
          ]
        )
      )
    )
  ));
}
