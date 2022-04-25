// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'picture_cache.dart';

class ClipperCachePage extends StatefulWidget {
  const ClipperCachePage({super.key});
  @override
  State<ClipperCachePage> createState() => _ClipperCachePageState();
}

class _ClipperCachePageState extends State<ClipperCachePage>
    with TickerProviderStateMixin {
  final ScrollController _controller = ScrollController();
  final bool isComplex = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.offset < 10) {
        _controller.animateTo(80, duration: const Duration(milliseconds: 1000), curve: Curves.ease);
      } else if (_controller.offset > 70) {
        _controller.animateTo(0, duration: const Duration(milliseconds: 1000), curve: Curves.ease);
      }
    });
    Timer(const Duration(milliseconds: 500), () {
      _controller.animateTo(80, duration: const Duration(milliseconds: 1000), curve: Curves.ease);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: ListView(
        controller: _controller,
        children: <Widget>[
          ClipPath(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: _makeChild(0, isComplex)
          ),
          ClipRect(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: _makeChild(1, isComplex)
          ),
          ClipRRect(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: _makeChild(2, isComplex)
          ),
          PhysicalModel(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            color: Colors.blueAccent,
            borderRadius: const BorderRadius.all(Radius.circular(5.0)),
            child: _makeChild(2, isComplex),
          ),
          const SizedBox(height: 1000),
        ],
      ),
    );
  }

  Widget _makeChild(int itemIndex, bool complex) {
    final BoxDecoration decoration = BoxDecoration(
      color: Colors.white70,
      boxShadow: const <BoxShadow>[
        BoxShadow(
          blurRadius: 5.0,
        ),
      ],
      borderRadius: BorderRadius.circular(5.0),
    );
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 5, 10, 5),
        decoration: complex ? decoration : null,
        child: ListItem(index: itemIndex),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
