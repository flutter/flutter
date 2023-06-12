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

/// Cross-platform implementation of "dart:io" that works in browsers too.
///
/// # Usage
/// Replace imports of "dart:io" with:
/// ```
/// import 'package:universal_io/io_impl_js.dart';
/// ```
library universal_io;

// ignore: invalid_export_of_internal_element
export 'src/io_impl_vm.dart'
    if (dart.library.io) 'src/io_impl_vm.dart'
    if (dart.library.js) 'src/io_impl_js.dart'
    if (dart.library.html) 'src/io_impl_js.dart';

export 'src/browser_http_client.dart';
