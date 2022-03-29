// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'picture_cache.dart';

class ShaderMaskCachePage extends StatefulWidget {
  const ShaderMaskCachePage({Key? key}) : super(key: key);
  @override
  State<ShaderMaskCachePage> createState() => _ShaderMaskCachePageState();
}

class _ShaderMaskCachePageState extends State<ShaderMaskCachePage>
    with TickerProviderStateMixin {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.offset < 10) {
        _controller.animateTo(100, duration: const Duration(milliseconds: 1000), curve: Curves.ease);
      } else if (_controller.offset > 90) {
        _controller.animateTo(0, duration: const Duration(milliseconds: 1000), curve: Curves.ease);
      }
    });
    Timer(const Duration(milliseconds: 500), () {
      _controller.animateTo(100, duration: const Duration(milliseconds: 1000), curve: Curves.ease);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: ListView(
        controller: _controller,
        children: <Widget>[
          const SizedBox(height: 100),
          buildShaderMask(0),
          const SizedBox(height: 10),
          buildShaderMask(1),
          const SizedBox(height: 10),
          buildShaderMaskWithBlendMode(BlendMode.modulate, 'BlendMode.modulate'),
          const SizedBox(height: 10),
          buildShaderMaskWithBlendMode(BlendMode.clear, 'BlendMode.clear'),
          const SizedBox(height: 10),
          buildShaderMaskWithBlendMode(BlendMode.dst, 'BlendMode.dst'),
          const SizedBox(height: 10),
          buildShaderMaskWithBlendMode(BlendMode.src, 'BlendMode.src'),
          const SizedBox(height: 1000),
        ],
      ),
    );
  }

  Widget buildShaderMask(int index) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const RadialGradient(
          center: Alignment.topLeft,
          radius: 1.0,
          colors: <Color>[Colors.yellow, Colors.red],
          tileMode: TileMode.mirror,
        ).createShader(bounds);
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.white,
            blurRadius: 5.0,
          ),
        ]),
        child: ListItem(index: index),
      ),
    );
  }

  Widget buildShaderMaskWithBlendMode(BlendMode blendMode, String blendModeDesc) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 100,
      child: Stack(
        children: [
          Positioned(
            top: 50,
            left: 10,
            child: Text(blendModeDesc, style: const TextStyle(fontWeight: FontWeight.w500),),
          ),
          Positioned(
            top: 0,
            left: 150,
            child: Container(
              width: 100,
              height: 100,
              color: Colors.green,
            ),
          ),
          Positioned(
            top: 0,
            left: 250,
            child: Container(
              width: 100,
              height: 100,
              color: Colors.red,
            ),
          ),
          Positioned(
              top: 0,
              left:170,
              child: SizedBox(
                width: 100,
                height: 100,
                // We hope the ShaderMask is larger than his children
                child: ShaderMask(
                  // We can specified the blend mode to check the ShaderMask behavior in different blend mode
                  blendMode: blendMode,
                  shaderCallback: (Rect bounds) {
                    return const RadialGradient(
                      center: Alignment.topLeft,
                      radius: 1.0,
                      colors: <Color>[Colors.yellow, Colors.red],
                      tileMode: TileMode.mirror,
                    ).createShader(bounds);
                  },
                  child: Flex(
                    direction: Axis.horizontal,
                    children: [
                      Container(width: 50, height: 50, color: Colors.blue,)
                    ],
                  ),
                ),
              )
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
