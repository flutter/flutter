import 'package:flutter/material.dart';
import 'package:switcher/core/switcher_size.dart';
import 'package:switcher/switcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Switcher',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Switcher'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Small',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 50),
                    Switcher(
                      value: false,
                      colorOff: Colors.purple.withOpacity(0.3),
                      colorOn: Colors.purple,
                      onChanged: (bool state) {
                        //
                      },
                      size: SwitcherSize.small,
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Medium',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 20),
                    Switcher(
                      value: false,
                      colorOff: Colors.orange.withOpacity(0.3),
                      colorOn: Colors.orange,
                      size: SwitcherSize.medium,
                      onChanged: (bool state) {
                        //
                      },
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Large',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 20),
                    Switcher(
                      value: false,
                      size: SwitcherSize.large,
                      colorOff: Colors.green.withOpacity(0.3),
                      colorOn: Colors.green,
                      onChanged: (bool state) {
                        //
                      },
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(
              height: 50,
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Small',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 50),
                    Switcher(
                      value: false,
                      size: SwitcherSize.small,
                      colorOff: Colors.amber.withOpacity(0.3),
                      colorOn: Colors.amber,
                      switcherButtonBoxShape: BoxShape.rectangle,
                      onChanged: (bool state) {
                        //
                      },
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Medium',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 20),
                    Switcher(
                      value: false,
                      size: SwitcherSize.medium,
                      colorOff: Colors.blueGrey.withOpacity(0.3),
                      colorOn: Colors.blueGrey,
                      switcherButtonBoxShape: BoxShape.rectangle,
                      onChanged: (bool state) {
                        //
                      },
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Large',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 20),
                    Switcher(
                      value: false,
                      iconOff: null,
                      size: SwitcherSize.large,
                      colorOff: Colors.indigo.withOpacity(0.3),
                      colorOn: Colors.indigo,
                      switcherButtonBoxShape: BoxShape.rectangle,
                      enabledSwitcherButtonRotate: false,
                      onChanged: (bool state) {
                        //
                      },
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(
              height: 50,
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Small',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 50),
                    Switcher(
                      value: false,
                      size: SwitcherSize.small,
                      switcherButtonRadius: 50,
                      switcherButtonAngleTransform: 0,
                      switcherRadius: 0,
                      colorOff: Colors.pink.withOpacity(0.3),
                      colorOn: Colors.pink,
                      onChanged: (bool state) {
                        //
                      },
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Medium',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 20),
                    Switcher(
                      value: false,
                      size: SwitcherSize.medium,
                      switcherButtonRadius: 3,
                      switcherRadius: 0,
                      colorOff: Colors.cyan.withOpacity(0.3),
                      colorOn: Colors.cyan,
                      onChanged: (bool state) {
                        //
                      },
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Large',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 20),
                    Switcher(
                      value: false,
                      size: SwitcherSize.large,
                      switcherButtonRadius: 3,
                      iconOff: null,
                      colorOff: Colors.brown.withOpacity(0.3),
                      colorOn: Colors.brown,
                      onChanged: (bool state) {
                        //
                      },
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(
              height: 50,
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Small',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 50),
                    Switcher(
                      value: false,
                      size: SwitcherSize.small,
                      switcherButtonRadius: 50,
                      switcherButtonAngleTransform: 0,
                      switcherRadius: 0,
                      enabledSwitcherButtonRotate: false,
                      colorOff: Colors.red.withOpacity(0.3),
                      colorOn: Colors.red,
                      onChanged: (bool state) {
                        //
                      },
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Medium',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 20),
                    Switcher(
                      value: false,
                      size: SwitcherSize.medium,
                      switcherButtonRadius: 3,
                      switcherRadius: 0,
                      enabledSwitcherButtonRotate: false,
                      colorOff: Colors.teal.withOpacity(0.3),
                      colorOn: Colors.teal,
                      onChanged: (bool state) {
                        //
                      },
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Large',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 20),
                    Switcher(
                      value: false,
                      size: SwitcherSize.large,
                      switcherButtonRadius: 50,
                      iconOff: null,
                      enabledSwitcherButtonRotate: false,
                      colorOff: Colors.blueGrey.withOpacity(0.3),
                      colorOn: Colors.blue,
                      onChanged: (bool state) {
                        //
                      },
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(
              height: 50,
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Small',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 50),
                    Switcher(
                      value: false,
                      size: SwitcherSize.small,
                      switcherButtonRadius: 50,
                      switcherButtonAngleTransform: 0,
                      switcherRadius: 0,
                      iconOff: Icons.airplanemode_off_sharp,
                      iconOn: Icons.airplanemode_on_sharp,
                      colorOff: Colors.blueGrey.withOpacity(0.3),
                      colorOn: Colors.purple,
                      onChanged: (bool state) {
                        //
                      },
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Medium',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 20),
                    Switcher(
                      value: false,
                      size: SwitcherSize.medium,
                      switcherButtonRadius: 3,
                      switcherRadius: 0,
                      iconOff: Icons.thumb_down_rounded,
                      iconOn: Icons.thumb_up_rounded,
                      colorOff: Colors.blueGrey.withOpacity(0.3),
                      colorOn: Colors.teal,
                      onChanged: (bool state) {
                        //
                      },
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Large',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 20),
                    Switcher(
                      value: false,
                      size: SwitcherSize.large,
                      switcherButtonRadius: 50,
                      enabledSwitcherButtonRotate: true,
                      iconOff: Icons.lock,
                      iconOn: Icons.lock_open,
                      colorOff: Colors.blueGrey.withOpacity(0.3),
                      colorOn: Colors.blue,
                      onChanged: (bool state) {
                        //
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
