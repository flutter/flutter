// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'cupertino_navigation_demo.dart' show coolColorNames;

const double _kPickerSheetHeight = 216.0;
const double _kPickerItemHeight = 32.0;

class CupertinoPickerDemo extends StatefulWidget {
  static const String routeName = '/cupertino/picker';

  @override
  _CupertinoPickerDemoState createState() => _CupertinoPickerDemoState();
}

class _CupertinoPickerDemoState extends State<CupertinoPickerDemo> {
  int _selectedColorIndex = 0;

  Duration timer = Duration();

  Widget _buildMenu(List<Widget> children) {
    return Container(
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFBCBBC1), width: 0.0),
          bottom: BorderSide(color: Color(0xFFBCBBC1), width: 0.0),
        ),
      ),
      height: 44.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SafeArea(
          top: false,
          bottom: false,
          child: DefaultTextStyle(
            style: const TextStyle(
              letterSpacing: -0.24,
              fontSize: 17.0,
              color: CupertinoColors.black,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    final FixedExtentScrollController scrollController =
      FixedExtentScrollController(initialItem: _selectedColorIndex);
    return CupertinoPicker(
      scrollController: scrollController,
      itemExtent: _kPickerItemHeight,
      backgroundColor: CupertinoColors.white,
      onSelectedItemChanged: (int index) {
        setState(() {
          _selectedColorIndex = index;
        });
      },
      children: List<Widget>.generate(coolColorNames.length, (int index) {
        return Center(child:
        Text(coolColorNames[index]),
        );
      }),
    );
  }

  Widget _buildBottomPicker(Widget picker) {
    return Container(
      height: _kPickerSheetHeight,
      color: CupertinoColors.white,
      child: DefaultTextStyle(
        style: const TextStyle(
          color: CupertinoColors.black,
          fontSize: 22.0,
        ),
        child: GestureDetector(
          // Blocks taps from propagating to the modal sheet and popping.
          onTap: () {},
          child: SafeArea(
            child: picker,
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownTimerPicker(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showCupertinoModalPopup<void>(
          context: context,
          builder: (BuildContext context) {
            return _buildBottomPicker(
              CupertinoTimerPicker(
                initialTimerDuration: timer,
                onTimerDurationChanged: (Duration newTimer) {
                  setState(() {
                    timer = newTimer;
                  });
                },
              ),
            );
          },
        );
      },
      child: _buildMenu(
          <Widget>[
            const Text('Countdown Timer'),
            Text(
              '${timer.inHours}:'
                '${(timer.inMinutes % 60).toString().padLeft(2,'0')}:'
                '${(timer.inSeconds % 60).toString().padLeft(2,'0')}',
              style: const TextStyle(color: CupertinoColors.inactiveGray),
            ),
          ]
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cupertino Picker'),
      ),
      body: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: '.SF UI Text',
          fontSize: 17.0,
          color: CupertinoColors.black,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFFEFEFF4)),
          child: ListView(
            children: <Widget>[
              const Padding(padding: EdgeInsets.only(top: 32.0)),
              GestureDetector(
                onTap: () async {
                  await showCupertinoModalPopup<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return _buildBottomPicker(_buildColorPicker());
                    },
                  );
                },
                child: _buildMenu(
                    <Widget>[
                      const Text('Favorite Color'),
                      Text(
                        coolColorNames[_selectedColorIndex],
                        style: const TextStyle(
                            color: CupertinoColors.inactiveGray
                        ),
                      ),
                    ]
                ),
              ),
              _buildCountdownTimerPicker(context),
            ],
          ),
        ),
      ),
    );
  }
}