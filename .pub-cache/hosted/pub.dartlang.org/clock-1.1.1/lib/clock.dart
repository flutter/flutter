// Copyright 2013 Google Inc. All Rights Reserved.
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

import 'src/default.dart';

export 'src/clock.dart';
export 'src/default.dart';

/// Returns current time.
@Deprecated('Pass around an instance of Clock instead.')
typedef TimeFunction = DateTime Function();

/// Returns the current system time.
@Deprecated('Use new DateTime.now() instead.')
DateTime systemTime() => DateTime.now();

/// Returns the current time as reported by [clock].
@Deprecated('Use clock.now() instead.')
DateTime get now => clock.now();

/// Returns a stopwatch that uses the current time as reported by [clock].
@Deprecated('Use clock.stopwatch() instead.')
Stopwatch getStopwatch() => clock.stopwatch();
