// Copyright (c) 2020, the Dart project authors.
// Copyright (c) 2006, Kirill Simonov.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'package:yaml/yaml.dart';

void main() {
  var doc = loadYaml("YAML: YAML Ain't Markup Language") as Map;
  print(doc['YAML']);
}
