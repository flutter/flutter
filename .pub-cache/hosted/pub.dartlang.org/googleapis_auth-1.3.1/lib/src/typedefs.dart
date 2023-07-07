// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Function for directing the user or it's user-agent to [uri].
///
/// The user is required to go to [uri] and either approve or decline the
/// application's request for access resources on his behalf.
typedef PromptUserForConsent = void Function(String uri);

/// Function for directing the user or it's user-agent to [uri].
///
/// The user is required to go to [uri] and either approve or decline the
/// application's request for access resources on his behalf.
///
/// The user will be given an authorization code. This function should complete
/// with this authorization code. If the user declined to give access this
/// function should complete with an error.
typedef PromptUserForConsentManual = Future<String> Function(String uri);
