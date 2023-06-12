// ignore_for_file: omit_local_variable_types
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'star_wars/planet_screen.dart';
import 'use_effect.dart';
import 'use_state.dart';
import 'use_stream.dart';

void main() => runApp(HooksGalleryApp());

/// An App that demonstrates how to use hooks. It includes examples that cover
/// the hooks provided by this library as well as examples that demonstrate
/// how to write custom hooks.
class HooksGalleryApp extends HookWidget {
  @override
  Widget build(BuildContext context) {
    useAnimationController(duration: const Duration(seconds: 2));
    return MaterialApp(
      title: 'Flutter Hooks Gallery',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Hooks Gallery'),
        ),
        body: ListView(children: [
          _GalleryItem(
            title: 'useState',
            builder: (context) => UseStateExample(),
          ),
          _GalleryItem(
            title: 'useMemoize + useStream',
            builder: (context) => UseStreamExample(),
          ),
          _GalleryItem(
            title: 'Custom Hook Function',
            builder: (context) => CustomHookExample(),
          ),
          _GalleryItem(
            title: 'Star Wars Planets',
            builder: (context) => PlanetScreen(),
          )
        ]),
      ),
    );
  }
}

class _GalleryItem extends StatelessWidget {
  const _GalleryItem({this.title, this.builder});

  final String title;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: builder,
          ),
        );
      },
    );
  }
}
