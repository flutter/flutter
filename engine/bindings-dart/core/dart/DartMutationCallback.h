// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

#ifndef DartMutationCallback_h
#define DartMutationCallback_h

#include "bindings/core/dart/DartCallback.h"
#include "bindings/core/dart/DartDOMWrapper.h"
#include "bindings/core/v8/ActiveDOMCallback.h"
#include "core/dom/MutationCallback.h"

namespace blink {

class DartMutationCallback : public MutationCallback, public ActiveDOMCallback {
public:
    static PassOwnPtr<DartMutationCallback> create(Dart_Handle object, ExecutionContext* context, Dart_Handle& exception)
    {
        return adoptPtr(new DartMutationCallback(object, exception, context));
    }

    virtual ExecutionContext* executionContext() const { return ActiveDOMCallback::executionContext(); }

    virtual void call(const Vector<RefPtr<MutationRecord> >& mutations, MutationObserver* observer);


private:
    DartMutationCallback(Dart_Handle object, Dart_Handle& exception, ExecutionContext* context)
        : ActiveDOMCallback(context)
        , m_callback(object, exception)
    {
    }

    DartCallback m_callback;
};

}

#endif // DartMutationCallback_h
