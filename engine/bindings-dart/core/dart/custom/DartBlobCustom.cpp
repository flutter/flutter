// Copyright 2011, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include "config.h"
#include "bindings/core/dart/DartBlob.h"

#include "bindings/core/dart/DartFile.h"
#include "core/dom/ExecutionContext.h"

namespace blink {

namespace DartBlobInternal {

void constructorCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        ExecutionContext* context = DartUtilities::scriptExecutionContext();
        if (!context) {
            exception = Dart_NewStringFromCString("Blob constructor associated document is unavailable");
            goto fail;
        }

        Vector<Dart_Handle> blobParts;
        DartUtilities::extractListElements(Dart_GetNativeArgument(args, 0), exception, blobParts);
        if (exception)
            goto fail;

        String type = DartUtilities::dartToStringWithNullCheck(args, 1, exception);
        if (exception)
            goto fail;

        String endings = DartUtilities::dartToStringWithNullCheck(args, 2, exception);
        if (exception)
            goto fail;
        if (endings.isNull())
            endings = "transparent";
        if (endings != "transparent" && endings != "native") {
            exception = Dart_NewStringFromCString("The endings property must be either \"transparent\" or \"native\"");
            goto fail;
        }

        // FIXMEDART: we could optimize when/where we compute this bool.
        bool normalizeLineEndingsToNative = endings == "native";

        OwnPtr<BlobData> blobData = BlobData::create();
        blobData->setContentType(type);

        uint32_t length = blobParts.size();

        for (uint32_t i = 0; i < length; ++i) {
            Dart_Handle item = blobParts[i];
            if (Dart_IsByteBuffer(item) || Dart_IsTypedData(item)) {
                RefPtr<ArrayBuffer> arrayBuffer = DartUtilities::dartToArrayBuffer(item, exception);
                if (exception)
                    goto fail;
                ASSERT(arrayBuffer);
                blobData->appendArrayBuffer(arrayBuffer.get());
            } else if (DartDOMWrapper::subtypeOf(item, DartBlob::dartClassId)) {
                Blob* blob = DartBlob::toNative(item, exception);
                if (exception)
                    goto fail;
                ASSERT(blob);
                blobData->appendBlob(blob->blobDataHandle(), 0, blob->size());
            } else {
                String stringValue = DartUtilities::dartToString(item, exception);
                if (exception)
                    goto fail;
                blobData->appendText(stringValue, normalizeLineEndingsToNative);
            }
        }

        long long blobSize = blobData->length();
        RefPtr<Blob> blob = Blob::create(BlobDataHandle::create(blobData.release(), blobSize));
        DartDOMWrapper::returnToDart<DartBlob>(args, blob.release());
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

}

Dart_Handle DartBlob::createWrapper(DartDOMData* domData, Blob* blob)
{
    if (!blob)
        return Dart_Null();

    if (blob->isFile())
        return DartFile::createWrapper(domData, static_cast<File*>(blob));

    return DartDOMWrapper::createWrapper<DartBlob>(domData, blob);
}

}
