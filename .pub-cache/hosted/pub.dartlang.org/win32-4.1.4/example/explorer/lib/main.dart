import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:win32/win32.dart';

import 'models/winver.dart';
import 'volumepanel.dart';
import 'windowroundingselector.dart';

void main() {
  runApp(ExplorerApp());
}

class ExplorerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  bool showRoundedCornerSwitch = false;

  @override
  void initState() {
    showRoundedCornerSwitch = isWindows11();

    super.initState();
  }

  void showDocumentsPath() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final hwnd = GetForegroundWindow();
    final pMessage = 'Path: ${appDocDir.path}'.toNativeUtf16();
    final pTitle = 'Application Documents'.toNativeUtf16();

    MessageBox(hwnd, pMessage, pTitle, MB_OK);

    free(pMessage);
    free(pTitle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Unsupported on Windows as of Flutter 3. Adding in preparation for later
      // releases.
      body: PlatformMenuBar(
        menus: [
          PlatformMenu(label: 'Explore', menus: [
            PlatformMenuItemGroup(members: [
              PlatformMenuItem(
                label: 'Show Docs Path...',
                shortcut: const SingleActivator(LogicalKeyboardKey.keyP,
                    control: true, shift: true),
                onSelected: () async => showDocumentsPath(),
              )
            ])
          ])
        ],
        child: Column(
          children: [
            if (showRoundedCornerSwitch) const WindowRoundingSelector(),
            Expanded(child: VolumePanel()),

            // Can be removed when PlatformMenuBar is supported on Windows.
            FloatingActionButton(
                mini: true,
                child: const Icon(Icons.folder),
                onPressed: () async => showDocumentsPath()),
          ],
        ),
      ),
    );
  }
}
