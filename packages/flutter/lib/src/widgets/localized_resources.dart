// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';

import 'container.dart';
import 'framework.dart';

/// Progress for a [LocalizedResourcesDelegate.load] method.
enum LocalizedResourcesStatus {
  /// Loading has not been started, [LocalizedResourcesDelegate.resourcesFor] will return null.
  none,

  /// Loading is underway, [LocalizedResourcesDelegate.resourcesFor] will return null.
  loading,

  /// Loading is complete, [LocalizedResourcesDelegate.resourcesFor] will return a valid non-null value.
  loaded,
}

/// An encapsulation of all of the resources to be loaded by a
/// [LocalizedResources] widget.
///
/// Typical applications have one [LocalizedResources] widget which is
/// created by the [WidgetsApp] and configured with the app's
/// `localizedResourcesDelegate` parameter.
///
/// See also:
///
///  * [DefaultLocalizedresorucesDelegate], a simple concrete version of
///    this class.
abstract class LocalizedResourcesDelegate {
  /// Start loading the resources for `locale`. The returned future completes
  /// when the resources have been loaded and cached.
  ///
  /// It's assumed that the this method will create one or more objects
  /// each of which contains a collection or related resources (typically
  /// defined by one method per resources). The objects will be retrieved
  /// by [Type] with [resourcesFor].
  Future<Null> load(Locale locale);

  /// Indicates the progress on loading resources for `locale`.
  ///
  /// If the returned value is not [LocalizedResourcesStatus.loaded] then
  /// [resourcesFor] will return null.
  LocalizedResourcesStatus statusFor(Locale locale);

  /// Return an instance of `Type` that contains all of the resources for
  /// `locale`.
  ///
  /// This method's type parameter `T` must match the `type` parameter.
  T resourcesFor<T>(Locale locale, Type type);

  /// Returns true if widgets that depend on this delegate should be rebuilt.
  bool updateShouldNotify(covariant LocalizedResourcesDelegate old);
}

/// Signature for the async localized resource loading callback used
/// by [DefaultLocalizedResourceLoader].
typedef Future<dynamic> LocalizedResourceLoader(Locale locale);


/// Defines all of an application's resources in terms of `allLoaders`:
/// a map from a [Type] to a _load_ function that creates an instance of
/// that type for a specific locale.
///
/// It's assumed that the that each loader will create an object that
/// contains a collection or related resources (typically
/// defined by one method per resource). The objects will be retrieved
/// by [Type] with [resourcesFor].
///
/// Each loader returns a Future because it may need to do work
/// asynchronously. For example localized resources might be loaded from
/// the nextwork. The [load] method returns a Future that completes
/// when all of the loaders have completed.
///
/// See also:
///
///  * [WidgetsApp.localizedResourcesDelegate] and [MaterialApp.localizedResourcesDelegate],
///    which enable configuring the app's LocalizedResourcesLoader.
class DefaultLocalizedResourcesDelegate extends LocalizedResourcesDelegate {
  DefaultLocalizedResourcesDelegate(this.allLoaders) {
    assert(allLoaders != null);
  }

  final Map<Type, LocalizedResourceLoader> allLoaders;

  final Map<Locale, Map<Type, dynamic>> _localeToResources = <Locale, Map<Type, dynamic>>{};
  final Set<Locale> _loading = new Set<Locale>();

