#!/usr/bin/env dart

import 'dart:io';

import 'package:completion/completion.dart';

void main(List<String> arguments) {
  try {
    print(generateCompletionScript(arguments));
  } catch (e) {
    print(e);
    exitCode = 1;
  }
}
