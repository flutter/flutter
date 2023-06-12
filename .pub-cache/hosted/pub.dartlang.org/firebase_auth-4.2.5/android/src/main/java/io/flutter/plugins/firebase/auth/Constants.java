/*
 * Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */

package io.flutter.plugins.firebase.auth;

public class Constants {

  // Base
  public static final String TAG = "FLTFirebaseAuthPlugin";
  public static final String ANDROID = "android";
  public static final String IOS = "iOS";
  public static final String MINIMUM_VERSION = "minimumVersion";
  public static final String INSTALL_APP = "installApp";
  public static final String PACKAGE_NAME = "packageName";
  public static final String BUNDLE_ID = "bundleId";
  public static final String APP_NAME = "appName";

  // Providers
  public static final String SIGN_IN_METHOD_PASSWORD = "password";
  public static final String SIGN_IN_METHOD_EMAIL_LINK = "emailLink";
  public static final String SIGN_IN_METHOD_FACEBOOK = "facebook.com";
  public static final String SIGN_IN_METHOD_GOOGLE = "google.com";
  public static final String SIGN_IN_METHOD_TWITTER = "twitter.com";
  public static final String SIGN_IN_METHOD_GITHUB = "github.com";
  public static final String SIGN_IN_METHOD_PHONE = "phone";
  public static final String SIGN_IN_METHOD_OAUTH = "oauth";

  // User
  public static final String USER = "user";
  public static final String EMAIL = "email";
  public static final String NEW_EMAIL = "newEmail";
  public static final String UID = "uid";
  public static final String USERNAME = "username";
  public static final String PASSWORD = "password";
  public static final String NEW_PASSWORD = "newPassword";
  public static final String PREVIOUS_EMAIL = "previousEmail";
  public static final String EMAIL_VERIFIED = "emailVerified";
  public static final String IS_ANONYMOUS = "isAnonymous";
  public static final String IS_NEW_USER = "isNewUser";
  public static final String METADATA = "metadata";
  public static final String DISPLAY_NAME = "displayName";
  public static final String PHONE_NUMBER = "phoneNumber";
  public static final String PHOTO_URL = "photoURL";
  public static final String PROFILE = "profile";
  public static final String ADDITIONAL_USER_INFO = "additionalUserInfo";
  public static final String CREATION_TIME = "creationTime";
  public static final String LAST_SIGN_IN_TIME = "lastSignInTime";
  public static final String TENANT_ID = "tenantId";

  // Auth
  public static final String PROVIDERS = "providers";
  public static final String PROVIDER_ID = "providerId";
  public static final String PROVIDER_DATA = "providerData";
  public static final String AUTH_CREDENTIAL = "authCredential";
  public static final String CREDENTIAL = "credential";
  public static final String SECRET = "secret";
  public static final String REFRESH_TOKEN = "refreshToken";
  public static final String ID_TOKEN = "idToken";
  public static final String TOKEN = "token";
  public static final String ACCESS_TOKEN = "accessToken";
  public static final String CODE = "code";
  public static final String RAW_NONCE = "rawNonce";
  public static final String EMAIL_LINK = "emailLink";
  public static final String VERIFICATION_ID = "verificationId";
  public static final String SMS_CODE = "smsCode";
  public static final String URL = "url";
  public static final String DYNAMIC_LINK_DOMAIN = "dynamicLinkDomain";
  public static final String LANGUAGE_CODE = "languageCode";
  public static final String CLAIMS = "claims";
  public static final String TIMEOUT = "timeout";
  public static final String AUTH_TIMESTAMP = "authTimestamp";
  public static final String EXPIRATION_TIMESTAMP = "expirationTimestamp";
  public static final String ISSUED_AT_TIMESTAMP = "issuedAtTimestamp";
  public static final String SIGN_IN_METHOD = "signInMethod";
  public static final String SIGN_IN_PROVIDER = "signInProvider";
  public static final String SIGN_IN_PROVIDER_SCOPE = "scopes";
  public static final String SIGN_IN_PROVIDER_CUSTOM_PARAMETERS = "customParameters";
  public static final String SIGN_IN_SECOND_FACTOR = "signInSecondFactor";
  public static final String FORCE_RESENDING_TOKEN = "forceResendingToken";
  public static final String FORCE_REFRESH = "forceRefresh";
  public static final String TOKEN_ONLY = "tokenOnly";
  public static final String HANDLE_CODE_IN_APP = "handleCodeInApp";
  public static final String ACTION_CODE_SETTINGS = "actionCodeSettings";
  public static final String AUTO_RETRIEVED_SMS_CODE_FOR_TESTING = "autoRetrievedSmsCodeForTesting";
  public static final String HOST = "host";
  public static final String PORT = "port";
  public static final String NAME = "name";
  public static final String APP_VERIFICATION_DISABLED_FOR_TESTING =
      "appVerificationDisabledForTesting";
  public static final String FORCE_RECAPTCHA_FLOW = "forceRecaptchaFlow";

  // MultiFactor
  public static final String MULTI_FACTOR_HINTS = "multiFactorHints";
  public static final String MULTI_FACTOR_SESSION_ID = "multiFactorSessionId";
  public static final String MULTI_FACTOR_RESOLVER_ID = "multiFactorResolverId";
  public static final String MULTI_FACTOR_INFO = "multiFactorInfo";
}
