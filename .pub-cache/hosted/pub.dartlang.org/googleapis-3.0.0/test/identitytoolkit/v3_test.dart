// ignore_for_file: avoid_returning_null
// ignore_for_file: camel_case_types
// ignore_for_file: cascade_invocations
// ignore_for_file: comment_references
// ignore_for_file: file_names
// ignore_for_file: library_names
// ignore_for_file: lines_longer_than_80_chars
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: prefer_expression_function_bodies
// ignore_for_file: prefer_final_locals
// ignore_for_file: prefer_interpolation_to_compose_strings
// ignore_for_file: prefer_single_quotes
// ignore_for_file: unnecessary_brace_in_string_interps
// ignore_for_file: unnecessary_cast
// ignore_for_file: unnecessary_lambdas
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: unnecessary_string_interpolations
// ignore_for_file: unused_local_variable

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:googleapis/identitytoolkit/v3.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<core.String> buildUnnamed576() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed576(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.List<core.String> buildUnnamed577() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed577(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.int buildCounterCreateAuthUriResponse = 0;
api.CreateAuthUriResponse buildCreateAuthUriResponse() {
  var o = api.CreateAuthUriResponse();
  buildCounterCreateAuthUriResponse++;
  if (buildCounterCreateAuthUriResponse < 3) {
    o.allProviders = buildUnnamed576();
    o.authUri = 'foo';
    o.captchaRequired = true;
    o.forExistingProvider = true;
    o.kind = 'foo';
    o.providerId = 'foo';
    o.registered = true;
    o.sessionId = 'foo';
    o.signinMethods = buildUnnamed577();
  }
  buildCounterCreateAuthUriResponse--;
  return o;
}

void checkCreateAuthUriResponse(api.CreateAuthUriResponse o) {
  buildCounterCreateAuthUriResponse++;
  if (buildCounterCreateAuthUriResponse < 3) {
    checkUnnamed576(o.allProviders!);
    unittest.expect(
      o.authUri!,
      unittest.equals('foo'),
    );
    unittest.expect(o.captchaRequired!, unittest.isTrue);
    unittest.expect(o.forExistingProvider!, unittest.isTrue);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.providerId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.registered!, unittest.isTrue);
    unittest.expect(
      o.sessionId!,
      unittest.equals('foo'),
    );
    checkUnnamed577(o.signinMethods!);
  }
  buildCounterCreateAuthUriResponse--;
}

core.int buildCounterDeleteAccountResponse = 0;
api.DeleteAccountResponse buildDeleteAccountResponse() {
  var o = api.DeleteAccountResponse();
  buildCounterDeleteAccountResponse++;
  if (buildCounterDeleteAccountResponse < 3) {
    o.kind = 'foo';
  }
  buildCounterDeleteAccountResponse--;
  return o;
}

void checkDeleteAccountResponse(api.DeleteAccountResponse o) {
  buildCounterDeleteAccountResponse++;
  if (buildCounterDeleteAccountResponse < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeleteAccountResponse--;
}

core.List<api.UserInfo> buildUnnamed578() {
  var o = <api.UserInfo>[];
  o.add(buildUserInfo());
  o.add(buildUserInfo());
  return o;
}

void checkUnnamed578(core.List<api.UserInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUserInfo(o[0] as api.UserInfo);
  checkUserInfo(o[1] as api.UserInfo);
}

core.int buildCounterDownloadAccountResponse = 0;
api.DownloadAccountResponse buildDownloadAccountResponse() {
  var o = api.DownloadAccountResponse();
  buildCounterDownloadAccountResponse++;
  if (buildCounterDownloadAccountResponse < 3) {
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.users = buildUnnamed578();
  }
  buildCounterDownloadAccountResponse--;
  return o;
}

void checkDownloadAccountResponse(api.DownloadAccountResponse o) {
  buildCounterDownloadAccountResponse++;
  if (buildCounterDownloadAccountResponse < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed578(o.users!);
  }
  buildCounterDownloadAccountResponse--;
}

core.int buildCounterEmailLinkSigninResponse = 0;
api.EmailLinkSigninResponse buildEmailLinkSigninResponse() {
  var o = api.EmailLinkSigninResponse();
  buildCounterEmailLinkSigninResponse++;
  if (buildCounterEmailLinkSigninResponse < 3) {
    o.email = 'foo';
    o.expiresIn = 'foo';
    o.idToken = 'foo';
    o.isNewUser = true;
    o.kind = 'foo';
    o.localId = 'foo';
    o.refreshToken = 'foo';
  }
  buildCounterEmailLinkSigninResponse--;
  return o;
}

void checkEmailLinkSigninResponse(api.EmailLinkSigninResponse o) {
  buildCounterEmailLinkSigninResponse++;
  if (buildCounterEmailLinkSigninResponse < 3) {
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expiresIn!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.idToken!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isNewUser!, unittest.isTrue);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.localId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.refreshToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterEmailLinkSigninResponse--;
}

core.int buildCounterEmailTemplate = 0;
api.EmailTemplate buildEmailTemplate() {
  var o = api.EmailTemplate();
  buildCounterEmailTemplate++;
  if (buildCounterEmailTemplate < 3) {
    o.body = 'foo';
    o.format = 'foo';
    o.from = 'foo';
    o.fromDisplayName = 'foo';
    o.replyTo = 'foo';
    o.subject = 'foo';
  }
  buildCounterEmailTemplate--;
  return o;
}

void checkEmailTemplate(api.EmailTemplate o) {
  buildCounterEmailTemplate++;
  if (buildCounterEmailTemplate < 3) {
    unittest.expect(
      o.body!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.format!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.from!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fromDisplayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.replyTo!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.subject!,
      unittest.equals('foo'),
    );
  }
  buildCounterEmailTemplate--;
}

core.List<api.UserInfo> buildUnnamed579() {
  var o = <api.UserInfo>[];
  o.add(buildUserInfo());
  o.add(buildUserInfo());
  return o;
}

void checkUnnamed579(core.List<api.UserInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUserInfo(o[0] as api.UserInfo);
  checkUserInfo(o[1] as api.UserInfo);
}

core.int buildCounterGetAccountInfoResponse = 0;
api.GetAccountInfoResponse buildGetAccountInfoResponse() {
  var o = api.GetAccountInfoResponse();
  buildCounterGetAccountInfoResponse++;
  if (buildCounterGetAccountInfoResponse < 3) {
    o.kind = 'foo';
    o.users = buildUnnamed579();
  }
  buildCounterGetAccountInfoResponse--;
  return o;
}

void checkGetAccountInfoResponse(api.GetAccountInfoResponse o) {
  buildCounterGetAccountInfoResponse++;
  if (buildCounterGetAccountInfoResponse < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed579(o.users!);
  }
  buildCounterGetAccountInfoResponse--;
}

core.int buildCounterGetOobConfirmationCodeResponse = 0;
api.GetOobConfirmationCodeResponse buildGetOobConfirmationCodeResponse() {
  var o = api.GetOobConfirmationCodeResponse();
  buildCounterGetOobConfirmationCodeResponse++;
  if (buildCounterGetOobConfirmationCodeResponse < 3) {
    o.email = 'foo';
    o.kind = 'foo';
    o.oobCode = 'foo';
  }
  buildCounterGetOobConfirmationCodeResponse--;
  return o;
}

void checkGetOobConfirmationCodeResponse(api.GetOobConfirmationCodeResponse o) {
  buildCounterGetOobConfirmationCodeResponse++;
  if (buildCounterGetOobConfirmationCodeResponse < 3) {
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.oobCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterGetOobConfirmationCodeResponse--;
}

core.int buildCounterGetRecaptchaParamResponse = 0;
api.GetRecaptchaParamResponse buildGetRecaptchaParamResponse() {
  var o = api.GetRecaptchaParamResponse();
  buildCounterGetRecaptchaParamResponse++;
  if (buildCounterGetRecaptchaParamResponse < 3) {
    o.kind = 'foo';
    o.recaptchaSiteKey = 'foo';
    o.recaptchaStoken = 'foo';
  }
  buildCounterGetRecaptchaParamResponse--;
  return o;
}

void checkGetRecaptchaParamResponse(api.GetRecaptchaParamResponse o) {
  buildCounterGetRecaptchaParamResponse++;
  if (buildCounterGetRecaptchaParamResponse < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.recaptchaSiteKey!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.recaptchaStoken!,
      unittest.equals('foo'),
    );
  }
  buildCounterGetRecaptchaParamResponse--;
}

core.Map<core.String, core.String> buildUnnamed580() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed580(core.Map<core.String, core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o['x']!,
    unittest.equals('foo'),
  );
  unittest.expect(
    o['y']!,
    unittest.equals('foo'),
  );
}

core.int buildCounterIdentitytoolkitRelyingpartyCreateAuthUriRequest = 0;
api.IdentitytoolkitRelyingpartyCreateAuthUriRequest
    buildIdentitytoolkitRelyingpartyCreateAuthUriRequest() {
  var o = api.IdentitytoolkitRelyingpartyCreateAuthUriRequest();
  buildCounterIdentitytoolkitRelyingpartyCreateAuthUriRequest++;
  if (buildCounterIdentitytoolkitRelyingpartyCreateAuthUriRequest < 3) {
    o.appId = 'foo';
    o.authFlowType = 'foo';
    o.clientId = 'foo';
    o.context = 'foo';
    o.continueUri = 'foo';
    o.customParameter = buildUnnamed580();
    o.hostedDomain = 'foo';
    o.identifier = 'foo';
    o.oauthConsumerKey = 'foo';
    o.oauthScope = 'foo';
    o.openidRealm = 'foo';
    o.otaApp = 'foo';
    o.providerId = 'foo';
    o.sessionId = 'foo';
    o.tenantId = 'foo';
    o.tenantProjectNumber = 'foo';
  }
  buildCounterIdentitytoolkitRelyingpartyCreateAuthUriRequest--;
  return o;
}

void checkIdentitytoolkitRelyingpartyCreateAuthUriRequest(
    api.IdentitytoolkitRelyingpartyCreateAuthUriRequest o) {
  buildCounterIdentitytoolkitRelyingpartyCreateAuthUriRequest++;
  if (buildCounterIdentitytoolkitRelyingpartyCreateAuthUriRequest < 3) {
    unittest.expect(
      o.appId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.authFlowType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.clientId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.context!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.continueUri!,
      unittest.equals('foo'),
    );
    checkUnnamed580(o.customParameter!);
    unittest.expect(
      o.hostedDomain!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.identifier!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.oauthConsumerKey!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.oauthScope!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.openidRealm!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.otaApp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.providerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sessionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tenantId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tenantProjectNumber!,
      unittest.equals('foo'),
    );
  }
  buildCounterIdentitytoolkitRelyingpartyCreateAuthUriRequest--;
}

core.int buildCounterIdentitytoolkitRelyingpartyDeleteAccountRequest = 0;
api.IdentitytoolkitRelyingpartyDeleteAccountRequest
    buildIdentitytoolkitRelyingpartyDeleteAccountRequest() {
  var o = api.IdentitytoolkitRelyingpartyDeleteAccountRequest();
  buildCounterIdentitytoolkitRelyingpartyDeleteAccountRequest++;
  if (buildCounterIdentitytoolkitRelyingpartyDeleteAccountRequest < 3) {
    o.delegatedProjectNumber = 'foo';
    o.idToken = 'foo';
    o.localId = 'foo';
  }
  buildCounterIdentitytoolkitRelyingpartyDeleteAccountRequest--;
  return o;
}

void checkIdentitytoolkitRelyingpartyDeleteAccountRequest(
    api.IdentitytoolkitRelyingpartyDeleteAccountRequest o) {
  buildCounterIdentitytoolkitRelyingpartyDeleteAccountRequest++;
  if (buildCounterIdentitytoolkitRelyingpartyDeleteAccountRequest < 3) {
    unittest.expect(
      o.delegatedProjectNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.idToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.localId!,
      unittest.equals('foo'),
    );
  }
  buildCounterIdentitytoolkitRelyingpartyDeleteAccountRequest--;
}

core.int buildCounterIdentitytoolkitRelyingpartyDownloadAccountRequest = 0;
api.IdentitytoolkitRelyingpartyDownloadAccountRequest
    buildIdentitytoolkitRelyingpartyDownloadAccountRequest() {
  var o = api.IdentitytoolkitRelyingpartyDownloadAccountRequest();
  buildCounterIdentitytoolkitRelyingpartyDownloadAccountRequest++;
  if (buildCounterIdentitytoolkitRelyingpartyDownloadAccountRequest < 3) {
    o.delegatedProjectNumber = 'foo';
    o.maxResults = 42;
    o.nextPageToken = 'foo';
    o.targetProjectId = 'foo';
  }
  buildCounterIdentitytoolkitRelyingpartyDownloadAccountRequest--;
  return o;
}

void checkIdentitytoolkitRelyingpartyDownloadAccountRequest(
    api.IdentitytoolkitRelyingpartyDownloadAccountRequest o) {
  buildCounterIdentitytoolkitRelyingpartyDownloadAccountRequest++;
  if (buildCounterIdentitytoolkitRelyingpartyDownloadAccountRequest < 3) {
    unittest.expect(
      o.delegatedProjectNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxResults!,
      unittest.equals(42),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetProjectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterIdentitytoolkitRelyingpartyDownloadAccountRequest--;
}

core.int buildCounterIdentitytoolkitRelyingpartyEmailLinkSigninRequest = 0;
api.IdentitytoolkitRelyingpartyEmailLinkSigninRequest
    buildIdentitytoolkitRelyingpartyEmailLinkSigninRequest() {
  var o = api.IdentitytoolkitRelyingpartyEmailLinkSigninRequest();
  buildCounterIdentitytoolkitRelyingpartyEmailLinkSigninRequest++;
  if (buildCounterIdentitytoolkitRelyingpartyEmailLinkSigninRequest < 3) {
    o.email = 'foo';
    o.idToken = 'foo';
    o.oobCode = 'foo';
  }
  buildCounterIdentitytoolkitRelyingpartyEmailLinkSigninRequest--;
  return o;
}

void checkIdentitytoolkitRelyingpartyEmailLinkSigninRequest(
    api.IdentitytoolkitRelyingpartyEmailLinkSigninRequest o) {
  buildCounterIdentitytoolkitRelyingpartyEmailLinkSigninRequest++;
  if (buildCounterIdentitytoolkitRelyingpartyEmailLinkSigninRequest < 3) {
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.idToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.oobCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterIdentitytoolkitRelyingpartyEmailLinkSigninRequest--;
}

core.List<core.String> buildUnnamed581() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed581(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.List<core.String> buildUnnamed582() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed582(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.List<core.String> buildUnnamed583() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed583(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.int buildCounterIdentitytoolkitRelyingpartyGetAccountInfoRequest = 0;
api.IdentitytoolkitRelyingpartyGetAccountInfoRequest
    buildIdentitytoolkitRelyingpartyGetAccountInfoRequest() {
  var o = api.IdentitytoolkitRelyingpartyGetAccountInfoRequest();
  buildCounterIdentitytoolkitRelyingpartyGetAccountInfoRequest++;
  if (buildCounterIdentitytoolkitRelyingpartyGetAccountInfoRequest < 3) {
    o.delegatedProjectNumber = 'foo';
    o.email = buildUnnamed581();
    o.idToken = 'foo';
    o.localId = buildUnnamed582();
    o.phoneNumber = buildUnnamed583();
  }
  buildCounterIdentitytoolkitRelyingpartyGetAccountInfoRequest--;
  return o;
}

void checkIdentitytoolkitRelyingpartyGetAccountInfoRequest(
    api.IdentitytoolkitRelyingpartyGetAccountInfoRequest o) {
  buildCounterIdentitytoolkitRelyingpartyGetAccountInfoRequest++;
  if (buildCounterIdentitytoolkitRelyingpartyGetAccountInfoRequest < 3) {
    unittest.expect(
      o.delegatedProjectNumber!,
      unittest.equals('foo'),
    );
    checkUnnamed581(o.email!);
    unittest.expect(
      o.idToken!,
      unittest.equals('foo'),
    );
    checkUnnamed582(o.localId!);
    checkUnnamed583(o.phoneNumber!);
  }
  buildCounterIdentitytoolkitRelyingpartyGetAccountInfoRequest--;
}

core.List<core.String> buildUnnamed584() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed584(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.List<api.IdpConfig> buildUnnamed585() {
  var o = <api.IdpConfig>[];
  o.add(buildIdpConfig());
  o.add(buildIdpConfig());
  return o;
}

void checkUnnamed585(core.List<api.IdpConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkIdpConfig(o[0] as api.IdpConfig);
  checkIdpConfig(o[1] as api.IdpConfig);
}

core.int buildCounterIdentitytoolkitRelyingpartyGetProjectConfigResponse = 0;
api.IdentitytoolkitRelyingpartyGetProjectConfigResponse
    buildIdentitytoolkitRelyingpartyGetProjectConfigResponse() {
  var o = api.IdentitytoolkitRelyingpartyGetProjectConfigResponse();
  buildCounterIdentitytoolkitRelyingpartyGetProjectConfigResponse++;
  if (buildCounterIdentitytoolkitRelyingpartyGetProjectConfigResponse < 3) {
    o.allowPasswordUser = true;
    o.apiKey = 'foo';
    o.authorizedDomains = buildUnnamed584();
    o.changeEmailTemplate = buildEmailTemplate();
    o.dynamicLinksDomain = 'foo';
    o.enableAnonymousUser = true;
    o.idpConfig = buildUnnamed585();
    o.legacyResetPasswordTemplate = buildEmailTemplate();
    o.projectId = 'foo';
    o.resetPasswordTemplate = buildEmailTemplate();
    o.useEmailSending = true;
    o.verifyEmailTemplate = buildEmailTemplate();
  }
  buildCounterIdentitytoolkitRelyingpartyGetProjectConfigResponse--;
  return o;
}

void checkIdentitytoolkitRelyingpartyGetProjectConfigResponse(
    api.IdentitytoolkitRelyingpartyGetProjectConfigResponse o) {
  buildCounterIdentitytoolkitRelyingpartyGetProjectConfigResponse++;
  if (buildCounterIdentitytoolkitRelyingpartyGetProjectConfigResponse < 3) {
    unittest.expect(o.allowPasswordUser!, unittest.isTrue);
    unittest.expect(
      o.apiKey!,
      unittest.equals('foo'),
    );
    checkUnnamed584(o.authorizedDomains!);
    checkEmailTemplate(o.changeEmailTemplate! as api.EmailTemplate);
    unittest.expect(
      o.dynamicLinksDomain!,
      unittest.equals('foo'),
    );
    unittest.expect(o.enableAnonymousUser!, unittest.isTrue);
    checkUnnamed585(o.idpConfig!);
    checkEmailTemplate(o.legacyResetPasswordTemplate! as api.EmailTemplate);
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
    checkEmailTemplate(o.resetPasswordTemplate! as api.EmailTemplate);
    unittest.expect(o.useEmailSending!, unittest.isTrue);
    checkEmailTemplate(o.verifyEmailTemplate! as api.EmailTemplate);
  }
  buildCounterIdentitytoolkitRelyingpartyGetProjectConfigResponse--;
}

api.IdentitytoolkitRelyingpartyGetPublicKeysResponse
    buildIdentitytoolkitRelyingpartyGetPublicKeysResponse() {
  var o = api.IdentitytoolkitRelyingpartyGetPublicKeysResponse();
  o["a"] = 'foo';
  o["b"] = 'foo';
  return o;
}

void checkIdentitytoolkitRelyingpartyGetPublicKeysResponse(
    api.IdentitytoolkitRelyingpartyGetPublicKeysResponse o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o["a"]!,
    unittest.equals('foo'),
  );
  unittest.expect(
    o["b"]!,
    unittest.equals('foo'),
  );
}

core.int buildCounterIdentitytoolkitRelyingpartyResetPasswordRequest = 0;
api.IdentitytoolkitRelyingpartyResetPasswordRequest
    buildIdentitytoolkitRelyingpartyResetPasswordRequest() {
  var o = api.IdentitytoolkitRelyingpartyResetPasswordRequest();
  buildCounterIdentitytoolkitRelyingpartyResetPasswordRequest++;
  if (buildCounterIdentitytoolkitRelyingpartyResetPasswordRequest < 3) {
    o.email = 'foo';
    o.newPassword = 'foo';
    o.oldPassword = 'foo';
    o.oobCode = 'foo';
  }
  buildCounterIdentitytoolkitRelyingpartyResetPasswordRequest--;
  return o;
}

void checkIdentitytoolkitRelyingpartyResetPasswordRequest(
    api.IdentitytoolkitRelyingpartyResetPasswordRequest o) {
  buildCounterIdentitytoolkitRelyingpartyResetPasswordRequest++;
  if (buildCounterIdentitytoolkitRelyingpartyResetPasswordRequest < 3) {
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.newPassword!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.oldPassword!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.oobCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterIdentitytoolkitRelyingpartyResetPasswordRequest--;
}

core.int buildCounterIdentitytoolkitRelyingpartySendVerificationCodeRequest = 0;
api.IdentitytoolkitRelyingpartySendVerificationCodeRequest
    buildIdentitytoolkitRelyingpartySendVerificationCodeRequest() {
  var o = api.IdentitytoolkitRelyingpartySendVerificationCodeRequest();
  buildCounterIdentitytoolkitRelyingpartySendVerificationCodeRequest++;
  if (buildCounterIdentitytoolkitRelyingpartySendVerificationCodeRequest < 3) {
    o.iosReceipt = 'foo';
    o.iosSecret = 'foo';
    o.phoneNumber = 'foo';
    o.recaptchaToken = 'foo';
  }
  buildCounterIdentitytoolkitRelyingpartySendVerificationCodeRequest--;
  return o;
}

void checkIdentitytoolkitRelyingpartySendVerificationCodeRequest(
    api.IdentitytoolkitRelyingpartySendVerificationCodeRequest o) {
  buildCounterIdentitytoolkitRelyingpartySendVerificationCodeRequest++;
  if (buildCounterIdentitytoolkitRelyingpartySendVerificationCodeRequest < 3) {
    unittest.expect(
      o.iosReceipt!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.iosSecret!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.phoneNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.recaptchaToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterIdentitytoolkitRelyingpartySendVerificationCodeRequest--;
}

core.int buildCounterIdentitytoolkitRelyingpartySendVerificationCodeResponse =
    0;
api.IdentitytoolkitRelyingpartySendVerificationCodeResponse
    buildIdentitytoolkitRelyingpartySendVerificationCodeResponse() {
  var o = api.IdentitytoolkitRelyingpartySendVerificationCodeResponse();
  buildCounterIdentitytoolkitRelyingpartySendVerificationCodeResponse++;
  if (buildCounterIdentitytoolkitRelyingpartySendVerificationCodeResponse < 3) {
    o.sessionInfo = 'foo';
  }
  buildCounterIdentitytoolkitRelyingpartySendVerificationCodeResponse--;
  return o;
}

void checkIdentitytoolkitRelyingpartySendVerificationCodeResponse(
    api.IdentitytoolkitRelyingpartySendVerificationCodeResponse o) {
  buildCounterIdentitytoolkitRelyingpartySendVerificationCodeResponse++;
  if (buildCounterIdentitytoolkitRelyingpartySendVerificationCodeResponse < 3) {
    unittest.expect(
      o.sessionInfo!,
      unittest.equals('foo'),
    );
  }
  buildCounterIdentitytoolkitRelyingpartySendVerificationCodeResponse--;
}

core.List<core.String> buildUnnamed586() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed586(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.List<core.String> buildUnnamed587() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed587(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.List<core.String> buildUnnamed588() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed588(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.int buildCounterIdentitytoolkitRelyingpartySetAccountInfoRequest = 0;
api.IdentitytoolkitRelyingpartySetAccountInfoRequest
    buildIdentitytoolkitRelyingpartySetAccountInfoRequest() {
  var o = api.IdentitytoolkitRelyingpartySetAccountInfoRequest();
  buildCounterIdentitytoolkitRelyingpartySetAccountInfoRequest++;
  if (buildCounterIdentitytoolkitRelyingpartySetAccountInfoRequest < 3) {
    o.captchaChallenge = 'foo';
    o.captchaResponse = 'foo';
    o.createdAt = 'foo';
    o.customAttributes = 'foo';
    o.delegatedProjectNumber = 'foo';
    o.deleteAttribute = buildUnnamed586();
    o.deleteProvider = buildUnnamed587();
    o.disableUser = true;
    o.displayName = 'foo';
    o.email = 'foo';
    o.emailVerified = true;
    o.idToken = 'foo';
    o.instanceId = 'foo';
    o.lastLoginAt = 'foo';
    o.localId = 'foo';
    o.oobCode = 'foo';
    o.password = 'foo';
    o.phoneNumber = 'foo';
    o.photoUrl = 'foo';
    o.provider = buildUnnamed588();
    o.returnSecureToken = true;
    o.upgradeToFederatedLogin = true;
    o.validSince = 'foo';
  }
  buildCounterIdentitytoolkitRelyingpartySetAccountInfoRequest--;
  return o;
}

void checkIdentitytoolkitRelyingpartySetAccountInfoRequest(
    api.IdentitytoolkitRelyingpartySetAccountInfoRequest o) {
  buildCounterIdentitytoolkitRelyingpartySetAccountInfoRequest++;
  if (buildCounterIdentitytoolkitRelyingpartySetAccountInfoRequest < 3) {
    unittest.expect(
      o.captchaChallenge!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.captchaResponse!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.createdAt!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.customAttributes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.delegatedProjectNumber!,
      unittest.equals('foo'),
    );
    checkUnnamed586(o.deleteAttribute!);
    checkUnnamed587(o.deleteProvider!);
    unittest.expect(o.disableUser!, unittest.isTrue);
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(o.emailVerified!, unittest.isTrue);
    unittest.expect(
      o.idToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.instanceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lastLoginAt!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.localId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.oobCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.password!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.phoneNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.photoUrl!,
      unittest.equals('foo'),
    );
    checkUnnamed588(o.provider!);
    unittest.expect(o.returnSecureToken!, unittest.isTrue);
    unittest.expect(o.upgradeToFederatedLogin!, unittest.isTrue);
    unittest.expect(
      o.validSince!,
      unittest.equals('foo'),
    );
  }
  buildCounterIdentitytoolkitRelyingpartySetAccountInfoRequest--;
}

core.List<core.String> buildUnnamed589() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed589(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.List<api.IdpConfig> buildUnnamed590() {
  var o = <api.IdpConfig>[];
  o.add(buildIdpConfig());
  o.add(buildIdpConfig());
  return o;
}

void checkUnnamed590(core.List<api.IdpConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkIdpConfig(o[0] as api.IdpConfig);
  checkIdpConfig(o[1] as api.IdpConfig);
}

core.int buildCounterIdentitytoolkitRelyingpartySetProjectConfigRequest = 0;
api.IdentitytoolkitRelyingpartySetProjectConfigRequest
    buildIdentitytoolkitRelyingpartySetProjectConfigRequest() {
  var o = api.IdentitytoolkitRelyingpartySetProjectConfigRequest();
  buildCounterIdentitytoolkitRelyingpartySetProjectConfigRequest++;
  if (buildCounterIdentitytoolkitRelyingpartySetProjectConfigRequest < 3) {
    o.allowPasswordUser = true;
    o.apiKey = 'foo';
    o.authorizedDomains = buildUnnamed589();
    o.changeEmailTemplate = buildEmailTemplate();
    o.delegatedProjectNumber = 'foo';
    o.enableAnonymousUser = true;
    o.idpConfig = buildUnnamed590();
    o.legacyResetPasswordTemplate = buildEmailTemplate();
    o.resetPasswordTemplate = buildEmailTemplate();
    o.useEmailSending = true;
    o.verifyEmailTemplate = buildEmailTemplate();
  }
  buildCounterIdentitytoolkitRelyingpartySetProjectConfigRequest--;
  return o;
}

void checkIdentitytoolkitRelyingpartySetProjectConfigRequest(
    api.IdentitytoolkitRelyingpartySetProjectConfigRequest o) {
  buildCounterIdentitytoolkitRelyingpartySetProjectConfigRequest++;
  if (buildCounterIdentitytoolkitRelyingpartySetProjectConfigRequest < 3) {
    unittest.expect(o.allowPasswordUser!, unittest.isTrue);
    unittest.expect(
      o.apiKey!,
      unittest.equals('foo'),
    );
    checkUnnamed589(o.authorizedDomains!);
    checkEmailTemplate(o.changeEmailTemplate! as api.EmailTemplate);
    unittest.expect(
      o.delegatedProjectNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(o.enableAnonymousUser!, unittest.isTrue);
    checkUnnamed590(o.idpConfig!);
    checkEmailTemplate(o.legacyResetPasswordTemplate! as api.EmailTemplate);
    checkEmailTemplate(o.resetPasswordTemplate! as api.EmailTemplate);
    unittest.expect(o.useEmailSending!, unittest.isTrue);
    checkEmailTemplate(o.verifyEmailTemplate! as api.EmailTemplate);
  }
  buildCounterIdentitytoolkitRelyingpartySetProjectConfigRequest--;
}

core.int buildCounterIdentitytoolkitRelyingpartySetProjectConfigResponse = 0;
api.IdentitytoolkitRelyingpartySetProjectConfigResponse
    buildIdentitytoolkitRelyingpartySetProjectConfigResponse() {
  var o = api.IdentitytoolkitRelyingpartySetProjectConfigResponse();
  buildCounterIdentitytoolkitRelyingpartySetProjectConfigResponse++;
  if (buildCounterIdentitytoolkitRelyingpartySetProjectConfigResponse < 3) {
    o.projectId = 'foo';
  }
  buildCounterIdentitytoolkitRelyingpartySetProjectConfigResponse--;
  return o;
}

void checkIdentitytoolkitRelyingpartySetProjectConfigResponse(
    api.IdentitytoolkitRelyingpartySetProjectConfigResponse o) {
  buildCounterIdentitytoolkitRelyingpartySetProjectConfigResponse++;
  if (buildCounterIdentitytoolkitRelyingpartySetProjectConfigResponse < 3) {
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterIdentitytoolkitRelyingpartySetProjectConfigResponse--;
}

core.int buildCounterIdentitytoolkitRelyingpartySignOutUserRequest = 0;
api.IdentitytoolkitRelyingpartySignOutUserRequest
    buildIdentitytoolkitRelyingpartySignOutUserRequest() {
  var o = api.IdentitytoolkitRelyingpartySignOutUserRequest();
  buildCounterIdentitytoolkitRelyingpartySignOutUserRequest++;
  if (buildCounterIdentitytoolkitRelyingpartySignOutUserRequest < 3) {
    o.instanceId = 'foo';
    o.localId = 'foo';
  }
  buildCounterIdentitytoolkitRelyingpartySignOutUserRequest--;
  return o;
}

void checkIdentitytoolkitRelyingpartySignOutUserRequest(
    api.IdentitytoolkitRelyingpartySignOutUserRequest o) {
  buildCounterIdentitytoolkitRelyingpartySignOutUserRequest++;
  if (buildCounterIdentitytoolkitRelyingpartySignOutUserRequest < 3) {
    unittest.expect(
      o.instanceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.localId!,
      unittest.equals('foo'),
    );
  }
  buildCounterIdentitytoolkitRelyingpartySignOutUserRequest--;
}

core.int buildCounterIdentitytoolkitRelyingpartySignOutUserResponse = 0;
api.IdentitytoolkitRelyingpartySignOutUserResponse
    buildIdentitytoolkitRelyingpartySignOutUserResponse() {
  var o = api.IdentitytoolkitRelyingpartySignOutUserResponse();
  buildCounterIdentitytoolkitRelyingpartySignOutUserResponse++;
  if (buildCounterIdentitytoolkitRelyingpartySignOutUserResponse < 3) {
    o.localId = 'foo';
  }
  buildCounterIdentitytoolkitRelyingpartySignOutUserResponse--;
  return o;
}

void checkIdentitytoolkitRelyingpartySignOutUserResponse(
    api.IdentitytoolkitRelyingpartySignOutUserResponse o) {
  buildCounterIdentitytoolkitRelyingpartySignOutUserResponse++;
  if (buildCounterIdentitytoolkitRelyingpartySignOutUserResponse < 3) {
    unittest.expect(
      o.localId!,
      unittest.equals('foo'),
    );
  }
  buildCounterIdentitytoolkitRelyingpartySignOutUserResponse--;
}

core.int buildCounterIdentitytoolkitRelyingpartySignupNewUserRequest = 0;
api.IdentitytoolkitRelyingpartySignupNewUserRequest
    buildIdentitytoolkitRelyingpartySignupNewUserRequest() {
  var o = api.IdentitytoolkitRelyingpartySignupNewUserRequest();
  buildCounterIdentitytoolkitRelyingpartySignupNewUserRequest++;
  if (buildCounterIdentitytoolkitRelyingpartySignupNewUserRequest < 3) {
    o.captchaChallenge = 'foo';
    o.captchaResponse = 'foo';
    o.disabled = true;
    o.displayName = 'foo';
    o.email = 'foo';
    o.emailVerified = true;
    o.idToken = 'foo';
    o.instanceId = 'foo';
    o.localId = 'foo';
    o.password = 'foo';
    o.phoneNumber = 'foo';
    o.photoUrl = 'foo';
    o.tenantId = 'foo';
    o.tenantProjectNumber = 'foo';
  }
  buildCounterIdentitytoolkitRelyingpartySignupNewUserRequest--;
  return o;
}

void checkIdentitytoolkitRelyingpartySignupNewUserRequest(
    api.IdentitytoolkitRelyingpartySignupNewUserRequest o) {
  buildCounterIdentitytoolkitRelyingpartySignupNewUserRequest++;
  if (buildCounterIdentitytoolkitRelyingpartySignupNewUserRequest < 3) {
    unittest.expect(
      o.captchaChallenge!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.captchaResponse!,
      unittest.equals('foo'),
    );
    unittest.expect(o.disabled!, unittest.isTrue);
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(o.emailVerified!, unittest.isTrue);
    unittest.expect(
      o.idToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.instanceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.localId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.password!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.phoneNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.photoUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tenantId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tenantProjectNumber!,
      unittest.equals('foo'),
    );
  }
  buildCounterIdentitytoolkitRelyingpartySignupNewUserRequest--;
}

core.List<api.UserInfo> buildUnnamed591() {
  var o = <api.UserInfo>[];
  o.add(buildUserInfo());
  o.add(buildUserInfo());
  return o;
}

void checkUnnamed591(core.List<api.UserInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUserInfo(o[0] as api.UserInfo);
  checkUserInfo(o[1] as api.UserInfo);
}

core.int buildCounterIdentitytoolkitRelyingpartyUploadAccountRequest = 0;
api.IdentitytoolkitRelyingpartyUploadAccountRequest
    buildIdentitytoolkitRelyingpartyUploadAccountRequest() {
  var o = api.IdentitytoolkitRelyingpartyUploadAccountRequest();
  buildCounterIdentitytoolkitRelyingpartyUploadAccountRequest++;
  if (buildCounterIdentitytoolkitRelyingpartyUploadAccountRequest < 3) {
    o.allowOverwrite = true;
    o.blockSize = 42;
    o.cpuMemCost = 42;
    o.delegatedProjectNumber = 'foo';
    o.dkLen = 42;
    o.hashAlgorithm = 'foo';
    o.memoryCost = 42;
    o.parallelization = 42;
    o.rounds = 42;
    o.saltSeparator = 'foo';
    o.sanityCheck = true;
    o.signerKey = 'foo';
    o.targetProjectId = 'foo';
    o.users = buildUnnamed591();
  }
  buildCounterIdentitytoolkitRelyingpartyUploadAccountRequest--;
  return o;
}

void checkIdentitytoolkitRelyingpartyUploadAccountRequest(
    api.IdentitytoolkitRelyingpartyUploadAccountRequest o) {
  buildCounterIdentitytoolkitRelyingpartyUploadAccountRequest++;
  if (buildCounterIdentitytoolkitRelyingpartyUploadAccountRequest < 3) {
    unittest.expect(o.allowOverwrite!, unittest.isTrue);
    unittest.expect(
      o.blockSize!,
      unittest.equals(42),
    );
    unittest.expect(
      o.cpuMemCost!,
      unittest.equals(42),
    );
    unittest.expect(
      o.delegatedProjectNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dkLen!,
      unittest.equals(42),
    );
    unittest.expect(
      o.hashAlgorithm!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.memoryCost!,
      unittest.equals(42),
    );
    unittest.expect(
      o.parallelization!,
      unittest.equals(42),
    );
    unittest.expect(
      o.rounds!,
      unittest.equals(42),
    );
    unittest.expect(
      o.saltSeparator!,
      unittest.equals('foo'),
    );
    unittest.expect(o.sanityCheck!, unittest.isTrue);
    unittest.expect(
      o.signerKey!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetProjectId!,
      unittest.equals('foo'),
    );
    checkUnnamed591(o.users!);
  }
  buildCounterIdentitytoolkitRelyingpartyUploadAccountRequest--;
}

core.int buildCounterIdentitytoolkitRelyingpartyVerifyAssertionRequest = 0;
api.IdentitytoolkitRelyingpartyVerifyAssertionRequest
    buildIdentitytoolkitRelyingpartyVerifyAssertionRequest() {
  var o = api.IdentitytoolkitRelyingpartyVerifyAssertionRequest();
  buildCounterIdentitytoolkitRelyingpartyVerifyAssertionRequest++;
  if (buildCounterIdentitytoolkitRelyingpartyVerifyAssertionRequest < 3) {
    o.autoCreate = true;
    o.delegatedProjectNumber = 'foo';
    o.idToken = 'foo';
    o.instanceId = 'foo';
    o.pendingIdToken = 'foo';
    o.postBody = 'foo';
    o.requestUri = 'foo';
    o.returnIdpCredential = true;
    o.returnRefreshToken = true;
    o.returnSecureToken = true;
    o.sessionId = 'foo';
    o.tenantId = 'foo';
    o.tenantProjectNumber = 'foo';
  }
  buildCounterIdentitytoolkitRelyingpartyVerifyAssertionRequest--;
  return o;
}

void checkIdentitytoolkitRelyingpartyVerifyAssertionRequest(
    api.IdentitytoolkitRelyingpartyVerifyAssertionRequest o) {
  buildCounterIdentitytoolkitRelyingpartyVerifyAssertionRequest++;
  if (buildCounterIdentitytoolkitRelyingpartyVerifyAssertionRequest < 3) {
    unittest.expect(o.autoCreate!, unittest.isTrue);
    unittest.expect(
      o.delegatedProjectNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.idToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.instanceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pendingIdToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.postBody!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.requestUri!,
      unittest.equals('foo'),
    );
    unittest.expect(o.returnIdpCredential!, unittest.isTrue);
    unittest.expect(o.returnRefreshToken!, unittest.isTrue);
    unittest.expect(o.returnSecureToken!, unittest.isTrue);
    unittest.expect(
      o.sessionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tenantId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tenantProjectNumber!,
      unittest.equals('foo'),
    );
  }
  buildCounterIdentitytoolkitRelyingpartyVerifyAssertionRequest--;
}

core.int buildCounterIdentitytoolkitRelyingpartyVerifyCustomTokenRequest = 0;
api.IdentitytoolkitRelyingpartyVerifyCustomTokenRequest
    buildIdentitytoolkitRelyingpartyVerifyCustomTokenRequest() {
  var o = api.IdentitytoolkitRelyingpartyVerifyCustomTokenRequest();
  buildCounterIdentitytoolkitRelyingpartyVerifyCustomTokenRequest++;
  if (buildCounterIdentitytoolkitRelyingpartyVerifyCustomTokenRequest < 3) {
    o.delegatedProjectNumber = 'foo';
    o.instanceId = 'foo';
    o.returnSecureToken = true;
    o.token = 'foo';
  }
  buildCounterIdentitytoolkitRelyingpartyVerifyCustomTokenRequest--;
  return o;
}

void checkIdentitytoolkitRelyingpartyVerifyCustomTokenRequest(
    api.IdentitytoolkitRelyingpartyVerifyCustomTokenRequest o) {
  buildCounterIdentitytoolkitRelyingpartyVerifyCustomTokenRequest++;
  if (buildCounterIdentitytoolkitRelyingpartyVerifyCustomTokenRequest < 3) {
    unittest.expect(
      o.delegatedProjectNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.instanceId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.returnSecureToken!, unittest.isTrue);
    unittest.expect(
      o.token!,
      unittest.equals('foo'),
    );
  }
  buildCounterIdentitytoolkitRelyingpartyVerifyCustomTokenRequest--;
}

core.int buildCounterIdentitytoolkitRelyingpartyVerifyPasswordRequest = 0;
api.IdentitytoolkitRelyingpartyVerifyPasswordRequest
    buildIdentitytoolkitRelyingpartyVerifyPasswordRequest() {
  var o = api.IdentitytoolkitRelyingpartyVerifyPasswordRequest();
  buildCounterIdentitytoolkitRelyingpartyVerifyPasswordRequest++;
  if (buildCounterIdentitytoolkitRelyingpartyVerifyPasswordRequest < 3) {
    o.captchaChallenge = 'foo';
    o.captchaResponse = 'foo';
    o.delegatedProjectNumber = 'foo';
    o.email = 'foo';
    o.idToken = 'foo';
    o.instanceId = 'foo';
    o.password = 'foo';
    o.pendingIdToken = 'foo';
    o.returnSecureToken = true;
    o.tenantId = 'foo';
    o.tenantProjectNumber = 'foo';
  }
  buildCounterIdentitytoolkitRelyingpartyVerifyPasswordRequest--;
  return o;
}

void checkIdentitytoolkitRelyingpartyVerifyPasswordRequest(
    api.IdentitytoolkitRelyingpartyVerifyPasswordRequest o) {
  buildCounterIdentitytoolkitRelyingpartyVerifyPasswordRequest++;
  if (buildCounterIdentitytoolkitRelyingpartyVerifyPasswordRequest < 3) {
    unittest.expect(
      o.captchaChallenge!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.captchaResponse!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.delegatedProjectNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.idToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.instanceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.password!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pendingIdToken!,
      unittest.equals('foo'),
    );
    unittest.expect(o.returnSecureToken!, unittest.isTrue);
    unittest.expect(
      o.tenantId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tenantProjectNumber!,
      unittest.equals('foo'),
    );
  }
  buildCounterIdentitytoolkitRelyingpartyVerifyPasswordRequest--;
}

core.int buildCounterIdentitytoolkitRelyingpartyVerifyPhoneNumberRequest = 0;
api.IdentitytoolkitRelyingpartyVerifyPhoneNumberRequest
    buildIdentitytoolkitRelyingpartyVerifyPhoneNumberRequest() {
  var o = api.IdentitytoolkitRelyingpartyVerifyPhoneNumberRequest();
  buildCounterIdentitytoolkitRelyingpartyVerifyPhoneNumberRequest++;
  if (buildCounterIdentitytoolkitRelyingpartyVerifyPhoneNumberRequest < 3) {
    o.code = 'foo';
    o.idToken = 'foo';
    o.operation = 'foo';
    o.phoneNumber = 'foo';
    o.sessionInfo = 'foo';
    o.temporaryProof = 'foo';
    o.verificationProof = 'foo';
  }
  buildCounterIdentitytoolkitRelyingpartyVerifyPhoneNumberRequest--;
  return o;
}

void checkIdentitytoolkitRelyingpartyVerifyPhoneNumberRequest(
    api.IdentitytoolkitRelyingpartyVerifyPhoneNumberRequest o) {
  buildCounterIdentitytoolkitRelyingpartyVerifyPhoneNumberRequest++;
  if (buildCounterIdentitytoolkitRelyingpartyVerifyPhoneNumberRequest < 3) {
    unittest.expect(
      o.code!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.idToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.operation!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.phoneNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sessionInfo!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.temporaryProof!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.verificationProof!,
      unittest.equals('foo'),
    );
  }
  buildCounterIdentitytoolkitRelyingpartyVerifyPhoneNumberRequest--;
}

core.int buildCounterIdentitytoolkitRelyingpartyVerifyPhoneNumberResponse = 0;
api.IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse
    buildIdentitytoolkitRelyingpartyVerifyPhoneNumberResponse() {
  var o = api.IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse();
  buildCounterIdentitytoolkitRelyingpartyVerifyPhoneNumberResponse++;
  if (buildCounterIdentitytoolkitRelyingpartyVerifyPhoneNumberResponse < 3) {
    o.expiresIn = 'foo';
    o.idToken = 'foo';
    o.isNewUser = true;
    o.localId = 'foo';
    o.phoneNumber = 'foo';
    o.refreshToken = 'foo';
    o.temporaryProof = 'foo';
    o.temporaryProofExpiresIn = 'foo';
    o.verificationProof = 'foo';
    o.verificationProofExpiresIn = 'foo';
  }
  buildCounterIdentitytoolkitRelyingpartyVerifyPhoneNumberResponse--;
  return o;
}

void checkIdentitytoolkitRelyingpartyVerifyPhoneNumberResponse(
    api.IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse o) {
  buildCounterIdentitytoolkitRelyingpartyVerifyPhoneNumberResponse++;
  if (buildCounterIdentitytoolkitRelyingpartyVerifyPhoneNumberResponse < 3) {
    unittest.expect(
      o.expiresIn!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.idToken!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isNewUser!, unittest.isTrue);
    unittest.expect(
      o.localId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.phoneNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.refreshToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.temporaryProof!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.temporaryProofExpiresIn!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.verificationProof!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.verificationProofExpiresIn!,
      unittest.equals('foo'),
    );
  }
  buildCounterIdentitytoolkitRelyingpartyVerifyPhoneNumberResponse--;
}

core.List<core.String> buildUnnamed592() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed592(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.int buildCounterIdpConfig = 0;
api.IdpConfig buildIdpConfig() {
  var o = api.IdpConfig();
  buildCounterIdpConfig++;
  if (buildCounterIdpConfig < 3) {
    o.clientId = 'foo';
    o.enabled = true;
    o.experimentPercent = 42;
    o.provider = 'foo';
    o.secret = 'foo';
    o.whitelistedAudiences = buildUnnamed592();
  }
  buildCounterIdpConfig--;
  return o;
}

void checkIdpConfig(api.IdpConfig o) {
  buildCounterIdpConfig++;
  if (buildCounterIdpConfig < 3) {
    unittest.expect(
      o.clientId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.enabled!, unittest.isTrue);
    unittest.expect(
      o.experimentPercent!,
      unittest.equals(42),
    );
    unittest.expect(
      o.provider!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.secret!,
      unittest.equals('foo'),
    );
    checkUnnamed592(o.whitelistedAudiences!);
  }
  buildCounterIdpConfig--;
}

core.int buildCounterRelyingparty = 0;
api.Relyingparty buildRelyingparty() {
  var o = api.Relyingparty();
  buildCounterRelyingparty++;
  if (buildCounterRelyingparty < 3) {
    o.androidInstallApp = true;
    o.androidMinimumVersion = 'foo';
    o.androidPackageName = 'foo';
    o.canHandleCodeInApp = true;
    o.captchaResp = 'foo';
    o.challenge = 'foo';
    o.continueUrl = 'foo';
    o.email = 'foo';
    o.iOSAppStoreId = 'foo';
    o.iOSBundleId = 'foo';
    o.idToken = 'foo';
    o.kind = 'foo';
    o.newEmail = 'foo';
    o.requestType = 'foo';
    o.userIp = 'foo';
  }
  buildCounterRelyingparty--;
  return o;
}

void checkRelyingparty(api.Relyingparty o) {
  buildCounterRelyingparty++;
  if (buildCounterRelyingparty < 3) {
    unittest.expect(o.androidInstallApp!, unittest.isTrue);
    unittest.expect(
      o.androidMinimumVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.androidPackageName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.canHandleCodeInApp!, unittest.isTrue);
    unittest.expect(
      o.captchaResp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.challenge!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.continueUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.iOSAppStoreId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.iOSBundleId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.idToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.newEmail!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.requestType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userIp!,
      unittest.equals('foo'),
    );
  }
  buildCounterRelyingparty--;
}

core.int buildCounterResetPasswordResponse = 0;
api.ResetPasswordResponse buildResetPasswordResponse() {
  var o = api.ResetPasswordResponse();
  buildCounterResetPasswordResponse++;
  if (buildCounterResetPasswordResponse < 3) {
    o.email = 'foo';
    o.kind = 'foo';
    o.newEmail = 'foo';
    o.requestType = 'foo';
  }
  buildCounterResetPasswordResponse--;
  return o;
}

void checkResetPasswordResponse(api.ResetPasswordResponse o) {
  buildCounterResetPasswordResponse++;
  if (buildCounterResetPasswordResponse < 3) {
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.newEmail!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.requestType!,
      unittest.equals('foo'),
    );
  }
  buildCounterResetPasswordResponse--;
}

core.int buildCounterSetAccountInfoResponseProviderUserInfo = 0;
api.SetAccountInfoResponseProviderUserInfo
    buildSetAccountInfoResponseProviderUserInfo() {
  var o = api.SetAccountInfoResponseProviderUserInfo();
  buildCounterSetAccountInfoResponseProviderUserInfo++;
  if (buildCounterSetAccountInfoResponseProviderUserInfo < 3) {
    o.displayName = 'foo';
    o.federatedId = 'foo';
    o.photoUrl = 'foo';
    o.providerId = 'foo';
  }
  buildCounterSetAccountInfoResponseProviderUserInfo--;
  return o;
}

void checkSetAccountInfoResponseProviderUserInfo(
    api.SetAccountInfoResponseProviderUserInfo o) {
  buildCounterSetAccountInfoResponseProviderUserInfo++;
  if (buildCounterSetAccountInfoResponseProviderUserInfo < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.federatedId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.photoUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.providerId!,
      unittest.equals('foo'),
    );
  }
  buildCounterSetAccountInfoResponseProviderUserInfo--;
}

core.List<api.SetAccountInfoResponseProviderUserInfo> buildUnnamed593() {
  var o = <api.SetAccountInfoResponseProviderUserInfo>[];
  o.add(buildSetAccountInfoResponseProviderUserInfo());
  o.add(buildSetAccountInfoResponseProviderUserInfo());
  return o;
}

void checkUnnamed593(core.List<api.SetAccountInfoResponseProviderUserInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSetAccountInfoResponseProviderUserInfo(
      o[0] as api.SetAccountInfoResponseProviderUserInfo);
  checkSetAccountInfoResponseProviderUserInfo(
      o[1] as api.SetAccountInfoResponseProviderUserInfo);
}

core.int buildCounterSetAccountInfoResponse = 0;
api.SetAccountInfoResponse buildSetAccountInfoResponse() {
  var o = api.SetAccountInfoResponse();
  buildCounterSetAccountInfoResponse++;
  if (buildCounterSetAccountInfoResponse < 3) {
    o.displayName = 'foo';
    o.email = 'foo';
    o.emailVerified = true;
    o.expiresIn = 'foo';
    o.idToken = 'foo';
    o.kind = 'foo';
    o.localId = 'foo';
    o.newEmail = 'foo';
    o.passwordHash = 'foo';
    o.photoUrl = 'foo';
    o.providerUserInfo = buildUnnamed593();
    o.refreshToken = 'foo';
  }
  buildCounterSetAccountInfoResponse--;
  return o;
}

void checkSetAccountInfoResponse(api.SetAccountInfoResponse o) {
  buildCounterSetAccountInfoResponse++;
  if (buildCounterSetAccountInfoResponse < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(o.emailVerified!, unittest.isTrue);
    unittest.expect(
      o.expiresIn!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.idToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.localId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.newEmail!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.passwordHash!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.photoUrl!,
      unittest.equals('foo'),
    );
    checkUnnamed593(o.providerUserInfo!);
    unittest.expect(
      o.refreshToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterSetAccountInfoResponse--;
}

core.int buildCounterSignupNewUserResponse = 0;
api.SignupNewUserResponse buildSignupNewUserResponse() {
  var o = api.SignupNewUserResponse();
  buildCounterSignupNewUserResponse++;
  if (buildCounterSignupNewUserResponse < 3) {
    o.displayName = 'foo';
    o.email = 'foo';
    o.expiresIn = 'foo';
    o.idToken = 'foo';
    o.kind = 'foo';
    o.localId = 'foo';
    o.refreshToken = 'foo';
  }
  buildCounterSignupNewUserResponse--;
  return o;
}

void checkSignupNewUserResponse(api.SignupNewUserResponse o) {
  buildCounterSignupNewUserResponse++;
  if (buildCounterSignupNewUserResponse < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expiresIn!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.idToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.localId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.refreshToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterSignupNewUserResponse--;
}

core.int buildCounterUploadAccountResponseError = 0;
api.UploadAccountResponseError buildUploadAccountResponseError() {
  var o = api.UploadAccountResponseError();
  buildCounterUploadAccountResponseError++;
  if (buildCounterUploadAccountResponseError < 3) {
    o.index = 42;
    o.message = 'foo';
  }
  buildCounterUploadAccountResponseError--;
  return o;
}

void checkUploadAccountResponseError(api.UploadAccountResponseError o) {
  buildCounterUploadAccountResponseError++;
  if (buildCounterUploadAccountResponseError < 3) {
    unittest.expect(
      o.index!,
      unittest.equals(42),
    );
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterUploadAccountResponseError--;
}

core.List<api.UploadAccountResponseError> buildUnnamed594() {
  var o = <api.UploadAccountResponseError>[];
  o.add(buildUploadAccountResponseError());
  o.add(buildUploadAccountResponseError());
  return o;
}

void checkUnnamed594(core.List<api.UploadAccountResponseError> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUploadAccountResponseError(o[0] as api.UploadAccountResponseError);
  checkUploadAccountResponseError(o[1] as api.UploadAccountResponseError);
}

core.int buildCounterUploadAccountResponse = 0;
api.UploadAccountResponse buildUploadAccountResponse() {
  var o = api.UploadAccountResponse();
  buildCounterUploadAccountResponse++;
  if (buildCounterUploadAccountResponse < 3) {
    o.error = buildUnnamed594();
    o.kind = 'foo';
  }
  buildCounterUploadAccountResponse--;
  return o;
}

void checkUploadAccountResponse(api.UploadAccountResponse o) {
  buildCounterUploadAccountResponse++;
  if (buildCounterUploadAccountResponse < 3) {
    checkUnnamed594(o.error!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterUploadAccountResponse--;
}

core.int buildCounterUserInfoProviderUserInfo = 0;
api.UserInfoProviderUserInfo buildUserInfoProviderUserInfo() {
  var o = api.UserInfoProviderUserInfo();
  buildCounterUserInfoProviderUserInfo++;
  if (buildCounterUserInfoProviderUserInfo < 3) {
    o.displayName = 'foo';
    o.email = 'foo';
    o.federatedId = 'foo';
    o.phoneNumber = 'foo';
    o.photoUrl = 'foo';
    o.providerId = 'foo';
    o.rawId = 'foo';
    o.screenName = 'foo';
  }
  buildCounterUserInfoProviderUserInfo--;
  return o;
}

void checkUserInfoProviderUserInfo(api.UserInfoProviderUserInfo o) {
  buildCounterUserInfoProviderUserInfo++;
  if (buildCounterUserInfoProviderUserInfo < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.federatedId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.phoneNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.photoUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.providerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rawId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.screenName!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserInfoProviderUserInfo--;
}

core.List<api.UserInfoProviderUserInfo> buildUnnamed595() {
  var o = <api.UserInfoProviderUserInfo>[];
  o.add(buildUserInfoProviderUserInfo());
  o.add(buildUserInfoProviderUserInfo());
  return o;
}

void checkUnnamed595(core.List<api.UserInfoProviderUserInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUserInfoProviderUserInfo(o[0] as api.UserInfoProviderUserInfo);
  checkUserInfoProviderUserInfo(o[1] as api.UserInfoProviderUserInfo);
}

core.int buildCounterUserInfo = 0;
api.UserInfo buildUserInfo() {
  var o = api.UserInfo();
  buildCounterUserInfo++;
  if (buildCounterUserInfo < 3) {
    o.createdAt = 'foo';
    o.customAttributes = 'foo';
    o.customAuth = true;
    o.disabled = true;
    o.displayName = 'foo';
    o.email = 'foo';
    o.emailVerified = true;
    o.lastLoginAt = 'foo';
    o.localId = 'foo';
    o.passwordHash = 'foo';
    o.passwordUpdatedAt = 42.0;
    o.phoneNumber = 'foo';
    o.photoUrl = 'foo';
    o.providerUserInfo = buildUnnamed595();
    o.rawPassword = 'foo';
    o.salt = 'foo';
    o.screenName = 'foo';
    o.validSince = 'foo';
    o.version = 42;
  }
  buildCounterUserInfo--;
  return o;
}

void checkUserInfo(api.UserInfo o) {
  buildCounterUserInfo++;
  if (buildCounterUserInfo < 3) {
    unittest.expect(
      o.createdAt!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.customAttributes!,
      unittest.equals('foo'),
    );
    unittest.expect(o.customAuth!, unittest.isTrue);
    unittest.expect(o.disabled!, unittest.isTrue);
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(o.emailVerified!, unittest.isTrue);
    unittest.expect(
      o.lastLoginAt!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.localId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.passwordHash!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.passwordUpdatedAt!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.phoneNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.photoUrl!,
      unittest.equals('foo'),
    );
    checkUnnamed595(o.providerUserInfo!);
    unittest.expect(
      o.rawPassword!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.salt!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.screenName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.validSince!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals(42),
    );
  }
  buildCounterUserInfo--;
}

core.List<core.String> buildUnnamed596() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed596(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.int buildCounterVerifyAssertionResponse = 0;
api.VerifyAssertionResponse buildVerifyAssertionResponse() {
  var o = api.VerifyAssertionResponse();
  buildCounterVerifyAssertionResponse++;
  if (buildCounterVerifyAssertionResponse < 3) {
    o.action = 'foo';
    o.appInstallationUrl = 'foo';
    o.appScheme = 'foo';
    o.context = 'foo';
    o.dateOfBirth = 'foo';
    o.displayName = 'foo';
    o.email = 'foo';
    o.emailRecycled = true;
    o.emailVerified = true;
    o.errorMessage = 'foo';
    o.expiresIn = 'foo';
    o.federatedId = 'foo';
    o.firstName = 'foo';
    o.fullName = 'foo';
    o.idToken = 'foo';
    o.inputEmail = 'foo';
    o.isNewUser = true;
    o.kind = 'foo';
    o.language = 'foo';
    o.lastName = 'foo';
    o.localId = 'foo';
    o.needConfirmation = true;
    o.needEmail = true;
    o.nickName = 'foo';
    o.oauthAccessToken = 'foo';
    o.oauthAuthorizationCode = 'foo';
    o.oauthExpireIn = 42;
    o.oauthIdToken = 'foo';
    o.oauthRequestToken = 'foo';
    o.oauthScope = 'foo';
    o.oauthTokenSecret = 'foo';
    o.originalEmail = 'foo';
    o.photoUrl = 'foo';
    o.providerId = 'foo';
    o.rawUserInfo = 'foo';
    o.refreshToken = 'foo';
    o.screenName = 'foo';
    o.timeZone = 'foo';
    o.verifiedProvider = buildUnnamed596();
  }
  buildCounterVerifyAssertionResponse--;
  return o;
}

void checkVerifyAssertionResponse(api.VerifyAssertionResponse o) {
  buildCounterVerifyAssertionResponse++;
  if (buildCounterVerifyAssertionResponse < 3) {
    unittest.expect(
      o.action!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.appInstallationUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.appScheme!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.context!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dateOfBirth!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(o.emailRecycled!, unittest.isTrue);
    unittest.expect(o.emailVerified!, unittest.isTrue);
    unittest.expect(
      o.errorMessage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expiresIn!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.federatedId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.firstName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fullName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.idToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.inputEmail!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isNewUser!, unittest.isTrue);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.language!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lastName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.localId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.needConfirmation!, unittest.isTrue);
    unittest.expect(o.needEmail!, unittest.isTrue);
    unittest.expect(
      o.nickName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.oauthAccessToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.oauthAuthorizationCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.oauthExpireIn!,
      unittest.equals(42),
    );
    unittest.expect(
      o.oauthIdToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.oauthRequestToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.oauthScope!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.oauthTokenSecret!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.originalEmail!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.photoUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.providerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rawUserInfo!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.refreshToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.screenName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timeZone!,
      unittest.equals('foo'),
    );
    checkUnnamed596(o.verifiedProvider!);
  }
  buildCounterVerifyAssertionResponse--;
}

core.int buildCounterVerifyCustomTokenResponse = 0;
api.VerifyCustomTokenResponse buildVerifyCustomTokenResponse() {
  var o = api.VerifyCustomTokenResponse();
  buildCounterVerifyCustomTokenResponse++;
  if (buildCounterVerifyCustomTokenResponse < 3) {
    o.expiresIn = 'foo';
    o.idToken = 'foo';
    o.isNewUser = true;
    o.kind = 'foo';
    o.refreshToken = 'foo';
  }
  buildCounterVerifyCustomTokenResponse--;
  return o;
}

void checkVerifyCustomTokenResponse(api.VerifyCustomTokenResponse o) {
  buildCounterVerifyCustomTokenResponse++;
  if (buildCounterVerifyCustomTokenResponse < 3) {
    unittest.expect(
      o.expiresIn!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.idToken!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isNewUser!, unittest.isTrue);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.refreshToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterVerifyCustomTokenResponse--;
}

core.int buildCounterVerifyPasswordResponse = 0;
api.VerifyPasswordResponse buildVerifyPasswordResponse() {
  var o = api.VerifyPasswordResponse();
  buildCounterVerifyPasswordResponse++;
  if (buildCounterVerifyPasswordResponse < 3) {
    o.displayName = 'foo';
    o.email = 'foo';
    o.expiresIn = 'foo';
    o.idToken = 'foo';
    o.kind = 'foo';
    o.localId = 'foo';
    o.oauthAccessToken = 'foo';
    o.oauthAuthorizationCode = 'foo';
    o.oauthExpireIn = 42;
    o.photoUrl = 'foo';
    o.refreshToken = 'foo';
    o.registered = true;
  }
  buildCounterVerifyPasswordResponse--;
  return o;
}

void checkVerifyPasswordResponse(api.VerifyPasswordResponse o) {
  buildCounterVerifyPasswordResponse++;
  if (buildCounterVerifyPasswordResponse < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expiresIn!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.idToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.localId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.oauthAccessToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.oauthAuthorizationCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.oauthExpireIn!,
      unittest.equals(42),
    );
    unittest.expect(
      o.photoUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.refreshToken!,
      unittest.equals('foo'),
    );
    unittest.expect(o.registered!, unittest.isTrue);
  }
  buildCounterVerifyPasswordResponse--;
}

void main() {
  unittest.group('obj-schema-CreateAuthUriResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateAuthUriResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateAuthUriResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateAuthUriResponse(od as api.CreateAuthUriResponse);
    });
  });

  unittest.group('obj-schema-DeleteAccountResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteAccountResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteAccountResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteAccountResponse(od as api.DeleteAccountResponse);
    });
  });

  unittest.group('obj-schema-DownloadAccountResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDownloadAccountResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DownloadAccountResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDownloadAccountResponse(od as api.DownloadAccountResponse);
    });
  });

  unittest.group('obj-schema-EmailLinkSigninResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEmailLinkSigninResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EmailLinkSigninResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEmailLinkSigninResponse(od as api.EmailLinkSigninResponse);
    });
  });

  unittest.group('obj-schema-EmailTemplate', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEmailTemplate();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EmailTemplate.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEmailTemplate(od as api.EmailTemplate);
    });
  });

  unittest.group('obj-schema-GetAccountInfoResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetAccountInfoResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetAccountInfoResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetAccountInfoResponse(od as api.GetAccountInfoResponse);
    });
  });

  unittest.group('obj-schema-GetOobConfirmationCodeResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetOobConfirmationCodeResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetOobConfirmationCodeResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetOobConfirmationCodeResponse(
          od as api.GetOobConfirmationCodeResponse);
    });
  });

  unittest.group('obj-schema-GetRecaptchaParamResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetRecaptchaParamResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetRecaptchaParamResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetRecaptchaParamResponse(od as api.GetRecaptchaParamResponse);
    });
  });

  unittest.group('obj-schema-IdentitytoolkitRelyingpartyCreateAuthUriRequest',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentitytoolkitRelyingpartyCreateAuthUriRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IdentitytoolkitRelyingpartyCreateAuthUriRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIdentitytoolkitRelyingpartyCreateAuthUriRequest(
          od as api.IdentitytoolkitRelyingpartyCreateAuthUriRequest);
    });
  });

  unittest.group('obj-schema-IdentitytoolkitRelyingpartyDeleteAccountRequest',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentitytoolkitRelyingpartyDeleteAccountRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IdentitytoolkitRelyingpartyDeleteAccountRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIdentitytoolkitRelyingpartyDeleteAccountRequest(
          od as api.IdentitytoolkitRelyingpartyDeleteAccountRequest);
    });
  });

  unittest.group('obj-schema-IdentitytoolkitRelyingpartyDownloadAccountRequest',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentitytoolkitRelyingpartyDownloadAccountRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IdentitytoolkitRelyingpartyDownloadAccountRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIdentitytoolkitRelyingpartyDownloadAccountRequest(
          od as api.IdentitytoolkitRelyingpartyDownloadAccountRequest);
    });
  });

  unittest.group('obj-schema-IdentitytoolkitRelyingpartyEmailLinkSigninRequest',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentitytoolkitRelyingpartyEmailLinkSigninRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IdentitytoolkitRelyingpartyEmailLinkSigninRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIdentitytoolkitRelyingpartyEmailLinkSigninRequest(
          od as api.IdentitytoolkitRelyingpartyEmailLinkSigninRequest);
    });
  });

  unittest.group('obj-schema-IdentitytoolkitRelyingpartyGetAccountInfoRequest',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentitytoolkitRelyingpartyGetAccountInfoRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IdentitytoolkitRelyingpartyGetAccountInfoRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIdentitytoolkitRelyingpartyGetAccountInfoRequest(
          od as api.IdentitytoolkitRelyingpartyGetAccountInfoRequest);
    });
  });

  unittest.group(
      'obj-schema-IdentitytoolkitRelyingpartyGetProjectConfigResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentitytoolkitRelyingpartyGetProjectConfigResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IdentitytoolkitRelyingpartyGetProjectConfigResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIdentitytoolkitRelyingpartyGetProjectConfigResponse(
          od as api.IdentitytoolkitRelyingpartyGetProjectConfigResponse);
    });
  });

  unittest.group('obj-schema-IdentitytoolkitRelyingpartyGetPublicKeysResponse',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentitytoolkitRelyingpartyGetPublicKeysResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IdentitytoolkitRelyingpartyGetPublicKeysResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIdentitytoolkitRelyingpartyGetPublicKeysResponse(
          od as api.IdentitytoolkitRelyingpartyGetPublicKeysResponse);
    });
  });

  unittest.group('obj-schema-IdentitytoolkitRelyingpartyResetPasswordRequest',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentitytoolkitRelyingpartyResetPasswordRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IdentitytoolkitRelyingpartyResetPasswordRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIdentitytoolkitRelyingpartyResetPasswordRequest(
          od as api.IdentitytoolkitRelyingpartyResetPasswordRequest);
    });
  });

  unittest.group(
      'obj-schema-IdentitytoolkitRelyingpartySendVerificationCodeRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentitytoolkitRelyingpartySendVerificationCodeRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.IdentitytoolkitRelyingpartySendVerificationCodeRequest.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkIdentitytoolkitRelyingpartySendVerificationCodeRequest(
          od as api.IdentitytoolkitRelyingpartySendVerificationCodeRequest);
    });
  });

  unittest.group(
      'obj-schema-IdentitytoolkitRelyingpartySendVerificationCodeResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentitytoolkitRelyingpartySendVerificationCodeResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.IdentitytoolkitRelyingpartySendVerificationCodeResponse.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkIdentitytoolkitRelyingpartySendVerificationCodeResponse(
          od as api.IdentitytoolkitRelyingpartySendVerificationCodeResponse);
    });
  });

  unittest.group('obj-schema-IdentitytoolkitRelyingpartySetAccountInfoRequest',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentitytoolkitRelyingpartySetAccountInfoRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IdentitytoolkitRelyingpartySetAccountInfoRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIdentitytoolkitRelyingpartySetAccountInfoRequest(
          od as api.IdentitytoolkitRelyingpartySetAccountInfoRequest);
    });
  });

  unittest.group(
      'obj-schema-IdentitytoolkitRelyingpartySetProjectConfigRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentitytoolkitRelyingpartySetProjectConfigRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IdentitytoolkitRelyingpartySetProjectConfigRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIdentitytoolkitRelyingpartySetProjectConfigRequest(
          od as api.IdentitytoolkitRelyingpartySetProjectConfigRequest);
    });
  });

  unittest.group(
      'obj-schema-IdentitytoolkitRelyingpartySetProjectConfigResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentitytoolkitRelyingpartySetProjectConfigResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IdentitytoolkitRelyingpartySetProjectConfigResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIdentitytoolkitRelyingpartySetProjectConfigResponse(
          od as api.IdentitytoolkitRelyingpartySetProjectConfigResponse);
    });
  });

  unittest.group('obj-schema-IdentitytoolkitRelyingpartySignOutUserRequest',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentitytoolkitRelyingpartySignOutUserRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IdentitytoolkitRelyingpartySignOutUserRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIdentitytoolkitRelyingpartySignOutUserRequest(
          od as api.IdentitytoolkitRelyingpartySignOutUserRequest);
    });
  });

  unittest.group('obj-schema-IdentitytoolkitRelyingpartySignOutUserResponse',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentitytoolkitRelyingpartySignOutUserResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IdentitytoolkitRelyingpartySignOutUserResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIdentitytoolkitRelyingpartySignOutUserResponse(
          od as api.IdentitytoolkitRelyingpartySignOutUserResponse);
    });
  });

  unittest.group('obj-schema-IdentitytoolkitRelyingpartySignupNewUserRequest',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentitytoolkitRelyingpartySignupNewUserRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IdentitytoolkitRelyingpartySignupNewUserRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIdentitytoolkitRelyingpartySignupNewUserRequest(
          od as api.IdentitytoolkitRelyingpartySignupNewUserRequest);
    });
  });

  unittest.group('obj-schema-IdentitytoolkitRelyingpartyUploadAccountRequest',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentitytoolkitRelyingpartyUploadAccountRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IdentitytoolkitRelyingpartyUploadAccountRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIdentitytoolkitRelyingpartyUploadAccountRequest(
          od as api.IdentitytoolkitRelyingpartyUploadAccountRequest);
    });
  });

  unittest.group('obj-schema-IdentitytoolkitRelyingpartyVerifyAssertionRequest',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentitytoolkitRelyingpartyVerifyAssertionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IdentitytoolkitRelyingpartyVerifyAssertionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIdentitytoolkitRelyingpartyVerifyAssertionRequest(
          od as api.IdentitytoolkitRelyingpartyVerifyAssertionRequest);
    });
  });

  unittest.group(
      'obj-schema-IdentitytoolkitRelyingpartyVerifyCustomTokenRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentitytoolkitRelyingpartyVerifyCustomTokenRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IdentitytoolkitRelyingpartyVerifyCustomTokenRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIdentitytoolkitRelyingpartyVerifyCustomTokenRequest(
          od as api.IdentitytoolkitRelyingpartyVerifyCustomTokenRequest);
    });
  });

  unittest.group('obj-schema-IdentitytoolkitRelyingpartyVerifyPasswordRequest',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentitytoolkitRelyingpartyVerifyPasswordRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IdentitytoolkitRelyingpartyVerifyPasswordRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIdentitytoolkitRelyingpartyVerifyPasswordRequest(
          od as api.IdentitytoolkitRelyingpartyVerifyPasswordRequest);
    });
  });

  unittest.group(
      'obj-schema-IdentitytoolkitRelyingpartyVerifyPhoneNumberRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentitytoolkitRelyingpartyVerifyPhoneNumberRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IdentitytoolkitRelyingpartyVerifyPhoneNumberRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIdentitytoolkitRelyingpartyVerifyPhoneNumberRequest(
          od as api.IdentitytoolkitRelyingpartyVerifyPhoneNumberRequest);
    });
  });

  unittest.group(
      'obj-schema-IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentitytoolkitRelyingpartyVerifyPhoneNumberResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkIdentitytoolkitRelyingpartyVerifyPhoneNumberResponse(
          od as api.IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse);
    });
  });

  unittest.group('obj-schema-IdpConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdpConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.IdpConfig.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkIdpConfig(od as api.IdpConfig);
    });
  });

  unittest.group('obj-schema-Relyingparty', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRelyingparty();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Relyingparty.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRelyingparty(od as api.Relyingparty);
    });
  });

  unittest.group('obj-schema-ResetPasswordResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResetPasswordResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResetPasswordResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResetPasswordResponse(od as api.ResetPasswordResponse);
    });
  });

  unittest.group('obj-schema-SetAccountInfoResponseProviderUserInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSetAccountInfoResponseProviderUserInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SetAccountInfoResponseProviderUserInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSetAccountInfoResponseProviderUserInfo(
          od as api.SetAccountInfoResponseProviderUserInfo);
    });
  });

  unittest.group('obj-schema-SetAccountInfoResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSetAccountInfoResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SetAccountInfoResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSetAccountInfoResponse(od as api.SetAccountInfoResponse);
    });
  });

  unittest.group('obj-schema-SignupNewUserResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSignupNewUserResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SignupNewUserResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSignupNewUserResponse(od as api.SignupNewUserResponse);
    });
  });

  unittest.group('obj-schema-UploadAccountResponseError', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUploadAccountResponseError();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UploadAccountResponseError.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUploadAccountResponseError(od as api.UploadAccountResponseError);
    });
  });

  unittest.group('obj-schema-UploadAccountResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUploadAccountResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UploadAccountResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUploadAccountResponse(od as api.UploadAccountResponse);
    });
  });

  unittest.group('obj-schema-UserInfoProviderUserInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserInfoProviderUserInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserInfoProviderUserInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserInfoProviderUserInfo(od as api.UserInfoProviderUserInfo);
    });
  });

  unittest.group('obj-schema-UserInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.UserInfo.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkUserInfo(od as api.UserInfo);
    });
  });

  unittest.group('obj-schema-VerifyAssertionResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVerifyAssertionResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VerifyAssertionResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVerifyAssertionResponse(od as api.VerifyAssertionResponse);
    });
  });

  unittest.group('obj-schema-VerifyCustomTokenResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVerifyCustomTokenResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VerifyCustomTokenResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVerifyCustomTokenResponse(od as api.VerifyCustomTokenResponse);
    });
  });

  unittest.group('obj-schema-VerifyPasswordResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVerifyPasswordResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VerifyPasswordResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVerifyPasswordResponse(od as api.VerifyPasswordResponse);
    });
  });

  unittest.group('resource-RelyingpartyResource', () {
    unittest.test('method--createAuthUri', () async {
      var mock = HttpServerMock();
      var res = api.IdentityToolkitApi(mock).relyingparty;
      var arg_request = buildIdentitytoolkitRelyingpartyCreateAuthUriRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.IdentitytoolkitRelyingpartyCreateAuthUriRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkIdentitytoolkitRelyingpartyCreateAuthUriRequest(
            obj as api.IdentitytoolkitRelyingpartyCreateAuthUriRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("identitytoolkit/v3/relyingparty/"),
        );
        pathOffset += 32;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("createAuthUri"),
        );
        pathOffset += 13;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCreateAuthUriResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.createAuthUri(arg_request, $fields: arg_$fields);
      checkCreateAuthUriResponse(response as api.CreateAuthUriResponse);
    });

    unittest.test('method--deleteAccount', () async {
      var mock = HttpServerMock();
      var res = api.IdentityToolkitApi(mock).relyingparty;
      var arg_request = buildIdentitytoolkitRelyingpartyDeleteAccountRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.IdentitytoolkitRelyingpartyDeleteAccountRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkIdentitytoolkitRelyingpartyDeleteAccountRequest(
            obj as api.IdentitytoolkitRelyingpartyDeleteAccountRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("identitytoolkit/v3/relyingparty/"),
        );
        pathOffset += 32;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("deleteAccount"),
        );
        pathOffset += 13;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildDeleteAccountResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.deleteAccount(arg_request, $fields: arg_$fields);
      checkDeleteAccountResponse(response as api.DeleteAccountResponse);
    });

    unittest.test('method--downloadAccount', () async {
      var mock = HttpServerMock();
      var res = api.IdentityToolkitApi(mock).relyingparty;
      var arg_request =
          buildIdentitytoolkitRelyingpartyDownloadAccountRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.IdentitytoolkitRelyingpartyDownloadAccountRequest.fromJson(
                json as core.Map<core.String, core.dynamic>);
        checkIdentitytoolkitRelyingpartyDownloadAccountRequest(
            obj as api.IdentitytoolkitRelyingpartyDownloadAccountRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("identitytoolkit/v3/relyingparty/"),
        );
        pathOffset += 32;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("downloadAccount"),
        );
        pathOffset += 15;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildDownloadAccountResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.downloadAccount(arg_request, $fields: arg_$fields);
      checkDownloadAccountResponse(response as api.DownloadAccountResponse);
    });

    unittest.test('method--emailLinkSignin', () async {
      var mock = HttpServerMock();
      var res = api.IdentityToolkitApi(mock).relyingparty;
      var arg_request =
          buildIdentitytoolkitRelyingpartyEmailLinkSigninRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.IdentitytoolkitRelyingpartyEmailLinkSigninRequest.fromJson(
                json as core.Map<core.String, core.dynamic>);
        checkIdentitytoolkitRelyingpartyEmailLinkSigninRequest(
            obj as api.IdentitytoolkitRelyingpartyEmailLinkSigninRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("identitytoolkit/v3/relyingparty/"),
        );
        pathOffset += 32;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("emailLinkSignin"),
        );
        pathOffset += 15;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildEmailLinkSigninResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.emailLinkSignin(arg_request, $fields: arg_$fields);
      checkEmailLinkSigninResponse(response as api.EmailLinkSigninResponse);
    });

    unittest.test('method--getAccountInfo', () async {
      var mock = HttpServerMock();
      var res = api.IdentityToolkitApi(mock).relyingparty;
      var arg_request = buildIdentitytoolkitRelyingpartyGetAccountInfoRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.IdentitytoolkitRelyingpartyGetAccountInfoRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkIdentitytoolkitRelyingpartyGetAccountInfoRequest(
            obj as api.IdentitytoolkitRelyingpartyGetAccountInfoRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("identitytoolkit/v3/relyingparty/"),
        );
        pathOffset += 32;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("getAccountInfo"),
        );
        pathOffset += 14;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGetAccountInfoResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.getAccountInfo(arg_request, $fields: arg_$fields);
      checkGetAccountInfoResponse(response as api.GetAccountInfoResponse);
    });

    unittest.test('method--getOobConfirmationCode', () async {
      var mock = HttpServerMock();
      var res = api.IdentityToolkitApi(mock).relyingparty;
      var arg_request = buildRelyingparty();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Relyingparty.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRelyingparty(obj as api.Relyingparty);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("identitytoolkit/v3/relyingparty/"),
        );
        pathOffset += 32;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("getOobConfirmationCode"),
        );
        pathOffset += 22;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGetOobConfirmationCodeResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.getOobConfirmationCode(arg_request, $fields: arg_$fields);
      checkGetOobConfirmationCodeResponse(
          response as api.GetOobConfirmationCodeResponse);
    });

    unittest.test('method--getProjectConfig', () async {
      var mock = HttpServerMock();
      var res = api.IdentityToolkitApi(mock).relyingparty;
      var arg_delegatedProjectNumber = 'foo';
      var arg_projectNumber = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("identitytoolkit/v3/relyingparty/"),
        );
        pathOffset += 32;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("getProjectConfig"),
        );
        pathOffset += 16;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["delegatedProjectNumber"]!.first,
          unittest.equals(arg_delegatedProjectNumber),
        );
        unittest.expect(
          queryMap["projectNumber"]!.first,
          unittest.equals(arg_projectNumber),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json
            .encode(buildIdentitytoolkitRelyingpartyGetProjectConfigResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getProjectConfig(
          delegatedProjectNumber: arg_delegatedProjectNumber,
          projectNumber: arg_projectNumber,
          $fields: arg_$fields);
      checkIdentitytoolkitRelyingpartyGetProjectConfigResponse(
          response as api.IdentitytoolkitRelyingpartyGetProjectConfigResponse);
    });

    unittest.test('method--getPublicKeys', () async {
      var mock = HttpServerMock();
      var res = api.IdentityToolkitApi(mock).relyingparty;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("identitytoolkit/v3/relyingparty/"),
        );
        pathOffset += 32;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("publicKeys"),
        );
        pathOffset += 10;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json
            .encode(buildIdentitytoolkitRelyingpartyGetPublicKeysResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getPublicKeys($fields: arg_$fields);
      checkIdentitytoolkitRelyingpartyGetPublicKeysResponse(
          response as api.IdentitytoolkitRelyingpartyGetPublicKeysResponse);
    });

    unittest.test('method--getRecaptchaParam', () async {
      var mock = HttpServerMock();
      var res = api.IdentityToolkitApi(mock).relyingparty;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("identitytoolkit/v3/relyingparty/"),
        );
        pathOffset += 32;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("getRecaptchaParam"),
        );
        pathOffset += 17;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGetRecaptchaParamResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getRecaptchaParam($fields: arg_$fields);
      checkGetRecaptchaParamResponse(response as api.GetRecaptchaParamResponse);
    });

    unittest.test('method--resetPassword', () async {
      var mock = HttpServerMock();
      var res = api.IdentityToolkitApi(mock).relyingparty;
      var arg_request = buildIdentitytoolkitRelyingpartyResetPasswordRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.IdentitytoolkitRelyingpartyResetPasswordRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkIdentitytoolkitRelyingpartyResetPasswordRequest(
            obj as api.IdentitytoolkitRelyingpartyResetPasswordRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("identitytoolkit/v3/relyingparty/"),
        );
        pathOffset += 32;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("resetPassword"),
        );
        pathOffset += 13;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildResetPasswordResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.resetPassword(arg_request, $fields: arg_$fields);
      checkResetPasswordResponse(response as api.ResetPasswordResponse);
    });

    unittest.test('method--sendVerificationCode', () async {
      var mock = HttpServerMock();
      var res = api.IdentityToolkitApi(mock).relyingparty;
      var arg_request =
          buildIdentitytoolkitRelyingpartySendVerificationCodeRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.IdentitytoolkitRelyingpartySendVerificationCodeRequest.fromJson(
                json as core.Map<core.String, core.dynamic>);
        checkIdentitytoolkitRelyingpartySendVerificationCodeRequest(
            obj as api.IdentitytoolkitRelyingpartySendVerificationCodeRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("identitytoolkit/v3/relyingparty/"),
        );
        pathOffset += 32;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("sendVerificationCode"),
        );
        pathOffset += 20;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(
            buildIdentitytoolkitRelyingpartySendVerificationCodeResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.sendVerificationCode(arg_request, $fields: arg_$fields);
      checkIdentitytoolkitRelyingpartySendVerificationCodeResponse(response
          as api.IdentitytoolkitRelyingpartySendVerificationCodeResponse);
    });

    unittest.test('method--setAccountInfo', () async {
      var mock = HttpServerMock();
      var res = api.IdentityToolkitApi(mock).relyingparty;
      var arg_request = buildIdentitytoolkitRelyingpartySetAccountInfoRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.IdentitytoolkitRelyingpartySetAccountInfoRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkIdentitytoolkitRelyingpartySetAccountInfoRequest(
            obj as api.IdentitytoolkitRelyingpartySetAccountInfoRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("identitytoolkit/v3/relyingparty/"),
        );
        pathOffset += 32;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("setAccountInfo"),
        );
        pathOffset += 14;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSetAccountInfoResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.setAccountInfo(arg_request, $fields: arg_$fields);
      checkSetAccountInfoResponse(response as api.SetAccountInfoResponse);
    });

    unittest.test('method--setProjectConfig', () async {
      var mock = HttpServerMock();
      var res = api.IdentityToolkitApi(mock).relyingparty;
      var arg_request =
          buildIdentitytoolkitRelyingpartySetProjectConfigRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.IdentitytoolkitRelyingpartySetProjectConfigRequest.fromJson(
                json as core.Map<core.String, core.dynamic>);
        checkIdentitytoolkitRelyingpartySetProjectConfigRequest(
            obj as api.IdentitytoolkitRelyingpartySetProjectConfigRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("identitytoolkit/v3/relyingparty/"),
        );
        pathOffset += 32;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("setProjectConfig"),
        );
        pathOffset += 16;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json
            .encode(buildIdentitytoolkitRelyingpartySetProjectConfigResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.setProjectConfig(arg_request, $fields: arg_$fields);
      checkIdentitytoolkitRelyingpartySetProjectConfigResponse(
          response as api.IdentitytoolkitRelyingpartySetProjectConfigResponse);
    });

    unittest.test('method--signOutUser', () async {
      var mock = HttpServerMock();
      var res = api.IdentityToolkitApi(mock).relyingparty;
      var arg_request = buildIdentitytoolkitRelyingpartySignOutUserRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.IdentitytoolkitRelyingpartySignOutUserRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkIdentitytoolkitRelyingpartySignOutUserRequest(
            obj as api.IdentitytoolkitRelyingpartySignOutUserRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("identitytoolkit/v3/relyingparty/"),
        );
        pathOffset += 32;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("signOutUser"),
        );
        pathOffset += 11;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json
            .encode(buildIdentitytoolkitRelyingpartySignOutUserResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.signOutUser(arg_request, $fields: arg_$fields);
      checkIdentitytoolkitRelyingpartySignOutUserResponse(
          response as api.IdentitytoolkitRelyingpartySignOutUserResponse);
    });

    unittest.test('method--signupNewUser', () async {
      var mock = HttpServerMock();
      var res = api.IdentityToolkitApi(mock).relyingparty;
      var arg_request = buildIdentitytoolkitRelyingpartySignupNewUserRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.IdentitytoolkitRelyingpartySignupNewUserRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkIdentitytoolkitRelyingpartySignupNewUserRequest(
            obj as api.IdentitytoolkitRelyingpartySignupNewUserRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("identitytoolkit/v3/relyingparty/"),
        );
        pathOffset += 32;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("signupNewUser"),
        );
        pathOffset += 13;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSignupNewUserResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.signupNewUser(arg_request, $fields: arg_$fields);
      checkSignupNewUserResponse(response as api.SignupNewUserResponse);
    });

    unittest.test('method--uploadAccount', () async {
      var mock = HttpServerMock();
      var res = api.IdentityToolkitApi(mock).relyingparty;
      var arg_request = buildIdentitytoolkitRelyingpartyUploadAccountRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.IdentitytoolkitRelyingpartyUploadAccountRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkIdentitytoolkitRelyingpartyUploadAccountRequest(
            obj as api.IdentitytoolkitRelyingpartyUploadAccountRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("identitytoolkit/v3/relyingparty/"),
        );
        pathOffset += 32;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("uploadAccount"),
        );
        pathOffset += 13;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildUploadAccountResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.uploadAccount(arg_request, $fields: arg_$fields);
      checkUploadAccountResponse(response as api.UploadAccountResponse);
    });

    unittest.test('method--verifyAssertion', () async {
      var mock = HttpServerMock();
      var res = api.IdentityToolkitApi(mock).relyingparty;
      var arg_request =
          buildIdentitytoolkitRelyingpartyVerifyAssertionRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.IdentitytoolkitRelyingpartyVerifyAssertionRequest.fromJson(
                json as core.Map<core.String, core.dynamic>);
        checkIdentitytoolkitRelyingpartyVerifyAssertionRequest(
            obj as api.IdentitytoolkitRelyingpartyVerifyAssertionRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("identitytoolkit/v3/relyingparty/"),
        );
        pathOffset += 32;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("verifyAssertion"),
        );
        pathOffset += 15;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildVerifyAssertionResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.verifyAssertion(arg_request, $fields: arg_$fields);
      checkVerifyAssertionResponse(response as api.VerifyAssertionResponse);
    });

    unittest.test('method--verifyCustomToken', () async {
      var mock = HttpServerMock();
      var res = api.IdentityToolkitApi(mock).relyingparty;
      var arg_request =
          buildIdentitytoolkitRelyingpartyVerifyCustomTokenRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.IdentitytoolkitRelyingpartyVerifyCustomTokenRequest.fromJson(
                json as core.Map<core.String, core.dynamic>);
        checkIdentitytoolkitRelyingpartyVerifyCustomTokenRequest(
            obj as api.IdentitytoolkitRelyingpartyVerifyCustomTokenRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("identitytoolkit/v3/relyingparty/"),
        );
        pathOffset += 32;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("verifyCustomToken"),
        );
        pathOffset += 17;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildVerifyCustomTokenResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.verifyCustomToken(arg_request, $fields: arg_$fields);
      checkVerifyCustomTokenResponse(response as api.VerifyCustomTokenResponse);
    });

    unittest.test('method--verifyPassword', () async {
      var mock = HttpServerMock();
      var res = api.IdentityToolkitApi(mock).relyingparty;
      var arg_request = buildIdentitytoolkitRelyingpartyVerifyPasswordRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.IdentitytoolkitRelyingpartyVerifyPasswordRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkIdentitytoolkitRelyingpartyVerifyPasswordRequest(
            obj as api.IdentitytoolkitRelyingpartyVerifyPasswordRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("identitytoolkit/v3/relyingparty/"),
        );
        pathOffset += 32;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("verifyPassword"),
        );
        pathOffset += 14;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildVerifyPasswordResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.verifyPassword(arg_request, $fields: arg_$fields);
      checkVerifyPasswordResponse(response as api.VerifyPasswordResponse);
    });

    unittest.test('method--verifyPhoneNumber', () async {
      var mock = HttpServerMock();
      var res = api.IdentityToolkitApi(mock).relyingparty;
      var arg_request =
          buildIdentitytoolkitRelyingpartyVerifyPhoneNumberRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.IdentitytoolkitRelyingpartyVerifyPhoneNumberRequest.fromJson(
                json as core.Map<core.String, core.dynamic>);
        checkIdentitytoolkitRelyingpartyVerifyPhoneNumberRequest(
            obj as api.IdentitytoolkitRelyingpartyVerifyPhoneNumberRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("identitytoolkit/v3/relyingparty/"),
        );
        pathOffset += 32;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("verifyPhoneNumber"),
        );
        pathOffset += 17;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(
            buildIdentitytoolkitRelyingpartyVerifyPhoneNumberResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.verifyPhoneNumber(arg_request, $fields: arg_$fields);
      checkIdentitytoolkitRelyingpartyVerifyPhoneNumberResponse(
          response as api.IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse);
    });
  });
}
