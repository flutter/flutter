// This is a generated file (see the discoveryapis_generator project).

// ignore_for_file: camel_case_types
// ignore_for_file: comment_references
// ignore_for_file: file_names
// ignore_for_file: library_names
// ignore_for_file: lines_longer_than_80_chars
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: prefer_expression_function_bodies
// ignore_for_file: prefer_interpolation_to_compose_strings
// ignore_for_file: unnecessary_brace_in_string_interps
// ignore_for_file: unnecessary_lambdas
// ignore_for_file: unnecessary_string_interpolations

/// Google OAuth2 API - v2
///
/// Obtains end-user authorization grants for use with other Google APIs.
///
/// For more information, see
/// <https://developers.google.com/identity/protocols/oauth2/>
///
/// Create an instance of [Oauth2Api] to access these resources:
///
/// - [UserinfoResource]
///   - [UserinfoV2Resource]
///     - [UserinfoV2MeResource]
library oauth2.v2;

import 'dart:async' as async;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Obtains end-user authorization grants for use with other Google APIs.
class Oauth2Api {
  /// View your email address
  static const userinfoEmailScope =
      'https://www.googleapis.com/auth/userinfo.email';

  /// See your personal info, including any personal info you've made publicly
  /// available
  static const userinfoProfileScope =
      'https://www.googleapis.com/auth/userinfo.profile';

  /// Associate you with your personal info on Google
  static const openidScope = 'openid';

  final commons.ApiRequester _requester;

  UserinfoResource get userinfo => UserinfoResource(_requester);

  Oauth2Api(http.Client client,
      {core.String rootUrl = 'https://www.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);

  /// Request parameters:
  ///
  /// [accessToken] - null
  ///
  /// [idToken] - null
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Tokeninfo].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Tokeninfo> tokeninfo({
    core.String? accessToken,
    core.String? idToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (accessToken != null) 'access_token': [accessToken],
      if (idToken != null) 'id_token': [idToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'oauth2/v2/tokeninfo';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return Tokeninfo.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class UserinfoResource {
  final commons.ApiRequester _requester;

  UserinfoV2Resource get v2 => UserinfoV2Resource(_requester);

  UserinfoResource(commons.ApiRequester client) : _requester = client;

  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Userinfo].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Userinfo> get({
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'oauth2/v2/userinfo';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Userinfo.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class UserinfoV2Resource {
  final commons.ApiRequester _requester;

  UserinfoV2MeResource get me => UserinfoV2MeResource(_requester);

  UserinfoV2Resource(commons.ApiRequester client) : _requester = client;
}

class UserinfoV2MeResource {
  final commons.ApiRequester _requester;

  UserinfoV2MeResource(commons.ApiRequester client) : _requester = client;

  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Userinfo].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Userinfo> get({
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'userinfo/v2/me';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Userinfo.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class Tokeninfo {
  /// Who is the intended audience for this token.
  ///
  /// In general the same as issued_to.
  core.String? audience;

  /// The email address of the user.
  ///
  /// Present only if the email scope is present in the request.
  core.String? email;

  /// The expiry time of the token, as number of seconds left until expiry.
  core.int? expiresIn;

  /// To whom was the token issued to.
  ///
  /// In general the same as audience.
  core.String? issuedTo;

  /// The space separated list of scopes granted to this token.
  core.String? scope;

  /// The obfuscated user id.
  core.String? userId;

  /// Boolean flag which is true if the email address is verified.
  ///
  /// Present only if the email scope is present in the request.
  core.bool? verifiedEmail;

  Tokeninfo();

  Tokeninfo.fromJson(core.Map _json) {
    if (_json.containsKey('audience')) {
      audience = _json['audience'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('expires_in')) {
      expiresIn = _json['expires_in'] as core.int;
    }
    if (_json.containsKey('issued_to')) {
      issuedTo = _json['issued_to'] as core.String;
    }
    if (_json.containsKey('scope')) {
      scope = _json['scope'] as core.String;
    }
    if (_json.containsKey('user_id')) {
      userId = _json['user_id'] as core.String;
    }
    if (_json.containsKey('verified_email')) {
      verifiedEmail = _json['verified_email'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (audience != null) 'audience': audience!,
        if (email != null) 'email': email!,
        if (expiresIn != null) 'expires_in': expiresIn!,
        if (issuedTo != null) 'issued_to': issuedTo!,
        if (scope != null) 'scope': scope!,
        if (userId != null) 'user_id': userId!,
        if (verifiedEmail != null) 'verified_email': verifiedEmail!,
      };
}

class Userinfo {
  /// The user's email address.
  core.String? email;

  /// The user's last name.
  core.String? familyName;

  /// The user's gender.
  core.String? gender;

  /// The user's first name.
  core.String? givenName;

  /// The hosted domain e.g. example.com if the user is Google apps user.
  core.String? hd;

  /// The obfuscated ID of the user.
  core.String? id;

  /// URL of the profile page.
  core.String? link;

  /// The user's preferred locale.
  core.String? locale;

  /// The user's full name.
  core.String? name;

  /// URL of the user's picture image.
  core.String? picture;

  /// Boolean flag which is true if the email address is verified.
  ///
  /// Always verified because we only return the user's primary email address.
  core.bool? verifiedEmail;

  Userinfo();

  Userinfo.fromJson(core.Map _json) {
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('family_name')) {
      familyName = _json['family_name'] as core.String;
    }
    if (_json.containsKey('gender')) {
      gender = _json['gender'] as core.String;
    }
    if (_json.containsKey('given_name')) {
      givenName = _json['given_name'] as core.String;
    }
    if (_json.containsKey('hd')) {
      hd = _json['hd'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('link')) {
      link = _json['link'] as core.String;
    }
    if (_json.containsKey('locale')) {
      locale = _json['locale'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('picture')) {
      picture = _json['picture'] as core.String;
    }
    if (_json.containsKey('verified_email')) {
      verifiedEmail = _json['verified_email'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (email != null) 'email': email!,
        if (familyName != null) 'family_name': familyName!,
        if (gender != null) 'gender': gender!,
        if (givenName != null) 'given_name': givenName!,
        if (hd != null) 'hd': hd!,
        if (id != null) 'id': id!,
        if (link != null) 'link': link!,
        if (locale != null) 'locale': locale!,
        if (name != null) 'name': name!,
        if (picture != null) 'picture': picture!,
        if (verifiedEmail != null) 'verified_email': verifiedEmail!,
      };
}
