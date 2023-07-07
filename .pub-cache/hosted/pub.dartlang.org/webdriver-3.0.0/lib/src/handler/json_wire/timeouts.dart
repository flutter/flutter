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

class JsonWireTimeoutsHandler extends TimeoutsHandler {
  WebDriverRequest _buildSetTimeoutRequest(String type, Duration timeout) =>
      WebDriverRequest.postRequest(
          'timeouts', {'type': type, 'ms': timeout.inMilliseconds});

  @override
  WebDriverRequest buildSetScriptTimeoutRequest(Duration timeout) =>
      _buildSetTimeoutRequest('script', timeout);

  @override
  void parseSetScriptTimeoutResponse(WebDriverResponse response) {
    parseJsonWireResponse(response);
  }

  @override
  WebDriverRequest buildSetImplicitTimeoutRequest(Duration timeout) =>
      _buildSetTimeoutRequest('implicit', timeout);

  @override
  void parseSetImplicitTimeoutResponse(WebDriverResponse response) {
    parseJsonWireResponse(response);
  }

  @override
  WebDriverRequest buildSetPageLoadTimeoutRequest(Duration timeout) =>
      _buildSetTimeoutRequest('page load', timeout);

  @override
  void parseSetPageLoadTimeoutResponse(WebDriverResponse response) {
    parseJsonWireResponse(response);
  }
}
