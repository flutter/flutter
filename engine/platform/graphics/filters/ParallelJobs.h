/*
 * Copyright (C) 2011 University of Szeged
 * Copyright (C) 2011 Gabor Loki <loki@webkit.org>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY UNIVERSITY OF SZEGED ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL UNIVERSITY OF SZEGED OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef ParallelJobs_h
#define ParallelJobs_h

#include "base/bind.h"
#include "base/threading/thread.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/wtf/Assertions.h"
#include "sky/engine/wtf/Noncopyable.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/Vector.h"

// Usage:
//
//     // Initialize parallel jobs
//     ParallelJobs<TypeOfParameter> parallelJobs(&worker, requestedNumberOfJobs);
//
//     // Fill the parameter array
//     for(i = 0; i < parallelJobs.numberOfJobs(); ++i) {
//       TypeOfParameter& params = parallelJobs.parameter(i);
//       params.attr1 = localVars ...
//       ...
//     }
//
//     // Execute parallel jobs
//     parallelJobs.execute();
//

namespace blink {

template<typename Type>
class ParallelJobs {
    WTF_MAKE_NONCOPYABLE(ParallelJobs);
    WTF_MAKE_FAST_ALLOCATED;
public:
    typedef void (*WorkerFunction)(Type*);

    ParallelJobs(WorkerFunction func, size_t requestedJobNumber)
        : m_func(func)
    {
        size_t numberOfJobs = std::max(static_cast<size_t>(2), std::min(requestedJobNumber, Platform::current()->numberOfProcessors()));
        m_parameters.grow(numberOfJobs);
        // The main thread can execute one job, so only create requestJobNumber - 1 threads.
        for (size_t i = 0; i < numberOfJobs - 1; ++i) {
            OwnPtr<base::Thread> thread = adoptPtr(new base::Thread("Unfortunate parallel worker"));
            thread->Start();
            m_threads.append(thread.release());
        }
    }

    size_t numberOfJobs()
    {
        return m_parameters.size();
    }

    Type& parameter(size_t i)
    {
        return m_parameters[i];
    }

    void execute()
    {
        for (size_t i = 0; i < numberOfJobs() - 1; ++i)
            m_threads[i]->message_loop()->PostTask(FROM_HERE, base::Bind(m_func, &parameter(i)));
        m_func(&parameter(numberOfJobs() - 1));
        m_threads.clear();
    }

private:
    WorkerFunction m_func;
    Vector<OwnPtr<base::Thread> > m_threads;
    Vector<Type> m_parameters;
};

} // namespace blink

#endif // ParallelJobs_h
