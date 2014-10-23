// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/fetch/FetchUtils.h"

#include "platform/network/HTTPHeaderMap.h"
#include "platform/network/HTTPParsers.h"
#include "wtf/HashSet.h"
#include "wtf/Threading.h"
#include "wtf/text/AtomicString.h"
#include "wtf/text/WTFString.h"

namespace blink {

namespace {

class ForbiddenHeaderNames {
    WTF_MAKE_NONCOPYABLE(ForbiddenHeaderNames); WTF_MAKE_FAST_ALLOCATED;
public:
    bool has(const String& name) const
    {
        return m_fixedNames.contains(name)
            || name.startsWith(m_proxyHeaderPrefix, false)
            || name.startsWith(m_secHeaderPrefix, false);
    }

    static const ForbiddenHeaderNames* get();

private:
    ForbiddenHeaderNames();

    String m_proxyHeaderPrefix;
    String m_secHeaderPrefix;
    HashSet<String, CaseFoldingHash> m_fixedNames;
};

ForbiddenHeaderNames::ForbiddenHeaderNames()
    : m_proxyHeaderPrefix("proxy-")
    , m_secHeaderPrefix("sec-")
{
    m_fixedNames.add("accept-charset");
    m_fixedNames.add("accept-encoding");
    m_fixedNames.add("access-control-request-headers");
    m_fixedNames.add("access-control-request-method");
    m_fixedNames.add("connection");
    m_fixedNames.add("content-length");
    m_fixedNames.add("cookie");
    m_fixedNames.add("cookie2");
    m_fixedNames.add("date");
    m_fixedNames.add("dnt");
    m_fixedNames.add("expect");
    m_fixedNames.add("host");
    m_fixedNames.add("keep-alive");
    m_fixedNames.add("origin");
    m_fixedNames.add("referer");
    m_fixedNames.add("te");
    m_fixedNames.add("trailer");
    m_fixedNames.add("transfer-encoding");
    m_fixedNames.add("upgrade");
    m_fixedNames.add("user-agent");
    m_fixedNames.add("via");
}

const ForbiddenHeaderNames* ForbiddenHeaderNames::get()
{
    AtomicallyInitializedStatic(const ForbiddenHeaderNames*, instance = new ForbiddenHeaderNames);
    return instance;
}

} // namespace

bool FetchUtils::isSimpleMethod(const String& method)
{
    // http://fetch.spec.whatwg.org/#simple-method
    // "A simple method is a method that is `GET`, `HEAD`, or `POST`."
    return method == "GET" || method == "HEAD" || method == "POST";
}

bool FetchUtils::isSimpleHeader(const AtomicString& name, const AtomicString& value)
{
    // http://fetch.spec.whatwg.org/#simple-header
    // "A simple header is a header whose name is either one of `Accept`,
    // `Accept-Language`, and `Content-Language`, or whose name is
    // `Content-Type` and value, once parsed, is one of
    // `application/x-www-form-urlencoded`, `multipart/form-data`, and
    // `text/plain`."

    if (equalIgnoringCase(name, "accept")
        || equalIgnoringCase(name, "accept-language")
        || equalIgnoringCase(name, "content-language"))
        return true;

    if (equalIgnoringCase(name, "content-type")) {
        AtomicString mimeType = extractMIMETypeFromMediaType(value);
        return equalIgnoringCase(mimeType, "application/x-www-form-urlencoded")
            || equalIgnoringCase(mimeType, "multipart/form-data")
            || equalIgnoringCase(mimeType, "text/plain");
    }

    return false;
}

bool FetchUtils::isSimpleRequest(const String& method, const HTTPHeaderMap& headerMap)
{
    if (!isSimpleMethod(method))
        return false;

    HTTPHeaderMap::const_iterator end = headerMap.end();
    for (HTTPHeaderMap::const_iterator it = headerMap.begin(); it != end; ++it) {
        // Preflight is required for MIME types that can not be sent via form
        // submission.
        if (!isSimpleHeader(it->key, it->value))
            return false;
    }

    return true;
}

bool FetchUtils::isForbiddenMethod(const String& method)
{
    // http://fetch.spec.whatwg.org/#forbidden-method
    // "A forbidden method is a method that is a byte case-insensitive match"
    //  for one of `CONNECT`, `TRACE`, and `TRACK`."
    return equalIgnoringCase(method, "TRACE")
        || equalIgnoringCase(method, "TRACK")
        || equalIgnoringCase(method, "CONNECT");
}

bool FetchUtils::isForbiddenHeaderName(const String& name)
{
    // http://fetch.spec.whatwg.org/#forbidden-header-name
    // "A forbidden header name is a header names that is one of:
    //   `Accept-Charset`, `Accept-Encoding`, `Access-Control-Request-Headers`,
    //   `Access-Control-Request-Method`, `Connection`,
    //   `Content-Length, Cookie`, `Cookie2`, `Date`, `DNT`, `Expect`, `Host`,
    //   `Keep-Alive`, `Origin`, `Referer`, `TE`, `Trailer`,
    //   `Transfer-Encoding`, `Upgrade`, `User-Agent`, `Via`
    // or starts with `Proxy-` or `Sec-` (including when it is just `Proxy-` or
    // `Sec-`)."

    return ForbiddenHeaderNames::get()->has(name);
}

bool FetchUtils::isForbiddenResponseHeaderName(const String& name)
{
    // http://fetch.spec.whatwg.org/#forbidden-response-header-name
    // "A forbidden response header name is a header name that is one of:
    // `Set-Cookie`, `Set-Cookie2`"

    return equalIgnoringCase(name, "set-cookie") || equalIgnoringCase(name, "set-cookie2");
}

bool FetchUtils::isSimpleOrForbiddenRequest(const String& method, const HTTPHeaderMap& headerMap)
{
    if (!isSimpleMethod(method))
        return false;

    HTTPHeaderMap::const_iterator end = headerMap.end();
    for (HTTPHeaderMap::const_iterator it = headerMap.begin(); it != end; ++it) {
        if (!isSimpleHeader(it->key, it->value) && !isForbiddenHeaderName(it->key))
            return false;
    }

    return true;
}

} // namespace blink
