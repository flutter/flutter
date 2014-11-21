/*
 * Copyright (C) 2010 Apple Inc. All Rights Reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE, INC. ``AS IS'' AND ANY
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
 *
 */

#ifndef SKY_ENGINE_PLATFORM_WEBORIGIN_SCHEMEREGISTRY_H_
#define SKY_ENGINE_PLATFORM_WEBORIGIN_SCHEMEREGISTRY_H_

#include "sky/engine/platform/PlatformExport.h"
#include "sky/engine/wtf/HashSet.h"
#include "sky/engine/wtf/text/StringHash.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {

typedef HashSet<String, CaseFoldingHash> URLSchemesMap;

class PLATFORM_EXPORT SchemeRegistry {
public:
    static void registerURLSchemeAsLocal(const String&);
    static void removeURLSchemeRegisteredAsLocal(const String&);
    static const URLSchemesMap& localSchemes();

    static bool shouldTreatURLSchemeAsLocal(const String&);

    // Secure schemes do not trigger mixed content warnings. For example,
    // https and data are secure schemes because they cannot be corrupted by
    // active network attackers.
    static void registerURLSchemeAsSecure(const String&);
    static bool shouldTreatURLSchemeAsSecure(const String&);

    static void registerURLSchemeAsNoAccess(const String&);
    static bool shouldTreatURLSchemeAsNoAccess(const String&);

    // Display-isolated schemes can only be displayed (in the sense of
    // SecurityOrigin::canDisplay) by documents from the same scheme.
    static void registerURLSchemeAsDisplayIsolated(const String&);
    static bool shouldTreatURLSchemeAsDisplayIsolated(const String&);

    static void registerURLSchemeAsEmptyDocument(const String&);
    static bool shouldLoadURLSchemeAsEmptyDocument(const String&);

    static void setDomainRelaxationForbiddenForURLScheme(bool forbidden, const String&);
    static bool isDomainRelaxationForbiddenForURLScheme(const String&);

    // Such schemes should delegate to SecurityOrigin::canRequest for any URL
    // passed to SecurityOrigin::canDisplay.
    static bool canDisplayOnlyIfCanRequest(const String& scheme);
    static void registerAsCanDisplayOnlyIfCanRequest(const String& scheme);

    // Allow non-HTTP schemes to be registered to allow CORS requests.
    static void registerURLSchemeAsCORSEnabled(const String& scheme);
    static bool shouldTreatURLSchemeAsCORSEnabled(const String& scheme);

    // Serialize the registered schemes in a comma-separated list.
    static String listOfCORSEnabledURLSchemes();
};

} // namespace blink

#endif  // SKY_ENGINE_PLATFORM_WEBORIGIN_SCHEMEREGISTRY_H_
