// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_PLATFORM_NET_CONSTANTS_H_
#define SKY_VIEWER_PLATFORM_NET_CONSTANTS_H_

namespace sky {
// This corresponds to ERR_ABORTED in net/base/net_error_list.h.
// TODO(ppi): declare an enum in the network service mojom so that the clients
// don't need to hard-code these values.
const int32_t kNetErrorAborted = -3;

const char kNetErrorDomain[] = "net";
}  // namespace sky
#endif  // SKY_VIEWER_PLATFORM_NET_CONSTANTS_H_
