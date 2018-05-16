// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app_bar.dart';
import 'colors.dart';
import 'input_border.dart';
import 'input_decorator.dart';
import 'material_localizations.dart';
import 'scaffold.dart';
import 'text_field.dart';
import 'theme.dart';

/// Shows a full screen search overlay.
///
/// The overlay consists of an app bar with a search field and a body which can
/// either show suggested search queries (the search page) or the search
/// results (the results page).
///
/// The appearance of the search overlay is determined by the provided
/// `delegate`. The initial query string is given by `query`, which defaults
/// to the empty string. When `query` is set to null, `delegate.query` will
/// be used as the initial query.
///
/// The transition to the search overlay triggered by this method looks best
/// if the screen triggering the transition contains an [AppBar] at the top
/// and the transition is triggered from an [IconButton.onPressed] within
/// [AppBar.actions]. The animation provided by [SearchDelegate.animation] can
/// be used to trigger additional animations in the underlying screen while
/// the search overlay fades in or out. This is commonly used to animate
/// an [AnimatedIcon] in the [AppBar.leading] position e.g. from the hamburger
/// menu to the back arrow used to exit the search overlay.
///
/// See also:
///
///  * [SearchDelegate] for ways to customize the search overlay.
Future<T> showSearchOverlay<T>({
  @required BuildContext context,
  @required SearchDelegate<T> delegate,
  String query: '',
}) {
  assert(delegate != null);
  assert(context != null);
  assert(delegate._result == null || delegate._result.isCompleted);
  delegate._result = new Completer<T>();
  delegate.query = query ?? delegate.query;
  Navigator.of(context).push(new _SearchPageRoute<T>(
    delegate: delegate,
  ));
  return delegate._result.future;
}

/// Delegate for [showSearchOverlay] to customize the search experience.
///
/// The search experience consists of two pages:
///
/// 1) A search page showing a search field in an [AppBar] and suggestions
///    shown below in the body of the page. Which suggestions are shown is
///    determined by [SearchDelegate.buildSuggestions].
/// 2) A results page with an [AppBar] showing the current search string and
///    the search results in the body. The search results are provided by
///    [SearchDelegate.buildResults].
///
/// Additionally, the [SearchDelegate] also allows customizing the buttons
/// shown alongside the [AppBar] on both screens via [leading] and [actions].
abstract class SearchDelegate<T> {

  /// Suggestions shown in the body of the search overlay while the user types a
  /// query into the search field.
  ///
  /// The delegate method is called whenever the content of [query] changes and
  /// the value of [query] can be used to determine which suggestions should
  /// be shown.
  ///
  /// Usually, this method will return a [ListView] with one [ListTile] per
  /// suggestion. When [ListTile.onTap] is called, [query] should be updated
  /// with the corresponding [suggestion] and the results page should be shown
  /// by calling [showResultsPage].
  Widget buildSuggestions(BuildContext context);

  /// The results shown after the user submits a search from the search page.
  ///
  /// The content of [query] can be used to determine what the users searched
  /// for.
  Widget buildResults(BuildContext context);

  /// A widget to display before the current query in the [AppBar] of the search
  /// overlay.
  ///
  /// Typically an [IconButton] as a back button to exit the search overlay. It
  /// is suggested to show an [AnimatedIcon] driven by [transitionAnimation],
  /// which animated from e.g. a hamburger menu to the back button as the search
  /// overlay fades in.
  ///
  /// See also:
  ///
  ///  * [AppBar.leading], the intended use for the return value of this method.
  Widget buildLeading(BuildContext context);

  /// Widgets to display after the search query in the [AppBar] of the search
  /// overlay.
  ///
  /// If the [query] is not empty, this should typically contain a button to
  /// clear the query and go back to the search page if the results page is
  /// currently shown.
  ///
  /// See also:
  ///
  ///  * [AppBar.actions], the intended use for the return value of this method.
  List<Widget> buildActions(BuildContext context);

  /// The theme used to style the [AppBar] of the search overlay.
  ///
  /// By default, a white theme is used.
  ///
  /// See also:
  ///
  ///  * [AppBar.backgroundColor], which is set to [ThemeData.primaryColor].
  ///  * [Appbar.iconTheme], which is set to [ThemeData.primaryIconTheme].
  ///  * [AppBar.textTheme], which is set to [ThemeData.primaryTextTheme].
  ///  * [AppBar.brightness], which is set to [ThemeData.primaryColorBrightness].
  ThemeData appBarTheme(BuildContext context) {
    assert(context != null);
    final ThemeData theme = Theme.of(context);
    assert(theme != null);
    return theme.copyWith(
      primaryColor: Colors.white,
      primaryIconTheme: theme.primaryIconTheme.copyWith(color: Colors.grey),
      primaryColorBrightness: Brightness.light,
      primaryTextTheme: theme.textTheme,
    );
  }

