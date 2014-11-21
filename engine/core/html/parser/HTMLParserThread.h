// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_HTML_PARSER_HTMLPARSERTHREAD_H_
#define SKY_ENGINE_CORE_HTML_PARSER_HTMLPARSERTHREAD_H_

#include "base/single_thread_task_runner.h"

namespace blink {

class HTMLParserThread {
public:
    static void start();
    static void stop();
    static base::SingleThreadTaskRunner* taskRunner();
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_HTML_PARSER_HTMLPARSERTHREAD_H_
