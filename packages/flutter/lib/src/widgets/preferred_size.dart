// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';

/// An interface for widgets that can return the size this widget would prefer
/// if it were otherwise unconstrained.
///
/// There are a few cases, notably [AppBar] and [TabBar], where it would be
/// undesirable for the widget to constrain its own size but where the widget
/// needs to expose a preferred or "default" size. For example a primary
/// [Scaffold] sets its app bar height to the app bar's preferred height
/// plus the height of the system status bar.
///
/// Use [PreferredSize] to give a preferred size to an arbitrary widget.
abstract class PreferredSizeWidget implements Widget {
  /// The size this widget would prefer if it were otherwise unconstrained.
  ///
  /// In many cases it's only necessary to define one preferred dimension.
  /// For example the [Scaffold] only depends on its app bar's preferred
  /// height. In that case implementations of this method can just return
  /// `new Size.fromHeight(myAppBarHeight)`.
  Size get preferredSize;
}

/// A widget with a preferred size.
///
/// This widget does not impose any constraints on its child, and it doesn't
/// affect the child's layout in any way. It just advertises a preferred size
/// which can be used by the parent.
///
/// ### Let's see 2 examples
///
/// The basic use of [PreferredSize] is when we need to change the
/// `Status Bar Color` of our app but we don't want to render an actual
/// [AppBar], and neither use [SystemChrome] of `services library`
///
/// {@tool dartpad --template=stateless_widget_material}
///
/// Here is the first example but be aware that we are assigning the `height` of the
/// [AppBar] to **0**, so it will not be rendered in the "Darpad Preview",
/// you will have to run the example on your real device or emulator
///
/// ```dart
/// Widget build(BuildContext context) {
///   return Scaffold(
///     appBar: PreferredSize(
///       preferredSize: const Size.fromHeight(0),
///         child: AppBar(
///           elevation: 0,
///           brightness: Brightness.dark,
///          )),
///       body: Center(
///         child: Text("Awesome Content"),
///    ));
/// }
/// ```
/// {@end-tool}
///
/// {@tool dartpad --template=stateless_widget_material}
///
/// This example explain how can we make a custom [AppBar] which has more `height`
/// than usual. In which we will have a `title`, two [Icons] and a [TabBar] that
/// controls body content in [Scaffold.body].
///
/// We assign the `height` parameter of our [PreferredSize] equal to 100, but you
/// can change this value and see how our [AppBar] behaves. The benefit of using
/// PreferredSize as an AppBar child its that we can use a different widget for creating
/// *custom app bars*, in this case. All this work because [Scaffold.appBar]
/// expect a [PreferredSizeWidget] and, as is describe above AppBar implements it
///
/// ```dart
/// Widget build(BuildContext context) {
///  return DefaultTabController(
///    length: 4,
///    child: Scaffold(
///        appBar: PreferredSize(
///          preferredSize: const Size(double.infinity, 100.0),
///          child: Container(
///            decoration: BoxDecoration(
///              gradient: LinearGradient(
///                colors: [Colors.blue, Colors.pink],
///              ),
///            ),
///            child: SafeArea(
///              child: Column(
///                mainAxisAlignment: MainAxisAlignment.end,
///                children: [
///                  Expanded(
///                    child: Padding(
///                      padding: const EdgeInsets.symmetric(horizontal: 10),
///                      child: Row(
///                        children: [
///                          Text(
///                            "Awesome App",
///                            style: TextStyle(color: Colors.white),
///                          ),
///                          Spacer(),
///                          IconButton(
///                              icon: Icon(
///                                Icons.search,
///                                size: 20,
///                              ),
///                              color: Colors.white,
///                              onPressed: () {}),
///                          IconButton(
///                              icon: Icon(
///                                Icons.more_vert,
///                                size: 20,
///                              ),
///                              color: Colors.white,
///                              onPressed: () {}),
///                        ],
///                      ),
///                    ),
///                  ),
///                  TabBar(
///                    tabs: [
///                      Icon(
///                        Icons.camera,
///                        size: 20,
///                      ),
///                      Tab(
///                        text: "Tab 1",
///                      ),
///                      Tab(
///                        text: "Tab 2",
///                      ),
///                      Tab(
///                        text: "Tab 3",
///                      ),
///                    ],
///                  ),
///                ],
///              ),
///            ),
///          ),
///        ),
///        body: TabBarView(
///          children: [
///            Center(
///              child: Text("Content for Camera"),
///            ),
///            Center(
///              child: Text("Content for tab 1"),
///            ),
///            Center(
///              child: Text("Content for tab 2"),
///            ),
///            Center(
///              child: Text("Content for tab 3"),
///            ),
///          ],
///        )),
///  );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [AppBar.bottom] and [Scaffold.appBar], which require preferred size widgets.
///  * [PreferredSizeWidget], the interface which this widget implements to expose
///    its preferred size.
///  * [AppBar] and [TabBar], which implement PreferredSizeWidget.
class PreferredSize extends StatelessWidget implements PreferredSizeWidget {
  /// Creates a widget that has a preferred size.
  const PreferredSize({
    Key? key,
    required this.child,
    required this.preferredSize,
  }) : super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  @override
  final Size preferredSize;

  @override
  Widget build(BuildContext context) => child;
}
