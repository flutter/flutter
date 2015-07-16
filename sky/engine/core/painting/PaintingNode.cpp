// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/PaintingNode.h"
#include "sky/engine/core/painting/Picture.h"

namespace blink {

class PaintingNodeDrawable : public SkDrawable {
public:
    static PassRefPtr<PaintingNodeDrawable> create(PassRefPtr<SkDrawable> skDrawable = nullptr);

    ~PaintingNodeDrawable() override;

    SkRect onGetBounds() override;
    void onDraw(SkCanvas* canvas) override;
    SkPicture* onNewPictureSnapshot() override;
    void set_drawable(PassRefPtr<SkDrawable> drawable) { m_drawable = drawable; }

private:
    PaintingNodeDrawable();
    explicit PaintingNodeDrawable(PassRefPtr<SkDrawable> skDrawable);
    RefPtr<SkDrawable> m_drawable;
};

// static
PassRefPtr<PaintingNodeDrawable> PaintingNodeDrawable::create(PassRefPtr<SkDrawable> skDrawable)
{
    return adoptRef(new PaintingNodeDrawable(skDrawable));
}

PaintingNodeDrawable::~PaintingNodeDrawable() {}


PaintingNodeDrawable::PaintingNodeDrawable(PassRefPtr<SkDrawable> skDrawable)
    : m_drawable(skDrawable)
{
}

SkPicture* PaintingNodeDrawable::onNewPictureSnapshot()
{
    if (!m_drawable)
        return nullptr;
    return m_drawable->newPictureSnapshot();
}

SkRect PaintingNodeDrawable::onGetBounds()
{
    if (!m_drawable)
        return SkRect::MakeEmpty();
    return m_drawable->getBounds();
}

void PaintingNodeDrawable::onDraw(SkCanvas* canvas)
{
    if (!m_drawable)
        return;
    return m_drawable->draw(canvas);
}




PassRefPtr<PaintingNode> PaintingNode::create()
{
    return adoptRef(new PaintingNode());
}

PaintingNode::PaintingNode()
    : m_paintingNodeDrawable(PaintingNodeDrawable::create())
{
}

void PaintingNode::setBackingDrawable(PassRefPtr<Drawable> drawable)
{
    m_paintingNodeDrawable->set_drawable(drawable->toSkia());
}

SkDrawable* PaintingNode::toSkia()
{
    return m_paintingNodeDrawable.get();
}

PassRefPtr<Picture> PaintingNode::newPictureSnapshot()
{
    ASSERT(m_paintingNodeDrawable);
    return Picture::create(
        adoptRef(m_paintingNodeDrawable->newPictureSnapshot()));
}

PaintingNode::~PaintingNode()
{
}

} // namespace blink
