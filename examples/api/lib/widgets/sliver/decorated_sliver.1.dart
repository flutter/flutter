
import 'package:flutter/material.dart';

// Flutter code example for [DecoratedSliver]
// with clipping turned off in a parent [CustomScrollView]

void main() => runApp(const DecoratedSliverClipExampleApp());


// This is a height-resizable window
// simulating a browser window with [CustomScrollView]
// to dynamically adjust the window height
// using Slider at the top.
// This allows testing how the [DecoratedSliver]
// behaves while resizing of browser window
// that is, when it doesn’t entirely fit within the viewport,
// demonstrating the effects of disabling parent clipping.

class DecoratedSliverClipExampleApp extends StatelessWidget {
  const DecoratedSliverClipExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DecoratedSliver Clip Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DecoratedSliverClipExample(),
    );
  }
}

class DecoratedSliverClipExample extends StatefulWidget {
  const DecoratedSliverClipExample({super.key});



  @override
  State<DecoratedSliverClipExample> createState() => _DecoratedSliverClipExampleState();
}

class _DecoratedSliverClipExampleState extends State<DecoratedSliverClipExample> {
  double _height = 225.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1C1C1C),
      body: Column(
        children: [
          Slider(
            activeColor: Colors.pink,
            inactiveColor: Colors.cyan,
            onChanged: (value) {
              setState(() {
                _height = value;
              });
            },
            value: _height,
            min: 150,
            max: 225,
          ),
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 400,
                  height: _height,
        // Parent [CustomScrollView] see below for implementation
                  child: const ResizableCustomScrollView(),
                ),
              ),
              Positioned(
                  top: _height,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - _height,
                    width: double.infinity,
                  ))
            ],
          ),
        ],
      ),
    );
  }
}


// Main [CustomScrollView]
// [clipBehavior] is set to [Clip.none]
// allowing decoration properties particularly [shadows]
// to render outside the widget's boundary
// and to persists and without being clipped.

class ResizableCustomScrollView extends StatelessWidget {
  const ResizableCustomScrollView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      clipBehavior: Clip.none, // defaults to Clip.hardEdge
      slivers: [
        DecoratedSliver(
          decoration: const ShapeDecoration(
            color: Color(0xFF2C2C2C),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(6)),
            ),
            shadows: <BoxShadow>[
              BoxShadow(
                color: Colors.cyan,
                offset: Offset(3, 3),
                blurRadius: 24,
              ),
            ],
          ),
          sliver: SliverList.builder(
            itemCount: 5,
            itemBuilder: (_, int index) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.add_box,
                      color: Color(0xFFA8A8A8)),
                  Flexible(
                      child: Text('Item $index',
                          style: const TextStyle(
                              color: Color(0xFFA8A8A8)))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}


