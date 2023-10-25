// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <optional>
#include "fml/macros.h"
#include "impeller/renderer/backend/gles/proc_table_gles.h"

namespace impeller {
namespace testing {

/// @brief      Provides a mocked version of the |ProcTableGLES| class.
///
/// Typically, Open GLES at runtime will be provided the host's GLES bindings
/// (as function pointers). This class maintains a set of function pointers that
/// appear to be GLES functions, but are actually just stubs that record
/// invocations.
///
/// See `README.md` for more information.
class MockGLES final {
 public:
  /// @brief      Returns an initialized |MockGLES| instance.
  ///
  /// This method overwrites mocked global GLES function pointers to record
  /// invocations on this instance of |MockGLES|. As such, it should only be
  /// called once per test.
  static std::shared_ptr<MockGLES> Init(
      const std::optional<std::vector<const unsigned char*>>& extensions =
          std::nullopt);

  /// @brief      Returns a configured |ProcTableGLES| instance.
  const ProcTableGLES& GetProcTable() const { return proc_table_; }

  /// @brief      Returns a vector of the names of all recorded calls.
  ///
  /// Calls are cleared after this method is called.
  std::vector<std::string> GetCapturedCalls() {
    std::vector<std::string> calls = captured_calls_;
    captured_calls_.clear();
    return calls;
  }

  ~MockGLES();

 private:
  friend void RecordGLCall(const char* name);

  MockGLES();

  void RecordCall(const char* name) { captured_calls_.emplace_back(name); }

  const ProcTableGLES proc_table_;
  std::vector<std::string> captured_calls_;

  MockGLES(const MockGLES&) = delete;

  MockGLES& operator=(const MockGLES&) = delete;
};

}  // namespace testing
}  // namespace impeller
