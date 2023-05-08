import 'dart:async';

import 'package:flutter/material.dart';

/// Flutter code sample for [Autocomplete] that demonstrates fetching the
/// options asynchronously and debouncing the network calls.

// TODO(justinmc): Could you add an actual debounce function now?
// TODO(justinmc): Consider adding error handling.

void main() => runApp(const AutocompleteExampleApp());

class AutocompleteExampleApp extends StatelessWidget {
  const AutocompleteExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Autocomplete Basic'),
        ),
        body: const Center(
          child: _AsyncAutocomplete(),
        ),
      ),
    );
  }
}

class _DebounceTimer {
  _DebounceTimer(
  ) {
    _timer = Timer(_debounceDuration, _onComplete);
  }

  static const Duration _debounceDuration = Duration(milliseconds: 500);

  late final Timer _timer;
  final Completer _completer = Completer();

  void _onComplete() {
    _completer.complete();
  }

  Future<void> get future => _completer.future;

  bool get isCompleted => _completer.isCompleted;

  void cancel() {
    //print('justin cancel');
    _timer.cancel();
    _completer.completeError(const _CancelException());
  }
}

// An excpetion indicating that the timer was canceled.
class _CancelException implements Exception {
  const _CancelException();
}

class _AsyncAutocomplete extends StatefulWidget {
  const _AsyncAutocomplete();

  @override
  State<_AsyncAutocomplete > createState() => _AsyncAutocompleteState();
}

class _AsyncAutocompleteState extends State<_AsyncAutocomplete > {
  // The query currently being searched for. If null, there is no pending
  // request.
  String? _currentQuery;

  // The most recent options received from the API.
  late Iterable<String> _lastOptions = <String>[];

  _DebounceTimer? _debounceTimer;

  Future<Iterable<String>?> _debouncedSearch(String query) async {
    if (_debounceTimer != null && !_debounceTimer!.isCompleted) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = _DebounceTimer();
    try {
      await _debounceTimer!.future;
    } catch (error) {
      if (error is _CancelException) {
        return null;
      }
      rethrow;
    }
    return _search(query);
  }

  // Calls the "remote" API to search with the given query. Returns null when
  // the call has been made obsolete.
  Future<Iterable<String>?> _search(String query) async {
    _currentQuery = query;

    // In a real application, there should be some error handling here.
    Iterable<String> options = await _FakeAPI.search(_currentQuery!);

    // If another search happened after this one, throw away these options.
    if (_currentQuery != query) {
      _currentQuery = null;
      return null;
    }
    _currentQuery = null;

    return options;
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        final Iterable<String>? options = await _debouncedSearch(textEditingValue.text);
        if (options == null) {
          return _lastOptions;
        }
        _lastOptions = options;
        return options;
      },
      onSelected: (String selection) {
        debugPrint('You just selected $selection');
      },
    );
  }
}

// Mimics a remote API.
class _FakeAPI {
  static const List<String> _kOptions = <String>[
    'aardvark',
    'bobcat',
    'chameleon',
  ];

  // Searches the options, but injects a fake "network" delay.
  static Future<Iterable<String>> search(String query) async {
    await Future.delayed(const Duration(seconds: 1)); // Fake 1 second delay.
    if (query == '') {
      return const Iterable<String>.empty();
    }
    return _kOptions.where((String option) {
      return option.contains(query.toLowerCase());
    });
  }
}


/// A function that can be debounced with the _debounce function.
typedef _Debounceable<S, T> = S Function(T currentArg);

/// A function that has been debounced by _debounce.
typedef _Debounced<S, T> = S Function(T currentArg);

/// Returns a _Debounced that will call through to the given function only after
/// it hasn't received a call in duration.
///
/// Only works for functions that take exactly one argument and return void.
/*
_Debounced<S, T> _debounce<S, T>({
  required Duration duration,
  required _Debounceable<S, T> function,
}) {
  Timer? timer;
  late T arg;

  return (T currentArg) {
    arg = currentArg;
    if (timer != null && timer!.isActive) {
      return timer!;
    }
    timer = Timer(duration, () {
      function(arg);
      timer = null;
    });
    return timer!;
  };
}
*/
