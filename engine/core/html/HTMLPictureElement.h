// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef HTMLPictureElement_h
#define HTMLPictureElement_h

#include "core/html/HTMLElement.h"

namespace blink {

class HTMLPictureElement final : public HTMLElement {
    DEFINE_WRAPPERTYPEINFO();
public:
    DECLARE_NODE_FACTORY(HTMLPictureElement);

    void sourceOrMediaChanged();

protected:
    explicit HTMLPictureElement(Document&);

private:
    virtual InsertionNotificationRequest insertedInto(ContainerNode*) override;
};

} // namespace blink

#endif // HTMLPictureElement_h
