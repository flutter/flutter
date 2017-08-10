// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';

import 'binding.dart';
import 'container.dart';
import 'framework.dart';

// Examples can assume:
// class Intl { static String message(String s, { String name, String locale }) => ''; }
// Future<Null> initializeMessages(String locale) => null;

/// Progress for a [LocalizationsDelegate.load] method.
enum LocalizationsStatus {
  /// Loading has not been started, [LocalizationsDelegate.resourcesFor] will return null.
  none,

  /// Loading is underway, [LocalizationsDelegate.resourcesFor] will return null.
  loading,

  /// Loading is complete, [LocalizationsDelegate.resourcesFor] will return a valid non-null value.
  loaded,
}

/// An encapsulation of all of the resources to be loaded by a
/// [Localizations] widget.
///
/// Typical applications have one [Localizations] widget which is
/// created by the [WidgetsApp] and configured with the app's
/// `localizationsDelegate` parameter.
///
/// See also:
///
///  * [DefaultLocalizationsDelegate], a simple concrete version of
///    this class.
abstract class LocalizationsDelegate {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  LocalizationsDelegate();

  /// Create single [LocalizationsDelegate] from a list of them.
  ///
  /// All of the delegates' load methods must return disjoint lists of types, i.e.
  /// only one delegate's [resourcesFor] method can be responsible for a set of
  /// localizations of a particular [Type].
  ///
  /// When possible, using DefaultLocalizationsDelegate should be preferred to
  /// using this factory constructor, since it's one less level of indirection.
  factory LocalizationsDelegate.merge(Iterable<LocalizationsDelegate> delegates) {
    assert(delegates != null && delegates.isNotEmpty);
    return new _MergedLocalizationsDelegate(delegates);
  }


  /// Start loading the resources for `locale`. The returned future completes
  /// when the resources have been loaded and cached.
  ///
  /// It's assumed that the this method will create one or more objects
  /// each of which contains a collection or related resources (typically
  /// defined with one method per resource). The objects will be retrieved
  /// by [Type] with [resourcesFor].
  Future<Iterable<Type>> load(Locale locale);

  /// Indicates the progress on loading resources for `locale`.
  ///
  /// If the returned value is not [LocalizationsStatus.loaded] then
  /// [resourcesFor] will return null.
  LocalizationsStatus statusFor(Locale locale);

  /// Returns an instance with the specified type that contains all of
  /// the resources for `locale`.
  ///
  /// This method's type parameter `T` must match the `type` parameter.
  T resourcesFor<T>(Locale locale, Type type);

  /// Returns true if the resources for this delegate should be loaded
  /// again by calling the [load] method.
  ///
  /// This method is called whenever its [Localizations] widget is
  /// rebuilt. If it returns true then dependent widgets will be rebuilt
  /// after [load] has completed.
  bool shouldReload(covariant LocalizationsDelegate old);
}

/// Signature for the async localized resource loading callback used
/// by [DefaultLocalizationsLoader].
typedef Future<dynamic> LocalizationsLoader(Locale locale);

// The returned Future<Map> will resolve when all of the input map's
// values have resolved. If all of the input map's values are
// SynchronousFutures then a SynchronousFuture will be returned.
//
// This is more complicated than just applying Future.wait to input.values
// because some of the input.values may be SynchronousFutures. We don't want
// to Future.wait for the synchronous futures.
Future<Map<K, V>> _loadMap<K, V>(Map<K, Future<V>> input) {
  final Map<K, V> output = <K, V>{};
  Map<K, Future<V>> outputFutures;

  for (K key in input.keys) {
    V completedValue;
    final Future<V> futureValue = input[key].then<V>((V value) {
      return completedValue = value;
    });
    if (completedValue != null) { // input[key] was a SynchronousFuture
      output[key] = completedValue;
    } else {
      outputFutures ??= <K, Future<V>>{};
      outputFutures[key] = futureValue;
    }
  }

  // All of the input.values were synchronous futures, we're done.
  if (outputFutures == null)
    return new SynchronousFuture<Map<K, V>>(output);

  // Some of input.values were asynchronous futures. Wait for them.
  return Future.wait<V>(outputFutures.values).then<Map<K, V>>((List<V> values) {
    final List<K> keys = outputFutures.keys.toList();
    for (int i = 0; i < keys.length; i++)
      output[keys[i]] = values[i];
    return output;
  });
}

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
///  * [WidgetsApp.localizationsDelegate] and [MaterialApp.localizationsDelegate],
///    which enable configuring the app's LocalizationsLoader.
class DefaultLocalizationsDelegate extends LocalizationsDelegate {
  DefaultLocalizationsDelegate(this.allLoaders) {
    assert(allLoaders != null);
  }

