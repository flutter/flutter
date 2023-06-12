// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Callback for when the ad inspector closes.
typedef OnAdInspectorClosedListener = void Function(AdInspectorError?);

/// Error information about why the ad inspector failed.
class AdInspectorError {
  /// Create an AdInspectorError with the given code, domain and message.
  AdInspectorError({
    this.code,
    this.domain,
    this.message,
  });

  /// Code to identifier the error.
  final String? code;

  /// The domain from which the error came.
  final String? domain;

  /// A message detailing the error.
  final String? message;
}
