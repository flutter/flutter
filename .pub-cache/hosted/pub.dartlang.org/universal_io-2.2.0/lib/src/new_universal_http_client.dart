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

import 'package:universal_io/io.dart';

import '_helpers.dart' as helpers;

/// Constructs a new [HttpClient] that will be [BrowserHttpClient] in browsers
/// and the normal _dart:io_ HTTP client everywhere else.
HttpClient newUniversalHttpClient() => helpers.newHttpClient();
