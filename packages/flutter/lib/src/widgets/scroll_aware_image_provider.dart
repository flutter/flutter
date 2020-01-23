// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';

import 'framework.dart';
import 'scrollable.dart';

/// Provides access to a [BuildContext] for a [ScrollAwareImageProvider].
///
/// Creators of this object must guarantee the following:
///
///   1. They create this object at or after [State.initState] but before
///      [State.dispose]. In particular, do not attempt to create this from the
///      constructor of a state.
///   2. They call [dispose] from [State.dispose].
///
/// This object will not hold on to the [State] after disposal.
@optionalTypeArgs
class ScrollAwareContextProvider<T extends State> {
  /// Creates a provider of a [BuildContext] for a [ScrollAwareImageProvider].
  ///
  /// Callers must call [dispose] when the [State] is disposed.
  ///
  /// The [State] must not be null, and [State.mounted] must be true.
  ScrollAwareContextProvider(this._state)
      : assert(_state != null),
        assert(_state.mounted, 'A ScrollAwareContextProvider was given a BuildContext for an Element that was never mounted.');

  /// Provides safe access to the build context.
  ///
  /// If [dispose] has been called, will return null.
  ///
  /// Otherwise, asserts the [_state] is still mounted and returns its context.
  BuildContext get _context {
    assert(debugValidate());
    if (_state == null) {
      return null;
    }
    return _state.context;
  }

  /// Called from asserts or tests to determine whether this object is in a
  /// valid state.
  ///
  /// Always returns true, but will assert if [dispose] has not been called
  /// but the state this is tracking is unmounted.
  @visibleForTesting
  bool debugValidate() {
    assert(
      _state == null || _state.mounted,
      'A ScrollAwareContextProvider tried to access the BuildContext of a '
      'disposed State object. This can happen when the creator of this provider '
      'fails to call dispose when it is disposed.',
    );
    return true;
  }

  /// Do not touch this.  Use [_context].
  T _state;

  /// Marks the [BuildContext] as disposed.
  ///
  /// Creators of this object should call [dispose] when their [Element] is
  /// unmounted, e.g. when [State.dispose] is called.
  void dispose() {
    _state = null;
  }
}

/// An [ImageProvider] that makes use of
/// [Scollable.recommendDeferredLoadingForContext] to avoid loading images when
/// rapidly scrolling.
///
/// This provider assumes that its wrapped [imageProvider] correctly uses the
/// [ImageCache], and does not attempt to re-acquire or decode images in the
/// cache.
///
/// Calling [resolve] on this provider will cause it to obtain the image key
/// and then check the following:
///
///   1. If the returned [ImageStream] has been completed, end. This can happen
///      if the caller sets the completer on the stream.
///   1. If the [ImageCache] has a completer for the key for this image, ask the
///      wrapped provider to resolve.
///      This can happen if the image was precached, or another [ImageProvider]
///      already resolved the same image.
///   1. If the [context] has been disposed, end. This can happen if the caller
///      has been disposed and is no longer interested in resolving the image.
///   1. If the widget is scrolling with high velocity at this point in time,
///      wait until the beginning of the next frame and go back to step 1.
///   1. Delegate loading the image to the wrapped provider and finish.
///
/// The [Image] widget wraps its incoming providers with this provider to avoid
/// overutilization of resources for images that would never appear on screen or
/// only be visible for a very brief period.
@optionalTypeArgs
class ScrollAwareImageProvider<T> extends ImageProvider<T> {
  /// Creates a [ScrollingAwareImageProvider].
  ///
  /// The [context] object is the [BuildContext] of the [State] using this
  /// provider. It is used to determine scrolling velocity during [resolve]. It
  /// must not be null.
  ///
  /// The [imageProvider] is used to create a key and load the image. It must
  /// not be null, and is assumed to interact with the cache in the normal way
  /// that [ImageProvider.useKey] does.
  const ScrollAwareImageProvider({
    @required this.context,
    @required this.imageProvider,
  }) : assert(context != null),
       assert(imageProvider != null);

  /// The context that may or may not be enclosed by a scrollable.
  ///
  /// Once [ScrollAwareContextProvider.dispose] is called on this context,
  /// the provider will
  final ScrollAwareContextProvider context;

  /// The wrapped image provider to delegate [obtainKey] and [load] to.
  final ImageProvider<T> imageProvider;

  @override
  void useKey(
    ImageConfiguration configuration,
    ImageStream stream,
    T key,
    ImageErrorListener handleError,
  ) {
    assert(stream != null);
    assert(key != null);
    assert(handleError != null);

    void deferredResolve([bool firstCall = false]) {
      // Something managed to complete the stream. Nothing left to do.
      if (stream.completer != null) {
        return;
      }
      // Something else got this image into the cache. Return it.
      if (PaintingBinding.instance.imageCache.containsKey(key)) {
        imageProvider.useKey(configuration, stream, key, handleError);
      }
      // The context has gone out of the tree - ignore it.
      if (context._context == null) {
        return;
      }
      // Something still wants this image, but check if the context is scrolling
      // too fast before scheduling work that might never show on screen.
      // Try to get to end of the frame callbacks of the next frame, and then
      // check again.
      if (Scrollable.recommendDeferredLoadingForContext(context._context)) {
          SchedulerBinding.instance.scheduleFrameCallback((_) {
            scheduleMicrotask(() => deferredResolve());
          });
          return;
      }
      // We are in the tree, we're not scrolling too fast, the cache doens't
      // have our image, and no one has otherwise completed the stream.  Go.
      imageProvider.useKey(configuration, stream, key, handleError);
    }
    deferredResolve(true);
  }

  @override
  ImageStreamCompleter load(T key, DecoderCallback decode) => imageProvider.load(key, decode);

  @override
  Future<T> obtainKey(ImageConfiguration configuration) => imageProvider.obtainKey(configuration);
}
