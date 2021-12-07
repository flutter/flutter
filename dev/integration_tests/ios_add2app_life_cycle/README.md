# iOS Add2App Life Cycle Test

This application demonstrates some basic functionality for Add2App,
along with a native iOS ViewController as a baseline and to demonstrate
interaction.

The following functionality is currently implemented:

1. A regular iOS view controller (UIViewController), similar to the default
   `flutter create` template (NativeViewController.m).
1. A FlutterViewController subclass that takes over the full screen. Demos showing
   this both from a cold/fresh engine state and a warm engine state
   (FullScreenViewController.m).
1. A demo of pushing a FlutterViewController on as a child view.
1. A demo of showing both the native and the Flutter views using a platform
   channel to interact with each other (HybridViewController.m).
1. A demo of showing two FlutterViewControllers simultaneously
   (DualViewController.m).

A few key things are tested here (IntegrationTests.m):

1. The ability to pre-warm the engine and attach/detach a ViewController from
   it.
1. The ability to use platform channels to communicate between views.
1. The ability to simultaneously run two instances of the engine.
1. That a FlutterViewController can be freed when no longer in use (also tested
   from FlutterViewControllerTests.m).
1. That a FlutterEngine can be freed when no longer in use.