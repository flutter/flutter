// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/css/parser/MediaQueryBlockWatcher.h"

#include "core/css/parser/MediaQueryToken.h"

namespace blink {

MediaQueryBlockWatcher::MediaQueryBlockWatcher()
    : m_blockLevel(0)
{
}

void MediaQueryBlockWatcher::handleToken(const MediaQueryToken& token)
{
    if (token.blockType() == MediaQueryToken::BlockStart) {
        ++m_blockLevel;
    } else if (token.blockType() == MediaQueryToken::BlockEnd) {
        ASSERT(m_blockLevel);
        --m_blockLevel;
    }
}

} // namespace

