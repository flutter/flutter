// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import "dart:math" as math;
import 'dart:sky';

double timeBase = null;
LayoutRoot layoutRoot = new LayoutRoot();

void beginFrame(double timeStamp) {
  if (timeBase == null)
    timeBase = timeStamp;
  double delta = timeStamp - timeBase;
  PictureRecorder recorder = new PictureRecorder();
  Canvas canvas = new Canvas(recorder, new Size(view.width, view.height));
  canvas.translate(view.width / 2.0, view.height / 2.0);
  canvas.rotate(math.PI * delta / 1800);
  canvas.drawRect(new Rect.fromLTRB(-100.0, -100.0, 100.0, 100.0),
                  new Paint()..color = const Color.fromARGB(255, 0, 255, 0));

  double sin = math.sin(delta / 200);
  layoutRoot.maxWidth = 150.0 + (50 * sin);
  layoutRoot.layout();

  canvas.translate(layoutRoot.maxWidth / -2.0, (layoutRoot.maxWidth / 2.0) - 125);
  layoutRoot.paint(canvas);

  view.picture = recorder.endRecording();
  view.scheduleFrame();
}

void main() {
  var document = new Document();
  var arabic = document.createText("هذا هو قليلا طويلة من النص الذي يجب التفاف .");
  var more = document.createText(" و أكثر قليلا لجعله أطول. ");
  var block = document.createElement('p');
  block.style['display'] = 'paragraph';
  block.style['direction'] = 'rtl';
  block.style['unicode-bidi'] = 'plaintext';
  block.appendChild(arabic);
  block.appendChild(more);

  layoutRoot.rootElement = block;

  view.setBeginFrameCallback(beginFrame);
  view.scheduleFrame();
}
