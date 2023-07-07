// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:material_color_utilities/scheme/scheme.dart';
import 'package:test/test.dart';

import './utils/color_matcher.dart';

void main() {
  test('blue light scheme', () {
    final scheme = Scheme.light(0xff0000ff);
    expect(scheme.primary, isColor(0xff343DFF));
  });

  test('blue dark scheme', () {
    final scheme = Scheme.dark(0xff0000ff);
    expect(scheme.primary, isColor(0xffBEC2FF));
  });

  test('3rd party light scheme', () async {
    final scheme = Scheme.light(0xff6750A4);
    expect(scheme.primary, isColor(0xff6750A4));
    expect(scheme.secondary, isColor(0xff625B71));
    expect(scheme.tertiary, isColor(0xff7E5260));
    expect(scheme.surface, isColor(0xffFFFBFF));
    expect(scheme.onSurface, isColor(0xff1C1B1E));
  });

  test('3rd party dark scheme', () async {
    final scheme = Scheme.dark(0xff6750A4);
    expect(scheme.primary, isColor(0xffCFBCFF));
    expect(scheme.secondary, isColor(0xffCBC2DB));
    expect(scheme.tertiary, isColor(0xffEFB8C8));
    expect(scheme.surface, isColor(0xff1c1b1e));
    expect(scheme.onSurface, isColor(0xffE6E1E6));
  });
}
