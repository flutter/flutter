// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'html.dart';

typedef LineAndPositionSetting = JSAny;
typedef AutoKeyword = String;
typedef DirectionSetting = String;
typedef LineAlignSetting = String;
typedef PositionAlignSetting = String;
typedef AlignSetting = String;
typedef ScrollSetting = String;

@JS('VTTCue')
@staticInterop
class VTTCue implements TextTrackCue {
  external factory VTTCue(
    num startTime,
    num endTime,
    String text,
  );
}

extension VTTCueExtension on VTTCue {
  external DocumentFragment getCueAsHTML();
  external set region(VTTRegion? value);
  external VTTRegion? get region;
  external set vertical(DirectionSetting value);
  external DirectionSetting get vertical;
  external set snapToLines(bool value);
  external bool get snapToLines;
  external set line(LineAndPositionSetting value);
  external LineAndPositionSetting get line;
  external set lineAlign(LineAlignSetting value);
  external LineAlignSetting get lineAlign;
  external set position(LineAndPositionSetting value);
  external LineAndPositionSetting get position;
  external set positionAlign(PositionAlignSetting value);
  external PositionAlignSetting get positionAlign;
  external set size(num value);
  external num get size;
  external set align(AlignSetting value);
  external AlignSetting get align;
  external set text(String value);
  external String get text;
}

@JS('VTTRegion')
@staticInterop
class VTTRegion {
  external factory VTTRegion();
}

extension VTTRegionExtension on VTTRegion {
  external set id(String value);
  external String get id;
  external set width(num value);
  external num get width;
  external set lines(int value);
  external int get lines;
  external set regionAnchorX(num value);
  external num get regionAnchorX;
  external set regionAnchorY(num value);
  external num get regionAnchorY;
  external set viewportAnchorX(num value);
  external num get viewportAnchorX;
  external set viewportAnchorY(num value);
  external num get viewportAnchorY;
  external set scroll(ScrollSetting value);
  external ScrollSetting get scroll;
}