  /// The [LocalizationsLoader]s in this map define all of the collections
  /// of resources for a [Localizations] widget.
  ///
  /// The [load] method's Future completes when all of the loaders' load functions
  /// have completed.
  final Map<Type, LocalizationsLoader> allLoaders;

  final Map<Locale, Map<Type, dynamic>> _localeToResources = <Locale, Map<Type, dynamic>>{};
  final Set<Locale> _loading = new Set<Locale>();

  @override
  Future<Iterable<Type>> load(Locale locale) {
    assert(locale != null);
    assert(!_loading.contains(locale));

    Iterable<Type> types;

    _loading.add(locale);
    final Future<Iterable<Type>> typesFuture = _loadMap<Type, dynamic>(
      new Map<Type, Future<dynamic>>.fromIterables(
        allLoaders.keys,
        allLoaders.values.map<Future<dynamic>>((LocalizationsLoader loader) => loader(locale)),
      ),
    ).then<Iterable<Type>>((Map<Type, dynamic> resources) {
      _loading.remove(locale);
      _localeToResources[locale] = resources;
      return types = resources.keys;
    });

    return types == null ? typesFuture : new SynchronousFuture<Iterable<Type>>(types);
  }

  @override
  LocalizationsStatus statusFor(Locale locale) {
    if (_localeToResources[locale] != null)
      return LocalizationsStatus.loaded;
    if (_loading.contains(locale))
      return LocalizationsStatus.loading;
    return LocalizationsStatus.none;
  }

  @override
  T resourcesFor<T>(Locale locale, Type type) {
    assert(locale != null);
    assert(type != null);
    final Map<Type, dynamic> resources = _localeToResources[locale];
    if (resources == null)
      return null;
    // TODO(hansmuller): assert(resources[type] is type) when
    // https://github.com/dart-lang/sdk/issues/27680 has been resolved.
    return resources[type];
  }

  @override
  bool shouldReload(DefaultLocalizationsDelegate old) => false;
}

class _MergedLocalizationsDelegate extends LocalizationsDelegate {
  // Creates a single [LocalizationsDelegate] whose methods delegate to the
  // elements of `allDelegates`.
  _MergedLocalizationsDelegate(this.allDelegates);

  // This class's [load], [statusFor], and [resourcesFor] methods delegate
  // to the members of this list.
  final Iterable<LocalizationsDelegate> allDelegates;

  final Map<Locale, Map<Type, LocalizationsDelegate>> _localeToDelegate = <Locale, Map<Type, LocalizationsDelegate>>{};
  final Set<Locale> _loading = new Set<Locale>();

  @override
  Future<Iterable<Type>> load(Locale locale) {
    assert(locale != null);
    assert(!_loading.contains(locale));

    List<Type> types;

    _loading.add(locale);
    final Future<Iterable<Type>> typesFuture = _loadMap<LocalizationsDelegate, Iterable<Type>>(
      new Map<LocalizationsDelegate, Future<Iterable<Type>>>.fromIterables(
        allDelegates,
        allDelegates.map<Future<Iterable<Type>>>((LocalizationsDelegate delegate) => delegate.load(locale)),
      ),
    ).then<Iterable<Type>>((Map<LocalizationsDelegate, Iterable<Type>> resources) {
      _loading.remove(locale);
      final Map<Type, LocalizationsDelegate> typeToDelegate = <Type, LocalizationsDelegate>{};
      for (LocalizationsDelegate delegate in resources.keys) {
        for (Type type in resources[delegate]) {
          assert(type != null && !typeToDelegate.containsKey(type));
          typeToDelegate[type] = delegate;
          types ??= <Type>[];
          types.add(type);
        }
      }
      _localeToDelegate[locale] = typeToDelegate;
      return types;
    });

    return types == null ? typesFuture : new SynchronousFuture<Iterable<Type>>(types);
  }

