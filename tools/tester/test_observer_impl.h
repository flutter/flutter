// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_TOOLS_TESTER_TEST_OBSERVER_IMPL_H_
#define SKY_TOOLS_TESTER_TEST_OBSERVER_IMPL_H_

#include "base/memory/weak_ptr.h"
#include "mojo/public/cpp/application/interface_factory_impl.h"
#include "mojo/public/cpp/system/core.h"
#include "sky/viewer/test_observer.mojom.h"

namespace sky {
namespace tester {
class TestRunner;

class TestObserverImpl : public mojo::InterfaceImpl<TestObserver> {
 public:
  explicit TestObserverImpl(TestRunner*);
  virtual ~TestObserverImpl();

 private:
  // TestObserver implementation.
  virtual void OnTestComplete(const mojo::String& test_result) override;

  base::WeakPtr<TestRunner> test_runner_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(TestObserverImpl);
};

typedef mojo::InterfaceFactoryImplWithContext<
    TestObserverImpl, TestRunner> TestObserverFactory;

}  // namespace tester
}  // namespace sky

#endif  // SKY_TOOLS_TESTER_TEST_OBSERVER_IMPL_H_
