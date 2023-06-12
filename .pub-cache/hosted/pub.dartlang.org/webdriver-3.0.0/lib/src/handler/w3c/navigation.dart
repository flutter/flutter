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

import '../../common/request.dart';
import '../../common/webdriver_handler.dart';
import 'utils.dart';

class W3cNavigationHandler extends NavigationHandler {
  @override
  WebDriverRequest buildNavigateToRequest(String url) =>
      WebDriverRequest.postRequest('url', {'url': url});

  @override
  void parseNavigateToResponse(WebDriverResponse response) {
    parseW3cResponse(response);
  }

  @override
  WebDriverRequest buildForwardRequest() =>
      WebDriverRequest.postRequest('forward');

  @override
  void parseForwardResponse(WebDriverResponse response) {
    parseW3cResponse(response);
  }

  @override
  WebDriverRequest buildBackRequest() => WebDriverRequest.postRequest('back');

  @override
  void parseBackResponse(WebDriverResponse response) {
    parseW3cResponse(response);
  }

  @override
  WebDriverRequest buildRefreshRequest() =>
      WebDriverRequest.postRequest('refresh');

  @override
  void parseRefreshResponse(WebDriverResponse response) {
    parseW3cResponse(response);
  }
}
