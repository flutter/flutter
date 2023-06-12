// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:stream_transform/stream_transform.dart';

void main() {
  var firstInput = document.querySelector('#first_input') as InputElement;
  var secondInput = document.querySelector('#second_input') as InputElement;
  var output = document.querySelector('#output')!;

  _inputValues(firstInput)
      .combineLatest(_inputValues(secondInput),
          (first, second) => 'First: $first, Second: $second')
      .tap((v) {
    print('Saw: $v');
  }).forEach((v) {
    output.text = v;
  });
}

Stream<String?> _inputValues(InputElement element) => element.onKeyUp
    .debounce(const Duration(milliseconds: 100))
    .map((_) => element.value);
