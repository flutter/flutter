/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

#ifndef WebEntities_h
#define WebEntities_h

#include "wtf/HashMap.h"
#include "wtf/text/WTFString.h"

namespace blink {

// FIXME: This class is wrong and needs to be removed!
class WebEntities {
public:
    // &apos;, &percnt;, &nsup;, &supl; are not defined by the HTML standards.
    //  - IE does not support &apos; as an HTML entity (but support it as an XML
    //    entity.)
    //  - Firefox supports &apos; as an HTML entity.
    //  - Both of IE and Firefox don't support &percnt;, &nsup; and &supl;.
    //
    // A web page saved by Chromium should be able to be read by other browsers
    // such as IE and Firefox.  Chromium should produce only the standard entity
    // references which other browsers can recognize.
    // So if standard_html_entities_ is true, we will use a numeric character
    // reference for &apos;, and don't use entity references for &percnt;, &nsup;
    // and &supl; for serialization.
    //
    // If xmlEntities is true, WebEntities will only contain standard XML
    // entities.
    explicit WebEntities(bool xmlEntities);

    // Check whether specified unicode has corresponding html or xml built-in
    // entity name. If yes, return the entity notation. If not, returns an
    // empty string. Parameter isHTML indicates check the code in html entity
    // map or in xml entity map.
    WTF::String entityNameByCode(int code) const;

    // Returns a new string with corresponding entity names replaced.
    WTF::String convertEntitiesInString(const WTF::String&) const;
private:
    typedef HashMap<int, WTF::String> EntitiesMapType;
    // An internal object that maps the Unicode character to corresponding
    // entity notation.
    EntitiesMapType m_entitiesMap;
};

} // namespace blink

#endif
