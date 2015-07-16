// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifdef WIN32
#include <windows.h>
#else
#include <pthread.h>
#endif

#include <algorithm>
#include <ostream>

#include "url/gurl.h"

#include "base/logging.h"
#include "url/url_canon_stdstring.h"
#include "url/url_util.h"

namespace {

static std::string* empty_string = NULL;
static GURL* empty_gurl = NULL;

#ifdef WIN32

// Returns a static reference to an empty string for returning a reference
// when there is no underlying string.
const std::string& EmptyStringForGURL() {
  // Avoid static object construction/destruction on startup/shutdown.
  if (!empty_string) {
    // Create the string. Be careful that we don't break in the case that this
    // is being called from multiple threads. Statics are not threadsafe.
    std::string* new_empty_string = new std::string;
    if (InterlockedCompareExchangePointer(
        reinterpret_cast<PVOID*>(&empty_string), new_empty_string, NULL)) {
      // The old value was non-NULL, so no replacement was done. Another
      // thread did the initialization out from under us.
      delete new_empty_string;
    }
  }
  return *empty_string;
}

#else

static pthread_once_t empty_string_once = PTHREAD_ONCE_INIT;
static pthread_once_t empty_gurl_once = PTHREAD_ONCE_INIT;

void EmptyStringForGURLOnce(void) {
  empty_string = new std::string;
}

const std::string& EmptyStringForGURL() {
  // Avoid static object construction/destruction on startup/shutdown.
  pthread_once(&empty_string_once, EmptyStringForGURLOnce);
  return *empty_string;
}

#endif  // WIN32

} // namespace

GURL::GURL() : is_valid_(false) {
}

GURL::GURL(const GURL& other)
    : spec_(other.spec_),
      is_valid_(other.is_valid_),
      parsed_(other.parsed_) {
  if (other.inner_url_)
    inner_url_.reset(new GURL(*other.inner_url_));
  // Valid filesystem urls should always have an inner_url_.
  DCHECK(!is_valid_ || !SchemeIsFileSystem() || inner_url_);
}

GURL::GURL(const std::string& url_string) {
  InitCanonical(url_string, true);
}

GURL::GURL(const base::string16& url_string) {
  InitCanonical(url_string, true);
}

GURL::GURL(const std::string& url_string, RetainWhiteSpaceSelector) {
  InitCanonical(url_string, false);
}

GURL::GURL(const char* canonical_spec,
           size_t canonical_spec_len,
           const url::Parsed& parsed,
           bool is_valid)
    : spec_(canonical_spec, canonical_spec_len),
      is_valid_(is_valid),
      parsed_(parsed) {
  InitializeFromCanonicalSpec();
}

GURL::GURL(std::string canonical_spec, const url::Parsed& parsed, bool is_valid)
    : is_valid_(is_valid),
      parsed_(parsed) {
  spec_.swap(canonical_spec);
  InitializeFromCanonicalSpec();
}

template<typename STR>
void GURL::InitCanonical(const STR& input_spec, bool trim_path_end) {
  // Reserve enough room in the output for the input, plus some extra so that
  // we have room if we have to escape a few things without reallocating.
  spec_.reserve(input_spec.size() + 32);
  url::StdStringCanonOutput output(&spec_);
  is_valid_ = url::Canonicalize(
      input_spec.data(), static_cast<int>(input_spec.length()), trim_path_end,
      NULL, &output, &parsed_);

  output.Complete();  // Must be done before using string.
  if (is_valid_ && SchemeIsFileSystem()) {
    inner_url_.reset(new GURL(spec_.data(), parsed_.Length(),
                              *parsed_.inner_parsed(), true));
  }
}

