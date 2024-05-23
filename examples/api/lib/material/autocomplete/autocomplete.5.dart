// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

/// Flutter code sample for [Autocomplete] that demonstrates displaying an
/// initial message when the field is focused for the first time, a message if
/// no options were found, and a loading message while fetching the options
/// asynchronously and debouncing the network calls, including handling network
/// errors.

const Duration fakeAPIDuration = Duration(seconds: 1);
const Duration debounceDuration = Duration(milliseconds: 500);

void main() => runApp(const AutocompleteExampleApp());

class AutocompleteExampleApp extends StatelessWidget {
  const AutocompleteExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Autocomplete - async and debouncing'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                  'Type below to autocomplete the following possible results: ${_FakeAPI._kOptions}.',
                  ),
              const _AsyncAutocomplete(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AsyncAutocomplete extends StatefulWidget {
  const _AsyncAutocomplete();

  @override
  State<_AsyncAutocomplete> createState() => _AsyncAutocompleteState();
}

class _AsyncAutocompleteState extends State<_AsyncAutocomplete> {
  // The query currently being searched for. If null, there is no pending
  // request.
  String? _currentQuery;

  // The most recent options received from the API.
  late Iterable<String> _lastOptions = <String>[];

  late final _Debounceable<Iterable<String>?, String> _debouncedSearch;

  // Whether to consider the fake network to be offline.
  bool _networkEnabled = true;

  // A network error was received on the most recent query.
  bool _networkError = false;

  // Check if the "remote" API's response is waiting to be received.
  bool _isLoading = false;

  // Store the text last used in the "remote" API request to stop loading after
  // the request and debounce durations have both elapsed.
  String _lastValue = '';

  // Check if the text field is currently empty.
  bool _isFieldEmpty = false;

  // Check if no options were returned by the "remote" API.
  bool _nothingFound = false;

  // Calls the "remote" API to search with the given query. Returns null when
  // the call has been made obsolete.
  Future<Iterable<String>?> _search(String query) async {
    _currentQuery = query;

    late final Iterable<String> options;
    try {
      options = await _FakeAPI.search(_currentQuery!, _networkEnabled);
    } catch (error) {
      if (error is _NetworkException) {
        setState(() {
          _networkError = true;
        });
        return <String>[];
      }
      rethrow;
    }

    // If another search happened after this one, throw away these options.
    if (_currentQuery != query) {
      return null;
    }
    _currentQuery = null;

    return options;
  }

  @override
  void initState() {
    super.initState();
    _debouncedSearch = _debounce<Iterable<String>?, String>(_search);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          _networkEnabled
              ? 'Network is on, toggle to induce network errors.'
              : 'Network is off, toggle to allow requests to go through.',
        ),
        Switch(
          value: _networkEnabled,
          onChanged: (bool? value) {
            setState(() {
              _networkEnabled = !_networkEnabled;
            });
          },
        ),
        const SizedBox(
          height: 32.0,
        ),
        Autocomplete<String>(
          showOptionsViewOnEmptyOptions: true,
          showOptionsViewOnPendingOptions: true,
          optionsBuilder: (TextEditingValue textEditingValue) async {
            _isFieldEmpty = textEditingValue.text.isEmpty;
            if (_isFieldEmpty ||
                (_nothingFound &&
                    textEditingValue.text.length > _lastValue.length)) {
              return const Iterable<String>.empty();
            }
            setState(() {
              _networkError = false;
            });
            _isLoading = true; // Begin options loading.
            _nothingFound = false;
            _lastValue = textEditingValue.text;
            final Iterable<String>? options =
                await _debouncedSearch(textEditingValue.text);
            if (textEditingValue.text == _lastValue || _networkError) {
              _isLoading = false; // End options loading.
            }
            if (options == null) {
              return _lastOptions;
            }
            _lastOptions = options;
            _nothingFound = options.isEmpty && !_networkError;
            return options;
          },
          onSelected: (String selection) {
            debugPrint('You just selected $selection');
          },
          optionsViewBuilder: (BuildContext context,
              AutocompleteOnSelected<String> onSelected,
              Iterable<String> options) {
            return _networkError
                ? const Text('Network error, please try again.')
                : _isLoading && !_isFieldEmpty && !_nothingFound
                    ? const Text('Loading...')
                    : _isFieldEmpty
                        ? const Text('Type something')
                        : _nothingFound
                            ? const Text('No options found!')
                            : AutocompleteOverlay(
                                onSelected: onSelected, options: options);
          },
        ),
      ],
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
  static Future<Iterable<String>> search(
      String query, bool networkEnabled) async {
    await Future<void>.delayed(fakeAPIDuration); // Fake 1 second delay.
    if (!networkEnabled) {
      throw const _NetworkException();
    }
    if (query == '') {
      return const Iterable<String>.empty();
    }
    return _kOptions.where((String option) {
      return option.contains(query.toLowerCase());
    });
  }
}

typedef _Debounceable<S, T> = Future<S?> Function(T parameter);

/// Returns a new function that is a debounced version of the given function.
///
/// This means that the original function will be called only after no calls
/// have been made for the given Duration.
_Debounceable<S, T> _debounce<S, T>(_Debounceable<S?, T> function) {
  _DebounceTimer? debounceTimer;

  return (T parameter) async {
    if (debounceTimer != null && !debounceTimer!.isCompleted) {
      debounceTimer!.cancel();
    }
    debounceTimer = _DebounceTimer();
    try {
      await debounceTimer!.future;
    } catch (error) {
      if (error is _CancelException) {
        return null;
      }
      rethrow;
    }
    return function(parameter);
  };
}

// A wrapper around Timer used for debouncing.
class _DebounceTimer {
  _DebounceTimer() {
    _timer = Timer(debounceDuration, _onComplete);
  }

  late final Timer _timer;
  final Completer<void> _completer = Completer<void>();

  void _onComplete() {
    _completer.complete();
  }

  Future<void> get future => _completer.future;

  bool get isCompleted => _completer.isCompleted;

  void cancel() {
    _timer.cancel();
    _completer.completeError(const _CancelException());
  }
}

// An exception indicating that the timer was canceled.
class _CancelException implements Exception {
  const _CancelException();
}

// An exception indicating that a network request has failed.
class _NetworkException implements Exception {
  const _NetworkException();
}

class AutocompleteOverlay extends StatelessWidget {
  const AutocompleteOverlay({
    super.key,
    required this.onSelected,
    required this.options,
  });
  final AutocompleteOnSelected<String> onSelected;
  final Iterable<String> options;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200, maxWidth: 500),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (BuildContext context, int index) {
              final String option = options.elementAt(index);
              return InkWell(
                onTap: () {
                  onSelected(option);
                },
                child: Container(
                  color: Theme.of(context).focusColor,
                  padding: const EdgeInsets.all(16.0),
                  child: Text(option),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
