// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'webgl1.dart';

@JS('OVR_multiview2')
@staticInterop
class OVR_multiview2 {
  external static GLenum get FRAMEBUFFER_ATTACHMENT_TEXTURE_NUM_VIEWS_OVR;
  external static GLenum get FRAMEBUFFER_ATTACHMENT_TEXTURE_BASE_VIEW_INDEX_OVR;
  external static GLenum get MAX_VIEWS_OVR;
  external static GLenum get FRAMEBUFFER_INCOMPLETE_VIEW_TARGETS_OVR;
}

extension OVRMultiview2Extension on OVR_multiview2 {
  external void framebufferTextureMultiviewOVR(
    GLenum target,
    GLenum attachment,
    WebGLTexture? texture,
    GLint level,
    GLint baseViewIndex,
    GLsizei numViews,
  );
}
