// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_EDITING_POSITIONWITHAFFINITY_H_
#define SKY_ENGINE_CORE_EDITING_POSITIONWITHAFFINITY_H_

namespace blink {

class RenderObject;

enum EAffinity { UPSTREAM, DOWNSTREAM };

// VisiblePosition default affinity is downstream because
// the callers do not really care (they just want the
// deep position without regard to line position), and this
// is cheaper than UPSTREAM
#define VP_DEFAULT_AFFINITY DOWNSTREAM

// Callers who do not know where on the line the position is,
// but would like UPSTREAM if at a line break or DOWNSTREAM
// otherwise, need a clear way to specify that.  The
// constructors auto-correct UPSTREAM to DOWNSTREAM if the
// position is not at a line break.
#define VP_UPSTREAM_IF_POSSIBLE UPSTREAM

class PositionWithAffinity {
 public:
  PositionWithAffinity(RenderObject* renderer,
                       int offset,
                       EAffinity = DOWNSTREAM);
  ~PositionWithAffinity();

  RenderObject* renderer() const { return m_renderer; }
  int offset() const { return m_offset; }
  EAffinity affinity() const { return m_affinity; }

 private:
  RenderObject* m_renderer;
  int m_offset;
  EAffinity m_affinity;
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_EDITING_POSITIONWITHAFFINITY_H_
