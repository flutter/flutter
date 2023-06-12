import 'dart:ui';

import 'package:device_frame/device_frame.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeScreen extends StatelessWidget {
  const FakeScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Container(
      color: Colors.red,
      child: Stack(
        children: [
          Container(
            margin: mediaQuery.viewInsets,
            color: Colors.blue,
          ),
          Container(
            margin: mediaQuery.viewPadding,
            color: Colors.white.withOpacity(0.5),
          ),
          Container(
            margin: mediaQuery.padding,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white,
                width: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('The frame renders correctly for ', () {
    for (var device in Devices.all) {
      testWidgets(device.identifier.toString(), (WidgetTester tester) async {
        tester.binding.window.devicePixelRatioTestValue = device.pixelRatio;
        tester.binding.window.physicalSizeTestValue = Size(
          (device.frameSize.width * 2 +
                  (device.canRotate ? device.frameSize.height * 2 : 0)) *
              device.pixelRatio,
          device.frameSize.height * device.pixelRatio,
        );
        const key = Key("device");
        await tester.pumpWidget(
          MaterialApp(
            home: Row(
              key: key,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var orientation in [
                  if (device.canRotate) Orientation.portrait,
                  Orientation.landscape
                ])
                  for (var isVirtualKeyboardEnabled in [false, true])
                    DeviceFrame(
                      device: device,
                      isFrameVisible: true,
                      orientation: orientation,
                      screen: Container(
                        color: Colors.blue,
                        child: VirtualKeyboard(
                          isEnabled: isVirtualKeyboardEnabled,
                          child: const FakeScreen(),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byKey(key),
          matchesGoldenFile(
            'devices/${device.identifier}.png',
          ),
        );
      });
    }
  });
}
