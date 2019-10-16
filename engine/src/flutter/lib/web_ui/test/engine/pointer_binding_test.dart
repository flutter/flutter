// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'package:test/test.dart';

void main() {
  group('Pointer Binding', () {
    html.Element glassPane = domRenderer.glassPaneElement;

    setUp(() {
      // Touching domRenderer creates PointerBinding.instance.
      domRenderer;

      // Set a new detector to reset the state of the listeners.
      PointerBinding.instance.debugOverrideDetector(TestPointerDetector());

      ui.window.onPointerDataPacket = null;
    });

    test('can receive pointer events on the glass pane', () {
      ui.PointerDataPacket receivedPacket;
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        receivedPacket = packet;
      };

      glassPane.dispatchEvent(html.PointerEvent('pointerdown', {
        'pointerId': 1,
        'button': 1,
      }));

      expect(receivedPacket, isNotNull);
      expect(receivedPacket.data[0].device, equals(1));
    });

    test('synthesizes a pointerup event on two pointerdowns in a row', () {
      List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      glassPane.dispatchEvent(html.PointerEvent('pointerdown', {
        'pointerId': 1,
        'button': 1,
      }));

      glassPane.dispatchEvent(html.PointerEvent('pointerdown', {
        'pointerId': 1,
        'button': 1,
      }));

      expect(packets, hasLength(3));
      expect(packets[0].data[0].change, equals(ui.PointerChange.down));
      expect(packets[1].data[0].change, equals(ui.PointerChange.up));
      expect(packets[2].data[0].change, equals(ui.PointerChange.down));
    });

    test('does not synthesize pointer up if from different device', () {
      List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      glassPane.dispatchEvent(html.PointerEvent('pointerdown', {
        'pointerId': 1,
        'button': 1,
      }));

      glassPane.dispatchEvent(html.PointerEvent('pointerdown', {
        'pointerId': 2,
        'button': 1,
      }));

      expect(packets, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.down));
      expect(packets[0].data[0].device, equals(1));
      expect(packets[1].data[0].change, equals(ui.PointerChange.down));
      expect(packets[1].data[0].device, equals(2));
    });

    test('creates an add event if the first pointer activity is a hover', () {
      List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      glassPane.dispatchEvent(html.PointerEvent('pointermove', {
        'pointerId': 1,
        'button': 1,
      }));

      expect(packets, hasLength(1));
      expect(packets.single.data, hasLength(2));

      expect(packets.single.data[0].change, equals(ui.PointerChange.add));
      expect(packets.single.data[1].change, equals(ui.PointerChange.hover));
    });

    test('does not create an add event if got a pointerdown', () {
      List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      glassPane.dispatchEvent(html.PointerEvent('pointerdown', {
        'pointerId': 1,
        'button': 1,
      }));

      expect(packets, hasLength(1));
      expect(packets.single.data, hasLength(1));

      expect(packets.single.data[0].change, equals(ui.PointerChange.down));
    });
  });
}

class TestPointerDetector extends PointerSupportDetector {
  @override
  final bool hasPointerEvents = true;

  @override
  final bool hasTouchEvents = false;

  @override
  final bool hasMouseEvents = false;
}
