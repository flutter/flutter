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

/// Browser cookie.
class Cookie {
  /// The name of the cookie.
  final String? name;

  /// The cookie value.
  final String? value;

  /// (Optional) The cookie path.
  final String? path;

  /// (Optional) The domain the cookie is visible to.
  final String? domain;

  /// (Optional) Whether the cookie is a secure cookie.
  final bool? secure;

  /// (Optional) When the cookie expires.
  final DateTime? expiry;

  Cookie(
    this.name,
    this.value, {
    this.path,
    this.domain,
    this.secure,
    this.expiry,
  });

  factory Cookie.fromJson(Map<String, dynamic> json) {
    DateTime? expiry;
    if (json['expiry'] is num) {
      expiry = DateTime.fromMillisecondsSinceEpoch(
        (json['expiry'] as num).toInt() * 1000,
        isUtc: true,
      );
    }
    return Cookie(
      json['name'] as String?,
      json['value'] as String?,
      path: json['path'] as String?,
      domain: json['domain'] as String?,
      secure: json['secure'] as bool?,
      expiry: expiry,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'name': name, 'value': value};
    if (path is String) {
      json['path'] = path;
    }
    if (domain is String) {
      json['domain'] = domain;
    }
    if (secure is bool) {
      json['secure'] = secure;
    }
    if (expiry is DateTime) {
      json['expiry'] = (expiry!.millisecondsSinceEpoch / 1000).ceil();
    }
    return json;
  }

  @override
  String toString() => 'Cookie${toJson()}';
}
