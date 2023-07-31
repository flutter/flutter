// environment utils

bool? _isRelease;

// http://stackoverflow.com/questions/29592826/detect-during-runtime-whether-the-application-is-in-release-mode-or-not

/// Check whether in release mode
bool get isRelease {
  if (_isRelease == null) {
    _isRelease = true;
    assert(() {
      _isRelease = false;
      return true;
    }());
  }
  return _isRelease!;
}

/// Check whether running in debug mode
bool get isDebug => !isRelease;

/// Special runtime trick to known whether we are in the javascript world
const isRunningAsJavascript = identical(1, 1.0);
