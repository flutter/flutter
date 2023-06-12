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

library quiver.iterables.all_tests;

import 'concat_test.dart' as concat;
import 'count_test.dart' as count;
import 'cycle_test.dart' as cycle;
import 'enumerate_test.dart' as enumerate;
import 'generating_iterable_test.dart' as generating_iterable;
import 'infinite_iterable_test.dart' as infinite_iterable;
import 'merge_test.dart' as merge;
import 'min_max_test.dart' as min_max;
import 'partition_test.dart' as partition;
import 'range_test.dart' as range;
import 'zip_test.dart' as zip;

void main() {
  concat.main();
  count.main();
  cycle.main();
  enumerate.main();
  generating_iterable.main();
  infinite_iterable.main();
  merge.main();
  min_max.main();
  partition.main();
  range.main();
  zip.main();
}
