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

/// Shows a full screen search page.
///
/// The search page consists of an app bar with a search field and a body which
/// can either show suggested search queries or the search results.
///
/// The appearance of the search page is determined by the provided
/// `delegate`. The initial query string is given by `query`, which defaults
/// to the empty string. When `query` is set to null, `delegate.query` will
/// be used as the initial query.
///
/// The method returns the selected search result, which can be set in the
/// [SearchDelegate.close] call.
///
/// The transition to the search page triggered by this method looks best if the
/// screen triggering the transition contains an [AppBar] at the top and the
/// transition is called from an [IconButton] that's part of [AppBar.actions].
/// The animation provided by [SearchDelegate.transitionAnimation] can be used
/// to trigger additional animations in the underlying page while the search
/// page fades in or out. This is commonly used to animate an [AnimatedIcon] in
/// the [AppBar.leading] position e.g. from the hamburger menu to the back arrow
/// used to exit the search page.
///
/// See also:
///
///  * [SearchDelegate] to define the content of the search page.
Future<T> showSearch<T>({
  @required BuildContext context,
  @required SearchDelegate<T> delegate,
  String query: '',
}) {
  assert(delegate != null);
  assert(context != null);
  assert(delegate._result == null || delegate._result.isCompleted);
  delegate._result = new Completer<T>();
  delegate.query = query ?? delegate.query;
  delegate._currentBody = _SearchBody.suggestions;
  Navigator.of(context).push(new _SearchPageRoute<T>(
    delegate: delegate,
  ));
  return delegate._result.future;
}

/// Delegate for [showSearch] to define the content of the search page.
///
/// The search page always shows an [AppBar] at the top where users can
/// enter their search queries. The buttons shown before and after the search
/// query text field can be customized via [SearchDelegate.leading] and
/// [SearchDelegate.actions].
///
/// The body below the [AppBar] can either show suggested queries (returned by
/// [SearchDelegate.buildSuggestions]) or - once the user submits a search  - the
/// results of the search as returned by [SearchDelegate.buildResults].
///
/// [SearchDelegate.query] always contains the current query entered by the user
/// and should be used to build the suggestions and results.
///
/// The results can be brought on screen by calling [SearchDelegate.showResults]
/// and you can go back to showing the suggestions by calling
/// [SearchDelegate.showSuggestions].
///
/// Once the user has selected a search result, [SearchDelegate.close] should be
/// called to remove the search page from the top of the navigation stack and
/// to notify the caller of [showSearch] about the selected search result.
abstract class SearchDelegate<T> {

  /// Suggestions shown in the body of the search page while the user types a
  /// query into the search field.
  ///
  /// The delegate method is called whenever the content of [query] changes.
  /// The suggestions should be based on the current [query] string. If the query
  /// string is empty, it is good practice to show suggested queries based on
  /// past queries or the current context.
  ///
  /// Usually, this method will return a [ListView] with one [ListTile] per
  /// suggestion. When [ListTile.onTap] is called, [query] should be updated
  /// with the corresponding suggestion and the results page should be shown
  /// by calling [showResults].
  Widget buildSuggestions(BuildContext context);

  /// The results shown after the user submits a search from the search page.
  ///
  /// The current value of [query] can be used to determine what the users
  /// searched for.
  ///
  /// Typically, this method returns a [ListView] with the search results.
  Widget buildResults(BuildContext context);

  /// A widget to display before the current query in the [AppBar].
  ///
  /// Typically an [IconButton] configured with a [BackButtonIcon] that exits
  /// the search with [close]. One can also use an [AnimatedIcon] driven by
  /// [transitionAnimation], which animated from e.g. a hamburger menu to the
  /// back button as the search overlay fades in.
  ///
  /// Returns null if no widget should be shown.
  ///
  /// See also:
  ///
  ///  * [AppBar.leading], the intended use for the return value of this method.
  Widget buildLeading(BuildContext context);

  /// Widgets to display after the search query in the [AppBar].
  ///
  /// If the [query] is not empty, this should typically contain a button to
  /// clear the query and show the suggestions again (via [showSuggestions]) if
  /// the results are currently shown.
  ///
  /// Returns null if no widget should be shown
  ///
  /// See also:
  ///
  ///  * [AppBar.actions], the intended use for the return value of this method.
  List<Widget> buildActions(BuildContext context);

  /// The theme used to style the [AppBar].
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

  /// The current query string shown in the [Appbar].
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

