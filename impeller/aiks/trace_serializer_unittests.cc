// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <sstream>
#include "flutter/testing/testing.h"
#include "impeller/aiks/trace_serializer.h"
namespace impeller {
namespace testing {

TEST(TraceSerializer, Save) {
  CanvasRecorder<TraceSerializer> recorder;
  std::ostringstream ss;
  fml::LogMessage::CaptureNextLog(&ss);
  recorder.Save();
  ASSERT_TRUE(ss.str().size() > 0);
}

}  // namespace testing
}  // namespace impeller
