// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:source_helper/source_helper.dart';

/// [escapeDartString] converts the argument to a [String] that can be used
/// when generating Dart source code.
void main() {
  for (var item in _examples) {
    print(
      '''
----- Input
$item
----- Output
${escapeDartString(item)}''',
    );
  }
}

const _examples = {
  'simple',
  "'single quotes'",
  '"double quotes"',
  r'$ special characters \n',
  '''
Row one
Row two
Row three''',
};
