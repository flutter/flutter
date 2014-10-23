// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FetchUtils_h
#define FetchUtils_h

#include "wtf/Forward.h"

namespace blink {

class HTTPHeaderMap;

class FetchUtils {
public:
    static bool isSimpleMethod(const String& method);
    static bool isSimpleHeader(const AtomicString& name, const AtomicString& value);
    static bool isSimpleRequest(const String& method, const HTTPHeaderMap&);
    static bool isForbiddenMethod(const String& method);
    static bool isUsefulMethod(const String& method) { return !isForbiddenMethod(method); }
    static bool isForbiddenHeaderName(const String& name);
    static bool isForbiddenResponseHeaderName(const String& name);
    static bool isSimpleOrForbiddenRequest(const String& method, const HTTPHeaderMap&);

private:
    FetchUtils(); // = delete;
};

} // namespace blink

#endif
