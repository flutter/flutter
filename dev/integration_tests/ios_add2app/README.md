# iOS Add2App Test

This application demonstrates some basic functionality for Add2App,
along with a native iOS ViewController as a baseline and to demonstrate
interaction.

The following functionality is currently implemented:

1. A regular iOS view controller (UIViewController), similar to the default `flutter create` template.
1. A FlutterViewController subclass that takes over full screen. Demos showing this both from a cold/fresh engine state and a warm engine state.
1. A demo of pushing a FlutterViewController on as a child view.
1. A demo of showing both the native and the Flutter views using a platform channel to to interact with each other.
1. A demo of showing two FlutterViewControllers simultaneously.

A few key things are tested here:

1. The ability to pre-warm the engine and attach/detatch a ViewController from it.
1. The ability to simultaneously run two instances of the engine.
1. The ability to use platform channels to communicate between views.
1. That a FlutterViewController can be freed when no longer in use.
1. That a FlutterEngine can be freed when no longer in use.