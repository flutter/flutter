import 'dart:async';

import 'package:stack_trace/stack_trace.dart';

void main() {
  Chain.capture(_scheduleAsync);
}

void _scheduleAsync() {
  Future.delayed(const Duration(seconds: 1)).then((_) => _runAsync());
}

void _runAsync() {
  throw 'oh no!';
}
