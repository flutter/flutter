import 'package:flutter/widgets.dart';

enum PlayInBackground { enabled, disabledPause, disabledRestoreOnForeground }

class AppLifecycleObserver with WidgetsBindingObserver {
  bool isActive = false;
  final Function()? onForeground;
  final Function()? onBackground;
  final Function(bool isActive)? onChanged;

  AppLifecycleObserver({this.onForeground, this.onBackground, this.onChanged});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    var lastActive = isActive;

    if (state == AppLifecycleState.resumed) {
      isActive = true;
    } else if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      isActive = false;
    }

    if (lastActive != isActive) {
      if (onChanged != null) {
        onChanged!(isActive);
      }
      if (isActive) {
        if (onForeground != null) {
          onForeground!();
        }
      } else {
        if (onBackground != null) {
          onBackground!();
        }
      }
    }
  }
}
