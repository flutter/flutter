// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter_rendering_examples/sector_layout.dart';

RenderBox initCircle() {
  return new RenderBoxToRenderSectorAdapter(
    innerRadius: 25.0,
    child: new RenderSectorRing(padding: 0.0)
  );
}

class SectorApp extends StatefulComponent {
  SectorAppState createState() => new SectorAppState();
}

class SectorAppState extends State<SectorApp> {

  final RenderBoxToRenderSectorAdapter sectors = initCircle();
  final math.Random rand = new math.Random(1);

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

  bool _enabledAdd = true;
  bool _enabledRemove = false;
  void updateEnabledState() {
    setState(() {
      var ring = (sectors.child as RenderSectorRing);
      SectorDimensions currentSize = ring.getIntrinsicDimensions(const SectorConstraints(), ring.deltaRadius);
      _enabledAdd = currentSize.deltaTheta < kTwoPi;
      _enabledRemove = ring.firstChild != null;
    });
  }

  Widget buildBody() {
    return new Column(<Widget>[
        new Container(
          padding: new EdgeDims.symmetric(horizontal: 8.0, vertical: 25.0),
          child: new Row(<Widget>[
              new RaisedButton(
                child: new IntrinsicWidth(
                  child: new Row(<Widget>[
                    new Container(
                      padding: new EdgeDims.all(4.0),
                      margin: new EdgeDims.only(right: 10.0),
                      child: new WidgetToRenderBoxAdapter(sectorAddIcon)
                    ),
                    new Text('ADD SECTOR'),
                  ])
                ),
                onPressed: _enabledAdd ? addSector : null
              ),
              new RaisedButton(
                child: new IntrinsicWidth(
                  child: new Row(<Widget>[
                    new Container(
                      padding: new EdgeDims.all(4.0),
                      margin: new EdgeDims.only(right: 10.0),
                      child: new WidgetToRenderBoxAdapter(sectorRemoveIcon)
                    ),
                    new Text('REMOVE SECTOR'),
                  ])
                ),
                onPressed: _enabledRemove ? removeSector : null
              )
            ],
            justifyContent: FlexJustifyContent.spaceAround
          )
        ),
        new Flexible(
          child: new Container(
            margin: new EdgeDims.all(8.0),
            decoration: new BoxDecoration(
              border: new Border.all(color: new Color(0xFF000000))
            ),
            padding: new EdgeDims.all(8.0),
            child: new WidgetToRenderBoxAdapter(sectors)
          )
        ),
      ],
      justifyContent: FlexJustifyContent.spaceBetween
    );
  }

  Widget build(BuildContext context) {
    return new MaterialApp(
      theme: new ThemeData.light(),
      title: 'Sector Layout',
      routes: <String, RouteBuilder>{
        '/': (RouteArguments args) {
          return new Scaffold(
            toolBar: new ToolBar(
              center: new Text('Sector Layout in a Widget Tree')
            ),
            body: buildBody()
          );
        }
      }
    );
  }
}

void main() {
  runApp(new SectorApp());
}
