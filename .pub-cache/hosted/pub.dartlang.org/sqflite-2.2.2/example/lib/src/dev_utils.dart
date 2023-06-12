export 'dart:async';

// ignore_for_file: avoid_print

/// Deprecated to prevent keeping the code used.
@Deprecated('Dev only')
void devPrint(Object object) {
  print(object);
}

/// Deprecated to prevent keeping the code used.
///
/// Can be use as a todo for weird code. int value = devWarning(myFunction());
/// The function is always called
@Deprecated('Dev only')
T devWarning<T>(T value) => value;
