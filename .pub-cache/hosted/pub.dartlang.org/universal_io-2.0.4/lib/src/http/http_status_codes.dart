// ------------------------------------------------------------------
// THIS FILE WAS DERIVED FROM SOURCE CODE UNDER THE FOLLOWING LICENSE
// ------------------------------------------------------------------
//
// Copyright 2012, the Dart project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ---------------------------------------------------------
// THIS, DERIVED FILE IS LICENSE UNDER THE FOLLOWING LICENSE
// ---------------------------------------------------------
// Copyright 2020 terrier989@gmail.com.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// HTTP status codes.
abstract class HttpStatus {
  static const int continue_ = 100;
  static const int switchingProtocols = 101;
  static const int processing = 102;
  static const int ok = 200;
  static const int created = 201;
  static const int accepted = 202;
  static const int nonAuthoritativeInformation = 203;
  static const int noContent = 204;
  static const int resetContent = 205;
  static const int partialContent = 206;
  static const int multiStatus = 207;
  static const int alreadyReported = 208;
  static const int imUsed = 226;
  static const int multipleChoices = 300;
  static const int movedPermanently = 301;
  static const int found = 302;
  static const int movedTemporarily = 302; // Common alias for found.
  static const int seeOther = 303;
  static const int notModified = 304;
  static const int useProxy = 305;
  static const int temporaryRedirect = 307;
  static const int permanentRedirect = 308;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int paymentRequired = 402;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int methodNotAllowed = 405;
  static const int notAcceptable = 406;
  static const int proxyAuthenticationRequired = 407;
  static const int requestTimeout = 408;
  static const int conflict = 409;
  static const int gone = 410;
  static const int lengthRequired = 411;
  static const int preconditionFailed = 412;
  static const int requestEntityTooLarge = 413;
  static const int requestUriTooLong = 414;
  static const int unsupportedMediaType = 415;
  static const int requestedRangeNotSatisfiable = 416;
  static const int expectationFailed = 417;
  static const int misdirectedRequest = 421;
  static const int unprocessableEntity = 422;
  static const int locked = 423;
  static const int failedDependency = 424;
  static const int upgradeRequired = 426;
  static const int preconditionRequired = 428;
  static const int tooManyRequests = 429;
  static const int requestHeaderFieldsTooLarge = 431;
  static const int connectionClosedWithoutResponse = 444;
  static const int unavailableForLegalReasons = 451;
  static const int clientClosedRequest = 499;
  static const int internalServerError = 500;
  static const int notImplemented = 501;
  static const int badGateway = 502;
  static const int serviceUnavailable = 503;
  static const int gatewayTimeout = 504;
  static const int httpVersionNotSupported = 505;
  static const int variantAlsoNegotiates = 506;
  static const int insufficientStorage = 507;
  static const int loopDetected = 508;
  static const int notExtended = 510;
  static const int networkAuthenticationRequired = 511;

  // Client generated status code.
  static const int networkConnectTimeoutError = 599;

