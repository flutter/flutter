// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Simple router basic functionality - synchronized', (WidgetTester tester) async {
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider();
    provider.value = const RouteInformation(
      location: 'initial',
    );
    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: SimpleRouterDelegate(
          builder: (BuildContext context, RouteInformation? information) {
            return Text(information!.location!);
          },
        ),
      ),
    ));
    expect(find.text('initial'), findsOneWidget);

    provider.value = const RouteInformation(
      location: 'update',
    );
    await tester.pump();
    expect(find.text('initial'), findsNothing);
    expect(find.text('update'), findsOneWidget);
  });

  testWidgets('Simple router basic functionality - asynchronized', (WidgetTester tester) async {
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider();
    provider.value = const RouteInformation(
      location: 'initial',
    );
    final SimpleAsyncRouteInformationParser parser = SimpleAsyncRouteInformationParser();
    final SimpleAsyncRouterDelegate delegate = SimpleAsyncRouterDelegate(
      builder: (BuildContext context, RouteInformation? information) {
        if (information == null) {
          return const Text('waiting');
        }
        return Text(information.location!);
      },
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(buildBoilerPlate(
        Router<RouteInformation>(
          routeInformationProvider: provider,
          routeInformationParser: parser,
          routerDelegate: delegate,
        ),
      ));
      // Future has not yet completed.
      expect(find.text('waiting'), findsOneWidget);

      await parser.parsingFuture;
      await delegate.setNewRouteFuture;
      await tester.pump();
      expect(find.text('initial'), findsOneWidget);

      provider.value = const RouteInformation(
        location: 'update',
      );
      await tester.pump();
      // Future has not yet completed.
      expect(find.text('initial'), findsOneWidget);

      await parser.parsingFuture;
      await delegate.setNewRouteFuture;
      await tester.pump();
      expect(find.text('update'), findsOneWidget);
    });
  });

  testWidgets('Interrupts route parsing should not crash', (WidgetTester tester) async {
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider();
    provider.value = const RouteInformation(
      location: 'initial',
    );
    final CompleterRouteInformationParser parser = CompleterRouteInformationParser();
    final SimpleAsyncRouterDelegate delegate = SimpleAsyncRouterDelegate(
      builder: (BuildContext context, RouteInformation? information) {
        if (information == null) {
          return const Text('waiting');
        }
        return Text(information.location!);
      },
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(buildBoilerPlate(
        Router<RouteInformation>(
          routeInformationProvider: provider,
          routeInformationParser: parser,
          routerDelegate: delegate,
        ),
      ));
      // Future has not yet completed.
      expect(find.text('waiting'), findsOneWidget);

      final Completer<void> firstTransactionCompleter = parser.completer;

      // Start a new parsing transaction before the previous one complete.
      provider.value = const RouteInformation(
        location: 'update',
      );
      await tester.pump();
      expect(find.text('waiting'), findsOneWidget);
      // Completing the previous transaction does not cause an update.
      firstTransactionCompleter.complete();
      await firstTransactionCompleter.future;
      await tester.pump();
      expect(find.text('waiting'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Make sure the new transaction can complete and update correctly.
      parser.completer.complete();
      await parser.completer.future;
      await delegate.setNewRouteFuture;
      await tester.pump();
      expect(find.text('update'), findsOneWidget);
    });
  });

  testWidgets('Router.maybeOf can be null', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(buildBoilerPlate(
      Text('dummy', key: key),
    ));
    final BuildContext textContext = key.currentContext!;

    // This should not throw error.
    final Router<dynamic>? router = Router.maybeOf(textContext);
    expect(router, isNull);

    expect(
      () => Router.of(textContext),
      throwsA(isFlutterError.having((FlutterError e) => e.message, 'message', startsWith('Router')))
    );
  });

  testWidgets('Simple router can handle pop route', (WidgetTester tester) async {
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider();
    provider.value = const RouteInformation(
      location: 'initial',
    );
    final BackButtonDispatcher dispatcher = RootBackButtonDispatcher();

    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: SimpleRouterDelegate(
          builder: (BuildContext context, RouteInformation? information) {
            return Text(information!.location!);
          },
          onPopRoute: () {
            provider.value = const RouteInformation(
              location: 'popped',
            );
            return SynchronousFuture<bool>(true);
          },
        ),
        backButtonDispatcher: dispatcher,
      ),
    ));
    expect(find.text('initial'), findsOneWidget);

    bool result = false;
    // SynchronousFuture should complete immediately.
    dispatcher.invokeCallback(SynchronousFuture<bool>(false))
      .then((bool data) {
        result = data;
      });
    expect(result, isTrue);

    await tester.pump();
    expect(find.text('popped'), findsOneWidget);
  });

  testWidgets('Router throw when passing routeInformationProvider without routeInformationParser', (WidgetTester tester) async {
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider();
    provider.value = const RouteInformation(
      location: 'initial',
    );
    expect(
      () {
        Router<RouteInformation>(
          routeInformationProvider: provider,
          routerDelegate: SimpleRouterDelegate(
            builder: (BuildContext context, RouteInformation? information) {
              return Text(information!.location!);
            },
          ),
        );
      },
      throwsA(isAssertionError.having(
        (AssertionError e) => e.message,
        'message',
        'A routeInformationParser must be provided when a routeInformationProvider is specified.',
      )),
    );
  });

  testWidgets('PopNavigatorRouterDelegateMixin works', (WidgetTester tester) async {
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider();
    provider.value = const RouteInformation(
      location: 'initial',
    );
    final BackButtonDispatcher dispatcher = RootBackButtonDispatcher();
    final SimpleNavigatorRouterDelegate delegate = SimpleNavigatorRouterDelegate(
      builder: (BuildContext context, RouteInformation? information) {
        return Text(information!.location!);
      },
      onPopPage: (Route<void> route, void result) {
        provider.value = const RouteInformation(
          location: 'popped',
        );
        return route.didPop(result);
      },
    );
    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: delegate,
        backButtonDispatcher: dispatcher,
      ),
    ));
    expect(find.text('initial'), findsOneWidget);

    // Pushes a nameless route.
    showDialog<void>(
      useRootNavigator: false,
      context: delegate.navigatorKey.currentContext!,
      builder: (BuildContext context) => const Text('dialog'),
    );
    await tester.pumpAndSettle();
    expect(find.text('dialog'), findsOneWidget);

    // Pops the nameless route and makes sure the initial page is shown.
    bool result = false;
    result = await dispatcher.invokeCallback(SynchronousFuture<bool>(false));
    expect(result, isTrue);

    await tester.pumpAndSettle();
    expect(find.text('initial'), findsOneWidget);
    expect(find.text('dialog'), findsNothing);

    // Pops one more time.
    result = false;
    result = await dispatcher.invokeCallback(SynchronousFuture<bool>(false));
    expect(result, isTrue);
    await tester.pumpAndSettle();
    expect(find.text('popped'), findsOneWidget);
  });

  testWidgets('Nested routers back button dispatcher works', (WidgetTester tester) async {
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider();
    provider.value = const RouteInformation(
      location: 'initial',
    );
    final BackButtonDispatcher outerDispatcher = RootBackButtonDispatcher();
    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        backButtonDispatcher: outerDispatcher,
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: SimpleRouterDelegate(
          builder: (BuildContext context, RouteInformation? information) {
            final BackButtonDispatcher innerDispatcher = ChildBackButtonDispatcher(outerDispatcher);
            innerDispatcher.takePriority();
            // Creates the sub-router.
            return Router<RouteInformation>(
              backButtonDispatcher: innerDispatcher,
              routerDelegate: SimpleRouterDelegate(
                builder: (BuildContext context, RouteInformation? innerInformation) {
                  return Text(information!.location!);
                },
                onPopRoute: () {
                  provider.value = const RouteInformation(
                    location: 'popped inner',
                  );
                  return SynchronousFuture<bool>(true);
                },
              ),
            );
          },
          onPopRoute: () {
            provider.value = const RouteInformation(
              location: 'popped outer',
            );
            return SynchronousFuture<bool>(true);
          },
        ),
      ),
    ));
    expect(find.text('initial'), findsOneWidget);

    // The outer dispatcher should trigger the pop on the inner router.
    bool result = false;
    result = await outerDispatcher.invokeCallback(SynchronousFuture<bool>(false));
    expect(result, isTrue);
    await tester.pump();
    expect(find.text('popped inner'), findsOneWidget);
  });

  testWidgets('Nested router back button dispatcher works for multiple children', (WidgetTester tester) async {
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider();
    provider.value = const RouteInformation(
      location: 'initial',
    );
    final BackButtonDispatcher outerDispatcher = RootBackButtonDispatcher();
    final BackButtonDispatcher innerDispatcher1 = ChildBackButtonDispatcher(outerDispatcher);
    final BackButtonDispatcher innerDispatcher2 = ChildBackButtonDispatcher(outerDispatcher);
    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        backButtonDispatcher: outerDispatcher,
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: SimpleRouterDelegate(
          builder: (BuildContext context, RouteInformation? information) {
            // Creates the sub-router.
            return Column(
              children: <Widget>[
                Text(information!.location!),
                Router<RouteInformation>(
                  backButtonDispatcher: innerDispatcher1,
                  routerDelegate: SimpleRouterDelegate(
                    builder: (BuildContext context, RouteInformation? innerInformation) {
                      return Container();
                    },
                    onPopRoute: () {
                      provider.value = const RouteInformation(
                        location: 'popped inner1',
                      );
                      return SynchronousFuture<bool>(true);
                    },
                  ),
                ),
                Router<RouteInformation>(
                  backButtonDispatcher: innerDispatcher2,
                  routerDelegate: SimpleRouterDelegate(
                    builder: (BuildContext context, RouteInformation? innerInformation) {
                      return Container();
                    },
                    onPopRoute: () {
                      provider.value = const RouteInformation(
                        location: 'popped inner2',
                      );
                      return SynchronousFuture<bool>(true);
                    },
                  ),
                ),
              ],
            );
          },
          onPopRoute: () {
            provider.value = const RouteInformation(
              location: 'popped outer',
            );
            return SynchronousFuture<bool>(true);
          },
        ),
      ),
    ));
    expect(find.text('initial'), findsOneWidget);

    // If none of the children have taken the priority, the root router handles
    // the pop.
    bool result = false;
    result = await outerDispatcher.invokeCallback(SynchronousFuture<bool>(false));
    expect(result, isTrue);
    await tester.pump();
    expect(find.text('popped outer'), findsOneWidget);

    innerDispatcher1.takePriority();
    result = false;
    result = await outerDispatcher.invokeCallback(SynchronousFuture<bool>(false));
    expect(result, isTrue);
    await tester.pump();
    expect(find.text('popped inner1'), findsOneWidget);

    // The last child dispatcher that took priority handles the pop.
    innerDispatcher2.takePriority();
    result = false;
    result = await outerDispatcher.invokeCallback(SynchronousFuture<bool>(false));
    expect(result, isTrue);
    await tester.pump();
    expect(find.text('popped inner2'), findsOneWidget);
  });

  testWidgets('ChildBackButtonDispatcher can be replaced without calling the takePriority', (WidgetTester tester) async {

    final BackButtonDispatcher outerDispatcher = RootBackButtonDispatcher();
    BackButtonDispatcher innerDispatcher = ChildBackButtonDispatcher(outerDispatcher);
    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        backButtonDispatcher: outerDispatcher,
        routerDelegate: SimpleRouterDelegate(
          builder: (BuildContext context, RouteInformation? information) {
            // Creates the sub-router.
            return Column(
              children: <Widget>[
                const Text('initial'),
                Router<RouteInformation>(
                  backButtonDispatcher: innerDispatcher,
                  routerDelegate: SimpleRouterDelegate(
                    builder: (BuildContext context, RouteInformation? innerInformation) {
                      return Container();
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ));

    // Creates a new child back button dispatcher and rebuild, this will cause
    // the old one to be replaced and discarded.
    innerDispatcher = ChildBackButtonDispatcher(outerDispatcher);
    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        backButtonDispatcher: outerDispatcher,
        routerDelegate: SimpleRouterDelegate(
          builder: (BuildContext context, RouteInformation? information) {
            // Creates the sub-router.
            return Column(
              children: <Widget>[
                const Text('initial'),
                Router<RouteInformation>(
                  backButtonDispatcher: innerDispatcher,
                  routerDelegate: SimpleRouterDelegate(
                    builder: (BuildContext context, RouteInformation? innerInformation) {
                      return Container();
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
  });

testWidgets('ChildBackButtonDispatcher take priority recursively', (WidgetTester tester) async {

    final BackButtonDispatcher outerDispatcher = RootBackButtonDispatcher();
    final BackButtonDispatcher innerDispatcher1 = ChildBackButtonDispatcher(outerDispatcher);
    final BackButtonDispatcher innerDispatcher2 = ChildBackButtonDispatcher(innerDispatcher1);
    final BackButtonDispatcher innerDispatcher3 = ChildBackButtonDispatcher(innerDispatcher2);
    bool isPopped = false;
    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        backButtonDispatcher: outerDispatcher,
        routerDelegate: SimpleRouterDelegate(
          builder: (BuildContext context, RouteInformation? information) {
            // Creates the sub-router.
            return Router<RouteInformation>(
              backButtonDispatcher: innerDispatcher1,
              routerDelegate: SimpleRouterDelegate(
                builder: (BuildContext context, RouteInformation? innerInformation) {
                  return Router<RouteInformation>(
                    backButtonDispatcher: innerDispatcher2,
                    routerDelegate: SimpleRouterDelegate(
                      builder: (BuildContext context, RouteInformation? innerInformation) {
                        return Router<RouteInformation>(
                          backButtonDispatcher: innerDispatcher3,
                          routerDelegate: SimpleRouterDelegate(
                            onPopRoute: () {
                              isPopped = true;
                              return SynchronousFuture<bool>(true);
                            },
                            builder: (BuildContext context, RouteInformation? innerInformation) {
                              return Container();
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    ));
    // This should work without calling the takePriority on the innerDispatcher2
    // and the innerDispatcher1.
    innerDispatcher3.takePriority();
    bool result = false;
    result = await outerDispatcher.invokeCallback(SynchronousFuture<bool>(false));
    expect(result, isTrue);
    expect(isPopped, isTrue);
  });

  testWidgets('router does report URL change correctly', (WidgetTester tester) async {
    RouteInformation? reportedRouteInformation;
    RouteInformationReportingType? reportedType;
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider(
      onRouterReport: (RouteInformation information, RouteInformationReportingType type) {
        // Makes sure we only report once after manually cleaning up.
        expect(reportedRouteInformation, isNull);
        expect(reportedType, isNull);
        reportedRouteInformation = information;
        reportedType = type;
      },
    );
    final SimpleRouterDelegate delegate = SimpleRouterDelegate(
      reportConfiguration: true,
      builder: (BuildContext context, RouteInformation? information) {
        return Text(information!.location!);
      },
    );
    delegate.onPopRoute = () {
      delegate.routeInformation = const RouteInformation(
        location: 'popped',
      );
      return SynchronousFuture<bool>(true);
    };
    final BackButtonDispatcher outerDispatcher = RootBackButtonDispatcher();

    provider.value = const RouteInformation(
      location: 'initial',
    );

    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        backButtonDispatcher: outerDispatcher,
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: delegate,
      ),
    ));
    expect(find.text('initial'), findsOneWidget);
    expect(reportedRouteInformation!.location, 'initial');
    expect(reportedType, RouteInformationReportingType.none);
    reportedRouteInformation = null;
    reportedType = null;
    delegate.routeInformation = const RouteInformation(
      location: 'update',
    );
    await tester.pump();
    expect(find.text('initial'), findsNothing);
    expect(find.text('update'), findsOneWidget);
    expect(reportedRouteInformation!.location, 'update');
    expect(reportedType, RouteInformationReportingType.none);

    // The router should report as non navigation event if only state changes.
    reportedRouteInformation = null;
    reportedType = null;
    delegate.routeInformation = const RouteInformation(
      location: 'update',
      state: 'another state',
    );
    await tester.pump();
    expect(find.text('update'), findsOneWidget);
    expect(reportedRouteInformation!.location, 'update');
    expect(reportedRouteInformation!.state, 'another state');
    expect(reportedType, RouteInformationReportingType.none);

    reportedRouteInformation = null;
    reportedType = null;
    bool result = false;
    result = await outerDispatcher.invokeCallback(SynchronousFuture<bool>(false));
    expect(result, isTrue);
    await tester.pump();
    expect(find.text('popped'), findsOneWidget);
    expect(reportedRouteInformation!.location, 'popped');
    expect(reportedType, RouteInformationReportingType.none);
  });

  testWidgets('router can be forced to recognize or ignore navigating events', (WidgetTester tester) async {
    RouteInformation? reportedRouteInformation;
    RouteInformationReportingType? reportedType;
    bool isNavigating = false;
    late RouteInformation nextRouteInformation;
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider(
      onRouterReport: (RouteInformation information, RouteInformationReportingType type) {
        // Makes sure we only report once after manually cleaning up.
        expect(reportedRouteInformation, isNull);
        expect(reportedType, isNull);
        reportedRouteInformation = information;
        reportedType = type;
      },
    );
    provider.value = const RouteInformation(
      location: 'initial',
    );
    final SimpleRouterDelegate delegate = SimpleRouterDelegate(reportConfiguration: true);
    delegate.builder = (BuildContext context, RouteInformation? information) {
      return ElevatedButton(
        child: Text(information!.location!),
        onPressed: () {
          if (isNavigating) {
            Router.navigate(context, () {
              if (delegate.routeInformation != nextRouteInformation) {
                delegate.routeInformation = nextRouteInformation;
              }
            });
          } else {
            Router.neglect(context, () {
              if (delegate.routeInformation != nextRouteInformation) {
                delegate.routeInformation = nextRouteInformation;
              }
            });
          }
        },
      );
    };
    final BackButtonDispatcher outerDispatcher = RootBackButtonDispatcher();

    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        backButtonDispatcher: outerDispatcher,
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: delegate,
      ),
    ));
    expect(find.text('initial'), findsOneWidget);
    expect(reportedRouteInformation!.location, 'initial');
    expect(reportedType, RouteInformationReportingType.none);
    reportedType = null;
    reportedRouteInformation = null;

    nextRouteInformation = const RouteInformation(
      location: 'update',
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(find.text('initial'), findsNothing);
    expect(find.text('update'), findsOneWidget);
    expect(reportedType, RouteInformationReportingType.neglect);
    expect(reportedRouteInformation!.location, 'update');
    reportedType = null;
    reportedRouteInformation = null;

    isNavigating = true;
    // This should not trigger any real navigating event because the
    // nextRouteInformation does not change. However, the router should still
    // report a route information because isNavigating = true.
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(reportedType, RouteInformationReportingType.navigate);
    expect(reportedRouteInformation!.location, 'update');
    reportedType = null;
    reportedRouteInformation = null;
  });

  testWidgets('router ignore navigating events updates RouteInformationProvider', (WidgetTester tester) async {
    RouteInformation? updatedRouteInformation;
    late RouteInformation nextRouteInformation;
    RouteInformationReportingType? reportingType;
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider(
      onRouterReport: (RouteInformation information, RouteInformationReportingType type) {
        expect(reportingType, isNull);
        expect(updatedRouteInformation, isNull);
        updatedRouteInformation = information;
        reportingType = type;
      },
    );
    provider.value = const RouteInformation(
      location: 'initial',
    );
    final SimpleRouterDelegate delegate = SimpleRouterDelegate(reportConfiguration: true);
    delegate.builder = (BuildContext context, RouteInformation? information) {
      return ElevatedButton(
        child: Text(information!.location!),
        onPressed: () {
          Router.neglect(context, () {
            if (delegate.routeInformation != nextRouteInformation) {
              delegate.routeInformation = nextRouteInformation;
            }
          });
        },
      );
    };
    final BackButtonDispatcher outerDispatcher = RootBackButtonDispatcher();

    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        backButtonDispatcher: outerDispatcher,
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: delegate,
      ),
    ));
    expect(find.text('initial'), findsOneWidget);
    expect(updatedRouteInformation!.location, 'initial');
    expect(reportingType, RouteInformationReportingType.none);
    updatedRouteInformation = null;
    reportingType = null;

    nextRouteInformation = const RouteInformation(
      location: 'update',
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(find.text('initial'), findsNothing);
    expect(find.text('update'), findsOneWidget);
    expect(updatedRouteInformation!.location, 'update');
    expect(reportingType, RouteInformationReportingType.neglect);
  });

  testWidgets('state change without location changes updates RouteInformationProvider', (WidgetTester tester) async {
    RouteInformation? updatedRouteInformation;
    late RouteInformation nextRouteInformation;
    RouteInformationReportingType? reportingType;
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider(
      onRouterReport: (RouteInformation information, RouteInformationReportingType type) {
        // This should never be a navigation event.
        expect(reportingType, isNull);
        expect(updatedRouteInformation, isNull);
        updatedRouteInformation = information;
        reportingType = type;
      },
    );
    provider.value = const RouteInformation(
      location: 'initial',
      state: 'state1',
    );
    final SimpleRouterDelegate delegate = SimpleRouterDelegate(reportConfiguration: true);
    delegate.builder = (BuildContext context, RouteInformation? information) {
      return ElevatedButton(
        child: Text(information!.location!),
        onPressed: () {
          delegate.routeInformation = nextRouteInformation;
        },
      );
    };
    final BackButtonDispatcher outerDispatcher = RootBackButtonDispatcher();

    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        backButtonDispatcher: outerDispatcher,
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: delegate,
      ),
    ));
    expect(find.text('initial'), findsOneWidget);
    expect(updatedRouteInformation!.location, 'initial');
    expect(reportingType, RouteInformationReportingType.none);
    updatedRouteInformation = null;
    reportingType = null;

    nextRouteInformation = const RouteInformation(
      location: 'initial',
      state: 'state2',
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(updatedRouteInformation!.location, 'initial');
    expect(updatedRouteInformation!.state, 'state2');
    expect(reportingType, RouteInformationReportingType.none);
  });

  testWidgets('PlatformRouteInformationProvider works', (WidgetTester tester) async {
    final RouteInformationProvider provider = PlatformRouteInformationProvider(
      initialRouteInformation: const RouteInformation(
        location: 'initial',
      ),
    );
    final SimpleRouterDelegate delegate = SimpleRouterDelegate(
      builder: (BuildContext context, RouteInformation? information) {
        final List<Widget> children = <Widget>[];
        if (information!.location != null) {
          children.add(Text(information.location!));
        }
        if (information.state != null) {
          children.add(Text(information.state.toString()));
        }
        return Column(
          children: children,
        );
      },
    );

    await tester.pumpWidget(MaterialApp.router(
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: delegate,
    ));
    expect(find.text('initial'), findsOneWidget);

    // Pushes through the `pushRouteInformation` in the navigation method channel.
    const Map<String, dynamic> testRouteInformation = <String, dynamic>{
      'location': 'testRouteName',
      'state': 'state',
    };
    final ByteData routerMessage = const JSONMethodCodec().encodeMethodCall(
      const MethodCall('pushRouteInformation', testRouteInformation),
    );
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage('flutter/navigation', routerMessage, (_) { });
    await tester.pump();
    expect(find.text('testRouteName'), findsOneWidget);
    expect(find.text('state'), findsOneWidget);

    // Pushes through the `pushRoute` in the navigation method channel.
    const String testRouteName = 'newTestRouteName';
    final ByteData message = const JSONMethodCodec().encodeMethodCall(
      const MethodCall('pushRoute', testRouteName),
    );
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage('flutter/navigation', message, (_) { });
    await tester.pump();
    expect(find.text('newTestRouteName'), findsOneWidget);
  });

  testWidgets('PlatformRouteInformationProvider updates route information', (WidgetTester tester) async {
    final List<MethodCall> log = <MethodCall>[];
    TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        SystemChannels.navigation,
        (MethodCall methodCall) async {
          log.add(methodCall);
	  return null;
        }
      );
    final RouteInformationProvider provider = PlatformRouteInformationProvider(
      initialRouteInformation: const RouteInformation(
        location: 'initial',
      ),
    );

    log.clear();
    provider.routerReportsNewRouteInformation(const RouteInformation(location: 'a', state: true));
    // Implicit reporting pushes new history entry if the location changes.
    expect(log, <Object>[
      isMethodCall('selectMultiEntryHistory', arguments: null),
      isMethodCall('routeInformationUpdated', arguments: <String, dynamic>{ 'location': 'a', 'state': true, 'replace': false }),
    ]);
    log.clear();
    provider.routerReportsNewRouteInformation(const RouteInformation(location: 'a', state: false));
    // Since the location is the same, the provider sends replaces message.
    expect(log, <Object>[
      isMethodCall('selectMultiEntryHistory', arguments: null),
      isMethodCall('routeInformationUpdated', arguments: <String, dynamic>{ 'location': 'a', 'state': false, 'replace': true }),
    ]);

    log.clear();
    provider.routerReportsNewRouteInformation(const RouteInformation(location: 'b', state: false), type: RouteInformationReportingType.neglect);
    expect(log, <Object>[
      isMethodCall('selectMultiEntryHistory', arguments: null),
      isMethodCall('routeInformationUpdated', arguments: <String, dynamic>{ 'location': 'b', 'state': false, 'replace': true }),
    ]);

    log.clear();
    provider.routerReportsNewRouteInformation(const RouteInformation(location: 'b', state: false), type: RouteInformationReportingType.navigate);
    expect(log, <Object>[
      isMethodCall('selectMultiEntryHistory', arguments: null),
      isMethodCall('routeInformationUpdated', arguments: <String, dynamic>{ 'location': 'b', 'state': false, 'replace': false }),
    ]);
  });

  testWidgets('RootBackButtonDispatcher works', (WidgetTester tester) async {
    final BackButtonDispatcher outerDispatcher = RootBackButtonDispatcher();
    final RouteInformationProvider provider = PlatformRouteInformationProvider(
      initialRouteInformation: const RouteInformation(
        location: 'initial',
      ),
    );
    final SimpleRouterDelegate delegate = SimpleRouterDelegate(
      reportConfiguration: true,
      builder: (BuildContext context, RouteInformation? information) {
        return Text(information!.location!);
      },
    );
    delegate.onPopRoute = () {
      delegate.routeInformation = const RouteInformation(
        location: 'popped',
      );
      return SynchronousFuture<bool>(true);
    };

    await tester.pumpWidget(MaterialApp.router(
      backButtonDispatcher: outerDispatcher,
      routeInformationProvider: provider,
      routeInformationParser: SimpleRouteInformationParser(),
      routerDelegate: delegate,
    ));
    expect(find.text('initial'), findsOneWidget);

    // Pop route through the message channel.
    final ByteData message = const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute'));
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage('flutter/navigation', message, (_) { });
    await tester.pump();
    expect(find.text('popped'), findsOneWidget);
  });

  testWidgets('BackButtonListener takes priority over root back dispatcher', (WidgetTester tester) async {
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider();
    provider.value = const RouteInformation(
      location: 'initial',
    );
    final BackButtonDispatcher outerDispatcher = RootBackButtonDispatcher();
    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        backButtonDispatcher: outerDispatcher,
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: SimpleRouterDelegate(
          builder: (BuildContext context, RouteInformation? information) {
            // Creates the sub-router.
            return Column(
              children: <Widget>[
                Text(information!.location!),
                BackButtonListener(
                  child: Container(),
                  onBackButtonPressed: () {
                      provider.value = const RouteInformation(
                        location: 'popped inner1',
                      );
                      return SynchronousFuture<bool>(true);
                    },
                ),
              ],
            );
          },
          onPopRoute: () {
            provider.value = const RouteInformation(
              location: 'popped outer',
            );
            return SynchronousFuture<bool>(true);
          },
        ),
      ),
    ));
    expect(find.text('initial'), findsOneWidget);

    bool result = false;
    result = await outerDispatcher.invokeCallback(SynchronousFuture<bool>(false));
    expect(result, isTrue);
    await tester.pump();
    expect(find.text('popped inner1'), findsOneWidget);
  });

  testWidgets('BackButtonListener updates callback if it has been changed', (WidgetTester tester) async {
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider();
    provider.value = const RouteInformation(
      location: 'initial',
    );
    final BackButtonDispatcher outerDispatcher = RootBackButtonDispatcher();
    final SimpleRouterDelegate routerDelegate = SimpleRouterDelegate()
      ..builder = (BuildContext context, RouteInformation? information) {
            // Creates the sub-router.
            return Column(
              children: <Widget>[
                Text(information!.location!),
                BackButtonListener(
                  child: Container(),
                  onBackButtonPressed: () {
                      provider.value = const RouteInformation(
                        location: 'first callback',
                      );
                      return SynchronousFuture<bool>(true);
                    },
                ),
              ],
            );
          }
        ..onPopRoute = () {
            provider.value = const RouteInformation(
              location: 'popped outer',
            );
            return SynchronousFuture<bool>(true);
          };

    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        backButtonDispatcher: outerDispatcher,
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: routerDelegate,
      ),
    ));

    routerDelegate
      ..builder = (BuildContext context, RouteInformation? information) {
        // Creates the sub-router.
        return Column(
          children: <Widget>[
            Text(information!.location!),
            BackButtonListener(
              child: Container(),
              onBackButtonPressed: () {
                  provider.value = const RouteInformation(
                    location: 'second callback',
                  );
                  return SynchronousFuture<bool>(true);
                },
            ),
          ],
        );
      }
      ..onPopRoute = () {
        provider.value = const RouteInformation(
          location: 'popped outer',
        );
        return SynchronousFuture<bool>(true);
      };

    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        backButtonDispatcher: outerDispatcher,
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: routerDelegate,
      ),
    ));
    await tester.pump();
    await outerDispatcher.invokeCallback(SynchronousFuture<bool>(false));
    await tester.pump();
    expect(find.text('second callback'), findsOneWidget);
  });

  testWidgets('BackButtonListener clears callback if it is disposed', (WidgetTester tester) async {
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider();
    provider.value = const RouteInformation(
      location: 'initial',
    );
    final BackButtonDispatcher outerDispatcher = RootBackButtonDispatcher();
    final SimpleRouterDelegate routerDelegate = SimpleRouterDelegate()
      ..builder = (BuildContext context, RouteInformation? information) {
            // Creates the sub-router.
            return Column(
              children: <Widget>[
                Text(information!.location!),
                BackButtonListener(
                  child: Container(),
                  onBackButtonPressed: () {
                      provider.value = const RouteInformation(
                        location: 'first callback',
                      );
                      return SynchronousFuture<bool>(true);
                    },
                ),
              ],
            );
          }
        ..onPopRoute = () {
            provider.value = const RouteInformation(
              location: 'popped outer',
            );
            return SynchronousFuture<bool>(true);
          };

    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        backButtonDispatcher: outerDispatcher,
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: routerDelegate,
      ),
    ));

    routerDelegate
      ..builder = (BuildContext context, RouteInformation? information) {
        // Creates the sub-router.
        return Column(
          children: <Widget>[
            Text(information!.location!),
          ],
        );
      }
      ..onPopRoute = () {
        provider.value = const RouteInformation(
          location: 'popped outer',
        );
        return SynchronousFuture<bool>(true);
      };

    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        backButtonDispatcher: outerDispatcher,
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: routerDelegate,
      ),
    ));
    await tester.pump();
    await outerDispatcher.invokeCallback(SynchronousFuture<bool>(false));
    await tester.pump();
    expect(find.text('popped outer'), findsOneWidget);
  });

  testWidgets('Nested backButtonListener should take priority', (WidgetTester tester) async {
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider();
    provider.value = const RouteInformation(
      location: 'initial',
    );
    final BackButtonDispatcher outerDispatcher = RootBackButtonDispatcher();
    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        backButtonDispatcher: outerDispatcher,
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: SimpleRouterDelegate(
          builder: (BuildContext context, RouteInformation? information) {
            // Creates the sub-router.
            return Column(
              children: <Widget>[
                Text(information!.location!),
                BackButtonListener(
                  child: BackButtonListener(
                    child: Container(),
                    onBackButtonPressed: () {
                      provider.value = const RouteInformation(
                        location: 'popped inner2',
                      );
                      return SynchronousFuture<bool>(true);
                    },
                  ),
                  onBackButtonPressed: () {
                      provider.value = const RouteInformation(
                        location: 'popped inner1',
                      );
                      return SynchronousFuture<bool>(true);
                    },
                ),
              ],
            );
          },
          onPopRoute: () {
            provider.value = const RouteInformation(
              location: 'popped outer',
            );
            return SynchronousFuture<bool>(true);
          },
        ),
      ),
    ));
    expect(find.text('initial'), findsOneWidget);

    bool result = false;
    result = await outerDispatcher.invokeCallback(SynchronousFuture<bool>(false));
    expect(result, isTrue);
    await tester.pump();
    expect(find.text('popped inner2'), findsOneWidget);
  });

  testWidgets('Nested backButtonListener that returns false should call next on the line', (WidgetTester tester) async {
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider();
    provider.value = const RouteInformation(
      location: 'initial',
    );
    final BackButtonDispatcher outerDispatcher = RootBackButtonDispatcher();
    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        backButtonDispatcher: outerDispatcher,
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: SimpleRouterDelegate(
          builder: (BuildContext context, RouteInformation? information) {
            // Creates the sub-router.
            return Column(
              children: <Widget>[
                Text(information!.location!),
                BackButtonListener(
                  child: BackButtonListener(
                    child: Container(),
                    onBackButtonPressed: () {
                      provider.value = const RouteInformation(
                        location: 'popped inner2',
                      );
                      return SynchronousFuture<bool>(false);
                    },
                  ),
                  onBackButtonPressed: () {
                      provider.value = const RouteInformation(
                        location: 'popped inner1',
                      );
                      return SynchronousFuture<bool>(true);
                    },
                ),
              ],
            );
          },
          onPopRoute: () {
            provider.value = const RouteInformation(
              location: 'popped outer',
            );
            return SynchronousFuture<bool>(true);
          },
        ),
      ),
    ));
    expect(find.text('initial'), findsOneWidget);

    bool result = false;
    result = await outerDispatcher.invokeCallback(SynchronousFuture<bool>(false));
    expect(result, isTrue);
    await tester.pump();
    expect(find.text('popped inner1'), findsOneWidget);
  });

  testWidgets('`didUpdateWidget` test', (WidgetTester tester) async {
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider();
    provider.value = const RouteInformation(
      location: 'initial',
    );
    final BackButtonDispatcher outerDispatcher = RootBackButtonDispatcher();
    late StateSetter setState;
    String location = 'first callback';
    final SimpleRouterDelegate routerDelegate = SimpleRouterDelegate()
      ..builder = (BuildContext context, RouteInformation? information) {
        // Creates the sub-router.
        return Column(
          children: <Widget>[
            Text(information!.location!),
            StatefulBuilder(
              builder: (BuildContext context, StateSetter setter) {
                setState = setter;
                return BackButtonListener(
                  child: Container(),
                  onBackButtonPressed: () {
                    provider.value = RouteInformation(
                      location: location,
                    );
                    return SynchronousFuture<bool>(true);
                  },
                );
              },
            ),
          ],
        );
      }
      ..onPopRoute = () {
        provider.value = const RouteInformation(
          location: 'popped outer',
        );
        return SynchronousFuture<bool>(true);
      };

    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        backButtonDispatcher: outerDispatcher,
        routeInformationProvider: provider,
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: routerDelegate,
      ),
    ));

    // Only update BackButtonListener widget.
    setState(() {
      location = 'second callback';
    });

    await tester.pump();
    await outerDispatcher.invokeCallback(SynchronousFuture<bool>(false));
    await tester.pump();
    expect(find.text('second callback'), findsOneWidget);
  });

  testWidgets('Router reports location if it is different from location given by OS', (WidgetTester tester) async {
    final List<RouteInformation> reportedRouteInformation = <RouteInformation>[];
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider(
      onRouterReport: (RouteInformation info, RouteInformationReportingType type) => reportedRouteInformation.add(info),
    )..value = const RouteInformation(location: '/home');

    await tester.pumpWidget(buildBoilerPlate(
      Router<RouteInformation>(
        routeInformationProvider: provider,
        routeInformationParser: RedirectingInformationParser(<String, RouteInformation>{
          '/doesNotExist' : const RouteInformation(location: '/404'),
        }),
        routerDelegate: SimpleRouterDelegate(
          builder: (BuildContext _, RouteInformation? info) => Text('Current route: ${info?.location}'),
          reportConfiguration: true,
        ),
      ),
    ));

    expect(find.text('Current route: /home'), findsOneWidget);
    expect(reportedRouteInformation.single.location, '/home');

    provider.value = const RouteInformation(location: '/doesNotExist');
    await tester.pump();

    expect(find.text('Current route: /404'), findsOneWidget);
    expect(reportedRouteInformation[1].location, '/404');
  });

  testWidgets('RouterInformationParser can look up dependencies and reparse', (WidgetTester tester) async {
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider();
    provider.value = const RouteInformation(
      location: 'initial',
    );
    final BackButtonDispatcher dispatcher = RootBackButtonDispatcher();
    int expectedMaxLines = 1;
    bool parserCalled = false;
    final Widget router = Router<RouteInformation>(
      routeInformationProvider: provider,
      routeInformationParser: CustomRouteInformationParser((RouteInformation information, BuildContext context) {
        parserCalled = true;
        final DefaultTextStyle style = DefaultTextStyle.of(context);
        return RouteInformation(location: '${style.maxLines}');
      }),
      routerDelegate: SimpleRouterDelegate(
        builder: (BuildContext context, RouteInformation? information) {
          return Text(information!.location!);
        },
        onPopRoute: () {
          provider.value = const RouteInformation(
            location: 'popped',
          );
          return SynchronousFuture<bool>(true);
        },
      ),
      backButtonDispatcher: dispatcher,
    );
    await tester.pumpWidget(buildBoilerPlate(
      DefaultTextStyle(
        style: const TextStyle(),
        maxLines: expectedMaxLines,
        child: router,
      ),
    ));

    expect(find.text('$expectedMaxLines'), findsOneWidget);
    expect(parserCalled, isTrue);

    parserCalled = false;
    expectedMaxLines = 2;
    await tester.pumpWidget(buildBoilerPlate(
      DefaultTextStyle(
        style: const TextStyle(),
        maxLines: expectedMaxLines,
        child: router,
      ),
    ));
    await tester.pump();
    expect(find.text('$expectedMaxLines'), findsOneWidget);
    expect(parserCalled, isTrue);
  });

  testWidgets('RouterInformationParser can look up dependencies without reparsing', (WidgetTester tester) async {
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider();
    provider.value = const RouteInformation(
      location: 'initial',
    );
    final BackButtonDispatcher dispatcher = RootBackButtonDispatcher();
    const int expectedMaxLines = 1;
    bool parserCalled = false;
    final Widget router = Router<RouteInformation>(
      routeInformationProvider: provider,
      routeInformationParser: CustomRouteInformationParser((RouteInformation information, BuildContext context) {
        parserCalled = true;
        final DefaultTextStyle style = context.getInheritedWidgetOfExactType<DefaultTextStyle>()!;
        return RouteInformation(location: '${style.maxLines}');
      }),
      routerDelegate: SimpleRouterDelegate(
        builder: (BuildContext context, RouteInformation? information) {
          return Text(information!.location!);
        },
        onPopRoute: () {
          provider.value = const RouteInformation(
            location: 'popped',
          );
          return SynchronousFuture<bool>(true);
        },
      ),
      backButtonDispatcher: dispatcher,
    );
    await tester.pumpWidget(buildBoilerPlate(
      DefaultTextStyle(
        style: const TextStyle(),
        maxLines: expectedMaxLines,
        child: router,
      ),
    ));

    expect(find.text('$expectedMaxLines'), findsOneWidget);
    expect(parserCalled, isTrue);

    parserCalled = false;
    const int newMaxLines = 2;
    // This rebuild should not trigger re-parsing.
    await tester.pumpWidget(buildBoilerPlate(
      DefaultTextStyle(
        style: const TextStyle(),
        maxLines: newMaxLines,
        child: router,
      ),
    ));
    await tester.pump();
    expect(find.text('$newMaxLines'), findsNothing);
    expect(find.text('$expectedMaxLines'), findsOneWidget);
    expect(parserCalled, isFalse);
  });

  testWidgets('Looks up dependencies in RouterDelegate does not trigger re-parsing', (WidgetTester tester) async {
    final SimpleRouteInformationProvider provider = SimpleRouteInformationProvider();
    provider.value = const RouteInformation(
      location: 'initial',
    );
    final BackButtonDispatcher dispatcher = RootBackButtonDispatcher();
    int expectedMaxLines = 1;
    bool parserCalled = false;
    final Widget router = Router<RouteInformation>(
      routeInformationProvider: provider,
      routeInformationParser: CustomRouteInformationParser((RouteInformation information, BuildContext context) {
        parserCalled = true;
        return information;
      }),
      routerDelegate: SimpleRouterDelegate(
        builder: (BuildContext context, RouteInformation? information) {
          final DefaultTextStyle style = DefaultTextStyle.of(context);
          return Text('${style.maxLines}');
        },
        onPopRoute: () {
          provider.value = const RouteInformation(
            location: 'popped',
          );
          return SynchronousFuture<bool>(true);
        },
      ),
      backButtonDispatcher: dispatcher,
    );
    await tester.pumpWidget(buildBoilerPlate(
      DefaultTextStyle(
        style: const TextStyle(),
        maxLines: expectedMaxLines,
        child: router,
      ),
    ));

    expect(find.text('$expectedMaxLines'), findsOneWidget);
    // Initial route will be parsed regardless.
    expect(parserCalled, isTrue);

    parserCalled = false;
    expectedMaxLines = 2;
    await tester.pumpWidget(buildBoilerPlate(
      DefaultTextStyle(
        style: const TextStyle(),
        maxLines: expectedMaxLines,
        child: router,
      ),
    ));
    await tester.pump();
    expect(find.text('$expectedMaxLines'), findsOneWidget);
    expect(parserCalled, isFalse);
  });

  testWidgets('Router can initialize with RouterConfig', (WidgetTester tester) async {
    const String expected = 'text';
    final RouterConfig<RouteInformation> config = RouterConfig<RouteInformation>(
      routeInformationProvider: SimpleRouteInformationProvider()..value = const RouteInformation(location: '/'),
      routeInformationParser: SimpleRouteInformationParser(),
      routerDelegate: SimpleRouterDelegate(
        builder: (_, __) => const Text(expected),
      ),
      backButtonDispatcher: RootBackButtonDispatcher(),
    );
    final Router<RouteInformation> router = Router<RouteInformation>.withConfig(config: config);
    expect(router.routerDelegate, config.routerDelegate);
    expect(router.routeInformationParser, config.routeInformationParser);
    expect(router.routeInformationProvider, config.routeInformationProvider);
    expect(router.backButtonDispatcher, config.backButtonDispatcher);

    await tester.pumpWidget(buildBoilerPlate(router));

    expect(find.text(expected), findsOneWidget);
  });
}

