/*
 * Copyright (C) 2003, 2006, 2008 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_CORE_RENDERING_RENDERTREEASTEXT_H_
#define SKY_ENGINE_CORE_RENDERING_RENDERTREEASTEXT_H_
#include "flutter/sky/engine/platform/text/TextStream.h"

#include "flutter/sky/engine/wtf/Forward.h"

namespace blink {

class LayoutRect;
class Node;
class RenderLayer;
class RenderObject;
class TextStream;

enum RenderAsTextBehaviorFlags {
  RenderAsTextBehaviorNormal = 0,
  RenderAsTextShowAllLayers =
      1 << 0,  // Dump all layers, not just those that would paint.
  RenderAsTextShowLayerNesting = 1 << 1,  // Annotate the layer lists.
  RenderAsTextShowCompositedLayers = 1
                                     << 2,  // Show which layers are composited.
  RenderAsTextShowAddresses = 1 << 3,   // Show layer and renderer addresses.
  RenderAsTextShowIDAndClass = 1 << 4,  // Show id and class attributes
  RenderAsTextDontUpdateLayout =
      1 << 6,  // Don't update layout, to make it safe to call showLayerTree()
               // from the debugger inside layout or painting code.
  RenderAsTextShowLayoutState =
      1 << 7  // Print the various 'needs layout' bits on renderers.
};
typedef unsigned RenderAsTextBehavior;

// You don't need pageWidthInPixels if you don't specify
// RenderAsTextInPrintingMode.
void write(TextStream&,
           const RenderObject&,
           int indent = 0,
           RenderAsTextBehavior = RenderAsTextBehaviorNormal);

class RenderTreeAsText {
  // FIXME: This is a cheesy hack to allow easy access to RenderStyle colors.
  // It won't be needed if we convert it to use colorIncludingFallback instead.
  // (This just involves rebaselining many results though, so for now it's not
  // being done).
 public:
  static void writeRenderObject(TextStream& ts,
                                const RenderObject& o,
                                RenderAsTextBehavior behavior);
  static void writeLayers(TextStream&,
                          const RenderLayer* rootLayer,
                          RenderLayer*,
                          const LayoutRect& paintDirtyRect,
                          int indent = 0,
                          RenderAsTextBehavior = RenderAsTextBehaviorNormal);
};

// Helper function shared with SVGRenderTreeAsText
String quoteAndEscapeNonPrintables(const String&);

}  // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_RENDERTREEASTEXT_H_