  @override
  Future<Null> load(Locale locale) {
    assert(locale != null);
    assert(!_loading.contains(locale));
    final Map<Type, dynamic> resourceMap = <Type, dynamic>{};

    _loading.add(locale);

    // This is more complicated then just making a list of allLoaders[type](locale)
    // for each type in allTypes and then Future.wait-ing for all of the futures
    // because some of the loaders may return SynchronousFutures. We don't want
    // to Future.wait for the synchronous futures.
    Map<Type, Future<dynamic>> resourceMapFutures;
    for(Type type in allLoaders.keys) {
      dynamic completedValue;
      final Future<dynamic> futureValue = allLoaders[type](locale).then<dynamic>((dynamic value) {
        return completedValue = value;
      });
      if (completedValue != null) {
        resourceMap[type] = completedValue;
      } else {
        resourceMapFutures ??= <Type, Future<dynamic>>{};
        resourceMapFutures[type] = futureValue;
      }
    }

    // Common case: only the toolkit resources were loaded and they were all
    // synchronous futures.
    if (resourceMapFutures == null) {
      _loading.remove(locale);
      _localeToResources[locale] = resourceMap;
      return new SynchronousFuture<Null>(null);
    }

    // Wait on the remaining futures and update resourceMap.
    return Future.wait<Null>(resourceMapFutures.values,
      eagerError: true,
      cleanUp: (dynamic value) {
        _loading.remove(locale);
      }
    ).then((List<dynamic> allValues) {
      final List<Type> allTypes = resourceMapFutures.keys.toList();
      _loading.remove(locale);
      for (int i = 0; i < allTypes.length; i += 1) {
        assert(allValues[i] != null);
        resourceMap[allTypes[i]] = allValues[i];
      }
      _localeToResources[locale] = resourceMap;
      return null;
    });
  }

  @override
  LocalizedResourcesStatus statusFor(Locale locale) {
    if (_localeToResources[locale] != null)
      return LocalizedResourcesStatus.loaded;
    if (_loading.contains(locale))
      return LocalizedResourcesStatus.loading;
    return LocalizedResourcesStatus.none;
  }

  @override
  T resourcesFor<T>(Locale locale, Type type) {
    assert(locale != null);
    assert(type != null);
    final Map<Type, dynamic> resources = _localeToResources[locale];
    if (resources == null)
      return null;
    // TBD: assert(resources[type].runtimeType, type)? Too restrictive?
    return resources[type];
  }

  @override
  bool updateShouldNotify(DefaultLocalizedResourcesDelegate old) => false;
}

class _LocalizedResourcesScope extends InheritedWidget {
  _LocalizedResourcesScope ({
    Key key,
    @required this.locale,
    @required this.localizedResourcesState,
    Widget child,
  }) : super(key: key, child: child) {
    assert(localizedResourcesState != null);
  }

  final Locale locale;
  final _LocalizedResourcesState localizedResourcesState;

  @override
  bool updateShouldNotify(_LocalizedResourcesScope old) {
    if (locale != old.locale)
      localizedResourcesState.load(locale);
    return false;
  }
}

/// The value returned by [LocalizedResources.of].
abstract class LocalizedResourcesData {
  /// The resources returned by `resourcesFor` will be specific to this locale.
  Locale get locale;

  /// Returns a `type` object that contains a collection of resources for `locale`.
  T resourcesFor<T>(Type type);
}