  @override
  LocalizationsStatus statusFor(Locale locale) {
    if (_localeToDelegate[locale] != null)
      return LocalizationsStatus.loaded;
    if (_loading.contains(locale))
      return LocalizationsStatus.loading;
    return LocalizationsStatus.none;
  }

  @override
  T resourcesFor<T>(Locale locale, Type type) {
    assert(locale != null);
    assert(type != null);
    final Map<Type, LocalizationsDelegate> resources = _localeToDelegate[locale];
    return resources[type]?.resourcesFor<T>(locale, type);
  }

  @override
  bool shouldReload(_MergedLocalizationsDelegate old) => false;
}

class _LocalizationsScope extends InheritedWidget {
  _LocalizationsScope ({
    Key key,
    @required this.locale,
    @required this.localizationsState,
    Widget child,
  }) : super(key: key, child: child) {
    assert(localizationsState != null);
  }

  final Locale locale;
  final _LocalizationsState localizationsState;

  @override
  bool updateShouldNotify(_LocalizationsScope old) {
    final LocalizationsDelegate delegate = localizationsState.widget.delegate;
    final bool shouldReload = locale != old.locale ||
      (delegate != null && delegate.shouldReload(old.localizationsState.widget.delegate));
    if (shouldReload)
      localizationsState.load(locale);
    return false;
  }
}

/// Defines the [Locale] for its `child` and the localized resources that the
/// child depends on.
///
/// Localized resources are loaded by the [LocalizationsDelegate] `delegate`.
/// Most apps should be able to use the [DefaultLocalizationsDelegate] to
/// specify a class that contains the app's localized resources and a function
/// that creates an instance of that class.
///
/// The [WidgetsApp] class creates a `Localizations` widget so most apps
/// will not need to create one. The widget app's `Localizations` delegate can
/// be initialized with [WidgetsApp.localizationsDelegate]. The [MaterialApp]
/// class also provides a `localizationsDelegate` parameter that's just
/// passed along to the [WidgetsApp].
///
/// Apps should retrieve collections of localized resources with
/// `Localizations.of<MyLocalizations>(context, MyLocalizations)`,
/// where MyLocalizations is an app specific class defines one function per
/// resource. This is conventionally done by a static `.of` method on the
/// MyLocalizations class.
///
/// For example, using the `MyLocalizations` class defined below, one would
/// lookup a localized title string like this:
/// ```dart
/// MyLocalizations.of(context).title()
/// ```
/// If `Localizations` were to be rebuilt with a new `locale` then
/// the widget subtree that corresponds to [BuildContext] `context` would
/// be rebuilt after the corresponding resources had been loaded.
///
/// This class is effectively an [InheritedWidget]. If it's rebuilt with
/// a new `locale` or if its `delegate.shouldReload` returns true,
/// widgets that have created a dependency by calling
/// `Localizations.of(context)` will be rebuilt after the resources
/// for the new locale have been loaded.
///
/// ## Sample code
///
/// This following class is defined in terms of the
/// [Dart `intl` package](https://github.com/dart-lang/intl). Using the `intl`
/// package isn't required.
///
/// ```dart
/// class MyLocalizations {
///   MyLocalizations(this.locale);
///
///   final Locale locale;
///
///   static Future<MyLocalizations> load(Locale locale) {
///     return initializeMessages(locale.toString())
///       .then((Null _) {
///         return new Future<MyLocalizations>.value(new MyLocalizations(locale));
///       });
///   }
///
///   static MyLocalizations of(BuildContext context) {
///     return Localizations.of<MyLocalizations>(context, MyLocalizations);
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
/// `MyLocalizations` class.
///
/// One could choose another approach for loading localized resources and looking them up while
/// still conforming to the structure of this example.
class Localizations extends StatefulWidget {
  Localizations({
    Key key,
    @required this.locale,
    this.delegate,
    this.child
  }) : super(key: key) {
    assert(locale != null);
  }