void GURL::InitializeFromCanonicalSpec() {
  if (is_valid_ && SchemeIsFileSystem()) {
    inner_url_.reset(
        new GURL(spec_.data(), parsed_.Length(),
                 *parsed_.inner_parsed(), true));
  }

#ifndef NDEBUG
  // For testing purposes, check that the parsed canonical URL is identical to
  // what we would have produced. Skip checking for invalid URLs have no meaning
  // and we can't always canonicalize then reproducabely.
  if (is_valid_) {
    url::Component scheme;
    // We can't do this check on the inner_url of a filesystem URL, as
    // canonical_spec actually points to the start of the outer URL, so we'd
    // end up with infinite recursion in this constructor.
    if (!url::FindAndCompareScheme(spec_.data(), spec_.length(),
                                   url::kFileSystemScheme, &scheme) ||
        scheme.begin == parsed_.scheme.begin) {
      // We need to retain trailing whitespace on path URLs, as the |parsed_|
      // spec we originally received may legitimately contain trailing white-
      // space on the path or  components e.g. if the #ref has been
      // removed from a "foo:hello #ref" URL (see http://crbug.com/291747).
      GURL test_url(spec_, RETAIN_TRAILING_PATH_WHITEPACE);

      DCHECK(test_url.is_valid_ == is_valid_);
      DCHECK(test_url.spec_ == spec_);

      DCHECK(test_url.parsed_.scheme == parsed_.scheme);
      DCHECK(test_url.parsed_.username == parsed_.username);
      DCHECK(test_url.parsed_.password == parsed_.password);
      DCHECK(test_url.parsed_.host == parsed_.host);
      DCHECK(test_url.parsed_.port == parsed_.port);
      DCHECK(test_url.parsed_.path == parsed_.path);
      DCHECK(test_url.parsed_.query == parsed_.query);
      DCHECK(test_url.parsed_.ref == parsed_.ref);
    }
  }
#endif
}

GURL::~GURL() {
}

GURL& GURL::operator=(GURL other) {
  Swap(&other);
  return *this;
}

const std::string& GURL::spec() const {
  if (is_valid_ || spec_.empty())
    return spec_;

  DCHECK(false) << "Trying to get the spec of an invalid URL!";
  return EmptyStringForGURL();
}

bool GURL::operator==(const GURL& other) const {
  return spec_ == other.spec_;
}

bool GURL::operator!=(const GURL& other) const {
  return spec_ != other.spec_;
}

bool GURL::operator<(const GURL& other) const {
  return spec_ < other.spec_;
}

bool GURL::operator>(const GURL& other) const {
  return spec_ > other.spec_;
}

GURL GURL::Resolve(const std::string& relative) const {
  return ResolveWithCharsetConverter(relative, NULL);
}
GURL GURL::Resolve(const base::string16& relative) const {
  return ResolveWithCharsetConverter(relative, NULL);
}

// Note: code duplicated below (it's inconvenient to use a template here).
GURL GURL::ResolveWithCharsetConverter(
    const std::string& relative,
    url::CharsetConverter* charset_converter) const {
  // Not allowed for invalid URLs.
  if (!is_valid_)
    return GURL();

  GURL result;

  // Reserve enough room in the output for the input, plus some extra so that
  // we have room if we have to escape a few things without reallocating.
  result.spec_.reserve(spec_.size() + 32);
  url::StdStringCanonOutput output(&result.spec_);

  if (!url::ResolveRelative(spec_.data(), static_cast<int>(spec_.length()),
                            parsed_, relative.data(),
                            static_cast<int>(relative.length()),
                            charset_converter, &output, &result.parsed_)) {
    // Error resolving, return an empty URL.
    return GURL();
  }

  output.Complete();
  result.is_valid_ = true;
  if (result.SchemeIsFileSystem()) {
    result.inner_url_.reset(
        new GURL(result.spec_.data(), result.parsed_.Length(),
                 *result.parsed_.inner_parsed(), true));
  }
  return result;
}

// Note: code duplicated above (it's inconvenient to use a template here).
GURL GURL::ResolveWithCharsetConverter(
    const base::string16& relative,
    url::CharsetConverter* charset_converter) const {
  // Not allowed for invalid URLs.
  if (!is_valid_)
    return GURL();

  GURL result;

  // Reserve enough room in the output for the input, plus some extra so that
  // we have room if we have to escape a few things without reallocating.
  result.spec_.reserve(spec_.size() + 32);
  url::StdStringCanonOutput output(&result.spec_);

  if (!url::ResolveRelative(spec_.data(), static_cast<int>(spec_.length()),
                            parsed_, relative.data(),
                            static_cast<int>(relative.length()),
                            charset_converter, &output, &result.parsed_)) {
    // Error resolving, return an empty URL.
    return GURL();
  }

  output.Complete();
  result.is_valid_ = true;
  if (result.SchemeIsFileSystem()) {
    result.inner_url_.reset(
        new GURL(result.spec_.data(), result.parsed_.Length(),
                 *result.parsed_.inner_parsed(), true));
  }
  return result;
}

