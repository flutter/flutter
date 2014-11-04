// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/platform/webmimeregistry_impl.h"

#include "base/files/file_path.h"
#include "base/strings/string_util.h"
#include "base/strings/sys_string_conversions.h"
#include "base/strings/utf_string_conversions.h"
#include "net/base/mime_util.h"
#include "sky/engine/public/platform/WebString.h"

namespace sky {
namespace {

std::string ToASCIIOrEmpty(const blink::WebString& string) {
  return base::IsStringASCII(string) ? base::UTF16ToASCII(string)
                                     : std::string();
}

}  // namespace

blink::WebMimeRegistry::SupportsType WebMimeRegistryImpl::supportsMIMEType(
    const blink::WebString& mime_type) {
  return net::IsSupportedMimeType(ToASCIIOrEmpty(mime_type)) ?
      blink::WebMimeRegistry::IsSupported :
      blink::WebMimeRegistry::IsNotSupported;
}

blink::WebMimeRegistry::SupportsType WebMimeRegistryImpl::supportsImageMIMEType(
    const blink::WebString& mime_type) {
  return net::IsSupportedImageMimeType(ToASCIIOrEmpty(mime_type)) ?
      blink::WebMimeRegistry::IsSupported :
      blink::WebMimeRegistry::IsNotSupported;
}

blink::WebMimeRegistry::SupportsType
WebMimeRegistryImpl::supportsImagePrefixedMIMEType(
    const blink::WebString& mime_type) {
  std::string ascii_mime_type = ToASCIIOrEmpty(mime_type);
  return (net::IsSupportedImageMimeType(ascii_mime_type) ||
          (StartsWithASCII(ascii_mime_type, "image/", true) &&
           net::IsSupportedNonImageMimeType(ascii_mime_type)))
             ? WebMimeRegistry::IsSupported
             : WebMimeRegistry::IsNotSupported;
}

blink::WebMimeRegistry::SupportsType
    WebMimeRegistryImpl::supportsJavaScriptMIMEType(
    const blink::WebString& mime_type) {
  return net::IsSupportedJavascriptMimeType(ToASCIIOrEmpty(mime_type)) ?
      blink::WebMimeRegistry::IsSupported :
      blink::WebMimeRegistry::IsNotSupported;
}

blink::WebMimeRegistry::SupportsType WebMimeRegistryImpl::supportsMediaMIMEType(
    const blink::WebString& mime_type,
    const blink::WebString& codecs,
    const blink::WebString& key_system) {
  NOTIMPLEMENTED();
  return IsNotSupported;
}

blink::WebMimeRegistry::SupportsType
    WebMimeRegistryImpl::supportsNonImageMIMEType(
    const blink::WebString& mime_type) {
  return net::IsSupportedNonImageMimeType(ToASCIIOrEmpty(mime_type)) ?
      blink::WebMimeRegistry::IsSupported :
      blink::WebMimeRegistry::IsNotSupported;
}

blink::WebString WebMimeRegistryImpl::mimeTypeForExtension(
    const blink::WebString& file_extension) {
  NOTIMPLEMENTED();
  return blink::WebString();
}

blink::WebString WebMimeRegistryImpl::wellKnownMimeTypeForExtension(
    const blink::WebString& file_extension) {
  NOTIMPLEMENTED();
  return blink::WebString();
}

blink::WebString WebMimeRegistryImpl::mimeTypeFromFile(
    const blink::WebString& file_path) {
  NOTIMPLEMENTED();
  return blink::WebString();
}

}  // namespace sky
