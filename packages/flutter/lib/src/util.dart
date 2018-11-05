/// Use this function to guard debugging code. When Dart is compiled in
/// production mode, the code guarded using this function will be tree
/// shaken away, reducing code size.
///
/// WARNING: DO NOT CHANGE THIS METHOD! This method is designed to have no
/// more AST nodes than the maximum allowed by dart2js to inline it. In
/// addition, the use of `assert` allows the compiler to statically compute
/// the value returned by this function and tree shake conditions guarded by
/// it.
///
/// Example:
///
/// if (assertionsEnabled) {
///   ...code here is tree shaken away in prod mode...
/// }
bool get assertionsEnabled {
  bool k = false;
  assert(k = true);
  return k;
}