// Note: code duplicated below (it's inconvenient to use a template here).
GURL GURL::ReplaceComponents(
    const url::Replacements<char>& replacements) const {
  GURL result;

  // Not allowed for invalid URLs.
  if (!is_valid_)
    return GURL();

  // Reserve enough room in the output for the input, plus some extra so that
  // we have room if we have to escape a few things without reallocating.
  result.spec_.reserve(spec_.size() + 32);
  url::StdStringCanonOutput output(&result.spec_);

  result.is_valid_ = url::ReplaceComponents(
      spec_.data(), static_cast<int>(spec_.length()), parsed_, replacements,
      NULL, &output, &result.parsed_);

  output.Complete();
  if (result.is_valid_ && result.SchemeIsFileSystem()) {
    result.inner_url_.reset(new GURL(spec_.data(), result.parsed_.Length(),
                                     *result.parsed_.inner_parsed(), true));
  }
  return result;
}

// Note: code duplicated above (it's inconvenient to use a template here).
GURL GURL::ReplaceComponents(
    const url::Replacements<base::char16>& replacements) const {
  GURL result;

  // Not allowed for invalid URLs.
  if (!is_valid_)
    return GURL();

  // Reserve enough room in the output for the input, plus some extra so that
  // we have room if we have to escape a few things without reallocating.
  result.spec_.reserve(spec_.size() + 32);
  url::StdStringCanonOutput output(&result.spec_);

  result.is_valid_ = url::ReplaceComponents(
      spec_.data(), static_cast<int>(spec_.length()), parsed_, replacements,
      NULL, &output, &result.parsed_);

  output.Complete();
  if (result.is_valid_ && result.SchemeIsFileSystem()) {
    result.inner_url_.reset(new GURL(spec_.data(), result.parsed_.Length(),
                                     *result.parsed_.inner_parsed(), true));
  }
  return result;
}

GURL GURL::GetOrigin() const {
  // This doesn't make sense for invalid or nonstandard URLs, so return
  // the empty URL
  if (!is_valid_ || !IsStandard())
    return GURL();

  if (SchemeIsFileSystem())
    return inner_url_->GetOrigin();

  url::Replacements<char> replacements;
  replacements.ClearUsername();
  replacements.ClearPassword();
  replacements.ClearPath();
  replacements.ClearQuery();
  replacements.ClearRef();

  return ReplaceComponents(replacements);
}

GURL GURL::GetAsReferrer() const {
  if (!is_valid_ || !SchemeIsHTTPOrHTTPS())
    return GURL();

  if (!has_ref() && !has_username() && !has_password())
    return GURL(*this);

  url::Replacements<char> replacements;
  replacements.ClearRef();
  replacements.ClearUsername();
  replacements.ClearPassword();
  return ReplaceComponents(replacements);
}

GURL GURL::GetWithEmptyPath() const {
  // This doesn't make sense for invalid or nonstandard URLs, so return
  // the empty URL.
  if (!is_valid_ || !IsStandard())
    return GURL();

  // We could optimize this since we know that the URL is canonical, and we are
  // appending a canonical path, so avoiding re-parsing.
  GURL other(*this);
  if (parsed_.path.len == 0)
    return other;

  // Clear everything after the path.
  other.parsed_.query.reset();
  other.parsed_.ref.reset();

  // Set the path, since the path is longer than one, we can just set the
  // first character and resize.
  other.spec_[other.parsed_.path.begin] = '/';
  other.parsed_.path.len = 1;
  other.spec_.resize(other.parsed_.path.begin + 1);
  return other;
}

bool GURL::IsStandard() const {
  return url::IsStandard(spec_.data(), parsed_.scheme);
}

bool GURL::SchemeIs(const char* lower_ascii_scheme) const {
  if (parsed_.scheme.len <= 0)
    return lower_ascii_scheme == NULL;
  return url::LowerCaseEqualsASCII(spec_.data() + parsed_.scheme.begin,
                                   spec_.data() + parsed_.scheme.end(),
                                   lower_ascii_scheme);
}

bool GURL::SchemeIsHTTPOrHTTPS() const {
  return SchemeIs(url::kHttpScheme) || SchemeIs(url::kHttpsScheme);
}

bool GURL::SchemeIsWSOrWSS() const {
  return SchemeIs(url::kWsScheme) || SchemeIs(url::kWssScheme);
}

int GURL::IntPort() const {
  if (parsed_.port.is_nonempty())
    return url::ParsePort(spec_.data(), parsed_.port);
  return url::PORT_UNSPECIFIED;
}

int GURL::EffectiveIntPort() const {
  int int_port = IntPort();
  if (int_port == url::PORT_UNSPECIFIED && IsStandard())
    return url::DefaultPortForScheme(spec_.data() + parsed_.scheme.begin,
                                     parsed_.scheme.len);
  return int_port;
}

std::string GURL::ExtractFileName() const {
  url::Component file_component;
  url::ExtractFileName(spec_.data(), parsed_.path, &file_component);
  return ComponentString(file_component);
}

