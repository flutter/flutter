/*
 * Copyright (C) 2003, 2006, 2007, 2008, 2009, 2011, 2012 Apple Inc. All rights reserved.
 *           (C) 2006 Graham Dennis (graham.dennis@gmail.com)
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef Settings_h
#define Settings_h

#include "gen/sky/core/SettingsMacros.h"
#include "sky/engine/bindings/core/v8/V8CacheOptions.h"
#include "sky/engine/core/css/PointerProperties.h"
#include "sky/engine/core/frame/SettingsDelegate.h"
#include "sky/engine/platform/Timer.h"
#include "sky/engine/platform/fonts/GenericFontFamilySettings.h"
#include "sky/engine/platform/geometry/IntSize.h"
#include "sky/engine/platform/weborigin/KURL.h"
#include "sky/engine/wtf/HashSet.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {

class Settings {
    WTF_MAKE_NONCOPYABLE(Settings); WTF_MAKE_FAST_ALLOCATED;
public:
    static PassOwnPtr<Settings> create();

    GenericFontFamilySettings& genericFontFamilySettings() { return m_genericFontFamilySettings; }
    void notifyGenericFontFamilyChange() { invalidate(SettingsDelegate::FontFamilyChange); }

    SETTINGS_GETTERS_AND_SETTERS

    // FIXME: naming_utilities.py isn't smart enough to handle OpenGL yet.
    // It could handle "GL", but that seems a bit overly broad.
    void setOpenGLMultisamplingEnabled(bool flag);
    bool openGLMultisamplingEnabled() { return m_openGLMultisamplingEnabled; }

    void setDelegate(SettingsDelegate*);

private:
    Settings();

    void invalidate(SettingsDelegate::ChangeType);

    SettingsDelegate* m_delegate;

    GenericFontFamilySettings m_genericFontFamilySettings;
    bool m_openGLMultisamplingEnabled : 1;

    SETTINGS_MEMBER_VARIABLES
};

} // namespace blink

#endif // Settings_h