/// Defines the [Locale] for its `child` and the localized resources that the
/// child depends on.
///
/// Localized resources are loaded by the [LocalizedResourcesDelegate] `delegate`.
/// Most apps should be able to use the [DefaultLocalizedResourcesDelegate] to
/// specify a class that contains the app's localized resources and a function
/// that creates an instance of that class.
///
/// The [WidgetsApp] class creates a `LocalizedResources` widget so most apps
/// will not need to create one. The widget app's `LocalizedResources` delegate can
/// be initialized with [WidgetsApp.localizedResourcesDelegate]. The [MaterialApp]
/// class also provides a `localizedResourcesDelegate` parameter that's just
/// pass along to the [WidgetsApp].
///
/// Apps should retrieve localized resources with the [LocalizedResourceData]
/// returned by `LocalizedResources.of(context)`. This is conventionally done
/// by a static `.of` method on the class that defines the app's localized
/// resources.
///
/// This class is effectively an [InheritedWidget]. If it's rebuilt with
/// a new `locale` or if its `delegate.updateShouldNotify` returns true,
/// widgets that have created a dependency by calling
/// `LocalizedResources.of(context)` will be rebuilt.
///
/// For example, using the `MyLocalizedResouces` class defined below, one would
/// lookup a localized title string like this:
/// ```dart
/// MyLocalizedResources.of(context).title()
/// ```
/// If the `LocalizedResources` were to be rebuilt with a new locale then
/// the widget subtree that corresponds to [BuildContext] `context` would
/// be rebuilt after the corresponding resources had been loaded.
///
/// ## Sample code
///
/// This following class is defined in terms of the
/// [Dart `intl` package](https://github.com/dart-lang/intl). Using the `intl`
/// package isn't required.
///
/// ```dart
/// class MyLocalizedResources {
///   MyLocalizedResources(this.locale);
///
///   final Locale locale;
///
///   static Future<MyLocalizedResources> load(Locale locale) {
///     return initializeMessages(locale.toString())
///       .then((Null _) {
///         return new Future<MyLocalizedResources>.value(new MyLocalizedResources(locale));
///       });
///   }
///
///   static MyLocalizedResources of(BuildContext context) {
///     return LocalizedResources.of(context).resourcesFor<MyLocalizedResources>(MyLocalizedResources);
///   }
///
///   String title() => Intl.message('<title>', name: 'title', locale: locale.toString());
///   // ... more Intl.message() methods like title()
/// }
/// ```
/// A class based on the `intl` package imports a generated message catalog that provides
/// the `initializeMessages()` function and the per-locale backing store for `Intl.message()`.
/// The message catalog is produced by an `intl` tool that analyzes the source code for
/// classes that contain `Intl.message()` calls. In this case that would just be the
/// `MyLocalizedResources` class.
///
/// One could choose another approach for loading localized resources and looking them up while
/// still conforming to the structure of this example.
class LocalizedResources extends StatefulWidget {
  LocalizedResources({
    Key key,
    @required this.locale,
    this.delegate,
    this.child
  }) : super(key: key) {
    assert(locale != null);
  }

  /// The resources returned by [LocalizedResources.of] will be specific to this locale.
  final Locale locale;

  /// This delegate is responsible for loading and caching resources for `locale`.
  ///
  /// Typically defined with [DefaultLocalizedResourcesDelegate].
  final LocalizedResourcesDelegate delegate;

  /// The widget below this widget in the tree.
  final Widget child;

  /// Returns the localized resources for the widget tree that corresponds to
  /// [BuildContext] `context`.
  ///
  /// This method is typically combined with [LocalizedResourcesData.for] to defined
  /// a static method that looks up a collection of related related resources. For
  /// example Flutter looks up Material resources with a method defined like this:
  ///
  /// ```dart
  /// static LocalizedMaterialResources of(BuildContext context) {
  ///  return LocalizedResources.of(context)
  ///    .resourcesFor<LocalizedMaterialResources>(LocalizedMaterialResources);
  /// }
  /// ```
  static LocalizedResourcesData of(BuildContext context) {
    final _LocalizedResourcesScope scope = context.inheritFromWidgetOfExactType(_LocalizedResourcesScope);
    return scope?.localizedResourcesState;
  }

  @override
  _LocalizedResourcesState createState() => new _LocalizedResourcesState();
}

class _LocalizedResourcesState extends State<LocalizedResources> implements LocalizedResourcesData {
  final GlobalKey _localizedResourcesScopeKey = new GlobalKey();

  @override
  Locale get locale => _locale;
  Locale _locale;

  @override
  void initState() {
    super.initState();
    load(widget.locale);
  }

  void load(Locale locale) {
    if (widget.delegate == null) {
      setState(() {
        _locale = locale;
      });
      return;
    }

    widget.delegate.load(locale).then((_) {
      setState(() {
        _locale = locale;
      });
      final InheritedElement scopeElement = _localizedResourcesScopeKey.currentContext;
      scopeElement?.dispatchDidChangeDependencies();
    });
  }

  @override
  T resourcesFor<T>(Type type) => widget.delegate.resourcesFor<T>(_locale, type);

  @override
  Widget build(BuildContext context) {
    return new _LocalizedResourcesScope(
      key: _localizedResourcesScopeKey,
      locale: widget.locale,
      localizedResourcesState: this,
      child: _locale != null ? widget.child : new Container(),
    );
  }
}