std::string GURL::PathForRequest() const {
  DCHECK(parsed_.path.len > 0) << "Canonical path for requests should be non-empty";
  if (parsed_.ref.len >= 0) {
    // Clip off the reference when it exists. The reference starts after the #
    // sign, so we have to subtract one to also remove it.
    return std::string(spec_, parsed_.path.begin,
                       parsed_.ref.begin - parsed_.path.begin - 1);
  }
  // Compute the actual path length, rather than depending on the spec's
  // terminator.  If we're an inner_url, our spec continues on into our outer
  // url's path/query/ref.
  int path_len = parsed_.path.len;
  if (parsed_.query.is_valid())
    path_len = parsed_.query.end() - parsed_.path.begin;

  return std::string(spec_, parsed_.path.begin, path_len);
}

std::string GURL::HostNoBrackets() const {
  // If host looks like an IPv6 literal, strip the square brackets.
  url::Component h(parsed_.host);
  if (h.len >= 2 && spec_[h.begin] == '[' && spec_[h.end() - 1] == ']') {
    h.begin++;
    h.len -= 2;
  }
  return ComponentString(h);
}

std::string GURL::GetContent() const {
  return is_valid_ ? ComponentString(parsed_.GetContent()) : std::string();
}

bool GURL::HostIsIPAddress() const {
  if (!is_valid_ || spec_.empty())
     return false;

  url::RawCanonOutputT<char, 128> ignored_output;
  url::CanonHostInfo host_info;
  url::CanonicalizeIPAddress(spec_.c_str(), parsed_.host, &ignored_output,
                             &host_info);
  return host_info.IsIPAddress();
}

#ifdef WIN32

const GURL& GURL::EmptyGURL() {
  // Avoid static object construction/destruction on startup/shutdown.
  if (!empty_gurl) {
    // Create the string. Be careful that we don't break in the case that this
    // is being called from multiple threads.
    GURL* new_empty_gurl = new GURL;
    if (InterlockedCompareExchangePointer(
        reinterpret_cast<PVOID*>(&empty_gurl), new_empty_gurl, NULL)) {
      // The old value was non-NULL, so no replacement was done. Another
      // thread did the initialization out from under us.
      delete new_empty_gurl;
    }
  }
  return *empty_gurl;
}

#else

void EmptyGURLOnce(void) {
  empty_gurl = new GURL;
}

const GURL& GURL::EmptyGURL() {
  // Avoid static object construction/destruction on startup/shutdown.
  pthread_once(&empty_gurl_once, EmptyGURLOnce);
  return *empty_gurl;
}

#endif  // WIN32

bool GURL::DomainIs(const char* lower_ascii_domain,
                    int domain_len) const {
  // Return false if this URL is not valid or domain is empty.
  if (!is_valid_ || !domain_len)
    return false;

  // FileSystem URLs have empty parsed_.host, so check this first.
  if (SchemeIsFileSystem() && inner_url_)
    return inner_url_->DomainIs(lower_ascii_domain, domain_len);

  if (!parsed_.host.is_nonempty())
    return false;

  // Check whether the host name is end with a dot. If yes, treat it
  // the same as no-dot unless the input comparison domain is end
  // with dot.
  const char* last_pos = spec_.data() + parsed_.host.end() - 1;
  int host_len = parsed_.host.len;
  if ('.' == *last_pos && '.' != lower_ascii_domain[domain_len - 1]) {
    last_pos--;
    host_len--;
  }

  // Return false if host's length is less than domain's length.
  if (host_len < domain_len)
    return false;

  // Compare this url whether belong specific domain.
  const char* start_pos = spec_.data() + parsed_.host.begin +
                          host_len - domain_len;

  if (!url::LowerCaseEqualsASCII(start_pos,
                                 last_pos + 1,
                                 lower_ascii_domain,
                                 lower_ascii_domain + domain_len))
    return false;

  // Check whether host has right domain start with dot, make sure we got
  // right domain range. For example www.google.com has domain
  // "google.com" but www.iamnotgoogle.com does not.
  if ('.' != lower_ascii_domain[0] && host_len > domain_len &&
      '.' != *(start_pos - 1))
    return false;

  return true;
}

void GURL::Swap(GURL* other) {
  spec_.swap(other->spec_);
  std::swap(is_valid_, other->is_valid_);
  std::swap(parsed_, other->parsed_);
  inner_url_.swap(other->inner_url_);
}

std::ostream& operator<<(std::ostream& out, const GURL& url) {
  return out << url.possibly_invalid_spec();
}
