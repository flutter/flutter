typedef void UnityCreatedCallback(UnityWidgetController controller);

abstract class UnityWidgetController {
  static dynamic webRegistrar;

  /// Method required for web initialization
  static void registerWith(dynamic registrar) {
    webRegistrar = registrar;
  }

  /// Initialize [UnityWidgetController] with [id]
  /// Mainly for internal use when instantiating a [UnityWidgetController] passed
  /// in [UnityWidget.onUnityCreated] callback.
  static Future<UnityWidgetController> init(
      int id, dynamic unityWidgetState) async {
    throw UnimplementedError('init() has not been implemented.');
  }

  /// Checks to see if unity player is ready to be used
  /// Returns `true` if unity player is ready.
  Future<bool?>? isReady() {
    throw UnimplementedError('isReady() has not been implemented.');
  }

  /// Get the current pause state of the unity player
  /// Returns `true` if unity player is paused.
  Future<bool?>? isPaused() {
    throw UnimplementedError('isPaused() has not been implemented.');
  }

  /// Get the current load state of the unity player
  /// Returns `true` if unity player is loaded.
  Future<bool?>? isLoaded() {
    throw UnimplementedError('isLoaded() has not been implemented.');
  }

  /// Helper method to know if Unity has been put in background mode (WIP) unstable
  /// Returns `true` if unity player is in background.
  Future<bool?>? inBackground() {
    throw UnimplementedError('inBackground() has not been implemented.');
  }

  /// Creates a unity player if it's not already created. Please only call this if unity is not ready,
  /// or is in unloaded state. Use [isLoaded] to check.
  /// Returns `true` if unity player was created succesfully.
  Future<bool?>? create() {
    throw UnimplementedError('create() has not been implemented.');
  }

  /// Post message to unity from flutter. This method takes in a string [message].
  /// The [gameObject] must match the name of an actual unity game object in a scene at runtime, and the [methodName],
  /// must exist in a `MonoDevelop` `class` and also exposed as a method. [message] is an parameter taken by the method
  ///
  /// ```dart
  /// postMessage("GameManager", "openScene", "ThirdScene")
  /// ```
  Future<void>? postMessage(String gameObject, methodName, message) {
    throw UnimplementedError('postMessage() has not been implemented.');
  }

  /// Post message to unity from flutter. This method takes in a Json or map structure as the [message].
  /// The [gameObject] must match the name of an actual unity game object in a scene at runtime, and the [methodName],
  /// must exist in a `MonoDevelop` `class` and also exposed as a method. [message] is an parameter taken by the method
  ///
  /// ```dart
  /// postJsonMessage("GameManager", "openScene", {"buildIndex": 3, "name": "ThirdScene"})
  /// ```
  Future<void>? postJsonMessage(
      String gameObject, String methodName, Map<String, dynamic> message) {
    throw UnimplementedError('postJsonMessage() has not been implemented.');
  }

  /// Pause the unity in-game player with this method
  Future<void>? pause() {
    throw UnimplementedError('pause() has not been implemented.');
  }

  /// Resume the unity in-game player with this method idf it is in a paused state
  Future<void>? resume() {
    throw UnimplementedError('resume() has not been implemented.');
  }

  /// Sometimes you want to open unity in it's own process and openInNativeProcess does just that.
  /// It works for Android and iOS is WIP
  Future<void>? openInNativeProcess() {
    throw UnimplementedError('openInNativeProcess() has not been implemented.');
  }

  /// Unloads unity player from th current process (Works on Android only for now)
  /// iOS is WIP. For more information please read [Unity Docs](https://docs.unity3d.com/2020.2/Documentation/Manual/UnityasaLibrary.html)
  Future<void>? unload() {
    throw UnimplementedError('unload() has not been implemented.');
  }

  /// Quits unity player. Note that this kills the current flutter process, thus quiting the app
  Future<void>? quit() {
    throw UnimplementedError('quit() has not been implemented.');
  }

  void dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }
}
