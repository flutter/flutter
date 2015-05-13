// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/painting/PaintingTasks.h"

#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/painting/PaintingCallback.h"
#include "sky/engine/core/painting/PaintingContext.h"
#include "sky/engine/core/rendering/RenderBox.h"
#include "sky/engine/platform/graphics/DisplayList.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/RefPtr.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {
namespace {

struct RequestTask {
    RequestTask(PassRefPtr<Element> e, PassOwnPtr<PaintingCallback> c)
        : element(e), callback(c) { }

    RefPtr<Element> element;
    OwnPtr<PaintingCallback> callback;

    // Used during serviceRequests.
    RefPtr<PaintingContext> context;
};

struct CommitTask {
    CommitTask(PassRefPtr<Node> n, PassRefPtr<DisplayList> d)
        : node(n), displayList(d) { }

    RefPtr<Node> node;
    RefPtr<DisplayList> displayList;
};

static Vector<OwnPtr<RequestTask>>& requests()
{
    DEFINE_STATIC_LOCAL(OwnPtr<Vector<OwnPtr<RequestTask>>>, queue, (adoptPtr(new Vector<OwnPtr<RequestTask>>())));
    return *queue;
}

static Vector<CommitTask>& commits()
{
    DEFINE_STATIC_LOCAL(OwnPtr<Vector<CommitTask>>, queue, (adoptPtr(new Vector<CommitTask>())));
    return *queue;
}

} // namespace

void PaintingTasks::enqueueRequest(PassRefPtr<Element> element, PassOwnPtr<PaintingCallback> callback)
{
    requests().append(adoptPtr(new RequestTask(element, callback)));
}

void PaintingTasks::enqueueCommit(PassRefPtr<Node> node, PassRefPtr<DisplayList> displayList)
{
    commits().append(CommitTask(node, displayList));
}

bool PaintingTasks::serviceRequests()
{
    if (requests().isEmpty())
        return false;

    for (auto& request : requests()) {
        RenderObject* renderer = request->element->renderer();
        if (!renderer || !renderer->isBox())
            continue;
        request->context = PaintingContext::create(request->element, toRenderBox(renderer)->size());
    }

    Vector<OwnPtr<RequestTask>> local;
    swap(requests(), local);
    for (const auto& request : local) {
        if (!request->context)
            continue;
        request->callback->handleEvent(request->context.get());
    }

    return true;
}

void PaintingTasks::drainCommits()
{
    for (auto& commit : commits()) {
        RenderObject* renderer = commit.node->renderer();
        if (!renderer || !renderer->isBox())
            return;
        toRenderBox(renderer)->setCustomPainting(commit.displayList.release());
    }

    commits().clear();
}

} // namespace blink
