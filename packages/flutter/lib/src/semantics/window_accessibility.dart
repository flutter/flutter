import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart' show SystemChannels;
import 'package:meta/meta.dart';

class AccessibilityNavigatorObserver extends NavigatorObserver {
  AccessibilityNavigatorObserver({this.routeNames = const <String, String>{}});

  final Map<String, String> routeNames;


  @override
  void didPop(Route route, Route previousRoute) {
    final String name = previousRoute.settings.name;
    SystemChannels.accessibility.send(new RouteChangeEvent(routeName: routeNames[name] ?? name).toMap());
  }

  @override
  void didPush(Route route, Route previousRoute) {
    final String name = route.settings.name;
    SystemChannels.accessibility.send(new RouteChangeEvent(routeName: routeNames[name] ?? name).toMap());
  }
}

class RouteChangeEvent extends SemanticsEvent {
  RouteChangeEvent({@required this.routeName}) :
    assert(routeName != null),
    super('route');

  final String routeName;

  @override
  Map<String, dynamic> getDataMap() {
    return <String, dynamic>{
      'routeName': routeName,
    };
  }
}