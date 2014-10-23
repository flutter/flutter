/*
 * Copyright (C) 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2009 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 3.  Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef MessageQueue_h
#define MessageQueue_h

#include <limits>
#include "wtf/Assertions.h"
#include "wtf/Deque.h"
#include "wtf/Noncopyable.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/ThreadingPrimitives.h"

namespace WTF {

    enum MessageQueueWaitResult {
        MessageQueueTerminated,       // Queue was destroyed while waiting for message.
        MessageQueueTimeout,          // Timeout was specified and it expired.
        MessageQueueMessageReceived   // A message was successfully received and returned.
    };

    // The queue takes ownership of messages and transfer it to the new owner
    // when messages are fetched from the queue.
    // Essentially, MessageQueue acts as a queue of OwnPtr<DataType>.
    template<typename DataType>
    class MessageQueue {
        WTF_MAKE_NONCOPYABLE(MessageQueue);
    public:
        MessageQueue() : m_killed(false) { }

        // Returns true if the queue is still alive, false if the queue has been killed.
        bool append(PassOwnPtr<DataType>);
        void appendAndKill(PassOwnPtr<DataType>);
        bool appendAndCheckEmpty(PassOwnPtr<DataType>);
        void prepend(PassOwnPtr<DataType>);

        PassOwnPtr<DataType> waitForMessage();
        PassOwnPtr<DataType> tryGetMessage();
        PassOwnPtr<DataType> tryGetMessageIgnoringKilled();
        PassOwnPtr<DataType> waitForMessageWithTimeout(MessageQueueWaitResult&, double absoluteTime);

        void kill();
        bool killed() const;

        // The result of isEmpty() is only valid if no other thread is manipulating the queue at the same time.
        bool isEmpty();

        static double infiniteTime() { return std::numeric_limits<double>::max(); }

    private:
        mutable Mutex m_mutex;
        ThreadCondition m_condition;
        Deque<OwnPtr<DataType> > m_queue;
        bool m_killed;
    };

    template<typename DataType>
    inline bool MessageQueue<DataType>::append(PassOwnPtr<DataType> message)
    {
        MutexLocker lock(m_mutex);
        m_queue.append(message);
        m_condition.signal();
        return !m_killed;
    }

    template<typename DataType>
    inline void MessageQueue<DataType>::appendAndKill(PassOwnPtr<DataType> message)
    {
        MutexLocker lock(m_mutex);
        m_queue.append(message);
        m_killed = true;
        m_condition.broadcast();
    }

    // Returns true if the queue was empty before the item was added.
    template<typename DataType>
    inline bool MessageQueue<DataType>::appendAndCheckEmpty(PassOwnPtr<DataType> message)
    {
        MutexLocker lock(m_mutex);
        bool wasEmpty = m_queue.isEmpty();
        m_queue.append(message);
        m_condition.signal();
        return wasEmpty;
    }

    template<typename DataType>
    inline void MessageQueue<DataType>::prepend(PassOwnPtr<DataType> message)
    {
        MutexLocker lock(m_mutex);
        m_queue.prepend(message);
        m_condition.signal();
    }

    template<typename DataType>
    inline PassOwnPtr<DataType> MessageQueue<DataType>::waitForMessage()
    {
        MessageQueueWaitResult exitReason;
        OwnPtr<DataType> result = waitForMessageWithTimeout(exitReason, infiniteTime());
        ASSERT(exitReason == MessageQueueTerminated || exitReason == MessageQueueMessageReceived);
        return result.release();
    }

    template<typename DataType>
    inline PassOwnPtr<DataType> MessageQueue<DataType>::waitForMessageWithTimeout(MessageQueueWaitResult& result, double absoluteTime)
    {
        MutexLocker lock(m_mutex);
        bool timedOut = false;

        while (!m_killed && !timedOut && m_queue.isEmpty())
            timedOut = !m_condition.timedWait(m_mutex, absoluteTime);

        ASSERT(!timedOut || absoluteTime != infiniteTime());

        if (m_killed) {
            result = MessageQueueTerminated;
            return nullptr;
        }

        if (timedOut) {
            result = MessageQueueTimeout;
            return nullptr;
        }

        ASSERT_WITH_SECURITY_IMPLICATION(!m_queue.isEmpty());
        result = MessageQueueMessageReceived;

        return m_queue.takeFirst();
    }

    template<typename DataType>
    inline PassOwnPtr<DataType> MessageQueue<DataType>::tryGetMessage()
    {
        MutexLocker lock(m_mutex);
        if (m_killed)
            return nullptr;
        if (m_queue.isEmpty())
            return nullptr;

        return m_queue.takeFirst();
    }

    template<typename DataType>
    inline PassOwnPtr<DataType> MessageQueue<DataType>::tryGetMessageIgnoringKilled()
    {
        MutexLocker lock(m_mutex);
        if (m_queue.isEmpty())
            return nullptr;

        return m_queue.takeFirst();
    }

    template<typename DataType>
    inline bool MessageQueue<DataType>::isEmpty()
    {
        MutexLocker lock(m_mutex);
        if (m_killed)
            return true;
        return m_queue.isEmpty();
    }

    template<typename DataType>
    inline void MessageQueue<DataType>::kill()
    {
        MutexLocker lock(m_mutex);
        m_killed = true;
        m_condition.broadcast();
    }

    template<typename DataType>
    inline bool MessageQueue<DataType>::killed() const
    {
        MutexLocker lock(m_mutex);
        return m_killed;
    }
} // namespace WTF

using WTF::MessageQueue;
// MessageQueueWaitResult enum and all its values.
using WTF::MessageQueueWaitResult;
using WTF::MessageQueueTerminated;
using WTF::MessageQueueTimeout;
using WTF::MessageQueueMessageReceived;

#endif // MessageQueue_h