Widget buildBoilerPlate(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

typedef SimpleRouterDelegateBuilder = Widget Function(BuildContext, RouteInformation?);
typedef SimpleRouterDelegatePopRoute = Future<bool> Function();
typedef SimpleNavigatorRouterDelegatePopPage<T> = bool Function(Route<T> route, T result);
typedef RouterReportRouterInformation = void Function(RouteInformation, RouteInformationReportingType);
typedef CustomRouteInformationParserCallback = RouteInformation Function(RouteInformation, BuildContext);

class SimpleRouteInformationParser extends RouteInformationParser<RouteInformation> {
  SimpleRouteInformationParser();

  @override
  Future<RouteInformation> parseRouteInformation(RouteInformation information) {
    return SynchronousFuture<RouteInformation>(information);
  }

  @override
  RouteInformation restoreRouteInformation(RouteInformation configuration) {
    return configuration;
  }
}

class CustomRouteInformationParser extends RouteInformationParser<RouteInformation> {
  const CustomRouteInformationParser(this.callback);

  final CustomRouteInformationParserCallback callback;

  @override
  Future<RouteInformation> parseRouteInformationWithDependencies(RouteInformation information, BuildContext context) {
    return SynchronousFuture<RouteInformation>(callback(information, context));
  }

  @override
  RouteInformation restoreRouteInformation(RouteInformation configuration) {
    return configuration;
  }
}

class SimpleRouterDelegate extends RouterDelegate<RouteInformation> with ChangeNotifier {
  SimpleRouterDelegate({
    this.builder,
    this.onPopRoute,
    this.reportConfiguration = false,
  });

  RouteInformation? get routeInformation => _routeInformation;
  RouteInformation? _routeInformation;
  set routeInformation(RouteInformation? newValue) {
    _routeInformation = newValue;
    notifyListeners();
  }

  SimpleRouterDelegateBuilder? builder;
  SimpleRouterDelegatePopRoute? onPopRoute;
  final bool reportConfiguration;

  @override
  RouteInformation? get currentConfiguration {
    if (reportConfiguration) {
      return routeInformation;
    }
    return null;
  }

  @override
  Future<void> setNewRoutePath(RouteInformation configuration) {
    _routeInformation = configuration;
    return SynchronousFuture<void>(null);
  }

  @override
  Future<bool> popRoute() {
    return onPopRoute?.call() ?? SynchronousFuture<bool>(true);
  }

  @override
  Widget build(BuildContext context) => builder!(context, routeInformation);
}

class SimpleNavigatorRouterDelegate extends RouterDelegate<RouteInformation> with PopNavigatorRouterDelegateMixin<RouteInformation>, ChangeNotifier {
  SimpleNavigatorRouterDelegate({
    required this.builder,
    required this.onPopPage,
  });

  @override
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  RouteInformation get routeInformation => _routeInformation;
  late RouteInformation _routeInformation;
  set routeInformation(RouteInformation newValue) {
    _routeInformation = newValue;
    notifyListeners();
  }

  SimpleRouterDelegateBuilder builder;
  SimpleNavigatorRouterDelegatePopPage<void> onPopPage;

  @override
  Future<void> setNewRoutePath(RouteInformation configuration) {
    _routeInformation = configuration;
    return SynchronousFuture<void>(null);
  }

  bool _handlePopPage(Route<void> route, void data) {
    return onPopPage(route, data);
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onPopPage: _handlePopPage,
      pages: <Page<void>>[
        // We need at least two pages for the pop to propagate through.
        // Otherwise, the navigator will bubble the pop to the system navigator.
        const MaterialPage<void>(
          child: Text('base'),
        ),
        MaterialPage<void>(
          key: ValueKey<String>(routeInformation.location!),
          child: builder(context, routeInformation),
        ),
      ],
    );
  }
}

