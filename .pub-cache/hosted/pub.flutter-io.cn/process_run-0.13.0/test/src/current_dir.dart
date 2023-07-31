#!/usr/bin/env dart

import 'dart:io';

///
/// Output the current directory
///
void main() {
  stdout.writeln(Directory.current.path);
}
