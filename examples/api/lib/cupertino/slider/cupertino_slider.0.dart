// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for CupertinoSlider

import 'package:flutter/cupertino.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: _title,
      home: CupertinoSliderSample(),
    );
  }
}

class CupertinoSliderSample extends StatefulWidget {
  const CupertinoSliderSample({Key? key}) : super(key: key);

  @override
  State<CupertinoSliderSample> createState() => _CupertinoSliderSampleState();
}

class _CupertinoSliderSampleState extends State<CupertinoSliderSample> {
  double _currentSliderValue =  0.0;
  String? _sliderStatus;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Display the current slider value.
            Text('$_currentSliderValue'),
            CupertinoSlider(
              key: const Key('slider'),
              value: _currentSliderValue,
              // This allows the slider to jump between divisions.
              // If null, the slide movement is continuous.
              divisions: 5,
              // The maximum slider value
              max: 100,
              activeColor: CupertinoColors.systemPurple,
              thumbColor: CupertinoColors.systemPurple,
              // This is called when sliding is started.
              onChangeStart: (double value) {
                setState(() {
                  _sliderStatus = 'Sliding';
                });
              },
              // This is called when sliding has ended.
              onChangeEnd: (double value) {
                setState(() {
                  _sliderStatus = 'Finished sliding';
                });
              },
              // This is called when slider value is changed.
              onChanged: (double value) {
                setState(() {
                  _currentSliderValue = value;
                });
              },
            ),
            Text(
              _sliderStatus ?? '',
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
