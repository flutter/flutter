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

/// Google Identity Toolkit API - v3
///
/// Help the third party sites to implement federated login.
///
/// For more information, see
/// <https://developers.google.com/identity-toolkit/v3/>
///
/// Create an instance of [IdentityToolkitApi] to access these resources:
///
/// - [RelyingpartyResource]
library identitytoolkit.v3;

import 'dart:async' as async;
import 'dart:collection' as collection;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Help the third party sites to implement federated login.
class IdentityToolkitApi {
  /// View and manage your data across Google Cloud Platform services
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  /// View and administer all your Firebase data and settings
  static const firebaseScope = 'https://www.googleapis.com/auth/firebase';

  final commons.ApiRequester _requester;

  RelyingpartyResource get relyingparty => RelyingpartyResource(_requester);

  IdentityToolkitApi(http.Client client,
      {core.String rootUrl = 'https://www.googleapis.com/',
      core.String servicePath = 'identitytoolkit/v3/relyingparty/'})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class RelyingpartyResource {
  final commons.ApiRequester _requester;

  RelyingpartyResource(commons.ApiRequester client) : _requester = client;

  /// Creates the URI used by the IdP to authenticate the user.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CreateAuthUriResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CreateAuthUriResponse> createAuthUri(
    IdentitytoolkitRelyingpartyCreateAuthUriRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'createAuthUri';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CreateAuthUriResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Delete user account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DeleteAccountResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DeleteAccountResponse> deleteAccount(
    IdentitytoolkitRelyingpartyDeleteAccountRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'deleteAccount';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return DeleteAccountResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Batch download user accounts.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DownloadAccountResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DownloadAccountResponse> downloadAccount(
    IdentitytoolkitRelyingpartyDownloadAccountRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'downloadAccount';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return DownloadAccountResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Reset password for a user.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [EmailLinkSigninResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<EmailLinkSigninResponse> emailLinkSignin(
    IdentitytoolkitRelyingpartyEmailLinkSigninRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'emailLinkSignin';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return EmailLinkSigninResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the account info.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetAccountInfoResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetAccountInfoResponse> getAccountInfo(
    IdentitytoolkitRelyingpartyGetAccountInfoRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'getAccountInfo';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GetAccountInfoResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Get a code for user action confirmation.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetOobConfirmationCodeResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetOobConfirmationCodeResponse> getOobConfirmationCode(
    Relyingparty request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'getOobConfirmationCode';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GetOobConfirmationCodeResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Get project configuration.
  ///
  /// Request parameters:
  ///
  /// [delegatedProjectNumber] - Delegated GCP project number of the request.
  ///
  /// [projectNumber] - GCP project number of the request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [IdentitytoolkitRelyingpartyGetProjectConfigResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<IdentitytoolkitRelyingpartyGetProjectConfigResponse>
      getProjectConfig({
    core.String? delegatedProjectNumber,
    core.String? projectNumber,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (delegatedProjectNumber != null)
        'delegatedProjectNumber': [delegatedProjectNumber],
      if (projectNumber != null) 'projectNumber': [projectNumber],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'getProjectConfig';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return IdentitytoolkitRelyingpartyGetProjectConfigResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Get token signing public key.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [IdentitytoolkitRelyingpartyGetPublicKeysResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<IdentitytoolkitRelyingpartyGetPublicKeysResponse> getPublicKeys({
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'publicKeys';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return IdentitytoolkitRelyingpartyGetPublicKeysResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Get recaptcha secure param.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetRecaptchaParamResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetRecaptchaParamResponse> getRecaptchaParam({
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'getRecaptchaParam';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GetRecaptchaParamResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Reset password for a user.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ResetPasswordResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ResetPasswordResponse> resetPassword(
    IdentitytoolkitRelyingpartyResetPasswordRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'resetPassword';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ResetPasswordResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Send SMS verification code.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a
  /// [IdentitytoolkitRelyingpartySendVerificationCodeResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<IdentitytoolkitRelyingpartySendVerificationCodeResponse>
      sendVerificationCode(
    IdentitytoolkitRelyingpartySendVerificationCodeRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'sendVerificationCode';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return IdentitytoolkitRelyingpartySendVerificationCodeResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Set account info for a user.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SetAccountInfoResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SetAccountInfoResponse> setAccountInfo(
    IdentitytoolkitRelyingpartySetAccountInfoRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'setAccountInfo';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return SetAccountInfoResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Set project configuration.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [IdentitytoolkitRelyingpartySetProjectConfigResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<IdentitytoolkitRelyingpartySetProjectConfigResponse>
      setProjectConfig(
    IdentitytoolkitRelyingpartySetProjectConfigRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'setProjectConfig';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return IdentitytoolkitRelyingpartySetProjectConfigResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sign out user.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [IdentitytoolkitRelyingpartySignOutUserResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<IdentitytoolkitRelyingpartySignOutUserResponse> signOutUser(
    IdentitytoolkitRelyingpartySignOutUserRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'signOutUser';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return IdentitytoolkitRelyingpartySignOutUserResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Signup new user.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SignupNewUserResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SignupNewUserResponse> signupNewUser(
    IdentitytoolkitRelyingpartySignupNewUserRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'signupNewUser';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return SignupNewUserResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Batch upload existing user accounts.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UploadAccountResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UploadAccountResponse> uploadAccount(
    IdentitytoolkitRelyingpartyUploadAccountRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'uploadAccount';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return UploadAccountResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Verifies the assertion returned by the IdP.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [VerifyAssertionResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<VerifyAssertionResponse> verifyAssertion(
    IdentitytoolkitRelyingpartyVerifyAssertionRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'verifyAssertion';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return VerifyAssertionResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Verifies the developer asserted ID token.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [VerifyCustomTokenResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<VerifyCustomTokenResponse> verifyCustomToken(
    IdentitytoolkitRelyingpartyVerifyCustomTokenRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'verifyCustomToken';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return VerifyCustomTokenResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Verifies the user entered password.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [VerifyPasswordResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<VerifyPasswordResponse> verifyPassword(
    IdentitytoolkitRelyingpartyVerifyPasswordRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'verifyPassword';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return VerifyPasswordResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Verifies ownership of a phone number and creates/updates the user account
  /// accordingly.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse>
      verifyPhoneNumber(
    IdentitytoolkitRelyingpartyVerifyPhoneNumberRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'verifyPhoneNumber';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Response of creating the IDP authentication URL.
class CreateAuthUriResponse {
  /// all providers the user has once used to do federated login
  core.List<core.String>? allProviders;

  /// The URI used by the IDP to authenticate the user.
  core.String? authUri;

  /// True if captcha is required.
  core.bool? captchaRequired;

  /// True if the authUri is for user's existing provider.
  core.bool? forExistingProvider;

  /// The fixed string identitytoolkit#CreateAuthUriResponse".
  core.String? kind;

  /// The provider ID of the auth URI.
  core.String? providerId;

  /// Whether the user is registered if the identifier is an email.
  core.bool? registered;

  /// Session ID which should be passed in the following verifyAssertion
  /// request.
  core.String? sessionId;

  /// All sign-in methods this user has used.
  core.List<core.String>? signinMethods;

  CreateAuthUriResponse();

  CreateAuthUriResponse.fromJson(core.Map _json) {
    if (_json.containsKey('allProviders')) {
      allProviders = (_json['allProviders'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('authUri')) {
      authUri = _json['authUri'] as core.String;
    }
    if (_json.containsKey('captchaRequired')) {
      captchaRequired = _json['captchaRequired'] as core.bool;
    }
    if (_json.containsKey('forExistingProvider')) {
      forExistingProvider = _json['forExistingProvider'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('providerId')) {
      providerId = _json['providerId'] as core.String;
    }
    if (_json.containsKey('registered')) {
      registered = _json['registered'] as core.bool;
    }
    if (_json.containsKey('sessionId')) {
      sessionId = _json['sessionId'] as core.String;
    }
    if (_json.containsKey('signinMethods')) {
      signinMethods = (_json['signinMethods'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allProviders != null) 'allProviders': allProviders!,
        if (authUri != null) 'authUri': authUri!,
        if (captchaRequired != null) 'captchaRequired': captchaRequired!,
        if (forExistingProvider != null)
          'forExistingProvider': forExistingProvider!,
        if (kind != null) 'kind': kind!,
        if (providerId != null) 'providerId': providerId!,
        if (registered != null) 'registered': registered!,
        if (sessionId != null) 'sessionId': sessionId!,
        if (signinMethods != null) 'signinMethods': signinMethods!,
      };
}

/// Respone of deleting account.
class DeleteAccountResponse {
  /// The fixed string "identitytoolkit#DeleteAccountResponse".
  core.String? kind;

  DeleteAccountResponse();

  DeleteAccountResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
      };
}

/// Response of downloading accounts in batch.
class DownloadAccountResponse {
  /// The fixed string "identitytoolkit#DownloadAccountResponse".
  core.String? kind;

  /// The next page token.
  ///
  /// To be used in a subsequent request to return the next page of results.
  core.String? nextPageToken;

  /// The user accounts data.
  core.List<UserInfo>? users;

  DownloadAccountResponse();

  DownloadAccountResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('users')) {
      users = (_json['users'] as core.List)
          .map<UserInfo>((value) =>
              UserInfo.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (users != null)
          'users': users!.map((value) => value.toJson()).toList(),
      };
}

/// Response of email signIn.
class EmailLinkSigninResponse {
  /// The user's email.
  core.String? email;

  /// Expiration time of STS id token in seconds.
  core.String? expiresIn;

  /// The STS id token to login the newly signed in user.
  core.String? idToken;

  /// Whether the user is new.
  core.bool? isNewUser;

  /// The fixed string "identitytoolkit#EmailLinkSigninResponse".
  core.String? kind;

  /// The RP local ID of the user.
  core.String? localId;

  /// The refresh token for the signed in user.
  core.String? refreshToken;

  EmailLinkSigninResponse();

  EmailLinkSigninResponse.fromJson(core.Map _json) {
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('expiresIn')) {
      expiresIn = _json['expiresIn'] as core.String;
    }
    if (_json.containsKey('idToken')) {
      idToken = _json['idToken'] as core.String;
    }
    if (_json.containsKey('isNewUser')) {
      isNewUser = _json['isNewUser'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('localId')) {
      localId = _json['localId'] as core.String;
    }
    if (_json.containsKey('refreshToken')) {
      refreshToken = _json['refreshToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (email != null) 'email': email!,
        if (expiresIn != null) 'expiresIn': expiresIn!,
        if (idToken != null) 'idToken': idToken!,
        if (isNewUser != null) 'isNewUser': isNewUser!,
        if (kind != null) 'kind': kind!,
        if (localId != null) 'localId': localId!,
        if (refreshToken != null) 'refreshToken': refreshToken!,
      };
}

/// Template for an email template.
class EmailTemplate {
  /// Email body.
  core.String? body;

  /// Email body format.
  core.String? format;

  /// From address of the email.
  core.String? from;

  /// From display name.
  core.String? fromDisplayName;

  /// Reply-to address.
  core.String? replyTo;

  /// Subject of the email.
  core.String? subject;

  EmailTemplate();

  EmailTemplate.fromJson(core.Map _json) {
    if (_json.containsKey('body')) {
      body = _json['body'] as core.String;
    }
    if (_json.containsKey('format')) {
      format = _json['format'] as core.String;
    }
    if (_json.containsKey('from')) {
      from = _json['from'] as core.String;
    }
    if (_json.containsKey('fromDisplayName')) {
      fromDisplayName = _json['fromDisplayName'] as core.String;
    }
    if (_json.containsKey('replyTo')) {
      replyTo = _json['replyTo'] as core.String;
    }
    if (_json.containsKey('subject')) {
      subject = _json['subject'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (body != null) 'body': body!,
        if (format != null) 'format': format!,
        if (from != null) 'from': from!,
        if (fromDisplayName != null) 'fromDisplayName': fromDisplayName!,
        if (replyTo != null) 'replyTo': replyTo!,
        if (subject != null) 'subject': subject!,
      };
}

/// Response of getting account information.
class GetAccountInfoResponse {
  /// The fixed string "identitytoolkit#GetAccountInfoResponse".
  core.String? kind;

  /// The info of the users.
  core.List<UserInfo>? users;

  GetAccountInfoResponse();

  GetAccountInfoResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('users')) {
      users = (_json['users'] as core.List)
          .map<UserInfo>((value) =>
              UserInfo.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (users != null)
          'users': users!.map((value) => value.toJson()).toList(),
      };
}

/// Response of getting a code for user confirmation (reset password, change
/// email etc.).
class GetOobConfirmationCodeResponse {
  /// The email address that the email is sent to.
  core.String? email;

  /// The fixed string "identitytoolkit#GetOobConfirmationCodeResponse".
  core.String? kind;

  /// The code to be send to the user.
  core.String? oobCode;

  GetOobConfirmationCodeResponse();

  GetOobConfirmationCodeResponse.fromJson(core.Map _json) {
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('oobCode')) {
      oobCode = _json['oobCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (email != null) 'email': email!,
        if (kind != null) 'kind': kind!,
        if (oobCode != null) 'oobCode': oobCode!,
      };
}

/// Response of getting recaptcha param.
class GetRecaptchaParamResponse {
  /// The fixed string "identitytoolkit#GetRecaptchaParamResponse".
  core.String? kind;

  /// Site key registered at recaptcha.
  core.String? recaptchaSiteKey;

  /// The stoken field for the recaptcha widget, used to request captcha
  /// challenge.
  core.String? recaptchaStoken;

  GetRecaptchaParamResponse();

  GetRecaptchaParamResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('recaptchaSiteKey')) {
      recaptchaSiteKey = _json['recaptchaSiteKey'] as core.String;
    }
    if (_json.containsKey('recaptchaStoken')) {
      recaptchaStoken = _json['recaptchaStoken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (recaptchaSiteKey != null) 'recaptchaSiteKey': recaptchaSiteKey!,
        if (recaptchaStoken != null) 'recaptchaStoken': recaptchaStoken!,
      };
}

/// Request to get the IDP authentication URL.
class IdentitytoolkitRelyingpartyCreateAuthUriRequest {
  /// The app ID of the mobile app, base64(CERT_SHA1):PACKAGE_NAME for Android,
  /// BUNDLE_ID for iOS.
  core.String? appId;

  /// Explicitly specify the auth flow type.
  ///
  /// Currently only support "CODE_FLOW" type. The field is only used for Google
  /// provider.
  core.String? authFlowType;

  /// The relying party OAuth client ID.
  core.String? clientId;

  /// The opaque value used by the client to maintain context info between the
  /// authentication request and the IDP callback.
  core.String? context;

  /// The URI to which the IDP redirects the user after the federated login
  /// flow.
  core.String? continueUri;

  /// The query parameter that client can customize by themselves in auth url.
  ///
  /// The following parameters are reserved for server so that they cannot be
  /// customized by clients: client_id, response_type, scope, redirect_uri,
  /// state, oauth_token.
  core.Map<core.String, core.String>? customParameter;

  /// The hosted domain to restrict sign-in to accounts at that domain for
  /// Google Apps hosted accounts.
  core.String? hostedDomain;

  /// The email or federated ID of the user.
  core.String? identifier;

  /// The developer's consumer key for OpenId OAuth Extension
  core.String? oauthConsumerKey;

  /// Additional oauth scopes, beyond the basid user profile, that the user
  /// would be prompted to grant
  core.String? oauthScope;

  /// Optional realm for OpenID protocol.
  ///
  /// The sub string "scheme://domain:port" of the param "continueUri" is used
  /// if this is not set.
  core.String? openidRealm;

  /// The native app package for OTA installation.
  core.String? otaApp;

  /// The IdP ID.
  ///
  /// For white listed IdPs it's a short domain name e.g. google.com, aol.com,
  /// live.net and yahoo.com. For other OpenID IdPs it's the OP identifier.
  core.String? providerId;

  /// The session_id passed by client.
  core.String? sessionId;

  /// For multi-tenant use cases, in order to construct sign-in URL with the
  /// correct IDP parameters, Firebear needs to know which Tenant to retrieve
  /// IDP configs from.
  core.String? tenantId;

  /// Tenant project number to be used for idp discovery.
  core.String? tenantProjectNumber;

  IdentitytoolkitRelyingpartyCreateAuthUriRequest();

  IdentitytoolkitRelyingpartyCreateAuthUriRequest.fromJson(core.Map _json) {
    if (_json.containsKey('appId')) {
      appId = _json['appId'] as core.String;
    }
    if (_json.containsKey('authFlowType')) {
      authFlowType = _json['authFlowType'] as core.String;
    }
    if (_json.containsKey('clientId')) {
      clientId = _json['clientId'] as core.String;
    }
    if (_json.containsKey('context')) {
      context = _json['context'] as core.String;
    }
    if (_json.containsKey('continueUri')) {
      continueUri = _json['continueUri'] as core.String;
    }
    if (_json.containsKey('customParameter')) {
      customParameter =
          (_json['customParameter'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('hostedDomain')) {
      hostedDomain = _json['hostedDomain'] as core.String;
    }
    if (_json.containsKey('identifier')) {
      identifier = _json['identifier'] as core.String;
    }
    if (_json.containsKey('oauthConsumerKey')) {
      oauthConsumerKey = _json['oauthConsumerKey'] as core.String;
    }
    if (_json.containsKey('oauthScope')) {
      oauthScope = _json['oauthScope'] as core.String;
    }
    if (_json.containsKey('openidRealm')) {
      openidRealm = _json['openidRealm'] as core.String;
    }
    if (_json.containsKey('otaApp')) {
      otaApp = _json['otaApp'] as core.String;
    }
    if (_json.containsKey('providerId')) {
      providerId = _json['providerId'] as core.String;
    }
    if (_json.containsKey('sessionId')) {
      sessionId = _json['sessionId'] as core.String;
    }
    if (_json.containsKey('tenantId')) {
      tenantId = _json['tenantId'] as core.String;
    }
    if (_json.containsKey('tenantProjectNumber')) {
      tenantProjectNumber = _json['tenantProjectNumber'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (appId != null) 'appId': appId!,
        if (authFlowType != null) 'authFlowType': authFlowType!,
        if (clientId != null) 'clientId': clientId!,
        if (context != null) 'context': context!,
        if (continueUri != null) 'continueUri': continueUri!,
        if (customParameter != null) 'customParameter': customParameter!,
        if (hostedDomain != null) 'hostedDomain': hostedDomain!,
        if (identifier != null) 'identifier': identifier!,
        if (oauthConsumerKey != null) 'oauthConsumerKey': oauthConsumerKey!,
        if (oauthScope != null) 'oauthScope': oauthScope!,
        if (openidRealm != null) 'openidRealm': openidRealm!,
        if (otaApp != null) 'otaApp': otaApp!,
        if (providerId != null) 'providerId': providerId!,
        if (sessionId != null) 'sessionId': sessionId!,
        if (tenantId != null) 'tenantId': tenantId!,
        if (tenantProjectNumber != null)
          'tenantProjectNumber': tenantProjectNumber!,
      };
}

/// Request to delete account.
class IdentitytoolkitRelyingpartyDeleteAccountRequest {
  /// GCP project number of the requesting delegated app.
  ///
  /// Currently only intended for Firebase V1 migration.
  core.String? delegatedProjectNumber;

  /// The GITKit token or STS id token of the authenticated user.
  core.String? idToken;

  /// The local ID of the user.
  core.String? localId;

  IdentitytoolkitRelyingpartyDeleteAccountRequest();

  IdentitytoolkitRelyingpartyDeleteAccountRequest.fromJson(core.Map _json) {
    if (_json.containsKey('delegatedProjectNumber')) {
      delegatedProjectNumber = _json['delegatedProjectNumber'] as core.String;
    }
    if (_json.containsKey('idToken')) {
      idToken = _json['idToken'] as core.String;
    }
    if (_json.containsKey('localId')) {
      localId = _json['localId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (delegatedProjectNumber != null)
          'delegatedProjectNumber': delegatedProjectNumber!,
        if (idToken != null) 'idToken': idToken!,
        if (localId != null) 'localId': localId!,
      };
}

/// Request to download user account in batch.
class IdentitytoolkitRelyingpartyDownloadAccountRequest {
  /// GCP project number of the requesting delegated app.
  ///
  /// Currently only intended for Firebase V1 migration.
  core.String? delegatedProjectNumber;

  /// The max number of results to return in the response.
  core.int? maxResults;

  /// The token for the next page.
  ///
  /// This should be taken from the previous response.
  core.String? nextPageToken;

  /// Specify which project (field value is actually project id) to operate.
  ///
  /// Only used when provided credential.
  core.String? targetProjectId;

  IdentitytoolkitRelyingpartyDownloadAccountRequest();

  IdentitytoolkitRelyingpartyDownloadAccountRequest.fromJson(core.Map _json) {
    if (_json.containsKey('delegatedProjectNumber')) {
      delegatedProjectNumber = _json['delegatedProjectNumber'] as core.String;
    }
    if (_json.containsKey('maxResults')) {
      maxResults = _json['maxResults'] as core.int;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('targetProjectId')) {
      targetProjectId = _json['targetProjectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (delegatedProjectNumber != null)
          'delegatedProjectNumber': delegatedProjectNumber!,
        if (maxResults != null) 'maxResults': maxResults!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (targetProjectId != null) 'targetProjectId': targetProjectId!,
      };
}

/// Request to sign in with email.
class IdentitytoolkitRelyingpartyEmailLinkSigninRequest {
  /// The email address of the user.
  core.String? email;

  /// Token for linking flow.
  core.String? idToken;

  /// The confirmation code.
  core.String? oobCode;

  IdentitytoolkitRelyingpartyEmailLinkSigninRequest();

  IdentitytoolkitRelyingpartyEmailLinkSigninRequest.fromJson(core.Map _json) {
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('idToken')) {
      idToken = _json['idToken'] as core.String;
    }
    if (_json.containsKey('oobCode')) {
      oobCode = _json['oobCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (email != null) 'email': email!,
        if (idToken != null) 'idToken': idToken!,
        if (oobCode != null) 'oobCode': oobCode!,
      };
}

/// Request to get the account information.
class IdentitytoolkitRelyingpartyGetAccountInfoRequest {
  /// GCP project number of the requesting delegated app.
  ///
  /// Currently only intended for Firebase V1 migration.
  core.String? delegatedProjectNumber;

  /// The list of emails of the users to inquiry.
  core.List<core.String>? email;

  /// The GITKit token of the authenticated user.
  core.String? idToken;

  /// The list of local ID's of the users to inquiry.
  core.List<core.String>? localId;

  /// Privileged caller can query users by specified phone number.
  core.List<core.String>? phoneNumber;

  IdentitytoolkitRelyingpartyGetAccountInfoRequest();

  IdentitytoolkitRelyingpartyGetAccountInfoRequest.fromJson(core.Map _json) {
    if (_json.containsKey('delegatedProjectNumber')) {
      delegatedProjectNumber = _json['delegatedProjectNumber'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = (_json['email'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('idToken')) {
      idToken = _json['idToken'] as core.String;
    }
    if (_json.containsKey('localId')) {
      localId = (_json['localId'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('phoneNumber')) {
      phoneNumber = (_json['phoneNumber'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (delegatedProjectNumber != null)
          'delegatedProjectNumber': delegatedProjectNumber!,
        if (email != null) 'email': email!,
        if (idToken != null) 'idToken': idToken!,
        if (localId != null) 'localId': localId!,
        if (phoneNumber != null) 'phoneNumber': phoneNumber!,
      };
}

/// Response of getting the project configuration.
class IdentitytoolkitRelyingpartyGetProjectConfigResponse {
  /// Whether to allow password user sign in or sign up.
  core.bool? allowPasswordUser;

  /// Browser API key, needed when making http request to Apiary.
  core.String? apiKey;

  /// Authorized domains.
  core.List<core.String>? authorizedDomains;

  /// Change email template.
  EmailTemplate? changeEmailTemplate;
  core.String? dynamicLinksDomain;

  /// Whether anonymous user is enabled.
  core.bool? enableAnonymousUser;

  /// OAuth2 provider configuration.
  core.List<IdpConfig>? idpConfig;

  /// Legacy reset password email template.
  EmailTemplate? legacyResetPasswordTemplate;

  /// Project ID of the relying party.
  core.String? projectId;

  /// Reset password email template.
  EmailTemplate? resetPasswordTemplate;

  /// Whether to use email sending provided by Firebear.
  core.bool? useEmailSending;

  /// Verify email template.
  EmailTemplate? verifyEmailTemplate;

  IdentitytoolkitRelyingpartyGetProjectConfigResponse();

  IdentitytoolkitRelyingpartyGetProjectConfigResponse.fromJson(core.Map _json) {
    if (_json.containsKey('allowPasswordUser')) {
      allowPasswordUser = _json['allowPasswordUser'] as core.bool;
    }
    if (_json.containsKey('apiKey')) {
      apiKey = _json['apiKey'] as core.String;
    }
    if (_json.containsKey('authorizedDomains')) {
      authorizedDomains = (_json['authorizedDomains'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('changeEmailTemplate')) {
      changeEmailTemplate = EmailTemplate.fromJson(
          _json['changeEmailTemplate'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dynamicLinksDomain')) {
      dynamicLinksDomain = _json['dynamicLinksDomain'] as core.String;
    }
    if (_json.containsKey('enableAnonymousUser')) {
      enableAnonymousUser = _json['enableAnonymousUser'] as core.bool;
    }
    if (_json.containsKey('idpConfig')) {
      idpConfig = (_json['idpConfig'] as core.List)
          .map<IdpConfig>((value) =>
              IdpConfig.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('legacyResetPasswordTemplate')) {
      legacyResetPasswordTemplate = EmailTemplate.fromJson(
          _json['legacyResetPasswordTemplate']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('resetPasswordTemplate')) {
      resetPasswordTemplate = EmailTemplate.fromJson(
          _json['resetPasswordTemplate']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('useEmailSending')) {
      useEmailSending = _json['useEmailSending'] as core.bool;
    }
    if (_json.containsKey('verifyEmailTemplate')) {
      verifyEmailTemplate = EmailTemplate.fromJson(
          _json['verifyEmailTemplate'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowPasswordUser != null) 'allowPasswordUser': allowPasswordUser!,
        if (apiKey != null) 'apiKey': apiKey!,
        if (authorizedDomains != null) 'authorizedDomains': authorizedDomains!,
        if (changeEmailTemplate != null)
          'changeEmailTemplate': changeEmailTemplate!.toJson(),
        if (dynamicLinksDomain != null)
          'dynamicLinksDomain': dynamicLinksDomain!,
        if (enableAnonymousUser != null)
          'enableAnonymousUser': enableAnonymousUser!,
        if (idpConfig != null)
          'idpConfig': idpConfig!.map((value) => value.toJson()).toList(),
        if (legacyResetPasswordTemplate != null)
          'legacyResetPasswordTemplate': legacyResetPasswordTemplate!.toJson(),
        if (projectId != null) 'projectId': projectId!,
        if (resetPasswordTemplate != null)
          'resetPasswordTemplate': resetPasswordTemplate!.toJson(),
        if (useEmailSending != null) 'useEmailSending': useEmailSending!,
        if (verifyEmailTemplate != null)
          'verifyEmailTemplate': verifyEmailTemplate!.toJson(),
      };
}

/// Respone of getting public keys.
class IdentitytoolkitRelyingpartyGetPublicKeysResponse
    extends collection.MapBase<core.String, core.String> {
  final _innerMap = <core.String, core.String>{};

  IdentitytoolkitRelyingpartyGetPublicKeysResponse();

  IdentitytoolkitRelyingpartyGetPublicKeysResponse.fromJson(
      core.Map<core.String, core.dynamic> _json) {
    _json.forEach((core.String key, value) {
      this[key] = value as core.String;
    });
  }

  core.Map<core.String, core.dynamic> toJson() =>
      core.Map<core.String, core.dynamic>.of(this);

  @core.override
  core.String? operator [](core.Object? key) => _innerMap[key];

  @core.override
  void operator []=(core.String key, core.String value) {
    _innerMap[key] = value;
  }

  @core.override
  void clear() {
    _innerMap.clear();
  }

  @core.override
  core.Iterable<core.String> get keys => _innerMap.keys;

  @core.override
  core.String? remove(core.Object? key) => _innerMap.remove(key);
}

/// Request to reset the password.
class IdentitytoolkitRelyingpartyResetPasswordRequest {
  /// The email address of the user.
  core.String? email;

  /// The new password inputted by the user.
  core.String? newPassword;

  /// The old password inputted by the user.
  core.String? oldPassword;

  /// The confirmation code.
  core.String? oobCode;

  IdentitytoolkitRelyingpartyResetPasswordRequest();

  IdentitytoolkitRelyingpartyResetPasswordRequest.fromJson(core.Map _json) {
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('newPassword')) {
      newPassword = _json['newPassword'] as core.String;
    }
    if (_json.containsKey('oldPassword')) {
      oldPassword = _json['oldPassword'] as core.String;
    }
    if (_json.containsKey('oobCode')) {
      oobCode = _json['oobCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (email != null) 'email': email!,
        if (newPassword != null) 'newPassword': newPassword!,
        if (oldPassword != null) 'oldPassword': oldPassword!,
        if (oobCode != null) 'oobCode': oobCode!,
      };
}

/// Request for Identitytoolkit-SendVerificationCode
class IdentitytoolkitRelyingpartySendVerificationCodeRequest {
  /// Receipt of successful app token validation with APNS.
  core.String? iosReceipt;

  /// Secret delivered to iOS app via APNS.
  core.String? iosSecret;

  /// The phone number to send the verification code to in E.164 format.
  core.String? phoneNumber;

  /// Recaptcha solution.
  core.String? recaptchaToken;

  IdentitytoolkitRelyingpartySendVerificationCodeRequest();

  IdentitytoolkitRelyingpartySendVerificationCodeRequest.fromJson(
      core.Map _json) {
    if (_json.containsKey('iosReceipt')) {
      iosReceipt = _json['iosReceipt'] as core.String;
    }
    if (_json.containsKey('iosSecret')) {
      iosSecret = _json['iosSecret'] as core.String;
    }
    if (_json.containsKey('phoneNumber')) {
      phoneNumber = _json['phoneNumber'] as core.String;
    }
    if (_json.containsKey('recaptchaToken')) {
      recaptchaToken = _json['recaptchaToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (iosReceipt != null) 'iosReceipt': iosReceipt!,
        if (iosSecret != null) 'iosSecret': iosSecret!,
        if (phoneNumber != null) 'phoneNumber': phoneNumber!,
        if (recaptchaToken != null) 'recaptchaToken': recaptchaToken!,
      };
}

/// Response for Identitytoolkit-SendVerificationCode
class IdentitytoolkitRelyingpartySendVerificationCodeResponse {
  /// Encrypted session information
  core.String? sessionInfo;

  IdentitytoolkitRelyingpartySendVerificationCodeResponse();

  IdentitytoolkitRelyingpartySendVerificationCodeResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('sessionInfo')) {
      sessionInfo = _json['sessionInfo'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sessionInfo != null) 'sessionInfo': sessionInfo!,
      };
}

/// Request to set the account information.
class IdentitytoolkitRelyingpartySetAccountInfoRequest {
  /// The captcha challenge.
  core.String? captchaChallenge;

  /// Response to the captcha.
  core.String? captchaResponse;

  /// The timestamp when the account is created.
  core.String? createdAt;

  /// The custom attributes to be set in the user's id token.
  core.String? customAttributes;

  /// GCP project number of the requesting delegated app.
  ///
  /// Currently only intended for Firebase V1 migration.
  core.String? delegatedProjectNumber;

  /// The attributes users request to delete.
  core.List<core.String>? deleteAttribute;

  /// The IDPs the user request to delete.
  core.List<core.String>? deleteProvider;

  /// Whether to disable the user.
  core.bool? disableUser;

  /// The name of the user.
  core.String? displayName;

  /// The email of the user.
  core.String? email;

  /// Mark the email as verified or not.
  core.bool? emailVerified;

  /// The GITKit token of the authenticated user.
  core.String? idToken;

  /// Instance id token of the app.
  core.String? instanceId;

  /// Last login timestamp.
  core.String? lastLoginAt;

  /// The local ID of the user.
  core.String? localId;

  /// The out-of-band code of the change email request.
  core.String? oobCode;

  /// The new password of the user.
  core.String? password;

  /// Privileged caller can update user with specified phone number.
  core.String? phoneNumber;

  /// The photo url of the user.
  core.String? photoUrl;

  /// The associated IDPs of the user.
  core.List<core.String>? provider;

  /// Whether return sts id token and refresh token instead of gitkit token.
  core.bool? returnSecureToken;

  /// Mark the user to upgrade to federated login.
  core.bool? upgradeToFederatedLogin;

  /// Timestamp in seconds for valid login token.
  core.String? validSince;

  IdentitytoolkitRelyingpartySetAccountInfoRequest();

  IdentitytoolkitRelyingpartySetAccountInfoRequest.fromJson(core.Map _json) {
    if (_json.containsKey('captchaChallenge')) {
      captchaChallenge = _json['captchaChallenge'] as core.String;
    }
    if (_json.containsKey('captchaResponse')) {
      captchaResponse = _json['captchaResponse'] as core.String;
    }
    if (_json.containsKey('createdAt')) {
      createdAt = _json['createdAt'] as core.String;
    }
    if (_json.containsKey('customAttributes')) {
      customAttributes = _json['customAttributes'] as core.String;
    }
    if (_json.containsKey('delegatedProjectNumber')) {
      delegatedProjectNumber = _json['delegatedProjectNumber'] as core.String;
    }
    if (_json.containsKey('deleteAttribute')) {
      deleteAttribute = (_json['deleteAttribute'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('deleteProvider')) {
      deleteProvider = (_json['deleteProvider'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('disableUser')) {
      disableUser = _json['disableUser'] as core.bool;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('emailVerified')) {
      emailVerified = _json['emailVerified'] as core.bool;
    }
    if (_json.containsKey('idToken')) {
      idToken = _json['idToken'] as core.String;
    }
    if (_json.containsKey('instanceId')) {
      instanceId = _json['instanceId'] as core.String;
    }
    if (_json.containsKey('lastLoginAt')) {
      lastLoginAt = _json['lastLoginAt'] as core.String;
    }
    if (_json.containsKey('localId')) {
      localId = _json['localId'] as core.String;
    }
    if (_json.containsKey('oobCode')) {
      oobCode = _json['oobCode'] as core.String;
    }
    if (_json.containsKey('password')) {
      password = _json['password'] as core.String;
    }
    if (_json.containsKey('phoneNumber')) {
      phoneNumber = _json['phoneNumber'] as core.String;
    }
    if (_json.containsKey('photoUrl')) {
      photoUrl = _json['photoUrl'] as core.String;
    }
    if (_json.containsKey('provider')) {
      provider = (_json['provider'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('returnSecureToken')) {
      returnSecureToken = _json['returnSecureToken'] as core.bool;
    }
    if (_json.containsKey('upgradeToFederatedLogin')) {
      upgradeToFederatedLogin = _json['upgradeToFederatedLogin'] as core.bool;
    }
    if (_json.containsKey('validSince')) {
      validSince = _json['validSince'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (captchaChallenge != null) 'captchaChallenge': captchaChallenge!,
        if (captchaResponse != null) 'captchaResponse': captchaResponse!,
        if (createdAt != null) 'createdAt': createdAt!,
        if (customAttributes != null) 'customAttributes': customAttributes!,
        if (delegatedProjectNumber != null)
          'delegatedProjectNumber': delegatedProjectNumber!,
        if (deleteAttribute != null) 'deleteAttribute': deleteAttribute!,
        if (deleteProvider != null) 'deleteProvider': deleteProvider!,
        if (disableUser != null) 'disableUser': disableUser!,
        if (displayName != null) 'displayName': displayName!,
        if (email != null) 'email': email!,
        if (emailVerified != null) 'emailVerified': emailVerified!,
        if (idToken != null) 'idToken': idToken!,
        if (instanceId != null) 'instanceId': instanceId!,
        if (lastLoginAt != null) 'lastLoginAt': lastLoginAt!,
        if (localId != null) 'localId': localId!,
        if (oobCode != null) 'oobCode': oobCode!,
        if (password != null) 'password': password!,
        if (phoneNumber != null) 'phoneNumber': phoneNumber!,
        if (photoUrl != null) 'photoUrl': photoUrl!,
        if (provider != null) 'provider': provider!,
        if (returnSecureToken != null) 'returnSecureToken': returnSecureToken!,
        if (upgradeToFederatedLogin != null)
          'upgradeToFederatedLogin': upgradeToFederatedLogin!,
        if (validSince != null) 'validSince': validSince!,
      };
}

/// Request to set the project configuration.
class IdentitytoolkitRelyingpartySetProjectConfigRequest {
  /// Whether to allow password user sign in or sign up.
  core.bool? allowPasswordUser;

  /// Browser API key, needed when making http request to Apiary.
  core.String? apiKey;

  /// Authorized domains for widget redirect.
  core.List<core.String>? authorizedDomains;

  /// Change email template.
  EmailTemplate? changeEmailTemplate;

  /// GCP project number of the requesting delegated app.
  ///
  /// Currently only intended for Firebase V1 migration.
  core.String? delegatedProjectNumber;

  /// Whether to enable anonymous user.
  core.bool? enableAnonymousUser;

  /// Oauth2 provider configuration.
  core.List<IdpConfig>? idpConfig;

  /// Legacy reset password email template.
  EmailTemplate? legacyResetPasswordTemplate;

  /// Reset password email template.
  EmailTemplate? resetPasswordTemplate;

  /// Whether to use email sending provided by Firebear.
  core.bool? useEmailSending;

  /// Verify email template.
  EmailTemplate? verifyEmailTemplate;

  IdentitytoolkitRelyingpartySetProjectConfigRequest();

  IdentitytoolkitRelyingpartySetProjectConfigRequest.fromJson(core.Map _json) {
    if (_json.containsKey('allowPasswordUser')) {
      allowPasswordUser = _json['allowPasswordUser'] as core.bool;
    }
    if (_json.containsKey('apiKey')) {
      apiKey = _json['apiKey'] as core.String;
    }
    if (_json.containsKey('authorizedDomains')) {
      authorizedDomains = (_json['authorizedDomains'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('changeEmailTemplate')) {
      changeEmailTemplate = EmailTemplate.fromJson(
          _json['changeEmailTemplate'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('delegatedProjectNumber')) {
      delegatedProjectNumber = _json['delegatedProjectNumber'] as core.String;
    }
    if (_json.containsKey('enableAnonymousUser')) {
      enableAnonymousUser = _json['enableAnonymousUser'] as core.bool;
    }
    if (_json.containsKey('idpConfig')) {
      idpConfig = (_json['idpConfig'] as core.List)
          .map<IdpConfig>((value) =>
              IdpConfig.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('legacyResetPasswordTemplate')) {
      legacyResetPasswordTemplate = EmailTemplate.fromJson(
          _json['legacyResetPasswordTemplate']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('resetPasswordTemplate')) {
      resetPasswordTemplate = EmailTemplate.fromJson(
          _json['resetPasswordTemplate']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('useEmailSending')) {
      useEmailSending = _json['useEmailSending'] as core.bool;
    }
    if (_json.containsKey('verifyEmailTemplate')) {
      verifyEmailTemplate = EmailTemplate.fromJson(
          _json['verifyEmailTemplate'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowPasswordUser != null) 'allowPasswordUser': allowPasswordUser!,
        if (apiKey != null) 'apiKey': apiKey!,
        if (authorizedDomains != null) 'authorizedDomains': authorizedDomains!,
        if (changeEmailTemplate != null)
          'changeEmailTemplate': changeEmailTemplate!.toJson(),
        if (delegatedProjectNumber != null)
          'delegatedProjectNumber': delegatedProjectNumber!,
        if (enableAnonymousUser != null)
          'enableAnonymousUser': enableAnonymousUser!,
        if (idpConfig != null)
          'idpConfig': idpConfig!.map((value) => value.toJson()).toList(),
        if (legacyResetPasswordTemplate != null)
          'legacyResetPasswordTemplate': legacyResetPasswordTemplate!.toJson(),
        if (resetPasswordTemplate != null)
          'resetPasswordTemplate': resetPasswordTemplate!.toJson(),
        if (useEmailSending != null) 'useEmailSending': useEmailSending!,
        if (verifyEmailTemplate != null)
          'verifyEmailTemplate': verifyEmailTemplate!.toJson(),
      };
}

/// Response of setting the project configuration.
class IdentitytoolkitRelyingpartySetProjectConfigResponse {
  /// Project ID of the relying party.
  core.String? projectId;

  IdentitytoolkitRelyingpartySetProjectConfigResponse();

  IdentitytoolkitRelyingpartySetProjectConfigResponse.fromJson(core.Map _json) {
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (projectId != null) 'projectId': projectId!,
      };
}

/// Request to sign out user.
class IdentitytoolkitRelyingpartySignOutUserRequest {
  /// Instance id token of the app.
  core.String? instanceId;

  /// The local ID of the user.
  core.String? localId;

  IdentitytoolkitRelyingpartySignOutUserRequest();

  IdentitytoolkitRelyingpartySignOutUserRequest.fromJson(core.Map _json) {
    if (_json.containsKey('instanceId')) {
      instanceId = _json['instanceId'] as core.String;
    }
    if (_json.containsKey('localId')) {
      localId = _json['localId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (instanceId != null) 'instanceId': instanceId!,
        if (localId != null) 'localId': localId!,
      };
}

/// Response of signing out user.
class IdentitytoolkitRelyingpartySignOutUserResponse {
  /// The local ID of the user.
  core.String? localId;

  IdentitytoolkitRelyingpartySignOutUserResponse();

  IdentitytoolkitRelyingpartySignOutUserResponse.fromJson(core.Map _json) {
    if (_json.containsKey('localId')) {
      localId = _json['localId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (localId != null) 'localId': localId!,
      };
}

/// Request to signup new user, create anonymous user or anonymous user reauth.
class IdentitytoolkitRelyingpartySignupNewUserRequest {
  /// The captcha challenge.
  core.String? captchaChallenge;

  /// Response to the captcha.
  core.String? captchaResponse;

  /// Whether to disable the user.
  ///
  /// Only can be used by service account.
  core.bool? disabled;

  /// The name of the user.
  core.String? displayName;

  /// The email of the user.
  core.String? email;

  /// Mark the email as verified or not.
  ///
  /// Only can be used by service account.
  core.bool? emailVerified;

  /// The GITKit token of the authenticated user.
  core.String? idToken;

  /// Instance id token of the app.
  core.String? instanceId;

  /// Privileged caller can create user with specified user id.
  core.String? localId;

  /// The new password of the user.
  core.String? password;

  /// Privileged caller can create user with specified phone number.
  core.String? phoneNumber;

  /// The photo url of the user.
  core.String? photoUrl;

  /// For multi-tenant use cases, in order to construct sign-in URL with the
  /// correct IDP parameters, Firebear needs to know which Tenant to retrieve
  /// IDP configs from.
  core.String? tenantId;

  /// Tenant project number to be used for idp discovery.
  core.String? tenantProjectNumber;

  IdentitytoolkitRelyingpartySignupNewUserRequest();

  IdentitytoolkitRelyingpartySignupNewUserRequest.fromJson(core.Map _json) {
    if (_json.containsKey('captchaChallenge')) {
      captchaChallenge = _json['captchaChallenge'] as core.String;
    }
    if (_json.containsKey('captchaResponse')) {
      captchaResponse = _json['captchaResponse'] as core.String;
    }
    if (_json.containsKey('disabled')) {
      disabled = _json['disabled'] as core.bool;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('emailVerified')) {
      emailVerified = _json['emailVerified'] as core.bool;
    }
    if (_json.containsKey('idToken')) {
      idToken = _json['idToken'] as core.String;
    }
    if (_json.containsKey('instanceId')) {
      instanceId = _json['instanceId'] as core.String;
    }
    if (_json.containsKey('localId')) {
      localId = _json['localId'] as core.String;
    }
    if (_json.containsKey('password')) {
      password = _json['password'] as core.String;
    }
    if (_json.containsKey('phoneNumber')) {
      phoneNumber = _json['phoneNumber'] as core.String;
    }
    if (_json.containsKey('photoUrl')) {
      photoUrl = _json['photoUrl'] as core.String;
    }
    if (_json.containsKey('tenantId')) {
      tenantId = _json['tenantId'] as core.String;
    }
    if (_json.containsKey('tenantProjectNumber')) {
      tenantProjectNumber = _json['tenantProjectNumber'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (captchaChallenge != null) 'captchaChallenge': captchaChallenge!,
        if (captchaResponse != null) 'captchaResponse': captchaResponse!,
        if (disabled != null) 'disabled': disabled!,
        if (displayName != null) 'displayName': displayName!,
        if (email != null) 'email': email!,
        if (emailVerified != null) 'emailVerified': emailVerified!,
        if (idToken != null) 'idToken': idToken!,
        if (instanceId != null) 'instanceId': instanceId!,
        if (localId != null) 'localId': localId!,
        if (password != null) 'password': password!,
        if (phoneNumber != null) 'phoneNumber': phoneNumber!,
        if (photoUrl != null) 'photoUrl': photoUrl!,
        if (tenantId != null) 'tenantId': tenantId!,
        if (tenantProjectNumber != null)
          'tenantProjectNumber': tenantProjectNumber!,
      };
}

/// Request to upload user account in batch.
class IdentitytoolkitRelyingpartyUploadAccountRequest {
  /// Whether allow overwrite existing account when user local_id exists.
  core.bool? allowOverwrite;
  core.int? blockSize;

  /// The following 4 fields are for standard scrypt algorithm.
  core.int? cpuMemCost;

  /// GCP project number of the requesting delegated app.
  ///
  /// Currently only intended for Firebase V1 migration.
  core.String? delegatedProjectNumber;
  core.int? dkLen;

  /// The password hash algorithm.
  core.String? hashAlgorithm;

  /// Memory cost for hash calculation.
  ///
  /// Used by scrypt similar algorithms.
  core.int? memoryCost;
  core.int? parallelization;

  /// Rounds for hash calculation.
  ///
  /// Used by scrypt and similar algorithms.
  core.int? rounds;

  /// The salt separator.
  core.String? saltSeparator;
  core.List<core.int> get saltSeparatorAsBytes =>
      convert.base64.decode(saltSeparator!);

  set saltSeparatorAsBytes(core.List<core.int> _bytes) {
    saltSeparator =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// If true, backend will do sanity check(including duplicate email and
  /// federated id) when uploading account.
  core.bool? sanityCheck;

  /// The key for to hash the password.
  core.String? signerKey;
  core.List<core.int> get signerKeyAsBytes => convert.base64.decode(signerKey!);

  set signerKeyAsBytes(core.List<core.int> _bytes) {
    signerKey =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// Specify which project (field value is actually project id) to operate.
  ///
  /// Only used when provided credential.
  core.String? targetProjectId;

  /// The account info to be stored.
  core.List<UserInfo>? users;

  IdentitytoolkitRelyingpartyUploadAccountRequest();

  IdentitytoolkitRelyingpartyUploadAccountRequest.fromJson(core.Map _json) {
    if (_json.containsKey('allowOverwrite')) {
      allowOverwrite = _json['allowOverwrite'] as core.bool;
    }
    if (_json.containsKey('blockSize')) {
      blockSize = _json['blockSize'] as core.int;
    }
    if (_json.containsKey('cpuMemCost')) {
      cpuMemCost = _json['cpuMemCost'] as core.int;
    }
    if (_json.containsKey('delegatedProjectNumber')) {
      delegatedProjectNumber = _json['delegatedProjectNumber'] as core.String;
    }
    if (_json.containsKey('dkLen')) {
      dkLen = _json['dkLen'] as core.int;
    }
    if (_json.containsKey('hashAlgorithm')) {
      hashAlgorithm = _json['hashAlgorithm'] as core.String;
    }
    if (_json.containsKey('memoryCost')) {
      memoryCost = _json['memoryCost'] as core.int;
    }
    if (_json.containsKey('parallelization')) {
      parallelization = _json['parallelization'] as core.int;
    }
    if (_json.containsKey('rounds')) {
      rounds = _json['rounds'] as core.int;
    }
    if (_json.containsKey('saltSeparator')) {
      saltSeparator = _json['saltSeparator'] as core.String;
    }
    if (_json.containsKey('sanityCheck')) {
      sanityCheck = _json['sanityCheck'] as core.bool;
    }
    if (_json.containsKey('signerKey')) {
      signerKey = _json['signerKey'] as core.String;
    }
    if (_json.containsKey('targetProjectId')) {
      targetProjectId = _json['targetProjectId'] as core.String;
    }
    if (_json.containsKey('users')) {
      users = (_json['users'] as core.List)
          .map<UserInfo>((value) =>
              UserInfo.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowOverwrite != null) 'allowOverwrite': allowOverwrite!,
        if (blockSize != null) 'blockSize': blockSize!,
        if (cpuMemCost != null) 'cpuMemCost': cpuMemCost!,
        if (delegatedProjectNumber != null)
          'delegatedProjectNumber': delegatedProjectNumber!,
        if (dkLen != null) 'dkLen': dkLen!,
        if (hashAlgorithm != null) 'hashAlgorithm': hashAlgorithm!,
        if (memoryCost != null) 'memoryCost': memoryCost!,
        if (parallelization != null) 'parallelization': parallelization!,
        if (rounds != null) 'rounds': rounds!,
        if (saltSeparator != null) 'saltSeparator': saltSeparator!,
        if (sanityCheck != null) 'sanityCheck': sanityCheck!,
        if (signerKey != null) 'signerKey': signerKey!,
        if (targetProjectId != null) 'targetProjectId': targetProjectId!,
        if (users != null)
          'users': users!.map((value) => value.toJson()).toList(),
      };
}

/// Request to verify the IDP assertion.
class IdentitytoolkitRelyingpartyVerifyAssertionRequest {
  /// When it's true, automatically creates a new account if the user doesn't
  /// exist.
  ///
  /// When it's false, allows existing user to sign in normally and throws
  /// exception if the user doesn't exist.
  core.bool? autoCreate;

  /// GCP project number of the requesting delegated app.
  ///
  /// Currently only intended for Firebase V1 migration.
  core.String? delegatedProjectNumber;

  /// The GITKit token of the authenticated user.
  core.String? idToken;

  /// Instance id token of the app.
  core.String? instanceId;

  /// The GITKit token for the non-trusted IDP pending to be confirmed by the
  /// user.
  core.String? pendingIdToken;

  /// The post body if the request is a HTTP POST.
  core.String? postBody;

  /// The URI to which the IDP redirects the user back.
  ///
  /// It may contain federated login result params added by the IDP.
  core.String? requestUri;

  /// Whether return 200 and IDP credential rather than throw exception when
  /// federated id is already linked.
  core.bool? returnIdpCredential;

  /// Whether to return refresh tokens.
  core.bool? returnRefreshToken;

  /// Whether return sts id token and refresh token instead of gitkit token.
  core.bool? returnSecureToken;

  /// Session ID, which should match the one in previous createAuthUri request.
  core.String? sessionId;

  /// For multi-tenant use cases, in order to construct sign-in URL with the
  /// correct IDP parameters, Firebear needs to know which Tenant to retrieve
  /// IDP configs from.
  core.String? tenantId;

  /// Tenant project number to be used for idp discovery.
  core.String? tenantProjectNumber;

  IdentitytoolkitRelyingpartyVerifyAssertionRequest();

  IdentitytoolkitRelyingpartyVerifyAssertionRequest.fromJson(core.Map _json) {
    if (_json.containsKey('autoCreate')) {
      autoCreate = _json['autoCreate'] as core.bool;
    }
    if (_json.containsKey('delegatedProjectNumber')) {
      delegatedProjectNumber = _json['delegatedProjectNumber'] as core.String;
    }
    if (_json.containsKey('idToken')) {
      idToken = _json['idToken'] as core.String;
    }
    if (_json.containsKey('instanceId')) {
      instanceId = _json['instanceId'] as core.String;
    }
    if (_json.containsKey('pendingIdToken')) {
      pendingIdToken = _json['pendingIdToken'] as core.String;
    }
    if (_json.containsKey('postBody')) {
      postBody = _json['postBody'] as core.String;
    }
    if (_json.containsKey('requestUri')) {
      requestUri = _json['requestUri'] as core.String;
    }
    if (_json.containsKey('returnIdpCredential')) {
      returnIdpCredential = _json['returnIdpCredential'] as core.bool;
    }
    if (_json.containsKey('returnRefreshToken')) {
      returnRefreshToken = _json['returnRefreshToken'] as core.bool;
    }
    if (_json.containsKey('returnSecureToken')) {
      returnSecureToken = _json['returnSecureToken'] as core.bool;
    }
    if (_json.containsKey('sessionId')) {
      sessionId = _json['sessionId'] as core.String;
    }
    if (_json.containsKey('tenantId')) {
      tenantId = _json['tenantId'] as core.String;
    }
    if (_json.containsKey('tenantProjectNumber')) {
      tenantProjectNumber = _json['tenantProjectNumber'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (autoCreate != null) 'autoCreate': autoCreate!,
        if (delegatedProjectNumber != null)
          'delegatedProjectNumber': delegatedProjectNumber!,
        if (idToken != null) 'idToken': idToken!,
        if (instanceId != null) 'instanceId': instanceId!,
        if (pendingIdToken != null) 'pendingIdToken': pendingIdToken!,
        if (postBody != null) 'postBody': postBody!,
        if (requestUri != null) 'requestUri': requestUri!,
        if (returnIdpCredential != null)
          'returnIdpCredential': returnIdpCredential!,
        if (returnRefreshToken != null)
          'returnRefreshToken': returnRefreshToken!,
        if (returnSecureToken != null) 'returnSecureToken': returnSecureToken!,
        if (sessionId != null) 'sessionId': sessionId!,
        if (tenantId != null) 'tenantId': tenantId!,
        if (tenantProjectNumber != null)
          'tenantProjectNumber': tenantProjectNumber!,
      };
}

/// Request to verify a custom token
class IdentitytoolkitRelyingpartyVerifyCustomTokenRequest {
  /// GCP project number of the requesting delegated app.
  ///
  /// Currently only intended for Firebase V1 migration.
  core.String? delegatedProjectNumber;

  /// Instance id token of the app.
  core.String? instanceId;

  /// Whether return sts id token and refresh token instead of gitkit token.
  core.bool? returnSecureToken;

  /// The custom token to verify
  core.String? token;

  IdentitytoolkitRelyingpartyVerifyCustomTokenRequest();

  IdentitytoolkitRelyingpartyVerifyCustomTokenRequest.fromJson(core.Map _json) {
    if (_json.containsKey('delegatedProjectNumber')) {
      delegatedProjectNumber = _json['delegatedProjectNumber'] as core.String;
    }
    if (_json.containsKey('instanceId')) {
      instanceId = _json['instanceId'] as core.String;
    }
    if (_json.containsKey('returnSecureToken')) {
      returnSecureToken = _json['returnSecureToken'] as core.bool;
    }
    if (_json.containsKey('token')) {
      token = _json['token'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (delegatedProjectNumber != null)
          'delegatedProjectNumber': delegatedProjectNumber!,
        if (instanceId != null) 'instanceId': instanceId!,
        if (returnSecureToken != null) 'returnSecureToken': returnSecureToken!,
        if (token != null) 'token': token!,
      };
}

/// Request to verify the password.
class IdentitytoolkitRelyingpartyVerifyPasswordRequest {
  /// The captcha challenge.
  core.String? captchaChallenge;

  /// Response to the captcha.
  core.String? captchaResponse;

  /// GCP project number of the requesting delegated app.
  ///
  /// Currently only intended for Firebase V1 migration.
  core.String? delegatedProjectNumber;

  /// The email of the user.
  core.String? email;

  /// The GITKit token of the authenticated user.
  core.String? idToken;

  /// Instance id token of the app.
  core.String? instanceId;

  /// The password inputed by the user.
  core.String? password;

  /// The GITKit token for the non-trusted IDP, which is to be confirmed by the
  /// user.
  core.String? pendingIdToken;

  /// Whether return sts id token and refresh token instead of gitkit token.
  core.bool? returnSecureToken;

  /// For multi-tenant use cases, in order to construct sign-in URL with the
  /// correct IDP parameters, Firebear needs to know which Tenant to retrieve
  /// IDP configs from.
  core.String? tenantId;

  /// Tenant project number to be used for idp discovery.
  core.String? tenantProjectNumber;

  IdentitytoolkitRelyingpartyVerifyPasswordRequest();

  IdentitytoolkitRelyingpartyVerifyPasswordRequest.fromJson(core.Map _json) {
    if (_json.containsKey('captchaChallenge')) {
      captchaChallenge = _json['captchaChallenge'] as core.String;
    }
    if (_json.containsKey('captchaResponse')) {
      captchaResponse = _json['captchaResponse'] as core.String;
    }
    if (_json.containsKey('delegatedProjectNumber')) {
      delegatedProjectNumber = _json['delegatedProjectNumber'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('idToken')) {
      idToken = _json['idToken'] as core.String;
    }
    if (_json.containsKey('instanceId')) {
      instanceId = _json['instanceId'] as core.String;
    }
    if (_json.containsKey('password')) {
      password = _json['password'] as core.String;
    }
    if (_json.containsKey('pendingIdToken')) {
      pendingIdToken = _json['pendingIdToken'] as core.String;
    }
    if (_json.containsKey('returnSecureToken')) {
      returnSecureToken = _json['returnSecureToken'] as core.bool;
    }
    if (_json.containsKey('tenantId')) {
      tenantId = _json['tenantId'] as core.String;
    }
    if (_json.containsKey('tenantProjectNumber')) {
      tenantProjectNumber = _json['tenantProjectNumber'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (captchaChallenge != null) 'captchaChallenge': captchaChallenge!,
        if (captchaResponse != null) 'captchaResponse': captchaResponse!,
        if (delegatedProjectNumber != null)
          'delegatedProjectNumber': delegatedProjectNumber!,
        if (email != null) 'email': email!,
        if (idToken != null) 'idToken': idToken!,
        if (instanceId != null) 'instanceId': instanceId!,
        if (password != null) 'password': password!,
        if (pendingIdToken != null) 'pendingIdToken': pendingIdToken!,
        if (returnSecureToken != null) 'returnSecureToken': returnSecureToken!,
        if (tenantId != null) 'tenantId': tenantId!,
        if (tenantProjectNumber != null)
          'tenantProjectNumber': tenantProjectNumber!,
      };
}

/// Request for Identitytoolkit-VerifyPhoneNumber
class IdentitytoolkitRelyingpartyVerifyPhoneNumberRequest {
  core.String? code;
  core.String? idToken;
  core.String? operation;
  core.String? phoneNumber;

  /// The session info previously returned by
  /// IdentityToolkit-SendVerificationCode.
  core.String? sessionInfo;
  core.String? temporaryProof;
  core.String? verificationProof;

  IdentitytoolkitRelyingpartyVerifyPhoneNumberRequest();

  IdentitytoolkitRelyingpartyVerifyPhoneNumberRequest.fromJson(core.Map _json) {
    if (_json.containsKey('code')) {
      code = _json['code'] as core.String;
    }
    if (_json.containsKey('idToken')) {
      idToken = _json['idToken'] as core.String;
    }
    if (_json.containsKey('operation')) {
      operation = _json['operation'] as core.String;
    }
    if (_json.containsKey('phoneNumber')) {
      phoneNumber = _json['phoneNumber'] as core.String;
    }
    if (_json.containsKey('sessionInfo')) {
      sessionInfo = _json['sessionInfo'] as core.String;
    }
    if (_json.containsKey('temporaryProof')) {
      temporaryProof = _json['temporaryProof'] as core.String;
    }
    if (_json.containsKey('verificationProof')) {
      verificationProof = _json['verificationProof'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (code != null) 'code': code!,
        if (idToken != null) 'idToken': idToken!,
        if (operation != null) 'operation': operation!,
        if (phoneNumber != null) 'phoneNumber': phoneNumber!,
        if (sessionInfo != null) 'sessionInfo': sessionInfo!,
        if (temporaryProof != null) 'temporaryProof': temporaryProof!,
        if (verificationProof != null) 'verificationProof': verificationProof!,
      };
}

/// Response for Identitytoolkit-VerifyPhoneNumber
class IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse {
  core.String? expiresIn;
  core.String? idToken;
  core.bool? isNewUser;
  core.String? localId;
  core.String? phoneNumber;
  core.String? refreshToken;
  core.String? temporaryProof;
  core.String? temporaryProofExpiresIn;
  core.String? verificationProof;
  core.String? verificationProofExpiresIn;

  IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse();

  IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('expiresIn')) {
      expiresIn = _json['expiresIn'] as core.String;
    }
    if (_json.containsKey('idToken')) {
      idToken = _json['idToken'] as core.String;
    }
    if (_json.containsKey('isNewUser')) {
      isNewUser = _json['isNewUser'] as core.bool;
    }
    if (_json.containsKey('localId')) {
      localId = _json['localId'] as core.String;
    }
    if (_json.containsKey('phoneNumber')) {
      phoneNumber = _json['phoneNumber'] as core.String;
    }
    if (_json.containsKey('refreshToken')) {
      refreshToken = _json['refreshToken'] as core.String;
    }
    if (_json.containsKey('temporaryProof')) {
      temporaryProof = _json['temporaryProof'] as core.String;
    }
    if (_json.containsKey('temporaryProofExpiresIn')) {
      temporaryProofExpiresIn = _json['temporaryProofExpiresIn'] as core.String;
    }
    if (_json.containsKey('verificationProof')) {
      verificationProof = _json['verificationProof'] as core.String;
    }
    if (_json.containsKey('verificationProofExpiresIn')) {
      verificationProofExpiresIn =
          _json['verificationProofExpiresIn'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (expiresIn != null) 'expiresIn': expiresIn!,
        if (idToken != null) 'idToken': idToken!,
        if (isNewUser != null) 'isNewUser': isNewUser!,
        if (localId != null) 'localId': localId!,
        if (phoneNumber != null) 'phoneNumber': phoneNumber!,
        if (refreshToken != null) 'refreshToken': refreshToken!,
        if (temporaryProof != null) 'temporaryProof': temporaryProof!,
        if (temporaryProofExpiresIn != null)
          'temporaryProofExpiresIn': temporaryProofExpiresIn!,
        if (verificationProof != null) 'verificationProof': verificationProof!,
        if (verificationProofExpiresIn != null)
          'verificationProofExpiresIn': verificationProofExpiresIn!,
      };
}

/// Template for a single idp configuration.
class IdpConfig {
  /// OAuth2 client ID.
  core.String? clientId;

  /// Whether this IDP is enabled.
  core.bool? enabled;

  /// Percent of users who will be prompted/redirected federated login for this
  /// IDP.
  core.int? experimentPercent;

  /// OAuth2 provider.
  core.String? provider;

  /// OAuth2 client secret.
  core.String? secret;

  /// Whitelisted client IDs for audience check.
  core.List<core.String>? whitelistedAudiences;

  IdpConfig();

  IdpConfig.fromJson(core.Map _json) {
    if (_json.containsKey('clientId')) {
      clientId = _json['clientId'] as core.String;
    }
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
    if (_json.containsKey('experimentPercent')) {
      experimentPercent = _json['experimentPercent'] as core.int;
    }
    if (_json.containsKey('provider')) {
      provider = _json['provider'] as core.String;
    }
    if (_json.containsKey('secret')) {
      secret = _json['secret'] as core.String;
    }
    if (_json.containsKey('whitelistedAudiences')) {
      whitelistedAudiences = (_json['whitelistedAudiences'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clientId != null) 'clientId': clientId!,
        if (enabled != null) 'enabled': enabled!,
        if (experimentPercent != null) 'experimentPercent': experimentPercent!,
        if (provider != null) 'provider': provider!,
        if (secret != null) 'secret': secret!,
        if (whitelistedAudiences != null)
          'whitelistedAudiences': whitelistedAudiences!,
      };
}

/// Request of getting a code for user confirmation (reset password, change
/// email etc.)
class Relyingparty {
  /// whether or not to install the android app on the device where the link is
  /// opened
  core.bool? androidInstallApp;

  /// minimum version of the app.
  ///
  /// if the version on the device is lower than this version then the user is
  /// taken to the play store to upgrade the app
  core.String? androidMinimumVersion;

  /// android package name of the android app to handle the action code
  core.String? androidPackageName;

  /// whether or not the app can handle the oob code without first going to web
  core.bool? canHandleCodeInApp;

  /// The recaptcha response from the user.
  core.String? captchaResp;

  /// The recaptcha challenge presented to the user.
  core.String? challenge;

  /// The url to continue to the Gitkit app
  core.String? continueUrl;

  /// The email of the user.
  core.String? email;

  /// iOS app store id to download the app if it's not already installed
  core.String? iOSAppStoreId;

  /// the iOS bundle id of iOS app to handle the action code
  core.String? iOSBundleId;

  /// The user's Gitkit login token for email change.
  core.String? idToken;

  /// The fixed string "identitytoolkit#relyingparty".
  core.String? kind;

  /// The new email if the code is for email change.
  core.String? newEmail;

  /// The request type.
  core.String? requestType;

  /// The IP address of the user.
  core.String? userIp;

  Relyingparty();

  Relyingparty.fromJson(core.Map _json) {
    if (_json.containsKey('androidInstallApp')) {
      androidInstallApp = _json['androidInstallApp'] as core.bool;
    }
    if (_json.containsKey('androidMinimumVersion')) {
      androidMinimumVersion = _json['androidMinimumVersion'] as core.String;
    }
    if (_json.containsKey('androidPackageName')) {
      androidPackageName = _json['androidPackageName'] as core.String;
    }
    if (_json.containsKey('canHandleCodeInApp')) {
      canHandleCodeInApp = _json['canHandleCodeInApp'] as core.bool;
    }
    if (_json.containsKey('captchaResp')) {
      captchaResp = _json['captchaResp'] as core.String;
    }
    if (_json.containsKey('challenge')) {
      challenge = _json['challenge'] as core.String;
    }
    if (_json.containsKey('continueUrl')) {
      continueUrl = _json['continueUrl'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('iOSAppStoreId')) {
      iOSAppStoreId = _json['iOSAppStoreId'] as core.String;
    }
    if (_json.containsKey('iOSBundleId')) {
      iOSBundleId = _json['iOSBundleId'] as core.String;
    }
    if (_json.containsKey('idToken')) {
      idToken = _json['idToken'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('newEmail')) {
      newEmail = _json['newEmail'] as core.String;
    }
    if (_json.containsKey('requestType')) {
      requestType = _json['requestType'] as core.String;
    }
    if (_json.containsKey('userIp')) {
      userIp = _json['userIp'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (androidInstallApp != null) 'androidInstallApp': androidInstallApp!,
        if (androidMinimumVersion != null)
          'androidMinimumVersion': androidMinimumVersion!,
        if (androidPackageName != null)
          'androidPackageName': androidPackageName!,
        if (canHandleCodeInApp != null)
          'canHandleCodeInApp': canHandleCodeInApp!,
        if (captchaResp != null) 'captchaResp': captchaResp!,
        if (challenge != null) 'challenge': challenge!,
        if (continueUrl != null) 'continueUrl': continueUrl!,
        if (email != null) 'email': email!,
        if (iOSAppStoreId != null) 'iOSAppStoreId': iOSAppStoreId!,
        if (iOSBundleId != null) 'iOSBundleId': iOSBundleId!,
        if (idToken != null) 'idToken': idToken!,
        if (kind != null) 'kind': kind!,
        if (newEmail != null) 'newEmail': newEmail!,
        if (requestType != null) 'requestType': requestType!,
        if (userIp != null) 'userIp': userIp!,
      };
}

/// Response of resetting the password.
class ResetPasswordResponse {
  /// The user's email.
  ///
  /// If the out-of-band code is for email recovery, the user's original email.
  core.String? email;

  /// The fixed string "identitytoolkit#ResetPasswordResponse".
  core.String? kind;

  /// If the out-of-band code is for email recovery, the user's new email.
  core.String? newEmail;

  /// The request type.
  core.String? requestType;

  ResetPasswordResponse();

  ResetPasswordResponse.fromJson(core.Map _json) {
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('newEmail')) {
      newEmail = _json['newEmail'] as core.String;
    }
    if (_json.containsKey('requestType')) {
      requestType = _json['requestType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (email != null) 'email': email!,
        if (kind != null) 'kind': kind!,
        if (newEmail != null) 'newEmail': newEmail!,
        if (requestType != null) 'requestType': requestType!,
      };
}

class SetAccountInfoResponseProviderUserInfo {
  /// The user's display name at the IDP.
  core.String? displayName;

  /// User's identifier at IDP.
  core.String? federatedId;

  /// The user's photo url at the IDP.
  core.String? photoUrl;

  /// The IdP ID.
  ///
  /// For whitelisted IdPs it's a short domain name, e.g., google.com, aol.com,
  /// live.net and yahoo.com. For other OpenID IdPs it's the OP identifier.
  core.String? providerId;

  SetAccountInfoResponseProviderUserInfo();

  SetAccountInfoResponseProviderUserInfo.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('federatedId')) {
      federatedId = _json['federatedId'] as core.String;
    }
    if (_json.containsKey('photoUrl')) {
      photoUrl = _json['photoUrl'] as core.String;
    }
    if (_json.containsKey('providerId')) {
      providerId = _json['providerId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (federatedId != null) 'federatedId': federatedId!,
        if (photoUrl != null) 'photoUrl': photoUrl!,
        if (providerId != null) 'providerId': providerId!,
      };
}

/// Respone of setting the account information.
class SetAccountInfoResponse {
  /// The name of the user.
  core.String? displayName;

  /// The email of the user.
  core.String? email;

  /// If email has been verified.
  core.bool? emailVerified;

  /// If idToken is STS id token, then this field will be expiration time of STS
  /// id token in seconds.
  core.String? expiresIn;

  /// The Gitkit id token to login the newly sign up user.
  core.String? idToken;

  /// The fixed string "identitytoolkit#SetAccountInfoResponse".
  core.String? kind;

  /// The local ID of the user.
  core.String? localId;

  /// The new email the user attempts to change to.
  core.String? newEmail;

  /// The user's hashed password.
  core.String? passwordHash;
  core.List<core.int> get passwordHashAsBytes =>
      convert.base64.decode(passwordHash!);

  set passwordHashAsBytes(core.List<core.int> _bytes) {
    passwordHash =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The photo url of the user.
  core.String? photoUrl;

  /// The user's profiles at the associated IdPs.
  core.List<SetAccountInfoResponseProviderUserInfo>? providerUserInfo;

  /// If idToken is STS id token, then this field will be refresh token.
  core.String? refreshToken;

  SetAccountInfoResponse();

  SetAccountInfoResponse.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('emailVerified')) {
      emailVerified = _json['emailVerified'] as core.bool;
    }
    if (_json.containsKey('expiresIn')) {
      expiresIn = _json['expiresIn'] as core.String;
    }
    if (_json.containsKey('idToken')) {
      idToken = _json['idToken'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('localId')) {
      localId = _json['localId'] as core.String;
    }
    if (_json.containsKey('newEmail')) {
      newEmail = _json['newEmail'] as core.String;
    }
    if (_json.containsKey('passwordHash')) {
      passwordHash = _json['passwordHash'] as core.String;
    }
    if (_json.containsKey('photoUrl')) {
      photoUrl = _json['photoUrl'] as core.String;
    }
    if (_json.containsKey('providerUserInfo')) {
      providerUserInfo = (_json['providerUserInfo'] as core.List)
          .map<SetAccountInfoResponseProviderUserInfo>((value) =>
              SetAccountInfoResponseProviderUserInfo.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('refreshToken')) {
      refreshToken = _json['refreshToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (email != null) 'email': email!,
        if (emailVerified != null) 'emailVerified': emailVerified!,
        if (expiresIn != null) 'expiresIn': expiresIn!,
        if (idToken != null) 'idToken': idToken!,
        if (kind != null) 'kind': kind!,
        if (localId != null) 'localId': localId!,
        if (newEmail != null) 'newEmail': newEmail!,
        if (passwordHash != null) 'passwordHash': passwordHash!,
        if (photoUrl != null) 'photoUrl': photoUrl!,
        if (providerUserInfo != null)
          'providerUserInfo':
              providerUserInfo!.map((value) => value.toJson()).toList(),
        if (refreshToken != null) 'refreshToken': refreshToken!,
      };
}

/// Response of signing up new user, creating anonymous user or anonymous user
/// reauth.
class SignupNewUserResponse {
  /// The name of the user.
  core.String? displayName;

  /// The email of the user.
  core.String? email;

  /// If idToken is STS id token, then this field will be expiration time of STS
  /// id token in seconds.
  core.String? expiresIn;

  /// The Gitkit id token to login the newly sign up user.
  core.String? idToken;

  /// The fixed string "identitytoolkit#SignupNewUserResponse".
  core.String? kind;

  /// The RP local ID of the user.
  core.String? localId;

  /// If idToken is STS id token, then this field will be refresh token.
  core.String? refreshToken;

  SignupNewUserResponse();

  SignupNewUserResponse.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('expiresIn')) {
      expiresIn = _json['expiresIn'] as core.String;
    }
    if (_json.containsKey('idToken')) {
      idToken = _json['idToken'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('localId')) {
      localId = _json['localId'] as core.String;
    }
    if (_json.containsKey('refreshToken')) {
      refreshToken = _json['refreshToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (email != null) 'email': email!,
        if (expiresIn != null) 'expiresIn': expiresIn!,
        if (idToken != null) 'idToken': idToken!,
        if (kind != null) 'kind': kind!,
        if (localId != null) 'localId': localId!,
        if (refreshToken != null) 'refreshToken': refreshToken!,
      };
}

class UploadAccountResponseError {
  /// The index of the malformed account, starting from 0.
  core.int? index;

  /// Detailed error message for the account info.
  core.String? message;

  UploadAccountResponseError();

  UploadAccountResponseError.fromJson(core.Map _json) {
    if (_json.containsKey('index')) {
      index = _json['index'] as core.int;
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (index != null) 'index': index!,
        if (message != null) 'message': message!,
      };
}

/// Respone of uploading accounts in batch.
class UploadAccountResponse {
  /// The error encountered while processing the account info.
  core.List<UploadAccountResponseError>? error;

  /// The fixed string "identitytoolkit#UploadAccountResponse".
  core.String? kind;

  UploadAccountResponse();

  UploadAccountResponse.fromJson(core.Map _json) {
    if (_json.containsKey('error')) {
      error = (_json['error'] as core.List)
          .map<UploadAccountResponseError>((value) =>
              UploadAccountResponseError.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (error != null)
          'error': error!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

class UserInfoProviderUserInfo {
  /// The user's display name at the IDP.
  core.String? displayName;

  /// User's email at IDP.
  core.String? email;

  /// User's identifier at IDP.
  core.String? federatedId;

  /// User's phone number.
  core.String? phoneNumber;

  /// The user's photo url at the IDP.
  core.String? photoUrl;

  /// The IdP ID.
  ///
  /// For white listed IdPs it's a short domain name, e.g., google.com, aol.com,
  /// live.net and yahoo.com. For other OpenID IdPs it's the OP identifier.
  core.String? providerId;

  /// User's raw identifier directly returned from IDP.
  core.String? rawId;

  /// User's screen name at Twitter or login name at Github.
  core.String? screenName;

  UserInfoProviderUserInfo();

  UserInfoProviderUserInfo.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('federatedId')) {
      federatedId = _json['federatedId'] as core.String;
    }
    if (_json.containsKey('phoneNumber')) {
      phoneNumber = _json['phoneNumber'] as core.String;
    }
    if (_json.containsKey('photoUrl')) {
      photoUrl = _json['photoUrl'] as core.String;
    }
    if (_json.containsKey('providerId')) {
      providerId = _json['providerId'] as core.String;
    }
    if (_json.containsKey('rawId')) {
      rawId = _json['rawId'] as core.String;
    }
    if (_json.containsKey('screenName')) {
      screenName = _json['screenName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (email != null) 'email': email!,
        if (federatedId != null) 'federatedId': federatedId!,
        if (phoneNumber != null) 'phoneNumber': phoneNumber!,
        if (photoUrl != null) 'photoUrl': photoUrl!,
        if (providerId != null) 'providerId': providerId!,
        if (rawId != null) 'rawId': rawId!,
        if (screenName != null) 'screenName': screenName!,
      };
}

/// Template for an individual account info.
class UserInfo {
  /// User creation timestamp.
  core.String? createdAt;

  /// The custom attributes to be set in the user's id token.
  core.String? customAttributes;

  /// Whether the user is authenticated by the developer.
  core.bool? customAuth;

  /// Whether the user is disabled.
  core.bool? disabled;

  /// The name of the user.
  core.String? displayName;

  /// The email of the user.
  core.String? email;

  /// Whether the email has been verified.
  core.bool? emailVerified;

  /// last login timestamp.
  core.String? lastLoginAt;

  /// The local ID of the user.
  core.String? localId;

  /// The user's hashed password.
  core.String? passwordHash;
  core.List<core.int> get passwordHashAsBytes =>
      convert.base64.decode(passwordHash!);

  set passwordHashAsBytes(core.List<core.int> _bytes) {
    passwordHash =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The timestamp when the password was last updated.
  core.double? passwordUpdatedAt;

  /// User's phone number.
  core.String? phoneNumber;

  /// The URL of the user profile photo.
  core.String? photoUrl;

  /// The IDP of the user.
  core.List<UserInfoProviderUserInfo>? providerUserInfo;

  /// The user's plain text password.
  core.String? rawPassword;

  /// The user's password salt.
  core.String? salt;
  core.List<core.int> get saltAsBytes => convert.base64.decode(salt!);

  set saltAsBytes(core.List<core.int> _bytes) {
    salt =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// User's screen name at Twitter or login name at Github.
  core.String? screenName;

  /// Timestamp in seconds for valid login token.
  core.String? validSince;

  /// Version of the user's password.
  core.int? version;

  UserInfo();

  UserInfo.fromJson(core.Map _json) {
    if (_json.containsKey('createdAt')) {
      createdAt = _json['createdAt'] as core.String;
    }
    if (_json.containsKey('customAttributes')) {
      customAttributes = _json['customAttributes'] as core.String;
    }
    if (_json.containsKey('customAuth')) {
      customAuth = _json['customAuth'] as core.bool;
    }
    if (_json.containsKey('disabled')) {
      disabled = _json['disabled'] as core.bool;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('emailVerified')) {
      emailVerified = _json['emailVerified'] as core.bool;
    }
    if (_json.containsKey('lastLoginAt')) {
      lastLoginAt = _json['lastLoginAt'] as core.String;
    }
    if (_json.containsKey('localId')) {
      localId = _json['localId'] as core.String;
    }
    if (_json.containsKey('passwordHash')) {
      passwordHash = _json['passwordHash'] as core.String;
    }
    if (_json.containsKey('passwordUpdatedAt')) {
      passwordUpdatedAt = (_json['passwordUpdatedAt'] as core.num).toDouble();
    }
    if (_json.containsKey('phoneNumber')) {
      phoneNumber = _json['phoneNumber'] as core.String;
    }
    if (_json.containsKey('photoUrl')) {
      photoUrl = _json['photoUrl'] as core.String;
    }
    if (_json.containsKey('providerUserInfo')) {
      providerUserInfo = (_json['providerUserInfo'] as core.List)
          .map<UserInfoProviderUserInfo>((value) =>
              UserInfoProviderUserInfo.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('rawPassword')) {
      rawPassword = _json['rawPassword'] as core.String;
    }
    if (_json.containsKey('salt')) {
      salt = _json['salt'] as core.String;
    }
    if (_json.containsKey('screenName')) {
      screenName = _json['screenName'] as core.String;
    }
    if (_json.containsKey('validSince')) {
      validSince = _json['validSince'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createdAt != null) 'createdAt': createdAt!,
        if (customAttributes != null) 'customAttributes': customAttributes!,
        if (customAuth != null) 'customAuth': customAuth!,
        if (disabled != null) 'disabled': disabled!,
        if (displayName != null) 'displayName': displayName!,
        if (email != null) 'email': email!,
        if (emailVerified != null) 'emailVerified': emailVerified!,
        if (lastLoginAt != null) 'lastLoginAt': lastLoginAt!,
        if (localId != null) 'localId': localId!,
        if (passwordHash != null) 'passwordHash': passwordHash!,
        if (passwordUpdatedAt != null) 'passwordUpdatedAt': passwordUpdatedAt!,
        if (phoneNumber != null) 'phoneNumber': phoneNumber!,
        if (photoUrl != null) 'photoUrl': photoUrl!,
        if (providerUserInfo != null)
          'providerUserInfo':
              providerUserInfo!.map((value) => value.toJson()).toList(),
        if (rawPassword != null) 'rawPassword': rawPassword!,
        if (salt != null) 'salt': salt!,
        if (screenName != null) 'screenName': screenName!,
        if (validSince != null) 'validSince': validSince!,
        if (version != null) 'version': version!,
      };
}

/// Response of verifying the IDP assertion.
class VerifyAssertionResponse {
  /// The action code.
  core.String? action;

  /// URL for OTA app installation.
  core.String? appInstallationUrl;

  /// The custom scheme used by mobile app.
  core.String? appScheme;

  /// The opaque value used by the client to maintain context info between the
  /// authentication request and the IDP callback.
  core.String? context;

  /// The birth date of the IdP account.
  core.String? dateOfBirth;

  /// The display name of the user.
  core.String? displayName;

  /// The email returned by the IdP.
  ///
  /// NOTE: The federated login user may not own the email.
  core.String? email;

  /// It's true if the email is recycled.
  core.bool? emailRecycled;

  /// The value is true if the IDP is also the email provider.
  ///
  /// It means the user owns the email.
  core.bool? emailVerified;

  /// Client error code.
  core.String? errorMessage;

  /// If idToken is STS id token, then this field will be expiration time of STS
  /// id token in seconds.
  core.String? expiresIn;

  /// The unique ID identifies the IdP account.
  core.String? federatedId;

  /// The first name of the user.
  core.String? firstName;

  /// The full name of the user.
  core.String? fullName;

  /// The ID token.
  core.String? idToken;

  /// It's the identifier param in the createAuthUri request if the identifier
  /// is an email.
  ///
  /// It can be used to check whether the user input email is different from the
  /// asserted email.
  core.String? inputEmail;

  /// True if it's a new user sign-in, false if it's a returning user.
  core.bool? isNewUser;

  /// The fixed string "identitytoolkit#VerifyAssertionResponse".
  core.String? kind;

  /// The language preference of the user.
  core.String? language;

  /// The last name of the user.
  core.String? lastName;

  /// The RP local ID if it's already been mapped to the IdP account identified
  /// by the federated ID.
  core.String? localId;

  /// Whether the assertion is from a non-trusted IDP and need account linking
  /// confirmation.
  core.bool? needConfirmation;

  /// Whether need client to supply email to complete the federated login flow.
  core.bool? needEmail;

  /// The nick name of the user.
  core.String? nickName;

  /// The OAuth2 access token.
  core.String? oauthAccessToken;

  /// The OAuth2 authorization code.
  core.String? oauthAuthorizationCode;

  /// The lifetime in seconds of the OAuth2 access token.
  core.int? oauthExpireIn;

  /// The OIDC id token.
  core.String? oauthIdToken;

  /// The user approved request token for the OpenID OAuth extension.
  core.String? oauthRequestToken;

  /// The scope for the OpenID OAuth extension.
  core.String? oauthScope;

  /// The OAuth1 access token secret.
  core.String? oauthTokenSecret;

  /// The original email stored in the mapping storage.
  ///
  /// It's returned when the federated ID is associated to a different email.
  core.String? originalEmail;

  /// The URI of the public accessible profiel picture.
  core.String? photoUrl;

  /// The IdP ID.
  ///
  /// For white listed IdPs it's a short domain name e.g. google.com, aol.com,
  /// live.net and yahoo.com. If the "providerId" param is set to OpenID OP
  /// identifer other than the whilte listed IdPs the OP identifier is returned.
  /// If the "identifier" param is federated ID in the createAuthUri request.
  /// The domain part of the federated ID is returned.
  core.String? providerId;

  /// Raw IDP-returned user info.
  core.String? rawUserInfo;

  /// If idToken is STS id token, then this field will be refresh token.
  core.String? refreshToken;

  /// The screen_name of a Twitter user or the login name at Github.
  core.String? screenName;

  /// The timezone of the user.
  core.String? timeZone;

  /// When action is 'map', contains the idps which can be used for
  /// confirmation.
  core.List<core.String>? verifiedProvider;

  VerifyAssertionResponse();

  VerifyAssertionResponse.fromJson(core.Map _json) {
    if (_json.containsKey('action')) {
      action = _json['action'] as core.String;
    }
    if (_json.containsKey('appInstallationUrl')) {
      appInstallationUrl = _json['appInstallationUrl'] as core.String;
    }
    if (_json.containsKey('appScheme')) {
      appScheme = _json['appScheme'] as core.String;
    }
    if (_json.containsKey('context')) {
      context = _json['context'] as core.String;
    }
    if (_json.containsKey('dateOfBirth')) {
      dateOfBirth = _json['dateOfBirth'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('emailRecycled')) {
      emailRecycled = _json['emailRecycled'] as core.bool;
    }
    if (_json.containsKey('emailVerified')) {
      emailVerified = _json['emailVerified'] as core.bool;
    }
    if (_json.containsKey('errorMessage')) {
      errorMessage = _json['errorMessage'] as core.String;
    }
    if (_json.containsKey('expiresIn')) {
      expiresIn = _json['expiresIn'] as core.String;
    }
    if (_json.containsKey('federatedId')) {
      federatedId = _json['federatedId'] as core.String;
    }
    if (_json.containsKey('firstName')) {
      firstName = _json['firstName'] as core.String;
    }
    if (_json.containsKey('fullName')) {
      fullName = _json['fullName'] as core.String;
    }
    if (_json.containsKey('idToken')) {
      idToken = _json['idToken'] as core.String;
    }
    if (_json.containsKey('inputEmail')) {
      inputEmail = _json['inputEmail'] as core.String;
    }
    if (_json.containsKey('isNewUser')) {
      isNewUser = _json['isNewUser'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('language')) {
      language = _json['language'] as core.String;
    }
    if (_json.containsKey('lastName')) {
      lastName = _json['lastName'] as core.String;
    }
    if (_json.containsKey('localId')) {
      localId = _json['localId'] as core.String;
    }
    if (_json.containsKey('needConfirmation')) {
      needConfirmation = _json['needConfirmation'] as core.bool;
    }
    if (_json.containsKey('needEmail')) {
      needEmail = _json['needEmail'] as core.bool;
    }
    if (_json.containsKey('nickName')) {
      nickName = _json['nickName'] as core.String;
    }
    if (_json.containsKey('oauthAccessToken')) {
      oauthAccessToken = _json['oauthAccessToken'] as core.String;
    }
    if (_json.containsKey('oauthAuthorizationCode')) {
      oauthAuthorizationCode = _json['oauthAuthorizationCode'] as core.String;
    }
    if (_json.containsKey('oauthExpireIn')) {
      oauthExpireIn = _json['oauthExpireIn'] as core.int;
    }
    if (_json.containsKey('oauthIdToken')) {
      oauthIdToken = _json['oauthIdToken'] as core.String;
    }
    if (_json.containsKey('oauthRequestToken')) {
      oauthRequestToken = _json['oauthRequestToken'] as core.String;
    }
    if (_json.containsKey('oauthScope')) {
      oauthScope = _json['oauthScope'] as core.String;
    }
    if (_json.containsKey('oauthTokenSecret')) {
      oauthTokenSecret = _json['oauthTokenSecret'] as core.String;
    }
    if (_json.containsKey('originalEmail')) {
      originalEmail = _json['originalEmail'] as core.String;
    }
    if (_json.containsKey('photoUrl')) {
      photoUrl = _json['photoUrl'] as core.String;
    }
    if (_json.containsKey('providerId')) {
      providerId = _json['providerId'] as core.String;
    }
    if (_json.containsKey('rawUserInfo')) {
      rawUserInfo = _json['rawUserInfo'] as core.String;
    }
    if (_json.containsKey('refreshToken')) {
      refreshToken = _json['refreshToken'] as core.String;
    }
    if (_json.containsKey('screenName')) {
      screenName = _json['screenName'] as core.String;
    }
    if (_json.containsKey('timeZone')) {
      timeZone = _json['timeZone'] as core.String;
    }
    if (_json.containsKey('verifiedProvider')) {
      verifiedProvider = (_json['verifiedProvider'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (action != null) 'action': action!,
        if (appInstallationUrl != null)
          'appInstallationUrl': appInstallationUrl!,
        if (appScheme != null) 'appScheme': appScheme!,
        if (context != null) 'context': context!,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!,
        if (displayName != null) 'displayName': displayName!,
        if (email != null) 'email': email!,
        if (emailRecycled != null) 'emailRecycled': emailRecycled!,
        if (emailVerified != null) 'emailVerified': emailVerified!,
        if (errorMessage != null) 'errorMessage': errorMessage!,
        if (expiresIn != null) 'expiresIn': expiresIn!,
        if (federatedId != null) 'federatedId': federatedId!,
        if (firstName != null) 'firstName': firstName!,
        if (fullName != null) 'fullName': fullName!,
        if (idToken != null) 'idToken': idToken!,
        if (inputEmail != null) 'inputEmail': inputEmail!,
        if (isNewUser != null) 'isNewUser': isNewUser!,
        if (kind != null) 'kind': kind!,
        if (language != null) 'language': language!,
        if (lastName != null) 'lastName': lastName!,
        if (localId != null) 'localId': localId!,
        if (needConfirmation != null) 'needConfirmation': needConfirmation!,
        if (needEmail != null) 'needEmail': needEmail!,
        if (nickName != null) 'nickName': nickName!,
        if (oauthAccessToken != null) 'oauthAccessToken': oauthAccessToken!,
        if (oauthAuthorizationCode != null)
          'oauthAuthorizationCode': oauthAuthorizationCode!,
        if (oauthExpireIn != null) 'oauthExpireIn': oauthExpireIn!,
        if (oauthIdToken != null) 'oauthIdToken': oauthIdToken!,
        if (oauthRequestToken != null) 'oauthRequestToken': oauthRequestToken!,
        if (oauthScope != null) 'oauthScope': oauthScope!,
        if (oauthTokenSecret != null) 'oauthTokenSecret': oauthTokenSecret!,
        if (originalEmail != null) 'originalEmail': originalEmail!,
        if (photoUrl != null) 'photoUrl': photoUrl!,
        if (providerId != null) 'providerId': providerId!,
        if (rawUserInfo != null) 'rawUserInfo': rawUserInfo!,
        if (refreshToken != null) 'refreshToken': refreshToken!,
        if (screenName != null) 'screenName': screenName!,
        if (timeZone != null) 'timeZone': timeZone!,
        if (verifiedProvider != null) 'verifiedProvider': verifiedProvider!,
      };
}

/// Response from verifying a custom token
class VerifyCustomTokenResponse {
  /// If idToken is STS id token, then this field will be expiration time of STS
  /// id token in seconds.
  core.String? expiresIn;

  /// The GITKit token for authenticated user.
  core.String? idToken;

  /// True if it's a new user sign-in, false if it's a returning user.
  core.bool? isNewUser;

  /// The fixed string "identitytoolkit#VerifyCustomTokenResponse".
  core.String? kind;

  /// If idToken is STS id token, then this field will be refresh token.
  core.String? refreshToken;

  VerifyCustomTokenResponse();

  VerifyCustomTokenResponse.fromJson(core.Map _json) {
    if (_json.containsKey('expiresIn')) {
      expiresIn = _json['expiresIn'] as core.String;
    }
    if (_json.containsKey('idToken')) {
      idToken = _json['idToken'] as core.String;
    }
    if (_json.containsKey('isNewUser')) {
      isNewUser = _json['isNewUser'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('refreshToken')) {
      refreshToken = _json['refreshToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (expiresIn != null) 'expiresIn': expiresIn!,
        if (idToken != null) 'idToken': idToken!,
        if (isNewUser != null) 'isNewUser': isNewUser!,
        if (kind != null) 'kind': kind!,
        if (refreshToken != null) 'refreshToken': refreshToken!,
      };
}

/// Request of verifying the password.
class VerifyPasswordResponse {
  /// The name of the user.
  core.String? displayName;

  /// The email returned by the IdP.
  ///
  /// NOTE: The federated login user may not own the email.
  core.String? email;

  /// If idToken is STS id token, then this field will be expiration time of STS
  /// id token in seconds.
  core.String? expiresIn;

  /// The GITKit token for authenticated user.
  core.String? idToken;

  /// The fixed string "identitytoolkit#VerifyPasswordResponse".
  core.String? kind;

  /// The RP local ID if it's already been mapped to the IdP account identified
  /// by the federated ID.
  core.String? localId;

  /// The OAuth2 access token.
  core.String? oauthAccessToken;

  /// The OAuth2 authorization code.
  core.String? oauthAuthorizationCode;

  /// The lifetime in seconds of the OAuth2 access token.
  core.int? oauthExpireIn;

  /// The URI of the user's photo at IdP
  core.String? photoUrl;

  /// If idToken is STS id token, then this field will be refresh token.
  core.String? refreshToken;

  /// Whether the email is registered.
  core.bool? registered;

  VerifyPasswordResponse();

  VerifyPasswordResponse.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('expiresIn')) {
      expiresIn = _json['expiresIn'] as core.String;
    }
    if (_json.containsKey('idToken')) {
      idToken = _json['idToken'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('localId')) {
      localId = _json['localId'] as core.String;
    }
    if (_json.containsKey('oauthAccessToken')) {
      oauthAccessToken = _json['oauthAccessToken'] as core.String;
    }
    if (_json.containsKey('oauthAuthorizationCode')) {
      oauthAuthorizationCode = _json['oauthAuthorizationCode'] as core.String;
    }
    if (_json.containsKey('oauthExpireIn')) {
      oauthExpireIn = _json['oauthExpireIn'] as core.int;
    }
    if (_json.containsKey('photoUrl')) {
      photoUrl = _json['photoUrl'] as core.String;
    }
    if (_json.containsKey('refreshToken')) {
      refreshToken = _json['refreshToken'] as core.String;
    }
    if (_json.containsKey('registered')) {
      registered = _json['registered'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (email != null) 'email': email!,
        if (expiresIn != null) 'expiresIn': expiresIn!,
        if (idToken != null) 'idToken': idToken!,
        if (kind != null) 'kind': kind!,
        if (localId != null) 'localId': localId!,
        if (oauthAccessToken != null) 'oauthAccessToken': oauthAccessToken!,
        if (oauthAuthorizationCode != null)
          'oauthAuthorizationCode': oauthAuthorizationCode!,
        if (oauthExpireIn != null) 'oauthExpireIn': oauthExpireIn!,
        if (photoUrl != null) 'photoUrl': photoUrl!,
        if (refreshToken != null) 'refreshToken': refreshToken!,
        if (registered != null) 'registered': registered!,
      };
}
