// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_CONVERTERS_URL_REQUEST_TYPES_H_
#define SKY_VIEWER_CONVERTERS_URL_REQUEST_TYPES_H_

#include "mojo/services/public/interfaces/network/url_loader.mojom.h"

namespace blink {
class WebURLRequest;
}

namespace mojo {

template <>
struct TypeConverter<URLRequestPtr, blink::WebURLRequest> {
  static URLRequestPtr Convert(const blink::WebURLRequest& request);
};

}  // namespace mojo

#endif  // SKY_VIEWER_CONVERTERS_URL_REQUEST_TYPES_H_
