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

class W3cFrameHandler extends FrameHandler {
  @override
  WebDriverRequest buildSwitchByIdRequest([int? id]) =>
      WebDriverRequest.postRequest('frame', {'id': id});

  @override
  void parseSwitchByIdResponse(WebDriverResponse response) {
    parseW3cResponse(response);
  }

  @override
  WebDriverRequest buildSwitchByElementRequest(String elementId) =>
      WebDriverRequest.postRequest('frame', {
        'id': {w3cElementStr: elementId}
      });

  @override
  void parseSwitchByElementResponse(WebDriverResponse response) {
    parseW3cResponse(response);
  }

  @override
  WebDriverRequest buildSwitchToParentRequest() =>
      WebDriverRequest.postRequest('frame/parent');

  @override
  void parseSwitchToParentResponse(WebDriverResponse response) {
    parseW3cResponse(response);
  }
}
