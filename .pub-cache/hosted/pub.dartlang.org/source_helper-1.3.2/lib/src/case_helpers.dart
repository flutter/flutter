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

/// Extensions getters on [String] to preform common, identifier-related
/// conversions.
extension CaseHelper on String {
  /// Returns `this` converted to
  /// [kebab-case](https://en.wikipedia.org/wiki/Kebab_case),
  /// where words are seperated by a hyphen.
  ///
  /// Examples:
  ///
  /// ```text
  /// 'simple'   -> 'simple',
  /// 'twoWords' -> 'two-words'
  /// 'FirstBig' -> 'first-big'
  /// ```
  ///
  /// Whitespace is not considered or affected.
  String get kebab => _fixCase('-');

  /// Returns `this` converted to
  /// [snake_case](https://en.wikipedia.org/wiki/Snake_case),
  /// where words are seperated by underscore.
  ///
  /// Examples:
  ///
  /// ```text
  /// 'simple'   -> 'simple',
  /// 'twoWords' -> 'two_words'
  /// 'FirstBig' -> 'first_big'
  /// ```
  ///
  /// Whitespace is not considered or affected.
  String get snake => _fixCase('_');

  /// Returns `this` where the first character is capitalized.
  ///
  /// Examples:
  ///
  /// ```text
  /// 'simple'   -> 'Simple',
  /// 'twoWords' -> 'TwoWords'
  /// 'FirstBig' -> 'FirstBig'
  /// ```
  ///
  /// Whitespace is not considered or affected.
  String get pascal {
    if (isEmpty) {
      return '';
    }

    return this[0].toUpperCase() + substring(1);
  }

  String _fixCase(String separator) => replaceAllMapped(_upperCase, (match) {
        var lower = match.group(0)!.toLowerCase();

        if (match.start > 0) {
          lower = '$separator$lower';
        }

        return lower;
      });

  /// Returns `this` with all leading underscore characters removed.
  String get nonPrivate => replaceFirst(RegExp(r'^_*'), '');
}

final _upperCase = RegExp('[A-Z]');
