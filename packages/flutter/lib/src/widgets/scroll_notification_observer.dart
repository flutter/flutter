import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'framework.dart';
import 'notification_listener.dart';
import 'scroll_notification.dart';


typedef ScrollNotificationCallback = void Function(ScrollNotification notification);

class _ScrollNotificationObserverScope extends InheritedWidget {
  const _ScrollNotificationObserverScope({
    Key? key,
    required Widget child,
    required ScrollNotificationObserverState scrollNotificationObserverState,
  }) : _scrollNotificationObserverState = scrollNotificationObserverState,
      super(key: key, child: child);

  final ScrollNotificationObserverState  _scrollNotificationObserverState;

  @override
  bool updateShouldNotify(_ScrollNotificationObserverScope old) => _scrollNotificationObserverState != old._scrollNotificationObserverState;
}

class _ListenerEntry extends LinkedListEntry<_ListenerEntry> {
  _ListenerEntry(this.listener);
  final ScrollNotificationCallback listener;
}

class ScrollNotificationObserverState extends State<ScrollNotificationObserver> {
  LinkedList<_ListenerEntry>? _listeners = LinkedList<_ListenerEntry>();

  bool _debugAssertNotDisposed() {
    assert(() {
      if (_listeners == null) {
        throw FlutterError(
          'A $runtimeType was used after being disposed.\n'
          'Once you have called dispose() on a $runtimeType, it can no longer be used.',
        );
      }
      return true;
    }());
    return true;
  }

  void addListener(ScrollNotificationCallback listener) {
    assert(_debugAssertNotDisposed());
    _listeners!.add(_ListenerEntry(listener));
  }

  void removeListener(ScrollNotificationCallback listener) {
    assert(_debugAssertNotDisposed());
    for (final _ListenerEntry entry in _listeners!) {
      if (entry.listener == listener) {
        entry.unlink();
        return;
      }
    }
  }

  void notifyListeners(ScrollNotification notification) {
    assert(_debugAssertNotDisposed());
    if (_listeners!.isEmpty)
      return;

    final List<_ListenerEntry> localListeners = List<_ListenerEntry>.from(_listeners!);
    for (final _ListenerEntry entry in localListeners) {
      try {
        if (entry.list != null)
          entry.listener(notification);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'widget library',
          context: ErrorDescription('while dispatching notifications for $runtimeType'),
          informationCollector: () sync* {
            yield DiagnosticsProperty<ScrollNotificationObserverState>(
              'The $runtimeType sending notification was',
              this,
              style: DiagnosticsTreeStyle.errorProperty,
            );
          },
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        notifyListeners(notification);
        return false;
      },
      child: _ScrollNotificationObserverScope(
        scrollNotificationObserverState: this,
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    assert(_debugAssertNotDisposed());
    _listeners = null;
    super.dispose();
  }
}

class ScrollNotificationObserver extends StatefulWidget {
  const ScrollNotificationObserver({
    Key? key,
    required this.child,
  }) : assert(child != null), super(key: key);

  final Widget child;

  static ScrollNotificationObserverState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ScrollNotificationObserverScope>()?._scrollNotificationObserverState;
  }

  ScrollNotificationObserverState createState() => ScrollNotificationObserverState();
}
