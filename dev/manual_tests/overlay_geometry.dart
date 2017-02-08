// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CardModel {
  CardModel(this.value, this.height, this.color);
  int value;
  double height;
  Color color;
  String get label => "Card $value";
  Key get key => new ObjectKey(this);
  GlobalKey get targetKey => new GlobalObjectKey(this);
}

enum MarkerType { topLeft, bottomRight, touch }

class _MarkerPainter extends CustomPainter {
  const _MarkerPainter({
    this.size,
    this.type
  });

  final double size;
  final MarkerType type;

  @override
  void paint(Canvas canvas, _) {
    Paint paint = new Paint()..color = const Color(0x8000FF00);
    double r = size / 2.0;
    canvas.drawCircle(new Point(r, r), r, paint);

    paint
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    if (type == MarkerType.topLeft) {
      canvas.drawLine(new Point(r, r), new Point(r + r - 1.0, r), paint);
      canvas.drawLine(new Point(r, r), new Point(r, r + r - 1.0), paint);
    }
    if (type == MarkerType.bottomRight) {
      canvas.drawLine(new Point(r, r), new Point(1.0, r), paint);
      canvas.drawLine(new Point(r, r), new Point(r, 1.0), paint);
    }
  }

  @override
  bool shouldRepaint(_MarkerPainter oldPainter) {
    return oldPainter.size != size
        || oldPainter.type != type;
  }
}

class Marker extends StatelessWidget {
  Marker({
    this.type: MarkerType.touch,
    this.position,
    this.size: 40.0,
    Key key
  }) : super(key: key);

  final Point position;
  final double size;
  final MarkerType type;

  @override
  Widget build(BuildContext context) {
    return new Positioned(
      left: position.x - size / 2.0,
      top: position.y - size / 2.0,
      width: size,
      height: size,
      child: new IgnorePointer(
        child: new CustomPaint(
          painter: new _MarkerPainter(
            size: size,
            type: type
          )
        )
      )
    );
  }
}

class OverlayGeometryApp extends StatefulWidget {
  @override
  OverlayGeometryAppState createState() => new OverlayGeometryAppState();
}

typedef void CardTapCallback(GlobalKey targetKey, Point globalPosition);

class CardBuilder extends LazyBlockDelegate {
  CardBuilder({ this.cardModels, this.onTapUp });

  final List<CardModel> cardModels;
  final CardTapCallback onTapUp;

  static const TextStyle cardLabelStyle =
    const TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold);

  @override
  Widget buildItem(BuildContext context, int index) {
    if (index >= cardModels.length)
      return null;
    CardModel cardModel = cardModels[index];
    return new GestureDetector(
      key: cardModel.key,
      onTapUp: (TapUpDetails details) { onTapUp(cardModel.targetKey, details.globalPosition); },
      child: new Card(
        key: cardModel.targetKey,
        color: cardModel.color,
        child: new Container(
          height: cardModel.height,
          padding: const EdgeInsets.all(8.0),
          child: new Center(child: new Text(cardModel.label, style: cardLabelStyle))
        )
      )
    );
  }

  @override
  bool shouldRebuild(CardBuilder oldDelegate) {
    return oldDelegate.cardModels != cardModels;
  }

  @override
  double estimateTotalExtent(int firstIndex, int lastIndex, double minOffset, double firstStartOffset, double lastEndOffset) {
    return (lastEndOffset - minOffset) * cardModels.length / (lastIndex + 1);
  }
}

class OverlayGeometryAppState extends State<OverlayGeometryApp> {
  List<CardModel> cardModels;
  Map<MarkerType, Point> markers = new Map<MarkerType, Point>();
  double markersScrollOffset = 0.0;
  ScrollListener scrollListener;

  @override
  void initState() {
    super.initState();
    List<double> cardHeights = <double>[
      48.0, 63.0, 82.0, 146.0, 60.0, 55.0, 84.0, 96.0, 50.0,
      48.0, 63.0, 82.0, 146.0, 60.0, 55.0, 84.0, 96.0, 50.0,
      48.0, 63.0, 82.0, 146.0, 60.0, 55.0, 84.0, 96.0, 50.0
    ];
    cardModels = new List<CardModel>.generate(cardHeights.length, (int i) {
      Color color = Color.lerp(Colors.red[300], Colors.blue[900], i / cardHeights.length);
      return new CardModel(i, cardHeights[i], color);
    });
  }

  void handleScroll(double offset) {
    setState(() {
      double dy = markersScrollOffset - offset;
      markersScrollOffset = offset;
      for (MarkerType type in markers.keys) {
        Point oldPosition = markers[type];
        markers[type] = new Point(oldPosition.x, oldPosition.y + dy);
      }
    });
  }

  void handleTapUp(GlobalKey target, Point globalPosition) {
    setState(() {
      markers[MarkerType.touch] = globalPosition;
      final RenderBox box = target.currentContext.findRenderObject();
      markers[MarkerType.topLeft] = box.localToGlobal(new Point(0.0, 0.0));
      final Size size = box.size;
      markers[MarkerType.bottomRight] = box.localToGlobal(new Point(size.width, size.height));
      final ScrollableState scrollable = Scrollable.of(target.currentContext);
      markersScrollOffset = scrollable.scrollOffset;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> layers = <Widget>[
      new Scaffold(
        appBar: new AppBar(title: new Text('Tap a Card')),
        body: new Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: new LazyBlock(
            onScroll: handleScroll,
            delegate: new CardBuilder(
              cardModels: cardModels,
              onTapUp: handleTapUp
            )
          )
        )
      )
    ];
    for (MarkerType type in markers.keys)
      layers.add(new Marker(type: type, position: markers[type]));
    return new Stack(children: layers);
  }
}

void main() {
  runApp(new MaterialApp(
    theme: new ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      accentColor: Colors.redAccent[200]
    ),
    title: 'Cards',
    home: new OverlayGeometryApp()
  ));
}
