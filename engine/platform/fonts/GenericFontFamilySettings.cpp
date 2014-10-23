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

#include "config.h"
#include "platform/fonts/GenericFontFamilySettings.h"

namespace blink {

GenericFontFamilySettings::GenericFontFamilySettings(const GenericFontFamilySettings& other)
    : m_standardFontFamilyMap(other.m_standardFontFamilyMap)
    , m_serifFontFamilyMap(other.m_serifFontFamilyMap)
    , m_fixedFontFamilyMap(other.m_fixedFontFamilyMap)
    , m_sansSerifFontFamilyMap(other.m_sansSerifFontFamilyMap)
    , m_cursiveFontFamilyMap(other.m_cursiveFontFamilyMap)
    , m_fantasyFontFamilyMap(other.m_fantasyFontFamilyMap)
    , m_pictographFontFamilyMap(other.m_pictographFontFamilyMap)
{
}

GenericFontFamilySettings& GenericFontFamilySettings::operator=(const GenericFontFamilySettings& other)
{
    m_standardFontFamilyMap = other.m_standardFontFamilyMap;
    m_serifFontFamilyMap = other.m_serifFontFamilyMap;
    m_fixedFontFamilyMap = other.m_fixedFontFamilyMap;
    m_sansSerifFontFamilyMap = other.m_sansSerifFontFamilyMap;
    m_cursiveFontFamilyMap = other.m_cursiveFontFamilyMap;
    m_fantasyFontFamilyMap = other.m_fantasyFontFamilyMap;
    m_pictographFontFamilyMap = other.m_pictographFontFamilyMap;
    return *this;
}

// Sets the entry in the font map for the given script. If family is the empty string, removes the entry instead.
void GenericFontFamilySettings::setGenericFontFamilyMap(ScriptFontFamilyMap& fontMap, const AtomicString& family, UScriptCode script)
{
    ScriptFontFamilyMap::iterator it = fontMap.find(static_cast<int>(script));
    if (family.isEmpty()) {
        if (it == fontMap.end())
            return;
        fontMap.remove(it);
    } else if (it != fontMap.end() && it->value == family) {
        return;
    } else {
        fontMap.set(static_cast<int>(script), family);
    }
}

const AtomicString& GenericFontFamilySettings::genericFontFamilyForScript(const ScriptFontFamilyMap& fontMap, UScriptCode script) const
{
    ScriptFontFamilyMap::const_iterator it = fontMap.find(static_cast<int>(script));
    if (it != fontMap.end())
        return it->value;
    if (script != USCRIPT_COMMON)
        return genericFontFamilyForScript(fontMap, USCRIPT_COMMON);
    return emptyAtom;
}

const AtomicString& GenericFontFamilySettings::standard(UScriptCode script) const
{
    return genericFontFamilyForScript(m_standardFontFamilyMap, script);
}

bool GenericFontFamilySettings::updateStandard(const AtomicString& family, UScriptCode script)
{
    if (family == standard())
        return false;
    setGenericFontFamilyMap(m_standardFontFamilyMap, family, script);
    return true;
}

const AtomicString& GenericFontFamilySettings::fixed(UScriptCode script) const
{
    return genericFontFamilyForScript(m_fixedFontFamilyMap, script);
}

bool GenericFontFamilySettings::updateFixed(const AtomicString& family, UScriptCode script)
{
    if (family == fixed())
        return false;
    setGenericFontFamilyMap(m_fixedFontFamilyMap, family, script);
    return true;
}

const AtomicString& GenericFontFamilySettings::serif(UScriptCode script) const
{
    return genericFontFamilyForScript(m_serifFontFamilyMap, script);
}

bool GenericFontFamilySettings::updateSerif(const AtomicString& family, UScriptCode script)
{
    if (family == serif())
        return false;
    setGenericFontFamilyMap(m_serifFontFamilyMap, family, script);
    return true;
}

const AtomicString& GenericFontFamilySettings::sansSerif(UScriptCode script) const
{
    return genericFontFamilyForScript(m_sansSerifFontFamilyMap, script);
}

bool GenericFontFamilySettings::updateSansSerif(const AtomicString& family, UScriptCode script)
{
    if (family == sansSerif())
        return false;
    setGenericFontFamilyMap(m_sansSerifFontFamilyMap, family, script);
    return true;
}

const AtomicString& GenericFontFamilySettings::cursive(UScriptCode script) const
{
    return genericFontFamilyForScript(m_cursiveFontFamilyMap, script);
}

bool GenericFontFamilySettings::updateCursive(const AtomicString& family, UScriptCode script)
{
    if (family == cursive())
        return false;
    setGenericFontFamilyMap(m_cursiveFontFamilyMap, family, script);
    return true;
}

const AtomicString& GenericFontFamilySettings::fantasy(UScriptCode script) const
{
    return genericFontFamilyForScript(m_fantasyFontFamilyMap, script);
}

bool GenericFontFamilySettings::updateFantasy(const AtomicString& family, UScriptCode script)
{
    if (family == fantasy())
        return false;
    setGenericFontFamilyMap(m_fantasyFontFamilyMap, family, script);
    return true;
}

const AtomicString& GenericFontFamilySettings::pictograph(UScriptCode script) const
{
    return genericFontFamilyForScript(m_pictographFontFamilyMap, script);
}

bool GenericFontFamilySettings::updatePictograph(const AtomicString& family, UScriptCode script)
{
    if (family == pictograph())
        return false;
    setGenericFontFamilyMap(m_pictographFontFamilyMap, family, script);
    return true;
}

void GenericFontFamilySettings::reset()
{
    m_standardFontFamilyMap.clear();
    m_serifFontFamilyMap.clear();
    m_fixedFontFamilyMap.clear();
    m_sansSerifFontFamilyMap.clear();
    m_cursiveFontFamilyMap.clear();
    m_fantasyFontFamilyMap.clear();
    m_pictographFontFamilyMap.clear();
}

} // namespace blink
