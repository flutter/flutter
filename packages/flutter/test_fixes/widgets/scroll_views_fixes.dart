// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() {
  // Runtime variable (should NOT be migrated)
  CacheExtentStyle myStyle = CacheExtentStyle.viewport;
  // ignore: unused_local_variable
  Viewport runtimeViewport = Viewport(
    offset: ViewportOffset.fixed(0.0),
    cacheExtent: 200.0,
    cacheExtentStyle: myStyle,
    slivers: const <Widget>[],
  );

  // ignore: unused_local_variable
  ShrinkWrappingViewport runtimeShrinkWrappingViewport = ShrinkWrappingViewport(
    offset: ViewportOffset.fixed(0.0),
    cacheExtent: 200.0,
    cacheExtentStyle: myStyle,
    slivers: const <Widget>[],
  );

  // ignore: abstract_class_instantiation, unused_local_variable
  TwoDimensionalScrollView runtimeTwoDimensionalScrollView =
      TwoDimensionalScrollView(
        delegate: TwoDimensionalChildBuilderDelegate(
          builder: (context, _) => null,
        ),
        cacheExtent: 200.0,
        cacheExtentStyle: myStyle,
      );

  // ignore: abstract_class_instantiation, unused_local_variable
  TwoDimensionalViewport runtimeTwoDimensionalViewport = TwoDimensionalViewport(
    verticalOffset: ViewportOffset.fixed(0.0),
    horizontalOffset: ViewportOffset.fixed(0.0),
    verticalAxisDirection: AxisDirection.down,
    horizontalAxisDirection: AxisDirection.right,
    delegate: TwoDimensionalChildBuilderDelegate(builder: (context, _) => null),
    mainAxis: Axis.vertical,
    childManager: null as TwoDimensionalChildManager,
    cacheExtent: 200.0,
    cacheExtentStyle: myStyle,
  );

  // Viewport
  Viewport viewport = Viewport(
    offset: ViewportOffset.fixed(0.0),
    cacheExtent: 200.0,
    slivers: const <Widget>[],
  );

  viewport = Viewport(
    offset: ViewportOffset.fixed(0.0),
    cacheExtent: 200.0,
    cacheExtentStyle: CacheExtentStyle.pixel,
    slivers: const <Widget>[],
  );

  viewport = Viewport(
    offset: ViewportOffset.fixed(0.0),
    cacheExtent: 0.5,
    cacheExtentStyle: CacheExtentStyle.viewport,
    slivers: const <Widget>[],
  );

  // ShrinkWrappingViewport
  ShrinkWrappingViewport shrinkWrappingViewport = ShrinkWrappingViewport(
    offset: ViewportOffset.fixed(0.0),
    cacheExtent: 200.0,
    slivers: const <Widget>[],
  );

  shrinkWrappingViewport = ShrinkWrappingViewport(
    offset: ViewportOffset.fixed(0.0),
    cacheExtent: 200.0,
    cacheExtentStyle: CacheExtentStyle.pixel,
    slivers: const <Widget>[],
  );

  shrinkWrappingViewport = ShrinkWrappingViewport(
    offset: ViewportOffset.fixed(0.0),
    cacheExtent: 0.5,
    cacheExtentStyle: CacheExtentStyle.viewport,
    slivers: const <Widget>[],
  );

  // TwoDimensionalScrollView (abstract)
  // ignore: abstract_class_instantiation
  TwoDimensionalScrollView twoDimensionalScrollView = TwoDimensionalScrollView(
    delegate: TwoDimensionalChildBuilderDelegate(builder: (context, _) => null),
    cacheExtent: 200.0,
  );

  // ignore: abstract_class_instantiation
  twoDimensionalScrollView = TwoDimensionalScrollView(
    delegate: TwoDimensionalChildBuilderDelegate(builder: (context, _) => null),
    cacheExtent: 200.0,
    cacheExtentStyle: CacheExtentStyle.pixel,
  );

  // ignore: abstract_class_instantiation
  twoDimensionalScrollView = TwoDimensionalScrollView(
    delegate: TwoDimensionalChildBuilderDelegate(builder: (context, _) => null),
    cacheExtent: 0.5,
    cacheExtentStyle: CacheExtentStyle.viewport,
  );

  // TwoDimensionalViewport (abstract)
  // ignore: abstract_class_instantiation
  TwoDimensionalViewport twoDimensionalViewport = TwoDimensionalViewport(
    verticalOffset: ViewportOffset.fixed(0.0),
    horizontalOffset: ViewportOffset.fixed(0.0),
    verticalAxisDirection: AxisDirection.down,
    horizontalAxisDirection: AxisDirection.right,
    delegate: TwoDimensionalChildBuilderDelegate(builder: (context, _) => null),
    mainAxis: Axis.vertical,
    childManager: null as TwoDimensionalChildManager,
    cacheExtent: 200.0,
  );

  // ignore: abstract_class_instantiation
  twoDimensionalViewport = TwoDimensionalViewport(
    verticalOffset: ViewportOffset.fixed(0.0),
    horizontalOffset: ViewportOffset.fixed(0.0),
    verticalAxisDirection: AxisDirection.down,
    horizontalAxisDirection: AxisDirection.right,
    delegate: TwoDimensionalChildBuilderDelegate(builder: (context, _) => null),
    mainAxis: Axis.vertical,
    childManager: null as TwoDimensionalChildManager,
    cacheExtent: 200.0,
    cacheExtentStyle: CacheExtentStyle.pixel,
  );

  // ignore: abstract_class_instantiation
  twoDimensionalViewport = TwoDimensionalViewport(
    verticalOffset: ViewportOffset.fixed(0.0),
    horizontalOffset: ViewportOffset.fixed(0.0),
    verticalAxisDirection: AxisDirection.down,
    horizontalAxisDirection: AxisDirection.right,
    delegate: TwoDimensionalChildBuilderDelegate(builder: (context, _) => null),
    mainAxis: Axis.vertical,
    childManager: null as TwoDimensionalChildManager,
    cacheExtent: 0.5,
    cacheExtentStyle: CacheExtentStyle.viewport,
  );
  // ScrollView (abstract, but testing fix)
  // ignore: abstract_class_instantiation
  ScrollView scrollView = ScrollView(cacheExtent: 200.0);

  // ListView
  ListView listView = ListView(cacheExtent: 200.0, children: const <Widget>[]);

  listView = ListView.builder(
    cacheExtent: 200.0,
    itemBuilder: (BuildContext context, int index) => const Text(''),
  );

  listView = ListView.separated(
    cacheExtent: 200.0,
    itemBuilder: (BuildContext context, int index) => const Text(''),
    separatorBuilder: (BuildContext context, int index) => const Divider(),
    itemCount: 10,
  );

  listView = ListView.custom(
    cacheExtent: 200.0,
    childrenDelegate: SliverChildListDelegate(const <Widget>[]),
  );

  // GridView
  GridView gridView = GridView(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
    ),
    cacheExtent: 200.0,
    children: const <Widget>[],
  );

  gridView = GridView.builder(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
    ),
    cacheExtent: 200.0,
    itemBuilder: (BuildContext context, int index) => const Text(''),
  );

  gridView = GridView.custom(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
    ),
    cacheExtent: 200.0,
    childrenDelegate: SliverChildListDelegate(const <Widget>[]),
  );

  gridView = GridView.count(
    crossAxisCount: 2,
    cacheExtent: 200.0,
    children: const <Widget>[],
  );

  gridView = GridView.extent(
    maxCrossAxisExtent: 200.0,
    cacheExtent: 200.0,
    children: const <Widget>[],
  );

  // CustomScrollView
  CustomScrollView customScrollView = CustomScrollView(
    cacheExtent: 200.0,
    slivers: const <Widget>[],
  );

  // ReorderableListView
  ReorderableListView reorderableListView = ReorderableListView(
    cacheExtent: 200.0,
    children: const <Widget>[],
    onReorder: (int oldIndex, int newIndex) {},
  );

  reorderableListView = ReorderableListView.builder(
    cacheExtent: 200.0,
    itemBuilder: (BuildContext context, int index) => const Text(''),
    itemCount: 10,
    onReorder: (int oldIndex, int newIndex) {},
  );
}
