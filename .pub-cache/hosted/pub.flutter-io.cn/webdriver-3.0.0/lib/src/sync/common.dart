// Copyright 2017 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import '../../async_core.dart' as async_core;
import '../common/by.dart';

import 'web_driver.dart';
import 'web_element.dart';

// Magic constants -- identifiers indicating a value is an element.
// Source: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol
const String jsonWireElementStr = 'ELEMENT';

// Source: https://www.w3.org/TR/webdriver/#elements
const String w3cElementStr = 'element-6066-11e4-a52e-4f735466cecf';

typedef GetAttribute = String? Function(String name);

/// Simple class to provide access to indexed properties such as WebElement
/// attributes or css styles.
class Attributes {
  final GetAttribute _getAttribute;

  Attributes(this._getAttribute);

  String? operator [](String name) => _getAttribute(name);
}

abstract class SearchContext {
  WebDriver get driver;

  /// Produces a compatible [async_core.SearchContext]. Allows backwards
  /// compatibility with other frameworks.
  async_core.SearchContext get asyncContext;

  /// Searches for multiple elements within the context.
  List<WebElement> findElements(By by);

  /// Searches for an element within the context.
  ///
  /// Throws [NoSuchElementException] if no matching element is found.
  WebElement findElement(By by);
}
