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

import 'color_utils.dart';

class StringUtils {
  static String hexFromArgb(int argb, {bool leadingHashSign = true}) {
    final red = ColorUtils.redFromArgb(argb);
    final green = ColorUtils.greenFromArgb(argb);
    final blue = ColorUtils.blueFromArgb(argb);
    return '${leadingHashSign ? '#' : ''}'
        '${red.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${green.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${blue.toRadixString(16).padLeft(2, '0').toUpperCase()}';
  }

  static int? argbFromHex(String hex) {
    return int.tryParse(hex.replaceAll('#', ''), radix: 16);
  }
}
