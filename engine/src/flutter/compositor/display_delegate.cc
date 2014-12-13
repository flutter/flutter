// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/display_delegate.h"

namespace sky {

static CreateDisplayDelegate createDisplayDelegateFunction = 0;

void DisplayDelegate::setDisplayDelegateCreateFunction(CreateDisplayDelegate createFunction)
{
    DCHECK(createFunction);
    DCHECK(!createDisplayDelegateFunction);
    createDisplayDelegateFunction = createFunction;
}

DisplayDelegate* DisplayDelegate::create(LayerClient* client)
{
    DCHECK(createDisplayDelegateFunction);
    return createDisplayDelegateFunction(client);
}

}  // namespace sky
