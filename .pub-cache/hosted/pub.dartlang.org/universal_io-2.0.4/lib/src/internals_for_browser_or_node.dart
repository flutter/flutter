// Copyright 2020 terrier989@gmail.com.
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

// Annotate as 'internal' so developers don't accidentally import this.
@internal
library universal_io.internals_for_browser_or_node;

import 'package:meta/meta.dart';

export 'internals_for_browser_or_node_impl_browser.dart'
    if (dart.library.html) 'internals_for_browser_or_node_impl_browser.dart'
    if (dart.library.js) 'internals_for_browser_or_node_impl_node.dart';
