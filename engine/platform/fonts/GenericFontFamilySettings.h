/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef GenericFontFamilySettings_h
#define GenericFontFamilySettings_h

#include "platform/PlatformExport.h"
#include "wtf/HashMap.h"
#include "wtf/text/AtomicString.h"
#include "wtf/text/AtomicStringHash.h"

#include <unicode/uscript.h>

namespace blink {

class PLATFORM_EXPORT GenericFontFamilySettings {
    WTF_MAKE_FAST_ALLOCATED;

public:
    GenericFontFamilySettings()
    {
    }

    explicit GenericFontFamilySettings(const GenericFontFamilySettings&);

    bool updateStandard(const AtomicString&, UScriptCode = USCRIPT_COMMON);
    const AtomicString& standard(UScriptCode = USCRIPT_COMMON) const;

    bool updateFixed(const AtomicString&, UScriptCode = USCRIPT_COMMON);
    const AtomicString& fixed(UScriptCode = USCRIPT_COMMON) const;

    bool updateSerif(const AtomicString&, UScriptCode = USCRIPT_COMMON);
    const AtomicString& serif(UScriptCode = USCRIPT_COMMON) const;

    bool updateSansSerif(const AtomicString&, UScriptCode = USCRIPT_COMMON);
    const AtomicString& sansSerif(UScriptCode = USCRIPT_COMMON) const;

    bool updateCursive(const AtomicString&, UScriptCode = USCRIPT_COMMON);
    const AtomicString& cursive(UScriptCode = USCRIPT_COMMON) const;

    bool updateFantasy(const AtomicString&, UScriptCode = USCRIPT_COMMON);
    const AtomicString& fantasy(UScriptCode = USCRIPT_COMMON) const;

    bool updatePictograph(const AtomicString&, UScriptCode = USCRIPT_COMMON);
    const AtomicString& pictograph(UScriptCode = USCRIPT_COMMON) const;

    // Only called by InternalSettings to clear font family maps.
    void reset();

    GenericFontFamilySettings& operator=(const GenericFontFamilySettings&);

private:
    // UScriptCode uses -1 and 0 for UScriptInvalidCode and UScriptCommon.
    // We need to use -2 and -3 for empty value and deleted value.
    struct UScriptCodeHashTraits : WTF::GenericHashTraits<int> {
        static const bool emptyValueIsZero = false;
        static int emptyValue() { return -2; }
        static void constructDeletedValue(int& slot, bool) { slot = -3; }
        static bool isDeletedValue(int value) { return value == -3; }
    };

    typedef HashMap<int, AtomicString, DefaultHash<int>::Hash, UScriptCodeHashTraits> ScriptFontFamilyMap;

    void setGenericFontFamilyMap(ScriptFontFamilyMap&, const AtomicString&, UScriptCode);
    const AtomicString& genericFontFamilyForScript(const ScriptFontFamilyMap&, UScriptCode) const;

    ScriptFontFamilyMap m_standardFontFamilyMap;
    ScriptFontFamilyMap m_serifFontFamilyMap;
    ScriptFontFamilyMap m_fixedFontFamilyMap;
    ScriptFontFamilyMap m_sansSerifFontFamilyMap;
    ScriptFontFamilyMap m_cursiveFontFamilyMap;
    ScriptFontFamilyMap m_fantasyFontFamilyMap;
    ScriptFontFamilyMap m_pictographFontFamilyMap;
};

} // namespace blink

#endif
