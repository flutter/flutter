// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_CSS_PARSER_MEDIAQUERYBLOCKWATCHER_H_
#define SKY_ENGINE_CORE_CSS_PARSER_MEDIAQUERYBLOCKWATCHER_H_

namespace blink {

class MediaQueryToken;

class MediaQueryBlockWatcher {
public:

    MediaQueryBlockWatcher();
    void handleToken(const MediaQueryToken&);
    unsigned blockLevel() const { return m_blockLevel; }

private:
    unsigned m_blockLevel;
};

} // namespace

#endif  // SKY_ENGINE_CORE_CSS_PARSER_MEDIAQUERYBLOCKWATCHER_H_
