/*
 * Copyright 2021 Google, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <fuchsia/fonts/cpp/fidl_test_base.h>
#include <lib/fidl/cpp/binding.h>
#include <lib/fidl/cpp/interface_handle.h>

#include "flutter/fml/logging.h"

namespace txt {

class FakeProvider : public fuchsia::fonts::testing::Provider_TestBase {
 public:
  FakeProvider() : binding_(this) {}

  fidl::InterfaceHandle<fuchsia::fonts::Provider> Bind(
      async_dispatcher_t* dispatcher) {
    FML_CHECK(!binding_.is_bound());

    fidl::InterfaceHandle<fuchsia::fonts::Provider> provider;
    binding_.Bind(provider.NewRequest(), dispatcher);

    return provider;
  }

  virtual void NotImplemented_(const std::string& name) override {
    FML_LOG(ERROR) << "A fidl call for " << name
                   << " on fake_provider is not implemented! This likely means"
                      "that your test will hang.";
  }

  void GetFontFamilyInfo(fuchsia::fonts::FamilyName family,
                         GetFontFamilyInfoCallback callback) override {
    was_invoked_ = true;
    callback(fuchsia::fonts::FontFamilyInfo());
  }

  bool WasInvoked() { return was_invoked_; }

 private:
  fidl::Binding<fuchsia::fonts::Provider> binding_;
  bool was_invoked_ = false;
};

}  // namespace txt
