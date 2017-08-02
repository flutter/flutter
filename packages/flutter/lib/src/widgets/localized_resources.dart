// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';

import 'container.dart';
import 'framework.dart';

enum LocalizedResourcesStatus {
  none,
  loading,
  loaded,
}

typedef Future<dynamic> LocalizedResourceLoader(Locale locale);

abstract class LocalizedResourcesDelegate {
  Future<Null> load(Locale locale);
  LocalizedResourcesStatus statusFor(Locale locale);
  T resourcesFor<T>(Locale locale, Type type);
  bool updateShouldNotify(covariant LocalizedResourcesDelegate old);
}

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
    final Iterable<Type> allTypes = allLoaders.keys;
    final Iterable<Future<dynamic>> allFutureValues = allTypes.map((Type type) => allLoaders[type](locale));
    _loading.add(locale);
    return Future.wait<Null>(allFutureValues,
      eagerError: true,
      cleanUp: (List<dynamic> values) {
        _loading.remove(locale);
      }
    ).then((List<dynamic> allValues) {
      _loading.remove(locale);
      final Map<Type, dynamic> resourceMap = new Map<Type, dynamic>.fromIterables(allTypes, allValues);
      assert(resourceMap.values.every((dynamic value) => value != null));
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
    return resources == null ? null : resources[type];
  }

  @override
  bool updateShouldNotify(DefaultLocalizedResourcesDelegate old) => false;
}

class _LocalizedResourcesScope extends InheritedWidget {
  _LocalizedResourcesScope ({
    Key key,
    @required this.locale,
    @required this.localizedResourcesState,
    Widget child
  }) : super(key: key, child: child) {
    assert(localizedResourcesState != null);
  }

  final Locale locale;
  final _LocalizedResourcesState localizedResourcesState;

  @override
  bool updateShouldNotify(_LocalizedResourcesScope old) {
    if (old.locale != locale)
      localizedResourcesState.load(locale);
    return false;
  }
}

abstract class LocalizedResourcesData {
  Locale get locale;
  T resourcesFor<T>(Type type);
}

class LocalizedResources extends StatefulWidget {
  LocalizedResources({
    Key key,
    @required this.locale,
    this.delegate,
    this.child
  }) : super(key: key) {
    assert(locale != null);
  }

  final Locale locale;
  final LocalizedResourcesDelegate delegate;
  final Widget child;

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
      scopeElement.dispatchDidChangeDependencies();
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
