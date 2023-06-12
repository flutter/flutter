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

library quiver.collection.all_tests;

import 'bimap_test.dart' as bimap;
import 'delegates/iterable_test.dart' as delegate_iterable;
import 'delegates/list_test.dart' as delegate_list;
import 'delegates/map_test.dart' as delegate_map;
import 'delegates/queue_test.dart' as delegate_queue;
import 'delegates/set_test.dart' as delegate_set;
import 'lru_map_test.dart' as lru_map;
import 'multimap_test.dart' as multimap;
import 'treeset_test.dart' as treeset;
import 'utils_test.dart' as utils;

void main() {
  bimap.main();
  delegate_iterable.main();
  delegate_list.main();
  delegate_map.main();
  delegate_queue.main();
  delegate_set.main();
  lru_map.main();
  multimap.main();
  treeset.main();
  utils.main();
}
