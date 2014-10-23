/*
 * Copyright (c) 2010, Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "bindings/core/v8/ScriptHeapSnapshot.h"

#include "bindings/core/v8/V8Binding.h"
#include "platform/JSONValues.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"
#include <v8-profiler.h>
#include <v8.h>

namespace blink {

ScriptHeapSnapshot::~ScriptHeapSnapshot()
{
    const_cast<v8::HeapSnapshot*>(m_snapshot)->Delete();
}

String ScriptHeapSnapshot::title() const
{
    v8::HandleScope scope(v8::Isolate::GetCurrent());
    return toCoreString(m_snapshot->GetTitle());
}

namespace {

class OutputStreamAdapter FINAL : public v8::OutputStream {
public:
    OutputStreamAdapter(ScriptHeapSnapshot::OutputStream* output)
        : m_output(output) { }
    virtual void EndOfStream() OVERRIDE { m_output->Close(); }
    virtual int GetChunkSize() OVERRIDE { return 102400; }
    virtual WriteResult WriteAsciiChunk(char* data, int size) OVERRIDE
    {
        m_output->Write(String(data, size));
        return kContinue;
    }
private:
    ScriptHeapSnapshot::OutputStream* m_output;
};

} // namespace

void ScriptHeapSnapshot::writeJSON(ScriptHeapSnapshot::OutputStream* stream)
{
    OutputStreamAdapter outputStream(stream);
    m_snapshot->Serialize(&outputStream, v8::HeapSnapshot::kJSON);
}

} // namespace blink
