// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:flutter/widgets.dart';

void main() {
  group('PageRouteObserver', () {
    test('calls correct listeners', () {
      final PageRouteObserver observer = new PageRouteObserver();
      final PageRouteAware pageRouteAware1 = new MockRouteAware();
      final MockPageRoute route1 = new MockPageRoute();
      observer.subscribe(pageRouteAware1, route1);
      verify(pageRouteAware1.didPush()).called(1);

      final PageRouteAware pageRouteAware2 = new MockRouteAware();
      final MockPageRoute route2 = new MockPageRoute();
      observer.didPush(route2, route1);
      verify(pageRouteAware1.didPushNext()).called(1);

      observer.subscribe(pageRouteAware2, route2);
      verify(pageRouteAware2.didPush()).called(1);

      observer.didPop(route2, route1);
      verify(pageRouteAware2.didPop()).called(1);
      verify(pageRouteAware1.didPopNext()).called(1);
    });

    test('does not call listeners for non-PageRoute', () {
      final PageRouteObserver observer = new PageRouteObserver();
      final PageRouteAware pageRouteAware = new MockRouteAware();
      final MockPageRoute pageRoute = new MockPageRoute();
      final MockRoute route = new MockRoute();
      observer.subscribe(pageRouteAware, pageRoute);
      verify(pageRouteAware.didPush());

      observer.didPush(route, pageRoute);
      observer.didPop(route, pageRoute);
      verifyNoMoreInteractions(pageRouteAware);
    });
  });
}

class MockPageRoute extends Mock implements PageRoute<dynamic> {}

class MockRoute extends Mock implements Route<dynamic> {}

class MockRouteAware extends Mock implements PageRouteAware {}