  /// The current query string shown in the app bar.
  ///
  /// The user manipulates this string via the keyboard.
  ///
  /// If the user taps on a suggestion provided by [buildSuggestions] this
  /// string should be updated to that suggestion via the setter.
  String get query => _textEditingController.text;
  set query(String value) {
    assert(query != null);
    _textEditingController.text = value;
  }


  /// Transition to the results page.
  ///
  /// If the user taps on a suggestion provided by [buildSuggestions] the
  /// search overlay should typically transition to the page showing the search
  /// results for the suggested query. This transition can be triggered
  /// by calling this method.
  ///
  /// See also:
  ///
  ///  * [isShowingResultsPage] to check if the search overlay is currently
  ///    showing the results page.
  ///  * [isShowingSearchPage] to check if the search overlay is currently
  ///     showing the search page.
  ///  * [showSearchPage] to transition to the search page.
  @protected
  void showResultsPage(BuildContext context) {
    assert(isShowingSearchPage(context));
    focusNode.unfocus();
    Navigator.of(context).pushReplacement(new _ResultsPageRoute<T>(
      delegate: this,
    ));
  }

  /// Transition to the search page.
  ///
  /// If the search overlay is currently showing the results page this method
  /// can be used to trigger a transition back to the search page.
  ///
  /// This can only be called if the search overlay is currently showing the
  /// results page. To show the search overlay on top of another route call
  /// [showSearchOverlay] instead of this method.
  ///
  /// See also:
  ///
  ///  * [isShowingResultsPage] to check if the search overlay is currently
  ///    showing the results page.
  ///  * [isShowingSearchPage] to check if the search overlay is currently
  ///     showing the search page.
  ///  * [showResultsPage] to transition to the results page.
  @protected
  void showSearchPage(BuildContext context) {
    assert(isShowingResultsPage(context));
    Navigator.of(context).pushReplacement(new _SearchPageRoute<T>(
      delegate: this,
      useProxyAnimationOnEntry: false,
    ));
  }

  /// Closes the search overlay and return to the underlying route.
  ///
  /// The value provided for `result` is used as the return value of the call
  /// to [showSearchOverlay] that launched the search initially.
  @protected
  void close(BuildContext context, T result) {
    assert(isShowingResultsPage(context) || isShowingSearchPage(context));
    focusNode.unfocus();
    _result.complete(result);
    Navigator.of(context).pop(result);
  }

  /// Whether the search overlay is currently showing the search page.
  ///
  /// On the search page the user can enter a search query in the app bar
  /// and sees suggested queries (from [buildSuggestions]) in the body.
  ///
  /// See also:
  ///
  ///  * [isShowingResultsPage] to check if the search overlay is currently
  ///    showing the results page.
  ///  * [showSearchPage] to transition to the search page.
  ///  * [showResultsPage] to transition to the results page.
  bool isShowingSearchPage(BuildContext context) => ModalRoute.of(context) is _SearchPageRoute;

  /// Whether the search overlay is currently showing the results page.
  ///
  /// On the results page the user should see hits for the provided [query],
  /// which are obtained from [buildResults].
  ///
  /// See also:
  ///
  ///  * [isShowingResultsPage] to check if the search overlay is currently
  ///    showing the results page.
  ///  * [showSearchPage] to transition to the search page.
  ///  * [showResultsPage] to transition to the results page.
  bool isShowingResultsPage(BuildContext context) => ModalRoute.of(context) is _ResultsPageRoute;

  /// [Animation] triggered while the search overlay fades in or out.
  ///
  /// This animation is commonly used to animate [AnimatedIcon]s of
  /// [IconButton]s return by [buildLeading] or contained within the route
  /// below the search overlay.
  Animation<double> get transitionAnimation => _proxyAnimation;

  /// [FocusNode] used by the text field showing the current search query.
  ///
  /// It can be used to unfocus the text field before transitioning to the
  /// results page.
  final FocusNode focusNode = new FocusNode();

  final TextEditingController _textEditingController = new TextEditingController();

  final ProxyAnimation _proxyAnimation = new ProxyAnimation(kAlwaysDismissedAnimation);

  Completer<T> _result;
}

/// Base class for routes within the search overlay.
///
/// [_SearchOverlayPageRoute] are cross-faded in and can trigger animations
/// during the route transition in the new and old route by setting
/// [SearchDelegate.transitionAnimation]. The latter is for example used to
/// animate the hamburger menu icon of an [AppBar] into a back arrow while the
/// search overlay fades in.
abstract class _SearchOverlayPageRoute<T> extends PageRoute<void> {
  _SearchOverlayPageRoute({
    @required this.delegate,
    this.triggerAnimationsInRoutesOnEntry: true,
  }) : assert(delegate != null), assert(triggerAnimationsInRoutesOnEntry != null);

