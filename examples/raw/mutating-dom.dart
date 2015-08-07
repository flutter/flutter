// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import "dart:math" as math;
import 'dart:sky' as sky;

const kMaxIterations = 100;
int peakCount = 1000; // this is the number that must be reached for us to start reporting the peak number of nodes in the tree each frame

void report(String s) {
  // uncomment this if you want to see what the mutations are
  // print("$s\n");
}

sky.LayoutRoot layoutRoot = new sky.LayoutRoot();
sky.Document document = new sky.Document();
sky.Element root;
math.Random random = new math.Random();

bool pickThis(double odds) {
  return random.nextDouble() < odds;
}

String generateCharacter(int min, int max) {
  String result = new String.fromCharCode(random.nextInt(max)+min);
  report("generated character: '$result'");
  return result;
}

String colorToCSSString(sky.Color color) {
  return 'rgba(${color.red}, ${color.green}, ${color.blue}, ${color.alpha / 255.0})';
}

void doFrame(double timeStamp) {
  // mutate the DOM randomly
  int iterationsLeft = kMaxIterations;
  sky.Node node = root;
  sky.Node other = null;
  while (node != null && iterationsLeft > 0) {
    iterationsLeft -= 1;
    if (node is sky.Element && pickThis(0.4)) {
      node = (node as sky.Element).firstChild;
    } else if (node.nextSibling != null && pickThis(0.5)) {
      node = node.nextSibling;
    } else if (other == null && node != root && pickThis(0.1)) {
      other = node;
      node = root;
    } else if (node != root && other != null && pickThis(0.1)) {
      report("insertBefore()");
      try {
        node.insertBefore([other]);
      } catch (_) {
      }
      break;
    } else if (node != root && pickThis(0.001)) {
      report("remove()");
      node.remove();
    } else if (node is sky.Element) {
      if (pickThis(0.1)) {
        report("appending a new text node (ASCII)");
        node.appendChild(document.createText(generateCharacter(0x20, 0x7F)));
        break;
      } else if (pickThis(0.05)) {
        report("appending a new text node (Latin1)");
        node.appendChild(document.createText(generateCharacter(0x20, 0xFF)));
        break;
      } else if (pickThis(0.025)) {
        report("appending a new text node (BMP)");
        node.appendChild(document.createText(generateCharacter(0x20, 0xFFFF)));
        break;
      } else if (pickThis(0.0125)) {
        report("appending a new text node (Unicode)");
        node.appendChild(document.createText(generateCharacter(0x20, 0x10FFFF)));
        break;
      } else if (pickThis(0.1)) {
        report("appending a new Element");
        node.appendChild(document.createElement('t'));
        break;
      } else if (pickThis(0.1)) {
        report("styling: color");
        node.style['color'] = colorToCSSString(new sky.Color(random.nextInt(0xFFFFFFFF) | 0xC0808080));
        break;
      } else if (pickThis(0.1)) {
        report("styling: font-size");
        node.style['font-size'] = "${random.nextDouble() * 48.0}px";
        break;
      } else if (pickThis(0.2)) {
        report("styling: font-weight");
        node.style['font-weight'] = "${random.nextInt(8)+1}00";
        break;
      } else if (pickThis(0.1)) {
        report("styling: line-height, dynamic");
        node.style['line-height'] = "${random.nextDouble()*1.5}";
        break;
      } else if (pickThis(0.001)) {
        report("styling: line-height, fixed");
        node.style['line-height'] = "${random.nextDouble()*1.5}px";
        break;
      } else if (pickThis(0.025)) {
        report("styling: font-style italic");
        node.style['font-style'] = "italic";
        break;
      } else if (pickThis(0.05)) {
        report("styling: font-style normal");
        node.style['font-style'] = "normal";
        break;
      } else if (pickThis(0.1)) {
        report("styling: text-decoration");
        node.style['text-decoration-line'] = "none";
        break;
      } else if (pickThis(0.01)) {
        report("styling: text-decoration");
        node.style['text-decoration-line'] = "underline";
        break;
      } else if (pickThis(0.01)) {
        report("styling: text-decoration");
        node.style['text-decoration-line'] = "overline";
        break;
      } else if (pickThis(0.01)) {
        report("styling: text-decoration");
        node.style['text-decoration-line'] = "underline overline";
        break;
      } else if (pickThis(0.1)) {
        report("styling: text-decoration-style: inherit");
        node.style['text-decoration-style'] = "inherit";
        break;
      } else if (pickThis(0.1)) {
        report("styling: text-decoration-style: solid");
        node.style['text-decoration-style'] = "solid";
        break;
      } else if (pickThis(0.1)) {
        report("styling: text-decoration-style: double");
        node.style['text-decoration-style'] = "double";
        break;
      } else if (pickThis(0.1)) {
        report("styling: text-decoration-style: dotted");
        node.style['text-decoration-style'] = "dotted";
        break;
      } else if (pickThis(0.1)) {
        report("styling: text-decoration-style: dashed");
        node.style['text-decoration-style'] = "dashed";
        break;
      } else if (pickThis(0.1)) {
        report("styling: text-decoration-style: wavy");
        node.style['text-decoration-style'] = "wavy";
        break;
      } else if (pickThis(0.1)) {
        report("styling: text-decoration-color");
        node.style['text-decoration-color'] = colorToCSSString(new sky.Color(random.nextInt(0xFFFFFFFF)));
        break;
      }
    } else {
      assert(node is sky.Text);
      final sky.Text text = node;
      if (pickThis(0.1)) {
        report("appending a new text node (ASCII)");
        text.appendData(generateCharacter(0x20, 0x7F));
        break;
      } else if (pickThis(0.05)) {
        report("appending a new text node (Latin1)");
        text.appendData(generateCharacter(0x20, 0xFF));
        break;
      } else if (pickThis(0.025)) {
        report("appending a new text node (BMP)");
        text.appendData(generateCharacter(0x20, 0xFFFF));
        break;
      } else if (pickThis(0.0125)) {
        report("appending a new text node (Unicode)");
        text.appendData(generateCharacter(0x20, 0x10FFFF));
        break;
      } else if (text.length > 1 && pickThis(0.1)) {
        report("deleting character from Text node");
        text.deleteData(random.nextInt(text.length), 1);
        break;
      }
    }
  }

  report("counting...");
  node = root;
  int count = 1;
  while (node != null) {
    if (node is sky.Element && node.firstChild != null) {
      node = (node as sky.Element).firstChild;
      count += 1;
    } else {
      while (node != null && node.nextSibling == null)
        node = node.parentNode;
      if (node != null && node.nextSibling != null) {
        node = node.nextSibling;
        count += 1;
      }
    }
  }
  report("node count: $count\r");
  if (count > peakCount) {
    peakCount = count;
    print("peak node count so far: $count\r");
  }

  // draw the result
  report("recording...");
  sky.PictureRecorder recorder = new sky.PictureRecorder();
  sky.Canvas canvas = new sky.Canvas(recorder, new sky.Rect.fromLTWH(0.0, 0.0, sky.view.width, sky.view.height));
  layoutRoot.maxWidth = sky.view.width;
  layoutRoot.layout();
  layoutRoot.paint(canvas);
  report("painting...");
  sky.view.picture = recorder.endRecording();
  sky.view.scheduleFrame();
}

void main() {
  root = document.createElement('p');
  root.style['display'] = 'paragraph';
  root.style['color'] = '#FFFFFF';
  layoutRoot.rootElement = root;
  sky.view.setFrameCallback(doFrame);
  sky.view.scheduleFrame();
}
