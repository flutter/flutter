// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "config.h"
#include "bindings/core/dart/DartMutationCallback.h"

#include "bindings/core/dart/DartMutationObserver.h"
#include "bindings/core/dart/DartMutationRecord.h"

namespace blink {

void DartMutationCallback::call(const Vector<RefPtr<MutationRecord> >& mutations, MutationObserver* observer)
{
    if (!m_callback.isIsolateAlive())
        return;

    DartIsolateScope scope(m_callback.isolate());
    DartApiScope apiScope;

    Dart_Handle arguments[] = {
        DartDOMWrapper::vectorToDart<DartMutationRecord>(mutations),
        DartMutationObserver::toDart(observer)
    };
    m_callback.handleEvent(2, arguments);
}

}