class SimpleRouteInformationProvider extends RouteInformationProvider with ChangeNotifier {
  SimpleRouteInformationProvider({
    this.onRouterReport,
  });

  RouterReportRouterInformation? onRouterReport;

  @override
  RouteInformation get value => _value;
  late RouteInformation _value;
  set value(RouteInformation newValue) {
    _value = newValue;
    notifyListeners();
  }

  @override
  void routerReportsNewRouteInformation(RouteInformation routeInformation, {RouteInformationReportingType type = RouteInformationReportingType.none}) {
    _value = routeInformation;
    onRouterReport?.call(routeInformation, type);
  }
}

class SimpleAsyncRouteInformationParser extends RouteInformationParser<RouteInformation> {
  SimpleAsyncRouteInformationParser();

  late Future<RouteInformation> parsingFuture;

  @override
  Future<RouteInformation> parseRouteInformation(RouteInformation information) {
    return parsingFuture = Future<RouteInformation>.value(information);
  }

  @override
  RouteInformation restoreRouteInformation(RouteInformation configuration) {
    return configuration;
  }
}

class CompleterRouteInformationParser extends RouteInformationParser<RouteInformation> {
  CompleterRouteInformationParser();

  late Completer<void> completer;

  @override
  Future<RouteInformation> parseRouteInformation(RouteInformation information) async {
    completer = Completer<void>();
    await completer.future;
    return SynchronousFuture<RouteInformation>(information);
  }