  /// The resources returned by [Localizations.of] will be specific to this locale.
  final Locale locale;

  /// This delegate is responsible for loading and caching resources for `locale`.
  ///
  /// Typically defined with [DefaultLocalizationsDelegate].
  final LocalizationsDelegate delegate;

  /// The widget below this widget in the tree.
  final Widget child;

  /// The locale of the Localizations widget for the widget tree that
  /// corresponds to [BuildContext] `context`.
  static Locale localeOf(BuildContext context) {
    assert(context != null);
    final _LocalizationsScope scope = context.inheritFromWidgetOfExactType(_LocalizationsScope);
    return scope.localizationsState.locale;
  }

  /// Returns the 'type' localized resources for the widget tree that
  /// corresponds to [BuildContext] `context`.
  ///
  /// This method is typically used by a static factory method on the 'type'
  /// class. For example Flutter's MaterialLocalizations class looks up Material
  /// resources with a method defined like this:
  ///
  /// ```dart
  /// static MaterialLocalizations of(BuildContext context) {
  ///    return Localizations.of<MaterialLocalizations>(context, MaterialLocalizations);
  /// }
  /// ```
  static T of<T>(BuildContext context, Type type) {
    assert(context != null);
    assert(type != null);
    final _LocalizationsScope scope = context.inheritFromWidgetOfExactType(_LocalizationsScope);
    return scope.localizationsState.resourcesFor<T>(type);
  }

  @override
  _LocalizationsState createState() => new _LocalizationsState();
}

class _LocalizationsState extends State<Localizations> {
  final GlobalKey _localizedResourcesScopeKey = new GlobalKey();

  Locale get locale => _locale;
  Locale _locale;

  @override
  void initState() {
    super.initState();
    if (widget.delegate == null)
      _locale = widget.locale;
    else
      load(widget.locale);
  }

  @override
  void didUpdateWidget(Localizations old) {
    super.didUpdateWidget(old);
    if (widget.delegate != old.delegate && widget.delegate != null)
      load(widget.locale);
  }

  void load(Locale locale) {
    final LocalizationsDelegate delegate = widget.delegate;
    if (delegate == null) {
      _locale = locale;
      return;
    }

    Iterable<Type> types;
    final Future<Iterable<Type>> futureTypes = delegate.load(locale)
      .then<Iterable<Type>>((Iterable<Type> value) {
        return types = value;
      });

    if (types != null) {
      // The delegate loaded its resources synchronously, do not rebuild
      _locale = locale;
    } else {
      // Don't rebuild the dependent widgets until the resources for the new locale
      // have finished loading. Until then the old locale will continue to be used.
      futureTypes.then((Iterable<Type> value) {
        if (!mounted)
          return;
        setState(() {
          _locale = locale;
        });
        final InheritedElement scopeElement = _localizedResourcesScopeKey.currentContext;
        scopeElement?.dispatchDidChangeDependencies();
      });
    }
  }

  T resourcesFor<T>(Type type) => widget.delegate?.resourcesFor<T>(_locale, type);

  @override
  Widget build(BuildContext context) {
    // If we're still waiting for resources to load don't call this the "first frame".
    // See https://github.com/flutter/flutter/issues/1865
    if (_locale == null)
      WidgetsBinding.instance.preventThisFrameFromBeingReportedAsFirstFrame();

    return new _LocalizationsScope(
      key: _localizedResourcesScopeKey,
      locale: widget.locale,
      localizationsState: this,
      child: _locale != null ? widget.child : new Container(),
    );
  }
}
