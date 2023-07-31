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

class WebDriverCommandEvent {
  final String? method;
  final String? endPoint;
  final dynamic params;
  final StackTrace? stackTrace;
  final DateTime? startTime;
  final DateTime? endTime;
  final dynamic exception;
  final dynamic result;

  WebDriverCommandEvent(
      {this.method,
      this.endPoint,
      this.params,
      this.startTime,
      this.endTime,
      this.exception,
      this.result,
      this.stackTrace});

  @override
  String toString() => '[$startTime - $endTime] $method $endPoint($params) => '
      '${exception ?? result}';
}
