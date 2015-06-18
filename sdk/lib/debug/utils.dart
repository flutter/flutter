
final bool inDebugBuild = _initInDebugBuild();

bool _initInDebugBuild() {
  bool _inDebug = false;
  bool setAssert() {
    _inDebug = true;
    return true;
  }
  assert(setAssert());
  return _inDebug;
}
