// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Thanks for checking out Flutter!
// Like what you see? Tweet us @FlutterDev

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() => runApp(const TestDurationApp());

class TestDurationApp extends StatelessWidget {
  const TestDurationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: const Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () {
                    showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.timelapse),
                  onPressed: () {
                    showDurationPicker(
                      context: context,
                      initialDuration: Duration.zero,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: () {
                    showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(DateTime.now().year + 1));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: () {
                    showDateRangePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(DateTime.now().year + 1));
                  },
                ),
              ],
            ),
            const DurationPickerDialog(
              durationPickerMode: DurationPickerMode.hms,
            ),
            const DurationPickerDialog(
                durationPickerMode: DurationPickerMode.ms),
            CupertinoTimerPicker(
              mode: CupertinoTimerPickerMode.hms,
              onTimerDurationChanged: (Duration value) {
                print(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