  /// The [SearchDelegate] determining the appearance of the search overlay
  /// owning this route.
  final SearchDelegate<T> delegate;

  /// Whether [delegate.animation] should be triggered while this route fades
  /// in.
  final bool triggerAnimationsInRoutesOnEntry;

  @override
  Color get barrierColor => null;

  @override
  String get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  bool get maintainState => false;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return new FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  @override
  Animation<double> createAnimation() {
    final Animation<double> animation = super.createAnimation();
    if (triggerAnimationsInRoutesOnEntry) {
      delegate._proxyAnimation.parent = animation;
    } else {
      Function listener;
      listener = (AnimationStatus status) {
        switch (status) {
          case AnimationStatus.dismissed:
          case AnimationStatus.forward:
            break;
          case AnimationStatus.reverse:
          case AnimationStatus.completed:
            animation.removeStatusListener(listener);
            delegate._proxyAnimation.parent = animation;
            break;
        }
      };
      animation.addStatusListener(listener);
    }
    return animation;
  }
}

// SEARCH PAGE

/// Route to switch to the search page of the search overlay.
class _SearchPageRoute<T> extends _SearchOverlayPageRoute<T> {
  _SearchPageRoute({
    bool useProxyAnimationOnEntry: true,
    SearchDelegate<T> delegate,
  }) : super(
          triggerAnimationsInRoutesOnEntry: useProxyAnimationOnEntry,
          delegate: delegate,
        );

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return new _SearchPage<T>(
      delegate: delegate,
      animation: animation,
    );
  }
}

class _SearchPage<T> extends StatefulWidget {
  const _SearchPage({
    this.delegate,
    this.animation,
  });

  final SearchDelegate<T> delegate;
  final Animation<double> animation;

  @override
  State<StatefulWidget> createState() => new _SearchPageState<T>();
}

class _SearchPageState<T> extends State<_SearchPage<T>> {
  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
    widget.animation.addStatusListener(_onAnimationStatusChanged);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.removeListener(_onQueryChanged);
    widget.animation.removeStatusListener(_onAnimationStatusChanged);
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }
    widget.animation.removeStatusListener(_onAnimationStatusChanged);
    FocusScope.of(context).requestFocus(widget.delegate.focusNode);
  }

  void _onQueryChanged() {
    setState(() {
      // rebuild ourselves because query changed.
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = widget.delegate.appBarTheme(context);
    return new Scaffold(
      appBar: new AppBar(
        backgroundColor: theme.primaryColor,
        iconTheme: theme.primaryIconTheme,
        textTheme: theme.primaryTextTheme,
        brightness: theme.primaryColorBrightness,
        leading: widget.delegate.buildLeading(context),
        // TODO(goderbauer): Show the search key (instead of enter) on keyboard, https://github.com/flutter/flutter/issues/17525
        title: new TextField(
          controller: _controller,
          focusNode: widget.delegate.focusNode,
          style: theme.textTheme.title,
          onSubmitted: (String _) {
            widget.delegate.showResultsPage(context);
          },
          decoration: new InputDecoration(
            border: InputBorder.none,
            hintText: MaterialLocalizations.of(context).searchFieldLabel
          ),
        ),
        actions: widget.delegate.buildActions(context),
      ),
      body: widget.delegate.buildSuggestions(context),
    );
  }

  TextEditingController get _controller => widget.delegate._textEditingController;
}

// RESULTS PAGE

/// Route to switch to the results page of the search overlay.
class _ResultsPageRoute<T> extends _SearchOverlayPageRoute<T> {
  _ResultsPageRoute({
    SearchDelegate<T> delegate,
  }) : super(delegate: delegate, triggerAnimationsInRoutesOnEntry: false);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return new _ResultsPage<T>(
      delegate: delegate,
    );
  }
}

class _ResultsPage<T> extends StatelessWidget {
  const _ResultsPage({
    this.delegate,
  });

  final SearchDelegate<T> delegate;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = delegate.appBarTheme(context);
    return new Scaffold(
      appBar: new AppBar(
        backgroundColor: theme.primaryColor,
        iconTheme: theme.primaryIconTheme,
        textTheme: theme.primaryTextTheme,
        brightness: theme.primaryColorBrightness,
        leading: delegate.buildLeading(context),
        centerTitle: false,
        title: new GestureDetector(
          // TODO(goderbauer): find a better way then Row-Expanded to make the GestureDetector as wide as the appbar allows.
          child: new Row(
            children: <Widget>[
              new Expanded(
                child: new Text(delegate.query),
              ),
            ],
          ),
          onTap: () {
            delegate.showSearchPage(context);
          },
        ),
        actions: delegate.buildActions(context),
      ),
      body: delegate.buildResults(context),
    );
  }
}
