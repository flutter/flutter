// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import java.util.Set

class AppLinkSettings {
    String applicationId
    Set<Deeplink> deeplinks
}

class Deeplink {
    String scheme, host, path
    boolean equals(o) {
        if (o == null)
            throw new NullPointerException()
        if (o.getClass() != getClass())
            return false
        return scheme == o.scheme &&
                host == o.host &&
                path == o.path
    }
}
