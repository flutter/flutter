// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/flex.dart';
import 'package:sky/rendering/sky_binding.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/material.dart';
import 'package:sky/widgets/raised_button.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/task_description.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/tool_bar.dart';
import 'package:sky/widgets/widget.dart';

import '../rendering/sector_layout.dart';

RenderBox initCircle() {
  return new RenderBoxToRenderSectorAdapter(
    innerRadius: 25.0,
    child: new RenderSectorRing(padding: 0.0)
  );
}

class SectorApp extends App {

  RenderBoxToRenderSectorAdapter sectors = initCircle();
  math.Random rand = new math.Random(1);

  void addSector() {
    double deltaTheta;
    var ring = (sectors.child as RenderSectorRing);
    SectorDimensions currentSize = ring.getIntrinsicDimensions(const SectorConstraints(), ring.deltaRadius);
    if (currentSize.deltaTheta >= kTwoPi - (math.PI * 0.2 + 0.05))
      deltaTheta = kTwoPi - currentSize.deltaTheta;
    else
      deltaTheta = math.PI * rand.nextDouble() / 5.0 + 0.05;
    Color color = new Color(((0xFF << 24) + rand.nextInt(0xFFFFFF)) | 0x808080);
    ring.add(new RenderSolidColor(color, desiredDeltaTheta: deltaTheta));
    updateEnabledState();
  }

  void removeSector() {
    (sectors.child as RenderSectorRing).remove((sectors.child as RenderSectorRing).lastChild);
    updateEnabledState();
  }

  static RenderBox initSector(Color color) {
    RenderSectorRing ring = new RenderSectorRing(padding: 1.0);
    ring.add(new RenderSolidColor(const Color(0xFF909090), desiredDeltaTheta: kTwoPi * 0.15));
    ring.add(new RenderSolidColor(const Color(0xFF909090), desiredDeltaTheta: kTwoPi * 0.15));
    ring.add(new RenderSolidColor(color, desiredDeltaTheta: kTwoPi * 0.2));
    return new RenderBoxToRenderSectorAdapter(
      innerRadius: 5.0,
      child: ring
    );
  }
  RenderBoxToRenderSectorAdapter sectorAddIcon = initSector(const Color(0xFF00DD00));
  RenderBoxToRenderSectorAdapter sectorRemoveIcon = initSector(const Color(0xFFDD0000));

  bool enabledAdd = true;
  bool enabledRemove = false;
  void updateEnabledState() {
    setState(() {
      var ring = (sectors.child as RenderSectorRing);
      SectorDimensions currentSize = ring.getIntrinsicDimensions(const SectorConstraints(), ring.deltaRadius);
      enabledAdd = currentSize.deltaTheta < kTwoPi;
      enabledRemove = ring.firstChild != null;
    });
  }

  Widget buildBody() {
    return new Material(
      type: MaterialType.canvas,
      child: new Flex([
          new Container(
            padding: new EdgeDims.symmetric(horizontal: 8.0, vertical: 25.0),
            child: new Flex([
                new RaisedButton(
                  enabled: enabledAdd,
                  child: new ShrinkWrapWidth(
                    child: new Flex([
                      new Container(
                        padding: new EdgeDims.all(4.0),
                        margin: new EdgeDims.only(right: 10.0),
                        child: new WidgetToRenderBoxAdapter(sectorAddIcon)
                      ),
                      new Text('ADD SECTOR'),
                    ])
                  ),
                  onPressed: addSector
                ),
                new RaisedButton(
                  enabled: enabledRemove,
                  child: new ShrinkWrapWidth(
                    child: new Flex([
                      new Container(
                        padding: new EdgeDims.all(4.0),
                        margin: new EdgeDims.only(right: 10.0),
                        child: new WidgetToRenderBoxAdapter(sectorRemoveIcon)
                      ),
                      new Text('REMOVE SECTOR'),
                    ])
                  ),
                  onPressed: removeSector
                )
              ],
              justifyContent: FlexJustifyContent.spaceAround
            )
          ),
          new Flexible(
            child: new Container(
              margin: new EdgeDims.all(8.0),
              decoration: new BoxDecoration(
                border: new Border.all(new BorderSide(color: new Color(0xFF000000)))
              ),
              padding: new EdgeDims.all(8.0),
              child: new WidgetToRenderBoxAdapter(sectors)
            )
          ),
        ],
        direction: FlexDirection.vertical,
        justifyContent: FlexJustifyContent.spaceBetween
      )
    );
  }

  Widget build() {
    return new Theme(
      data: new ThemeData.light(),
      child: new TaskDescription(
        label: 'Sector Layout',
        child: new Scaffold(
          toolbar: new ToolBar(
            center: new Text('Sector Layout in a Widget Tree')
          ),
          body: buildBody()
        )
      )
    );
  }
}

void main() {
  runApp(new SectorApp());
  SkyBinding.instance.onFrame = () {
    // uncomment this for debugging:
    // SkyBinding.instance.debugDumpRenderTree();
  };
}
