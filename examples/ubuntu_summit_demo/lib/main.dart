import 'dart:async';

import 'package:ubuntu_summit_demo/popup_menu.dart';
import 'package:ubuntu_summit_demo/regular.dart';
import 'package:ubuntu_summit_demo/satellite.dart';

import 'toolbar.dart';
import 'package:flutter/material.dart';

StreamController<ThemeData> _themeStream = StreamController();

void main() {
  runWidget(MultiWindowApp(
    initialWindows: [
      (BuildContext context) => createRegular(
          context: context,
          size: const Size(800, 600),
          builder: (BuildContext context) => const MyApp())
    ],
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ThemeData>(
        initialData: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        stream: _themeStream.stream,
        builder: (BuildContext context, AsyncSnapshot<ThemeData> data) {
          return MaterialApp(
            title: 'Ubuntu Summit Demo 2024.10',
            theme: data.data!,
            home: Home(),
          );
        });
  }
}

class Home extends StatefulWidget {
  Home({super.key});

  @override
  State<StatefulWidget> createState() {
    return _HomeState();
  }
}

class _HomeState extends State<Home> {
  // final _satelliteWindowCreatorController = WindowCreatorController();
  Window? satellite;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: <Widget>[
        Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Toolbar(onBackgroundColorSelected: _onColorChanged),
        ]),
        Expanded(
            child: Center(
                child: ListView(shrinkWrap: true, children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                  child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[PopupMenu()],
                  ),
                  const ListTile(
                    leading: Tooltip(
                        message: "I am a very long and interesting tooltip!",
                        child: Icon(Icons.info)),
                    title: Text('Ubuntu Summit Multi-Window Demo'),
                    subtitle: Text('Brought to you buy the Mir team.'),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(
                        child: const Text('About'),
                        onPressed: () {
                          showAboutDialog(context: context);
                        },
                      ),
                      const SizedBox(width: 8),
                      // WindowCreator(
                      //   builder: (BuildContext context, Window window) {
                      //     const WindowPositioner positioner = WindowPositioner(
                      //       parentAnchor: WindowPositionerAnchor.right,
                      //       childAnchor: WindowPositionerAnchor.left,
                      //     );
                      //     return createSatelliteWindow(
                      //         context: context,
                      //         parent: window,
                      //         size: const Size(200, 500),
                      //         positioner: positioner,
                      //         builder: (BuildContext context) {
                      //           return Satellite();
                      //         });
                      //   },
                      //   controller: _satelliteWindowCreatorController,
                      //   child: ,
                      // ),
                      ViewAnchor(
                          view: satellite == null
                              ? null
                              : View(
                                  view: satellite!.view,
                                  child: satellite!.builder(context),
                                ),
                          child: TextButton(
                            child: const Text('Open Toolbar'),
                            onPressed: () async {
                              if (satellite != null) {
                                return;
                              }

                              const WindowPositioner positioner =
                                  WindowPositioner(
                                parentAnchor: WindowPositionerAnchor.right,
                                childAnchor: WindowPositionerAnchor.left,
                              );
                              final window = await createSatellite(
                                  context: context,
                                  parent: WindowContext.of(context)!.window,
                                  size: const Size(200, 500),
                                  positioner: positioner,
                                  builder: (BuildContext context) {
                                    return Satellite();
                                  });
                              setState(() => satellite = window);
                              window.destroyedStream.listen((void v) {
                                setState(() {
                                  satellite = null;
                                });
                              });
                            },
                          )),
                      const SizedBox(width: 8),
                      TextButton(
                        child: const Text('Open Second Window'),
                        onPressed: () async {
                          await createRegular(
                              context: context,
                              size: const Size(400, 300),
                              builder: (BuildContext context) {
                                return Regular();
                              });
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              )))
        ]))),
      ],
    ));
  }

  void _onColorChanged(Color color) {
    _themeStream.add(ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: color),
      useMaterial3: true,
    ));
  }
}
