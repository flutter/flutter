// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(mattkae): remove invalid_use_of_internal_member ignore comment when this API is stable.
// See: https://github.com/flutter/flutter/issues/177586
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports
import 'package:flutter/widgets.dart';
import 'package:flutter/src/widgets/_window.dart';

void main() {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    final WindowController controller = WindowController(
      size: const Size(800, 600),
    );
    runWidget(
      WindowManager(
        initialWindows: <WindowEntry>[
          WindowEntry(
            controller: controller,
            builder: (BuildContext context) => const MainWindow(),
          ),
        ],
      ),
    );
  } on UnsupportedError catch (e) {
    // TODO(mattkae): Remove this catch block when windowing is supported in tests.
    // For now, we need to catch the error so that the API smoke tests pass.
    runApp(
      WidgetsApp(
        color: const Color(0xFFFFFFFF),
        builder: (BuildContext context, Widget? child) {
          return Center(
            child: Text(
              e.message ?? 'Unsupported',
              textDirection: TextDirection.ltr,
            ),
          );
        },
      ),
    );
  }
}

class MainWindow extends StatelessWidget {
  const MainWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: const Color(0xFFFFFFFF),
      builder: (BuildContext context, Widget? child) {
        return Center(
          child: GestureDetector(
            onTap: () => mountToplevelWindow(
              context: context,
              entry: WindowEntry(
                controller: DialogWindowController(
                  parent: WindowScope.of(context),
                  size: const Size(400, 300),
                ),
                builder: (BuildContext context) {
                  return const SizedBox.shrink();
                },
              ),
            ),
            child: const Text(
              'Open a dialog',
              textDirection: TextDirection.ltr,
            ),
          ),
        );
      },
    );
  }
}
