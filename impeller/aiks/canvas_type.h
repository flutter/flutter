// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_AIKS_CANVAS_TYPE_H_
#define FLUTTER_IMPELLER_AIKS_CANVAS_TYPE_H_

#include "impeller/aiks/canvas.h"
#include "impeller/aiks/canvas_recorder.h"
#include "impeller/aiks/trace_serializer.h"

namespace impeller {

/// CanvasType defines what is the concrete type of the Canvas to be used. When
/// the recorder is enabled it will be swapped out in place of the Canvas at
/// compile-time.
#ifdef IMPELLER_TRACE_CANVAS
using CanvasType = CanvasRecorder<TraceSerializer>;
#else
using CanvasType = Canvas;
#endif

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_AIKS_CANVAS_TYPE_H_