  /// Transition to show search results.
  ///
  /// If the user taps on a suggestion provided by [buildSuggestions] the
  /// screen should typically transition to the page showing the search
  /// results for the suggested query. This transition can be triggered
  /// by calling this method.
  ///
  /// See also:
  ///
  ///  * [showSuggestions] to show the search suggestions again.
  void showResults(BuildContext context) {
    _focusNode.unfocus();
    _currentBody = _SearchBody.results;
  }

  /// Transition to show the search suggestions and places the input focus
  /// back into the search text field.
  ///
  /// If the results are currently shown this method can be used to go back
  /// to showing the search suggestions.
  ///
  /// See also:
  ///
  ///  * [showResults] to show the search results.
  void showSuggestions(BuildContext context) {
    FocusScope.of(context).requestFocus(_focusNode);
    _currentBody = _SearchBody.suggestions;
  }

  /// Closes the search page and returns to the underlying route.
  ///
  /// The value provided for `result` is used as the return value of the call
  /// to [showSearch] that launched the search initially.
  void close(BuildContext context, T result) {
    _currentBody = null;
    _focusNode.unfocus();
    _result.complete(result);
    Navigator.of(context).pop(result);
  }

  /// [Animation] triggered when the search pages fades in or out.
  ///
  /// This animation is commonly used to animate [AnimatedIcon]s of
  /// [IconButton]s returned by [buildLeading] or contained within the route
  /// below the search page.
  Animation<double> get transitionAnimation => _proxyAnimation;

  final FocusNode _focusNode = new FocusNode();

  final TextEditingController _textEditingController = new TextEditingController();

  final ProxyAnimation _proxyAnimation = new ProxyAnimation(kAlwaysDismissedAnimation);

  final ValueNotifier<_SearchBody> _currentBodyNotifier = new ValueNotifier<_SearchBody>(null);

  _SearchBody get _currentBody => _currentBodyNotifier.value;
  set _currentBody(_SearchBody value) {
    _currentBodyNotifier.value = value;
  }

  Completer<T> _result;

}

/// Describes the body that is currently shown under the [AppBar] in the
/// search page.
enum _SearchBody {
  /// Suggested queries are shown in the body.
  ///
  /// The suggested queries are generated by [SearchDelegate.buildSuggestions].
  suggestions,

  /// Search results are currently shown in the body.
  ///
  /// The search results are generated by [SearchDelegate.buildResults].
  results,
}


class _SearchPageRoute<T> extends PageRoute<void> {
  _SearchPageRoute({
    @required this.delegate,
  }) : assert(delegate != null);

  final SearchDelegate<T> delegate;

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
    delegate._proxyAnimation.parent = animation;
    return animation;
  }

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
    widget.delegate._currentBodyNotifier.addListener(_onSearchBodyChanged);
    widget.delegate._focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.removeListener(_onQueryChanged);
    widget.animation.removeStatusListener(_onAnimationStatusChanged);
    widget.delegate._currentBodyNotifier.removeListener(_onSearchBodyChanged);
    widget.delegate._focusNode.removeListener(_onFocusChanged);
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }
    widget.animation.removeStatusListener(_onAnimationStatusChanged);
    if (widget.delegate._currentBody == _SearchBody.suggestions) {
      FocusScope.of(context).requestFocus(widget.delegate._focusNode);
    }
  }

  void _onFocusChanged() {
    if (widget.delegate._focusNode.hasFocus && widget.delegate._currentBody != _SearchBody.suggestions) {
      widget.delegate.showSuggestions(context);
    }
  }

  void _onQueryChanged() {
    setState(() {
      // rebuild ourselves because query changed.
    });
  }

  void _onSearchBodyChanged() {
    setState(() {
      // rebuild ourselves because search body changed.
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = widget.delegate.appBarTheme(context);
    Widget body;
    switch(widget.delegate._currentBody) {
      case _SearchBody.suggestions:
        body = new Container(
          key: const ValueKey<_SearchBody>(_SearchBody.suggestions),
          child: widget.delegate.buildSuggestions(context),
        );
        break;
      case _SearchBody.results:
        body = new Container(
          key: const ValueKey<_SearchBody>(_SearchBody.results),
          child: widget.delegate.buildResults(context),
        );
        break;
    }


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
          focusNode: widget.delegate._focusNode,
          style: theme.textTheme.title,
          onSubmitted: (String _) {
            widget.delegate.showResults(context);
          },
          decoration: new InputDecoration(
            border: InputBorder.none,
            hintText: MaterialLocalizations.of(context).searchFieldLabel
          ),
        ),
        actions: widget.delegate.buildActions(context),
      ),
      body: new AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: body,
      ),
    );
  }

  TextEditingController get _controller => widget.delegate._textEditingController;
}