  @override
  RouteInformation restoreRouteInformation(RouteInformation configuration) {
    return configuration;
  }
}

class SimpleAsyncRouterDelegate extends RouterDelegate<RouteInformation> with ChangeNotifier {
  SimpleAsyncRouterDelegate({
    required this.builder,
  });

  RouteInformation? get routeInformation => _routeInformation;
  RouteInformation? _routeInformation;
  set routeInformation(RouteInformation? newValue) {
    _routeInformation = newValue;
    notifyListeners();
  }

  SimpleRouterDelegateBuilder builder;
  late Future<void> setNewRouteFuture;

  @override
  Future<void> setNewRoutePath(RouteInformation configuration) {
    _routeInformation = configuration;
    return setNewRouteFuture = Future<void>.value();
  }

  @override
  Future<bool> popRoute() {
    return Future<bool>.value(true);
  }

  @override
  Widget build(BuildContext context) => builder(context, routeInformation);
}

class RedirectingInformationParser extends RouteInformationParser<RouteInformation> {

  RedirectingInformationParser(this.redirects);

  final Map<String, RouteInformation> redirects;

  @override
  Future<RouteInformation> parseRouteInformation(RouteInformation information) {
    return SynchronousFuture<RouteInformation>(redirects[information.location] ?? information);
  }

  @override
  RouteInformation restoreRouteInformation(RouteInformation configuration) {
    return configuration;
  }
}
