// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/html/parser/HTMLParserThread.h"

#include "base/threading/thread.h"
#include "wtf/Assertions.h"

namespace blink {

static base::Thread* s_thread = 0;
static base::SingleThreadTaskRunner* s_taskRunner = 0;

void HTMLParserThread::start()
{
    ASSERT(!s_thread);
    s_thread = new base::Thread("HTMLParserThread");
    s_thread->Start();
    s_thread->task_runner().swap(&s_taskRunner);
}

void HTMLParserThread::stop()
{
    ASSERT(s_thread);
    base::Thread* thread = s_thread;
    s_thread = 0;

    scoped_refptr<base::SingleThreadTaskRunner> taskRunner;
    taskRunner.swap(&s_taskRunner);

    delete thread;
    taskRunner = nullptr;
}

base::SingleThreadTaskRunner* HTMLParserThread::taskRunner()
{
    ASSERT(s_taskRunner);
    return s_taskRunner;
}

} // namespace blink
