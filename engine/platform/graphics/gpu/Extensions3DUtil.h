// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef Extensions3DUtil_h
#define Extensions3DUtil_h

#include "sky/engine/platform/PlatformExport.h"
#include "sky/engine/platform/graphics/GraphicsTypes3D.h"
#include "sky/engine/wtf/HashSet.h"
#include "sky/engine/wtf/text/WTFString.h"
#include "third_party/khronos/GLES2/gl2.h"
#include "third_party/khronos/GLES2/gl2ext.h"

namespace blink {

class WebGraphicsContext3D;

class PLATFORM_EXPORT Extensions3DUtil {
public:
    // Creates a new Extensions3DUtil. If the passed WebGraphicsContext3D has been spontaneously lost, returns null.
    static PassOwnPtr<Extensions3DUtil> create(WebGraphicsContext3D*);
    ~Extensions3DUtil();

    bool supportsExtension(const String& name);
    bool ensureExtensionEnabled(const String& name);
    bool isExtensionEnabled(const String& name);

    static bool canUseCopyTextureCHROMIUM(GLenum destFormat, GLenum destType, GLint level);

private:
    Extensions3DUtil(WebGraphicsContext3D*);
    bool initializeExtensions();

    WebGraphicsContext3D* m_context;
    HashSet<String> m_enabledExtensions;
    HashSet<String> m_requestableExtensions;
};

} // namespace blink

#endif // Extensions3DUtil_h
