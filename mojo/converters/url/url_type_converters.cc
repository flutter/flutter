// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/converters/url/url_type_converters.h"

#include "url/gurl.h"

namespace mojo {

String TypeConverter<String, GURL>::Convert(const GURL& input) {
  return String(input.spec());
}

GURL TypeConverter<GURL, String>::Convert(const String& input) {
  return GURL(input.get());
}

}  // namespace mojo
