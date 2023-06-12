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

library quiver.async.all_tests;

import 'collect_test.dart' as collect;
import 'concat_test.dart' as concat;
import 'countdown_timer_test.dart' as countdown_timer;
import 'enumerate_test.dart' as enumerate;
import 'future_stream_test.dart' as future_stream;
import 'metronome_test.dart' as metronome;
import 'stream_buffer_test.dart' as stream_buffer;
import 'stream_router_test.dart' as stream_router;
import 'string_test.dart' as string;

void main() {
  collect.main();
  concat.main();
  countdown_timer.main();
  enumerate.main();
  future_stream.main();
  metronome.main();
  stream_buffer.main();
  stream_router.main();
  string.main();
}
