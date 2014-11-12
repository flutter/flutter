/*
 * Copyright (C) 2004, 2007, 2008, 2011, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2012 Research In Motion Limited. All rights reserved.
 * Copyright (C) 2008, 2009, 2011 Google Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
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

#include "config.h"
#include "platform/weborigin/KURL.h"

#include "platform/weborigin/KnownPorts.h"
#include "wtf/StdLibExtras.h"
#include "wtf/text/CString.h"
#include "wtf/text/StringHash.h"
#include "wtf/text/StringUTF8Adaptor.h"
#include "wtf/text/TextEncoding.h"
#include <algorithm>
#include <url/url_util.h>
#ifndef NDEBUG
#include <stdio.h>
#endif

namespace blink {

static const int maximumValidPortNumber = 0xFFFE;
static const int invalidPortNumber = 0xFFFF;

static void assertProtocolIsGood(const char* protocol)
{
#if ENABLE(ASSERT)
    const char* p = protocol;
    while (*p) {
        ASSERT(*p > ' ' && *p < 0x7F && !(*p >= 'A' && *p <= 'Z'));
        ++p;
    }
#endif
}

// Note: You must ensure that |spec| is a valid canonicalized URL before calling this function.
static const char* asURLChar8Subtle(const String& spec)
{
    ASSERT(spec.is8Bit());
    // characters8 really return characters in Latin-1, but because we canonicalize
    // URL strings, we know that everything before the fragment identifier will
    // actually be ASCII, which means this cast is safe as long as you don't look
    // at the fragment component.
    return reinterpret_cast<const char*>(spec.characters8());
}

// Returns the characters for the given string, or a pointer to a static empty
// string if the input string is null. This will always ensure we have a non-
// null character pointer since ReplaceComponents has special meaning for null.
static const char* charactersOrEmpty(const StringUTF8Adaptor& string)
{
    static const char zero = 0;
    return string.data() ? string.data() : &zero;
}

static bool isSchemeFirstChar(char c)
{
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
}

static bool isSchemeChar(char c)
{
    return isSchemeFirstChar(c) || (c >= '0' && c <= '9') || c == '.' || c == '-' || c == '+';
}

static bool isUnicodeEncoding(const WTF::TextEncoding* encoding)
{
    return encoding->encodingForFormSubmission() == UTF8Encoding();
}

namespace {

class KURLCharsetConverter FINAL : public url::CharsetConverter {
public:
    // The encoding parameter may be 0, but in this case the object must not be called.
    explicit KURLCharsetConverter(const WTF::TextEncoding* encoding)
        : m_encoding(encoding)
    {
    }

    virtual void ConvertFromUTF16(const url::UTF16Char* input, int inputLength, url::CanonOutput* output) override
    {
        CString encoded = m_encoding->normalizeAndEncode(String(input, inputLength), WTF::URLEncodedEntitiesForUnencodables);
        output->Append(encoded.data(), static_cast<int>(encoded.length()));
    }

private:
    const WTF::TextEncoding* m_encoding;
};

} // namespace

bool isValidProtocol(const String& protocol)
{
    // RFC3986: ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
    if (protocol.isEmpty())
        return false;
    if (!isSchemeFirstChar(protocol[0]))
        return false;
    unsigned protocolLength = protocol.length();
    for (unsigned i = 1; i < protocolLength; i++) {
        if (!isSchemeChar(protocol[i]))
            return false;
    }
    return true;
}

String KURL::strippedForUseAsReferrer() const
{
    if (protocolIsAbout() || protocolIs("data") || protocolIs("javascript"))
        return String();

    if (m_parsed.username.is_nonempty() || m_parsed.password.is_nonempty() || m_parsed.ref.is_nonempty()) {
        KURL referrer(*this);
        referrer.setUser(String());
        referrer.setPass(String());
        referrer.removeFragmentIdentifier();
        return referrer.string();
    }
    return string();
}

bool KURL::isLocalFile() const
{
    // Including feed here might be a bad idea since drag and drop uses this check
    // and including feed would allow feeds to potentially let someone's blog
    // read the contents of the clipboard on a drag, even without a drop.
    // Likewise with using the FrameLoader::shouldTreatURLAsLocal() function.
    return protocolIs("file");
}

bool protocolIsJavaScript(const String& url)
{
    return protocolIs(url, "javascript");
}

const KURL& blankURL()
{
    DEFINE_STATIC_LOCAL(KURL, staticBlankURL, (ParsedURLString, "about:blank"));
    return staticBlankURL;
}

bool KURL::isAboutBlankURL() const
{
    return *this == blankURL();
}

String KURL::elidedString() const
{
    if (string().length() <= 1024)
        return string();

    return string().left(511) + "..." + string().right(510);
}

KURL::KURL()
    : m_isValid(false)
    , m_protocolIsInHTTPFamily(false)
{
}

// Initializes with a string representing an absolute URL. No encoding
// information is specified. This generally happens when a KURL is converted
// to a string and then converted back. In this case, the URL is already
// canonical and in proper escaped form so needs no encoding. We treat it as
// UTF-8 just in case.
KURL::KURL(ParsedURLStringTag, const String& url)
{
    if (!url.isNull())
        init(KURL(), url, 0);
    else {
        // WebCore expects us to preserve the nullness of strings when this
        // constructor is used. In all other cases, it expects a non-null
        // empty string, which is what init() will create.
        m_isValid = false;
        m_protocolIsInHTTPFamily = false;
    }
}

KURL KURL::createIsolated(ParsedURLStringTag, const String& url)
{
    // FIXME: We should be able to skip this extra copy and created an
    // isolated KURL more efficiently.
    return KURL(ParsedURLString, url).copy();
}

// Constructs a new URL given a base URL and a possibly relative input URL.
// This assumes UTF-8 encoding.
KURL::KURL(const KURL& base, const String& relative)
{
    init(base, relative, 0);
}

// Constructs a new URL given a base URL and a possibly relative input URL.
// Any query portion of the relative URL will be encoded in the given encoding.
KURL::KURL(const KURL& base, const String& relative, const WTF::TextEncoding& encoding)
{
    init(base, relative, &encoding.encodingForFormSubmission());
}

KURL::KURL(const AtomicString& canonicalString, const url::Parsed& parsed, bool isValid)
    : m_isValid(isValid)
    , m_protocolIsInHTTPFamily(false)
    , m_parsed(parsed)
    , m_string(canonicalString)
{
    initProtocolIsInHTTPFamily();
    initInnerURL();
}

KURL::KURL(WTF::HashTableDeletedValueType)
    : m_isValid(false)
    , m_protocolIsInHTTPFamily(false)
    , m_string(WTF::HashTableDeletedValue)
{
}

KURL::KURL(const KURL& other)
    : m_isValid(other.m_isValid)
    , m_protocolIsInHTTPFamily(other.m_protocolIsInHTTPFamily)
    , m_parsed(other.m_parsed)
    , m_string(other.m_string)
{
    if (other.m_innerURL.get())
        m_innerURL = adoptPtr(new KURL(other.m_innerURL->copy()));
}

KURL& KURL::operator=(const KURL& other)
{
    m_isValid = other.m_isValid;
    m_protocolIsInHTTPFamily = other.m_protocolIsInHTTPFamily;
    m_parsed = other.m_parsed;
    m_string = other.m_string;
    if (other.m_innerURL)
        m_innerURL = adoptPtr(new KURL(other.m_innerURL->copy()));
    else
        m_innerURL.clear();
    return *this;
}

#if COMPILER_SUPPORTS(CXX_RVALUE_REFERENCES)
KURL::KURL(KURL&& other)
    : m_isValid(other.m_isValid)
    , m_protocolIsInHTTPFamily(other.m_protocolIsInHTTPFamily)
    , m_parsed(other.m_parsed)
    // FIXME: Instead of explicitly casting to String&& here, we should use std::move, but that requires us to
    // have a standard library that supports move semantics.
    , m_string(static_cast<String&&>(other.m_string))
    , m_innerURL(other.m_innerURL.release())
{
}

KURL& KURL::operator=(KURL&& other)
{
    m_isValid = other.m_isValid;
    m_protocolIsInHTTPFamily = other.m_protocolIsInHTTPFamily;
    m_parsed = other.m_parsed;
    // FIXME: Instead of explicitly casting to String&& here, we should use std::move, but that requires us to
    // have a standard library that supports move semantics.
    m_string = static_cast<String&&>(other.m_string);
    m_innerURL = other.m_innerURL.release();
    return *this;
}
#endif

KURL KURL::copy() const
{
    KURL result;
    result.m_isValid = m_isValid;
    result.m_protocolIsInHTTPFamily = m_protocolIsInHTTPFamily;
    result.m_parsed = m_parsed;
    result.m_string = m_string.isolatedCopy();
    if (m_innerURL)
        result.m_innerURL = adoptPtr(new KURL(m_innerURL->copy()));
    return result;
}

bool KURL::isNull() const
{
    return m_string.isNull();
}

bool KURL::isEmpty() const
{
    return m_string.isEmpty();
}

bool KURL::isValid() const
{
    return m_isValid;
}

bool KURL::hasPort() const
{
    return hostEnd() < pathStart();
}

bool KURL::protocolIsInHTTPFamily() const
{
    return m_protocolIsInHTTPFamily;
}

bool KURL::hasPath() const
{
    // Note that http://www.google.com/" has a path, the path is "/". This can
    // return false only for invalid or nonstandard URLs.
    return m_parsed.path.len >= 0;
}

// We handle "parameters" separated by a semicolon, while KURL.cpp does not,
// which can lead to different results in some cases.
String KURL::lastPathComponent() const
{
    if (!m_isValid)
        return stringForInvalidComponent();
    ASSERT(!m_string.isNull());

    // When the output ends in a slash, WebCore has different expectations than
    // the GoogleURL library. For "/foo/bar/" the library will return the empty
    // string, but WebCore wants "bar".
    url::Component path = m_parsed.path;
    if (path.len > 0 && m_string[path.end() - 1] == '/')
        path.len--;

    url::Component file;
    if (m_string.is8Bit())
        url::ExtractFileName(asURLChar8Subtle(m_string), path, &file);
    else
        url::ExtractFileName(m_string.characters16(), path, &file);

    // Bug: https://bugs.webkit.org/show_bug.cgi?id=21015 this function returns
    // a null string when the path is empty, which we duplicate here.
    if (!file.is_nonempty())
        return String();
    return componentString(file);
}

String KURL::protocol() const
{
    return componentString(m_parsed.scheme);
}

String KURL::host() const
{
    return componentString(m_parsed.host);
}

// Returns 0 when there is no port.
//
// We treat URL's with out-of-range port numbers as invalid URLs, and they will
// be rejected by the canonicalizer. KURL.cpp will allow them in parsing, but
// return invalidPortNumber from this port() function, so we mirror that behavior here.
unsigned short KURL::port() const
{
    if (!m_isValid || m_parsed.port.len <= 0)
        return 0;
    ASSERT(!m_string.isNull());
    int port = m_string.is8Bit() ?
        url::ParsePort(asURLChar8Subtle(m_string), m_parsed.port) :
        url::ParsePort(m_string.characters16(), m_parsed.port);
    ASSERT(port != url::PORT_UNSPECIFIED); // Checked port.len <= 0 before.

    if (port == url::PORT_INVALID || port > maximumValidPortNumber) // Mimic KURL::port()
        port = invalidPortNumber;

    return static_cast<unsigned short>(port);
}

String KURL::pass() const
{
    // Bug: https://bugs.webkit.org/show_bug.cgi?id=21015 this function returns
    // a null string when the password is empty, which we duplicate here.
    if (!m_parsed.password.is_nonempty())
        return String();
    return componentString(m_parsed.password);
}

String KURL::user() const
{
    return componentString(m_parsed.username);
}

String KURL::fragmentIdentifier() const
{
    // Empty but present refs ("foo.com/bar#") should result in the empty
    // string, which componentString will produce. Nonexistent refs
    // should be the null string.
    if (!m_parsed.ref.is_valid())
        return String();
    return componentString(m_parsed.ref);
}

bool KURL::hasFragmentIdentifier() const
{
    return m_parsed.ref.len >= 0;
}

String KURL::baseAsString() const
{
    // FIXME: There is probably a more efficient way to do this?
    return m_string.left(pathAfterLastSlash());
}

String KURL::query() const
{
    if (m_parsed.query.len >= 0)
        return componentString(m_parsed.query);

    // Bug: https://bugs.webkit.org/show_bug.cgi?id=21015 this function returns
    // an empty string when the query is empty rather than a null (not sure
    // which is right).
    // Returns a null if the query is not specified, instead of empty.
    if (m_parsed.query.is_valid())
        return emptyString();
    return String();
}

String KURL::path() const
{
    return componentString(m_parsed.path);
}

bool KURL::setProtocol(const String& protocol)
{
    // Firefox and IE remove everything after the first ':'.
    int separatorPosition = protocol.find(':');
    String newProtocol = protocol.substring(0, separatorPosition);
    StringUTF8Adaptor newProtocolUTF8(newProtocol);

    // If KURL is given an invalid scheme, it returns failure without modifying
    // the URL at all. This is in contrast to most other setters which modify
    // the URL and set "m_isValid."
    url::RawCanonOutputT<char> canonProtocol;
    url::Component protocolComponent;
    if (!url::CanonicalizeScheme(newProtocolUTF8.data(), url::Component(0, newProtocolUTF8.length()), &canonProtocol, &protocolComponent)
        || !protocolComponent.is_nonempty())
        return false;

    url::Replacements<char> replacements;
    replacements.SetScheme(charactersOrEmpty(newProtocolUTF8), url::Component(0, newProtocolUTF8.length()));
    replaceComponents(replacements);

    // isValid could be false but we still return true here. This is because
    // WebCore or JS scripts can build up a URL by setting individual
    // components, and a JS exception is based on the return value of this
    // function. We want to throw the exception and stop the script only when
    // its trying to set a bad protocol, and not when it maybe just hasn't
    // finished building up its final scheme.
    return true;
}

void KURL::setHost(const String& host)
{
    StringUTF8Adaptor hostUTF8(host);
    url::Replacements<char> replacements;
    replacements.SetHost(charactersOrEmpty(hostUTF8), url::Component(0, hostUTF8.length()));
    replaceComponents(replacements);
}

static String parsePortFromStringPosition(const String& value, unsigned portStart)
{
    // "008080junk" needs to be treated as port "8080" and "000" as "0".
    size_t length = value.length();
    unsigned portEnd = portStart;
    while (isASCIIDigit(value[portEnd]) && portEnd < length)
        ++portEnd;
    while (value[portStart] == '0' && portStart < portEnd - 1)
        ++portStart;

    // Required for backwards compat.
    // https://www.w3.org/Bugs/Public/show_bug.cgi?id=23463
    if (portStart == portEnd)
        return "0";

    return value.substring(portStart, portEnd - portStart);
}

void KURL::setHostAndPort(const String& hostAndPort)
{
    size_t separator = hostAndPort.find(':');
    if (!separator)
        return;

    if (separator == kNotFound) {
        url::Replacements<char> replacements;
        StringUTF8Adaptor hostUTF8(hostAndPort);
        replacements.SetHost(charactersOrEmpty(hostUTF8), url::Component(0, hostUTF8.length()));
        replaceComponents(replacements);
        return;
    }

    String host = hostAndPort.substring(0, separator);
    String port = parsePortFromStringPosition(hostAndPort, separator + 1);

    StringUTF8Adaptor hostUTF8(host);
    StringUTF8Adaptor portUTF8(port);

    url::Replacements<char> replacements;
    replacements.SetHost(charactersOrEmpty(hostUTF8), url::Component(0, hostUTF8.length()));
    replacements.SetPort(charactersOrEmpty(portUTF8), url::Component(0, portUTF8.length()));
    replaceComponents(replacements);
}

void KURL::removePort()
{
    if (!hasPort())
        return;
    url::Replacements<char> replacements;
    replacements.ClearPort();
    replaceComponents(replacements);
}

void KURL::setPort(const String& port)
{
    String parsedPort = parsePortFromStringPosition(port, 0);
    setPort(parsedPort.toUInt());
}

void KURL::setPort(unsigned short port)
{
    if (isDefaultPortForProtocol(port, protocol())) {
        removePort();
        return;
    }

    String portString = String::number(port);
    ASSERT(portString.is8Bit());

    url::Replacements<char> replacements;
    replacements.SetPort(reinterpret_cast<const char*>(portString.characters8()), url::Component(0, portString.length()));
    replaceComponents(replacements);
}

void KURL::setUser(const String& user)
{
    // This function is commonly called to clear the username, which we
    // normally don't have, so we optimize this case.
    if (user.isEmpty() && !m_parsed.username.is_valid())
        return;

    // The canonicalizer will clear any usernames that are empty, so we
    // don't have to explicitly call ClearUsername() here.
    StringUTF8Adaptor userUTF8(user);
    url::Replacements<char> replacements;
    replacements.SetUsername(charactersOrEmpty(userUTF8), url::Component(0, userUTF8.length()));
    replaceComponents(replacements);
}

void KURL::setPass(const String& pass)
{
    // This function is commonly called to clear the password, which we
    // normally don't have, so we optimize this case.
    if (pass.isEmpty() && !m_parsed.password.is_valid())
        return;

    // The canonicalizer will clear any passwords that are empty, so we
    // don't have to explicitly call ClearUsername() here.
    StringUTF8Adaptor passUTF8(pass);
    url::Replacements<char> replacements;
    replacements.SetPassword(charactersOrEmpty(passUTF8), url::Component(0, passUTF8.length()));
    replaceComponents(replacements);
}

void KURL::setFragmentIdentifier(const String& fragment)
{
    // This function is commonly called to clear the ref, which we
    // normally don't have, so we optimize this case.
    if (fragment.isNull() && !m_parsed.ref.is_valid())
        return;

    StringUTF8Adaptor fragmentUTF8(fragment);

    url::Replacements<char> replacements;
    if (fragment.isNull())
        replacements.ClearRef();
    else
        replacements.SetRef(charactersOrEmpty(fragmentUTF8), url::Component(0, fragmentUTF8.length()));
    replaceComponents(replacements);
}

void KURL::removeFragmentIdentifier()
{
    url::Replacements<char> replacements;
    replacements.ClearRef();
    replaceComponents(replacements);
}

void KURL::setQuery(const String& query)
{
    StringUTF8Adaptor queryUTF8(query);
    url::Replacements<char> replacements;
    if (query.isNull()) {
        // KURL.cpp sets to null to clear any query.
        replacements.ClearQuery();
    } else if (query.length() > 0 && query[0] == '?') {
        // WebCore expects the query string to begin with a question mark, but
        // GoogleURL doesn't. So we trim off the question mark when setting.
        replacements.SetQuery(charactersOrEmpty(queryUTF8), url::Component(1, queryUTF8.length() - 1));
    } else {
        // When set with the empty string or something that doesn't begin with
        // a question mark, KURL.cpp will add a question mark for you. The only
        // way this isn't compatible is if you call this function with an empty
        // string. KURL.cpp will leave a '?' with nothing following it in the
        // URL, whereas we'll clear it.
        // FIXME We should eliminate this difference.
        replacements.SetQuery(charactersOrEmpty(queryUTF8), url::Component(0, queryUTF8.length()));
    }
    replaceComponents(replacements);
}

void KURL::setPath(const String& path)
{
    // Empty paths will be canonicalized to "/", so we don't have to worry
    // about calling ClearPath().
    StringUTF8Adaptor pathUTF8(path);
    url::Replacements<char> replacements;
    replacements.SetPath(charactersOrEmpty(pathUTF8), url::Component(0, pathUTF8.length()));
    replaceComponents(replacements);
}

String decodeURLEscapeSequences(const String& string)
{
    return decodeURLEscapeSequences(string, UTF8Encoding());
}

// In KURL.cpp's implementation, this is called by every component getter.
// It will unescape every character, including '\0'. This is scary, and may
// cause security holes. We never call this function for components, and
// just return the ASCII versions instead.
//
// This function is also used to decode javascript: URLs and as a general
// purpose unescaping function.
//
// FIXME These should be merged to the KURL.cpp implementation.
String decodeURLEscapeSequences(const String& string, const WTF::TextEncoding& encoding)
{
    // FIXME We can probably use KURL.cpp's version of this function
    // without modification. However, I'm concerned about
    // https://bugs.webkit.org/show_bug.cgi?id=20559 so am keeping this old
    // custom code for now. Using their version will also fix the bug that
    // we ignore the encoding.
    //
    // FIXME b/1350291: This does not get called very often. We just convert
    // first to 8-bit UTF-8, then unescape, then back to 16-bit. This kind of
    // sucks, and we don't use the encoding properly, which will make some
    // obscure anchor navigations fail.
    StringUTF8Adaptor stringUTF8(string);
    url::RawCanonOutputT<url::UTF16Char> unescaped;
    url::DecodeURLEscapeSequences(stringUTF8.data(), stringUTF8.length(), &unescaped);
    return StringImpl::create8BitIfPossible(reinterpret_cast<UChar*>(unescaped.data()), unescaped.length());
}

String encodeWithURLEscapeSequences(const String& notEncodedString)
{
    CString utf8 = UTF8Encoding().normalizeAndEncode(notEncodedString, WTF::URLEncodedEntitiesForUnencodables);

    url::RawCanonOutputT<char> buffer;
    int inputLength = utf8.length();
    if (buffer.length() < inputLength * 3)
        buffer.Resize(inputLength * 3);

    url::EncodeURIComponent(utf8.data(), inputLength, &buffer);
    String escaped(buffer.data(), buffer.length());
    // Unescape '/'; it's safe and much prettier.
    escaped.replace("%2F", "/");
    return escaped;
}

bool KURL::isHierarchical() const
{
    if (m_string.isNull() || !m_parsed.scheme.is_nonempty())
        return false;
    return m_string.is8Bit() ?
        url::IsStandard(asURLChar8Subtle(m_string), m_parsed.scheme) :
        url::IsStandard(m_string.characters16(), m_parsed.scheme);
}

#ifndef NDEBUG
void KURL::print() const
{
    printf("%s\n", m_string.utf8().data());
}
#endif

bool equalIgnoringFragmentIdentifier(const KURL& a, const KURL& b)
{
    // Compute the length of each URL without its ref. Note that the reference
    // begin (if it exists) points to the character *after* the '#', so we need
    // to subtract one.
    int aLength = a.m_string.length();
    if (a.m_parsed.ref.len >= 0)
        aLength = a.m_parsed.ref.begin - 1;

    int bLength = b.m_string.length();
    if (b.m_parsed.ref.len >= 0)
        bLength = b.m_parsed.ref.begin - 1;

    if (aLength != bLength)
        return false;

    const String& aString = a.m_string;
    const String& bString = b.m_string;
    // FIXME: Abstraction this into a function in WTFString.h.
    for (int i = 0; i < aLength; ++i) {
        if (aString[i] != bString[i])
            return false;
    }
    return true;
}

unsigned KURL::hostStart() const
{
    return m_parsed.CountCharactersBefore(url::Parsed::HOST, false);
}

unsigned KURL::hostEnd() const
{
    return m_parsed.CountCharactersBefore(url::Parsed::PORT, true);
}

unsigned KURL::pathStart() const
{
    return m_parsed.CountCharactersBefore(url::Parsed::PATH, false);
}

unsigned KURL::pathEnd() const
{
    return m_parsed.CountCharactersBefore(url::Parsed::QUERY, true);
}

unsigned KURL::pathAfterLastSlash() const
{
    if (m_string.isNull())
        return 0;
    if (!m_isValid || !m_parsed.path.is_valid())
        return m_parsed.CountCharactersBefore(url::Parsed::PATH, false);
    url::Component filename;
    if (m_string.is8Bit())
        url::ExtractFileName(asURLChar8Subtle(m_string), m_parsed.path, &filename);
    else
        url::ExtractFileName(m_string.characters16(), m_parsed.path, &filename);
    return filename.begin;
}

bool protocolIs(const String& url, const char* protocol)
{
    assertProtocolIsGood(protocol);
    if (url.isNull())
        return false;
    if (url.is8Bit())
        return url::FindAndCompareScheme(asURLChar8Subtle(url), url.length(), protocol, 0);
    return url::FindAndCompareScheme(url.characters16(), url.length(), protocol, 0);
}

void KURL::init(const KURL& base, const String& relative, const WTF::TextEncoding* queryEncoding)
{
    if (!relative.isNull() && relative.is8Bit()) {
        StringUTF8Adaptor relativeUTF8(relative);
        init(base, relativeUTF8.data(), relativeUTF8.length(), queryEncoding);
    } else
        init(base, relative.characters16(), relative.length(), queryEncoding);
    initProtocolIsInHTTPFamily();
    initInnerURL();
}

template <typename CHAR>
void KURL::init(const KURL& base, const CHAR* relative, int relativeLength, const WTF::TextEncoding* queryEncoding)
{
    // As a performance optimization, we do not use the charset converter
    // if encoding is UTF-8 or other Unicode encodings. Note that this is
    // per HTML5 2.5.3 (resolving URL). The URL canonicalizer will be more
    // efficient with no charset converter object because it can do UTF-8
    // internally with no extra copies.

    // We feel free to make the charset converter object every time since it's
    // just a wrapper around a reference.
    KURLCharsetConverter charsetConverterObject(queryEncoding);
    KURLCharsetConverter* charsetConverter = (!queryEncoding || isUnicodeEncoding(queryEncoding)) ? 0 : &charsetConverterObject;

    StringUTF8Adaptor baseUTF8(base.string());

    url::RawCanonOutputT<char> output;
    m_isValid = url::ResolveRelative(baseUTF8.data(), baseUTF8.length(), base.m_parsed, relative, relativeLength, charsetConverter, &output, &m_parsed);

    // See FIXME in KURLPrivate in the header. If canonicalization has not
    // changed the string, we can avoid an extra allocation by using assignment.
    m_string = AtomicString::fromUTF8(output.data(), output.length());
}

void KURL::initInnerURL()
{
    if (!m_isValid) {
        m_innerURL.clear();
        return;
    }
    if (url::Parsed* innerParsed = m_parsed.inner_parsed())
        m_innerURL = adoptPtr(new KURL(ParsedURLString, m_string.substring(innerParsed->scheme.begin, innerParsed->Length() - innerParsed->scheme.begin)));
    else
        m_innerURL.clear();
}

template<typename CHAR>
bool internalProtocolIs(const url::Component& scheme, const CHAR* spec, const char* protocol)
{
    const CHAR* begin = spec + scheme.begin;
    const CHAR* end = begin + scheme.len;

    while (begin != end && *protocol) {
        ASSERT(toASCIILower(*protocol) == *protocol);
        if (toASCIILower(*begin++) != *protocol++)
            return false;
    }

    // Both strings are equal (ignoring case) if and only if all of the characters were equal,
    // and the end of both has been reached.
    return begin == end && !*protocol;
}

template<typename CHAR>
bool checkIfProtocolIsInHTTPFamily(const url::Component& scheme, const CHAR* spec)
{
    if (scheme.len == 4)
        return internalProtocolIs(scheme, spec, "http");
    if (scheme.len == 5)
        return internalProtocolIs(scheme, spec, "https");
    return false;
}

void KURL::initProtocolIsInHTTPFamily()
{
    if (!m_isValid) {
        m_protocolIsInHTTPFamily = false;
        return;
    }

    ASSERT(!m_string.isNull());
    m_protocolIsInHTTPFamily = m_string.is8Bit() ?
        checkIfProtocolIsInHTTPFamily(m_parsed.scheme, m_string.characters8()) :
        checkIfProtocolIsInHTTPFamily(m_parsed.scheme, m_string.characters16());
}

bool KURL::protocolIs(const char* protocol) const
{
    assertProtocolIsGood(protocol);

    // JavaScript URLs are "valid" and should be executed even if KURL decides they are invalid.
    // The free function protocolIsJavaScript() should be used instead.
    // FIXME: Chromium code needs to be fixed for this assert to be enabled. ASSERT(strcmp(protocol, "javascript"));

    if (m_string.isNull() || m_parsed.scheme.len <= 0)
        return *protocol == '\0';

    return m_string.is8Bit() ?
        internalProtocolIs(m_parsed.scheme, m_string.characters8(), protocol) :
        internalProtocolIs(m_parsed.scheme, m_string.characters16(), protocol);
}

String KURL::stringForInvalidComponent() const
{
    if (m_string.isNull())
        return String();
    return emptyString();
}

String KURL::componentString(const url::Component& component) const
{
    if (!m_isValid || component.len <= 0)
        return stringForInvalidComponent();
    // begin and len are in terms of bytes which do not match
    // if string() is UTF-16 and input contains non-ASCII characters.
    // However, the only part in urlString that can contain non-ASCII
    // characters is 'ref' at the end of the string. In that case,
    // begin will always match the actual value and len (in terms of
    // byte) will be longer than what's needed by 'mid'. However, mid
    // truncates len to avoid go past the end of a string so that we can
    // get away without doing anything here.
    return string().substring(component.begin, component.len);
}

template<typename CHAR>
void KURL::replaceComponents(const url::Replacements<CHAR>& replacements)
{
    url::RawCanonOutputT<char> output;
    url::Parsed newParsed;

    StringUTF8Adaptor utf8(m_string);
    m_isValid = url::ReplaceComponents(utf8.data(), utf8.length(), m_parsed, replacements, 0, &output, &newParsed);

    m_parsed = newParsed;
    m_string = AtomicString::fromUTF8(output.data(), output.length());
}

bool KURL::isSafeToSendToAnotherThread() const
{
    return m_string.isSafeToSendToAnotherThread()
        && (!m_innerURL || m_innerURL->isSafeToSendToAnotherThread());
}

} // namespace blink
