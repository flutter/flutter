// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show base64Decode;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// A 100x100 png in Display P3 colorspace.
const String _displayP3Logo =
    'iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAYAAABw4pVUAAABdWlDQ1BrQ0dDb2xvclNwYWNlRG'
    'lzcGxheVAzAAAokXWQvUvDUBTFT6tS0DqIDh0cMolD1NIKdnFoKxRFMFQFq1OafgltfCQpUnET'
    'Vyn4H1jBWXCwiFRwcXAQRAcR3Zw6KbhoeN6XVNoi3sfl/Ticc7lcwBtQGSv2AijplpFMxKS11L'
    'rke4OHnlOqZrKooiwK/v276/PR9d5PiFlNu3YQ2U9cl84ul3aeAlN//V3Vn8maGv3f1EGNGRbg'
    'kYmVbYsJ3iUeMWgp4qrgvMvHgtMunzuelWSc+JZY0gpqhrhJLKc79HwHl4plrbWD2N6f1VeXxR'
    'zqUcxhEyYYilBRgQQF4X/8044/ji1yV2BQLo8CLMpESRETssTz0KFhEjJxCEHqkLhz634PrfvJ'
    'bW3vFZhtcM4v2tpCAzidoZPV29p4BBgaAG7qTDVUR+qh9uZywPsJMJgChu8os2HmwiF3e38M6H'
    'vh/GMM8B0CdpXzryPO7RqFn4Er/QcXKWq8UwZBywAAAJplWElmTU0AKgAAAAgABQESAAMAAAAB'
    'AAEAAAEaAAUAAAABAAAASgEbAAUAAAABAAAAUgExAAIAAAAhAAAAWodpAAQAAAABAAAAfAAAAA'
    'AAAABIAAAAAQAAAEgAAAABQWRvYmUgUGhvdG9zaG9wIDI0LjEgKE1hY2ludG9zaCkAAAACoAIA'
    'BAAAAAEAAABkoAMABAAAAAEAAABkAAAAALGpdjYAAAAJcEhZcwAACxMAAAsTAQCanBgAAAR2aV'
    'RYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1l'
    'dGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaH'
    'R0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICAgIDxyZGY6'
    'RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiCiAgICAgICAgICAgIHhtbG5zOnRpZmY9Imh0dHA6Ly'
    '9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIgogICAgICAgICAgICB4bWxuczp4bXBNTT0iaHR0cDov'
    'L25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIKICAgICAgICAgICAgeG1sbnM6c3RSZWY9Imh0dH'
    'A6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiCiAgICAgICAgICAg'
    'IHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyI+CiAgICAgICAgIDx0aW'
    'ZmOllSZXNvbHV0aW9uPjcyPC90aWZmOllSZXNvbHV0aW9uPgogICAgICAgICA8dGlmZjpYUmVz'
    'b2x1dGlvbj43MjwvdGlmZjpYUmVzb2x1dGlvbj4KICAgICAgICAgPHRpZmY6T3JpZW50YXRpb2'
    '4+MTwvdGlmZjpPcmllbnRhdGlvbj4KICAgICAgICAgPHhtcE1NOkRlcml2ZWRGcm9tIHJkZjpw'
    'YXJzZVR5cGU9IlJlc291cmNlIj4KICAgICAgICAgICAgPHN0UmVmOmluc3RhbmNlSUQ+eG1wLm'
    'lpZDpDREE0Mzc3NzhBRjcxMUVEQTU0N0JCNjBEMjUwOTI2RDwvc3RSZWY6aW5zdGFuY2VJRD4K'
    'ICAgICAgICAgICAgPHN0UmVmOmRvY3VtZW50SUQ+eG1wLmRpZDpDREE0Mzc3ODhBRjcxMUVEQT'
    'U0N0JCNjBEMjUwOTI2RDwvc3RSZWY6ZG9jdW1lbnRJRD4KICAgICAgICAgPC94bXBNTTpEZXJp'
    'dmVkRnJvbT4KICAgICAgICAgPHhtcE1NOkRvY3VtZW50SUQ+eG1wLmRpZDpDREE0Mzc3QThBRj'
    'cxMUVEQTU0N0JCNjBEMjUwOTI2RDwveG1wTU06RG9jdW1lbnRJRD4KICAgICAgICAgPHhtcE1N'
    'Okluc3RhbmNlSUQ+eG1wLmlpZDpDREE0Mzc3OThBRjcxMUVEQTU0N0JCNjBEMjUwOTI2RDwveG'
    '1wTU06SW5zdGFuY2VJRD4KICAgICAgICAgPHhtcDpDcmVhdG9yVG9vbD5BZG9iZSBQaG90b3No'
    'b3AgMjQuMSAoTWFjaW50b3NoKTwveG1wOkNyZWF0b3JUb29sPgogICAgICA8L3JkZjpEZXNjcm'
    'lwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KRm6gbQAABNpJREFUeAHtnOty3CAM'
    'hZO2Pzrt+z9qO/3RS/iSOVPGwcTrFZLwoqlDfUPifAgc75Lnf09P5d+yLAp8yhLIiuNNgQUkWU'
    '9YQBaQZAokC2dlyAKSTIFk4awMWUCSKZAsnJUhyYB8SRbPkHB4FfG3bM8DaqduerVV3ZcFglCI'
    '9KdsP8tm/X6IuoH8uWzfyraAFBH2rIbxo1yk/b3rzxwXjO/lZisYxHG5OUTikxmjYOCDzLCGUa'
    'q8FpDZYVwKSAQMfFrbJYasKBiWc4fATg8kAgbijYBBvVMDiYKBcKNsWiARMPA52qYEEgVj1DBV'
    'Q54OSAQMBPOAgZ+pgETA8BimACGbBkgUDK/MmArIo8AAynNprHdWqjPcVM76buqmRpaLUw9Z6i'
    'meMOTzViGtrk8LBGEYv71heM8ZW5ApgUTAQJhoGMSQDkgUDMTIYKmARMDAZyZLAyQKRoZhqu4Q'
    'KYBEwECEbDCIKRxIFAwan9FCgUTAwGdmCwMSBSPjMFV3kBAgETBodHYYxOgOJAJG9mEKEDJXIF'
    'EwZsgMdyALhiTvly4ZsmD0IdRnhwOJgEEDZxqm3IBEwMDnzDYsQ6JgzJoZ6kRDgCwYkvf20hxI'
    'BAyaPXtmCJ3pkrYIGPKpBrVKrhm5xpDOYNWzTYEQWJbPwAWKeDzWGBY3JmYF9jUYTxg43Bumtj'
    'DIDmujTsRjwaeliGYZ4g2jJ7B3pvZiufWcGVzLcbRuBL396AJLrsUydY63iI7/NANCRaxKRTwJ'
    'czyM9pVbGL16OeedGb142i36+KgZEFwhCGOqBZQWDOpvWQ1DE/jeta37jxzbxsM91j6o0xQIQV'
    'tkyi2Nr2GwLn3E463isfyLDYjfMlMg9BgJdHb4UuO1KJ/9PZMvrznDVKydRpn7uAdKC8besOAN'
    'Q+3a0dHssDkQIlPwlEczZQtD9VBuLQrGXufYxnfP/hAgBHQLlBaMvUZFwFB79mKyPD4MiBohAf'
    'cy5SwMr6cp4vO0oUBoSC9TtjB6jeccdWkCH/k0VT9QeAxT6CRzW9ImQSl5PP1dNt7bqPHlv7um'
    'ewVD+7s3nDhBnUffCJyo/vAtbkCISELSu3+V7WvZPkpR3fMIMIocuRd9RsCQT8SJsI86aERMrz'
    '4lDJnhOYF7zxlbgc1ev28rvme/huH5Z/qiYaBZugyJgnFPB7K8Nx0QeimT/sjMoNF6uqMDZLJ0'
    'Q5bn05SyMROQlBkyciwHAhmY1Vx/DzkqAqIxZJEt1nCUFfWrHGsfR9vZui5dhrQEawV+9hjib4'
    'Gzn8XSAZFglHUvthRMPuoszAIlHRCERzDsEaGkBPKG4/+7L89Mke+oMjWQiEwBROTwlRqIeikC'
    'PcrwNQWQiEzBZ0SmTAEkMlPk26ucCkhEpgDCM1OmAqJeeuU5ZUogGt8pPR+JPTJlSiBkShQUZe'
    'moclogUVDwOzJTpgYSBUXZiX9rmx4IgkigK8wplwAiKCpnnugvAwQYmNcjMV9NGvEBWspPDF+V'
    'veOHoFDqM487qnt3a2uIfHfRyQOXBFJrARR6s+WXs2vgwLFcq355IIKDiCMNMBaW7mtAFo1q1W'
    'ElWKtuy2OXm9QtxYmoawGJUL3jcwHpiBNxagGJUL3jcwHpiBNxagGJUL3jcwHpiBNxagGJUL3j'
    'cwHpiBNx6gU/2fLWVmm7wQAAAABJRU5ErkJggg==';

