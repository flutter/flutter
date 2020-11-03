// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';
import 'navigator.dart';
import 'routes.dart';

/// Registers a callback to veto attempts by the user to dismiss the enclosing
/// [ModalRoute].
///
/// {@tool snippet --template=stateful_widget}
///
/// Whenever the back button is pressed, you will get a callback at [onWillPop],
/// which returns a [Future]. If the [Future] returned is true, the screen is
/// popped and if it is false, the screen is not popped.
///
/// ```dart
/// @override
/// Widget build(BuildContext) {
///     return WillPopScope (
///      onWillPop: () async {
///        return shouldPop;
///      },
///        child: MyWidget(),
///     );
/// }
/// ```
/// {@end-tool}
///
/// {@tool dartpad --template=stateless_widget_material}
/// ```dart imports
/// import 'package:flutter/material.dart';
/// ```
///
/// ```dart main
/// void main() => runApp(MyApp());
/// ```
///
/// ```dart
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       initialRoute: '/',
///       routes: {
///         '/': (context) => FirstPage(),
///         '/second_screen': (context) => SecondPage(),
///       },
///     );
///   }
/// }
///
/// class FirstPage extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(
///         title: Text('WillPopScope demo'),
///       ),
///       body: Center(
///         child: RaisedButton(
///           child: Text('Go to the second screen'),
///           onPressed: () {
///             Navigator.pushNamed(context, '/second_screen');
///           },
///         ),
///       ),
///     );
///   }
/// }
///
/// class SecondPage extends StatefulWidget {
///   SecondPage({Key key, this.title}) : super(key: key);
///   final String title;
///   @override
///   _SecondPageState createState() => _SecondPageState();
/// }
///
/// class _SecondPageState extends State<SecondPage> {
///   bool shouldPop = true;
///
///   @override
///   Widget build(BuildContext context) {
///     return WillPopScope(
///       onWillPop: () async => shouldPop,
///       child: Scaffold(
///         appBar: AppBar(
///           title: Text("WillPopScope demo"),
///           leading: BackButton(),
///         ),
///         body: Center(
///           child: Column(
///             mainAxisAlignment: MainAxisAlignment.center,
///             children: <Widget>[
///               Text(
///                   "Toggle shouldPop using the button.Press the back button in appbar to see the effect."),
///               OutlinedButton(
///                 child: Text('shouldPop: $shouldPop'),
///                 onPressed: () {
///                   setState(() {
///                     shouldPop = !shouldPop;
///                   });
///                 },
///               ),
///             ],
///           ),
///         ),
///       ),
///     );
///   }
/// }
/// ```
///
/// {@end-tool}
///
/// See also:
///
///  * [ModalRoute.addScopedWillPopCallback] and [ModalRoute.removeScopedWillPopCallback],
///    which this widget uses to register and unregister [onWillPop].
///  * [Form], which provides an `onWillPop` callback that enables the form
///    to veto a `pop` initiated by the app's back button.
///
class WillPopScope extends StatefulWidget {
  /// Creates a widget that registers a callback to veto attempts by the user to
  /// dismiss the enclosing [ModalRoute].
  ///
  /// The [child] argument must not be null.
  const WillPopScope({
    Key? key,
    required this.child,
    required this.onWillPop,
  }) : assert(child != null),
       super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// Called to veto attempts by the user to dismiss the enclosing [ModalRoute].
  ///
  /// If the callback returns a Future that resolves to false, the enclosing
  /// route will not be popped.
  final WillPopCallback? onWillPop;

  @override
  _WillPopScopeState createState() => _WillPopScopeState();
}

class _WillPopScopeState extends State<WillPopScope> {
  ModalRoute<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.onWillPop != null)
      _route?.removeScopedWillPopCallback(widget.onWillPop!);
    _route = ModalRoute.of(context);
    if (widget.onWillPop != null)
      _route?.addScopedWillPopCallback(widget.onWillPop!);
  }

  @override
  void didUpdateWidget(WillPopScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(_route == ModalRoute.of(context));
    if (widget.onWillPop != oldWidget.onWillPop && _route != null) {
      if (oldWidget.onWillPop != null)
        _route!.removeScopedWillPopCallback(oldWidget.onWillPop!);
      if (widget.onWillPop != null)
        _route!.addScopedWillPopCallback(widget.onWillPop!);
    }
  }

  @override
  void dispose() {
    if (widget.onWillPop != null)
      _route?.removeScopedWillPopCallback(widget.onWillPop!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
