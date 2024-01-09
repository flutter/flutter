// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [StepStyle].

void main() => runApp(const StepStyleExampleApp());

class StepStyleExampleApp extends StatelessWidget {

  const StepStyleExampleApp({ super.key });

   @override
   Widget build(BuildContext context) {
       return MaterialApp(
         home: Scaffold(
             appBar: AppBar(title: const Text('Step Style Example')),
             body: const Center(
                 child: StepStyleExample(),
             ),
         ),
       );
  }
}

class StepStyleExample extends StatefulWidget {
  const StepStyleExample({ super.key });

   @override
   State<StepStyleExample> createState() => _StepStyleExampleState();
}


class _StepStyleExampleState extends State<StepStyleExample> {

   @override
   Widget build(BuildContext context) {
      return Stepper(
      type: StepperType.horizontal,
      stepIconHeight: 48,
      stepIconWidth: 48,
      stepIconMargin: EdgeInsets.zero,
      steps: <Step>[
        Step(
          title: const SizedBox.shrink(),
          content: const SizedBox.shrink(),
          isActive: true,
          stepStyle: StepStyle(
            connectorThickness: 10,
            color: Colors.white,
            connectorColor: Colors.red,
            indexStyle: const TextStyle(
              color: Colors.black,
              fontSize: 20,
            ),
            border: Border.all(
              width: 2
            ),
          ),
        ),
        const Step(
          title: SizedBox.shrink(),
          content: SizedBox.shrink(),
          isActive: true,
          stepStyle: StepStyle(
            connectorColor: Colors.orange,
            connectorThickness: 10,
            gradient: LinearGradient(
              colors: <Color>[
                Colors.white,
                Colors.black,
              ],
            ),

          )
        ),
        Step(
          title: const SizedBox.shrink(),
          content: const SizedBox.shrink(),
          isActive: true,
          stepStyle: StepStyle(
            color: Colors.white,
            connectorColor: Colors.blue,
            connectorThickness: 10,
            indexStyle: const TextStyle(
              color: Colors.black,
              fontSize: 20,
            ),
            border: Border.all(
              width: 2,
            ),
          ),
        ),
        Step(
          title: const SizedBox.shrink(),
          content: const SizedBox.shrink(),
          isActive: true,
          stepStyle: StepStyle(
            color: Colors.white,
            indexStyle: const TextStyle(
              color: Colors.black,
              fontSize: 20,
            ),
            border: Border.all(
              width: 2,
            ),
          ),
        ),
      ],
    );
  }
}