  @Deprecated('Use continue_ instead')
  static const int CONTINUE = continue_;
  @Deprecated('Use switchingProtocols instead')
  static const int SWITCHING_PROTOCOLS = switchingProtocols;
  @Deprecated('Use ok instead')
  static const int OK = ok;
  @Deprecated('Use created instead')
  static const int CREATED = created;
  @Deprecated('Use accepted instead')
  static const int ACCEPTED = accepted;
  @Deprecated('Use nonAuthoritativeInformation instead')
  static const int NON_AUTHORITATIVE_INFORMATION = nonAuthoritativeInformation;
  @Deprecated('Use noContent instead')
  static const int NO_CONTENT = noContent;
  @Deprecated('Use resetContent instead')
  static const int RESET_CONTENT = resetContent;
  @Deprecated('Use partialContent instead')
  static const int PARTIAL_CONTENT = partialContent;
  @Deprecated('Use multipleChoices instead')
  static const int MULTIPLE_CHOICES = multipleChoices;
  @Deprecated('Use movedPermanently instead')
  static const int MOVED_PERMANENTLY = movedPermanently;
  @Deprecated('Use found instead')
  static const int FOUND = found;
  @Deprecated('Use movedTemporarily instead')
  static const int MOVED_TEMPORARILY = movedTemporarily;
  @Deprecated('Use seeOther instead')
  static const int SEE_OTHER = seeOther;
  @Deprecated('Use notModified instead')
  static const int NOT_MODIFIED = notModified;
  @Deprecated('Use useProxy instead')
  static const int USE_PROXY = useProxy;
  @Deprecated('Use temporaryRedirect instead')
  static const int TEMPORARY_REDIRECT = temporaryRedirect;
  @Deprecated('Use badRequest instead')
  static const int BAD_REQUEST = badRequest;
  @Deprecated('Use unauthorized instead')
  static const int UNAUTHORIZED = unauthorized;
  @Deprecated('Use paymentRequired instead')
  static const int PAYMENT_REQUIRED = paymentRequired;
  @Deprecated('Use forbidden instead')
  static const int FORBIDDEN = forbidden;
  @Deprecated('Use notFound instead')
  static const int NOT_FOUND = notFound;
  @Deprecated('Use methodNotAllowed instead')
  static const int METHOD_NOT_ALLOWED = methodNotAllowed;
  @Deprecated('Use notAcceptable instead')
  static const int NOT_ACCEPTABLE = notAcceptable;
  @Deprecated('Use proxyAuthenticationRequired instead')
  static const int PROXY_AUTHENTICATION_REQUIRED = proxyAuthenticationRequired;
  @Deprecated('Use requestTimeout instead')
  static const int REQUEST_TIMEOUT = requestTimeout;
  @Deprecated('Use conflict instead')
  static const int CONFLICT = conflict;
  @Deprecated('Use gone instead')
  static const int GONE = gone;
  @Deprecated('Use lengthRequired instead')
  static const int LENGTH_REQUIRED = lengthRequired;
  @Deprecated('Use preconditionFailed instead')
  static const int PRECONDITION_FAILED = preconditionFailed;
  @Deprecated('Use requestEntityTooLarge instead')
  static const int REQUEST_ENTITY_TOO_LARGE = requestEntityTooLarge;
  @Deprecated('Use requestUriTooLong instead')
  static const int REQUEST_URI_TOO_LONG = requestUriTooLong;
  @Deprecated('Use unsupportedMediaType instead')
  static const int UNSUPPORTED_MEDIA_TYPE = unsupportedMediaType;
  @Deprecated('Use requestedRangeNotSatisfiable instead')
  static const int REQUESTED_RANGE_NOT_SATISFIABLE =
      requestedRangeNotSatisfiable;
  @Deprecated('Use expectationFailed instead')
  static const int EXPECTATION_FAILED = expectationFailed;
  @Deprecated('Use upgradeRequired instead')
  static const int UPGRADE_REQUIRED = upgradeRequired;
  @Deprecated('Use internalServerError instead')
  static const int INTERNAL_SERVER_ERROR = internalServerError;
  @Deprecated('Use notImplemented instead')
  static const int NOT_IMPLEMENTED = notImplemented;
  @Deprecated('Use badGateway instead')
  static const int BAD_GATEWAY = badGateway;
  @Deprecated('Use serviceUnavailable instead')
  static const int SERVICE_UNAVAILABLE = serviceUnavailable;
  @Deprecated('Use gatewayTimeout instead')
  static const int GATEWAY_TIMEOUT = gatewayTimeout;
  @Deprecated('Use httpVersionNotSupported instead')
  static const int HTTP_VERSION_NOT_SUPPORTED = httpVersionNotSupported;
  @Deprecated('Use networkConnectTimeoutError instead')
  static const int NETWORK_CONNECT_TIMEOUT_ERROR = networkConnectTimeoutError;
}