void main() => run(Setup.canvasSaveLayer);

enum Setup {
  image,
  canvasSaveLayer,
}

void run(Setup setup) {
  runApp(MyApp(setup));
}

class MyApp extends StatelessWidget {
  const MyApp(this._setup, {super.key});

  final Setup _setup;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wide Gamut Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(_setup, title: 'Wide Gamut Test'),
    );
  }
}

class _SaveLayerDrawer extends CustomPainter {
  _SaveLayerDrawer(this._image);

  final ui.Image? _image;

  @override
  void paint(Canvas canvas, Size size) {
    if (_image != null) {
      final Rect imageRect = Rect.fromCenter(
          center: Offset.zero,
          width: _image!.width.toDouble(),
          height: _image!.height.toDouble());
      canvas.saveLayer(
          imageRect,
          Paint());
      canvas.drawRect(
          imageRect.inflate(-_image!.width.toDouble() / 4.0),
          Paint()
            ..style = PaintingStyle.stroke
            ..color = const Color(0xffffffff)
            ..strokeWidth = 3);
      canvas.saveLayer(
          imageRect,
          Paint()..blendMode = BlendMode.multiply);
      canvas.drawImage(_image!,
          Offset(-_image!.width / 2.0, -_image!.height / 2.0), Paint());
      canvas.restore();
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

Future<ui.Image> _loadImage() async {
  final ui.ImmutableBuffer buffer =
      await ui.ImmutableBuffer.fromUint8List(base64Decode(_displayP3Logo));
  final ui.ImageDescriptor descriptor =
      await ui.ImageDescriptor.encoded(buffer);
  final ui.Codec codec = await descriptor.instantiateCodec();
  return (await codec.getNextFrame()).image;
}

class MyHomePage extends StatefulWidget {
  const MyHomePage(this.setup, {super.key, required this.title});

  final Setup setup;
  final String title;

  @override
  State<StatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ui.Image? _image;

  @override
  void initState() {
    if (widget.setup == Setup.canvasSaveLayer) {
      _loadImage().then((ui.Image? value) {
        setState(() {
          _image = value;
        });
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    late Widget imageWidget;
    switch (widget.setup) {
      case Setup.image:
        imageWidget = Image.memory(base64Decode(_displayP3Logo));
        break;
      case Setup.canvasSaveLayer:
        imageWidget = CustomPaint(painter: _SaveLayerDrawer(_image));
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            imageWidget,
          ],
        ),
      ),
    );
  }
}
