// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FrameWidget_h
#define FrameWidget_h

#include "platform/Widget.h"

namespace blink {

class Widget;

class FrameWidget : public Widget {
public:
    virtual void removeChild(Widget*) = 0;
}; // class FrameWidget

DEFINE_TYPE_CASTS(FrameWidget, Widget, widget, widget->isFrameView(), widget.isFrameView());

} // namespace blink

#endif // FrameWidget_h
