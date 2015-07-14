/*
 * Copyright (C) 2006, 2007, 2008, 2009, 2010, 2013 Apple Inc. All rights reserved.
 * Copyright (C) 2008 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#ifndef SKY_ENGINE_CORE_PAGE_PAGE_H_
#define SKY_ENGINE_CORE_PAGE_PAGE_H_

#include "sky/engine/core/frame/ConsoleTypes.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/frame/SettingsDelegate.h"
#include "sky/engine/core/inspector/ConsoleAPITypes.h"
#include "sky/engine/core/page/FocusType.h"
#include "sky/engine/platform/HostWindow.h"
#include "sky/engine/platform/LifecycleContext.h"
#include "sky/engine/platform/Supplementable.h"
#include "sky/engine/platform/geometry/LayoutRect.h"
#include "sky/engine/platform/geometry/Region.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/HashSet.h"
#include "sky/engine/wtf/Noncopyable.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {

class ChromeClient;
class ClientRectList;
class Document;
class DragCaretController;
class EditorClient;
class FloatRect;
class FocusController;
class Frame;
class FrameHost;
class IntRect;
class LocalFrame;
class Node;
class PageLifecycleNotifier;
class Range;
class RenderBox;
class RenderObject;
class ServiceProvider;
class Settings;
class SpellCheckerClient;
class UndoStack;
class VisibleSelection;

typedef uint64_t LinkHash;

float deviceScaleFactor(LocalFrame*);

class Page final : public Supplementable<Page>, public LifecycleContext<Page>, public SettingsDelegate, public HostWindow {
    WTF_MAKE_NONCOPYABLE(Page);
    friend class Settings;
public:
    // It is up to the platform to ensure that non-null clients are provided where required.
    struct PageClients {
        WTF_MAKE_NONCOPYABLE(PageClients); WTF_MAKE_FAST_ALLOCATED;
    public:
        PageClients();
        ~PageClients();

        ChromeClient* chromeClient;
        EditorClient* editorClient;
        SpellCheckerClient* spellCheckerClient;
    };

    Page(PageClients&, ServiceProvider*);
    virtual ~Page();

    FrameHost& frameHost() const { return *m_frameHost; }

    void setNeedsRecalcStyleInAllFrames();

    EditorClient& editorClient() const { return *m_editorClient; }
    SpellCheckerClient& spellCheckerClient() const { return *m_spellCheckerClient; }
    UndoStack& undoStack() const { return *m_undoStack; }

    void setMainFrame(LocalFrame*);
    LocalFrame* mainFrame() const { return m_mainFrame; }

    void documentDetached(Document*);

    DragCaretController& dragCaretController() const { return *m_dragCaretController; }
    FocusController& focusController() const { return *m_focusController; }

    Settings& settings() const { return *m_settings; }

    void unmarkAllTextMatches();

    float deviceScaleFactor() const { return m_deviceScaleFactor; }
    void setDeviceScaleFactor(float);

#if ENABLE(ASSERT)
    void setIsPainting(bool painting) { m_isPainting = painting; }
    bool isPainting() const { return m_isPainting; }
#endif

    double timerAlignmentInterval() const;

    class MultisamplingChangedObserver {
    public:
        virtual void multisamplingChanged(bool) = 0;
    };

    void addMultisamplingChangedObserver(MultisamplingChangedObserver*);
    void removeMultisamplingChangedObserver(MultisamplingChangedObserver*);

    void didCommitLoad(LocalFrame*);

    void acceptLanguagesChanged();

    PassOwnPtr<LifecycleNotifier<Page> > createLifecycleNotifier();

    void willBeDestroyed();

    // HostWindow methods.
    virtual IntRect rootViewToScreen(const IntRect&) const override;
    virtual blink::WebScreenInfo screenInfo() const override;
    virtual void scheduleVisualUpdate() override;

    void setWindowRect(const FloatRect&) const;
    FloatRect windowRect() const;

    void focus() const;

    bool canTakeFocus(FocusType) const;
    void takeFocus(FocusType) const;

    void focusedNodeChanged(Node*) const;
    void focusedFrameChanged(LocalFrame*) const;

    bool shouldReportDetailedMessageForSource(const String& source);
    void addMessageToConsole(LocalFrame*, MessageSource, MessageLevel, const String& message, unsigned lineNumber, const String& sourceID, const String& stackTrace);

    void* webView() const;

private:
    PageLifecycleNotifier& lifecycleNotifier();

    void initGroup();

    void setTimerAlignmentInterval(double);

    void setNeedsLayoutInAllFrames();

    // SettingsDelegate overrides.
    virtual void settingsChanged(SettingsDelegate::ChangeType) override;

    ChromeClient* m_chromeClient;
    const OwnPtr<DragCaretController> m_dragCaretController;
    const OwnPtr<FocusController> m_focusController;
    const OwnPtr<UndoStack> m_undoStack;

    // Typically, the main frame and Page should both be owned by the embedder,
    // which must call Page::willBeDestroyed() prior to destroying Page. This
    // call detaches the main frame and clears this pointer, thus ensuring that
    // this field only references a live main frame.
    //
    // However, there are several locations (InspectorOverlay)
    // which don't hold a reference to the main frame at all
    // after creating it. These are still safe because they always create a
    // Frame with a FrameView. FrameView and Frame hold references to each
    // other, thus keeping each other alive. The call to willBeDestroyed()
    // breaks this cycle, so the frame is still properly destroyed once no
    // longer needed.
    LocalFrame* m_mainFrame;

    EditorClient* const m_editorClient;
    SpellCheckerClient* const m_spellCheckerClient;

    float m_deviceScaleFactor;

    double m_timerAlignmentInterval;

#if ENABLE(ASSERT)
    bool m_isPainting;
#endif

    HashSet<RawPtr<MultisamplingChangedObserver> > m_multisamplingChangedObservers;

    // A pointer to all the interfaces provided to in-process Frames for this Page.
    // FIXME: Most of the members of Page should move onto FrameHost.
    OwnPtr<FrameHost> m_frameHost;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAGE_PAGE_H_
