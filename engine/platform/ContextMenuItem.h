/*
 * Copyright (C) 2006 Apple Computer, Inc.  All rights reserved.
 * Copyright (C) 2010 Igalia S.L
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

#ifndef ContextMenuItem_h
#define ContextMenuItem_h

#include "platform/PlatformExport.h"
#include "wtf/OwnPtr.h"
#include "wtf/text/WTFString.h"

namespace blink {

class ContextMenu;

enum ContextMenuAction {
    ContextMenuItemBaseCustomTag = 5000,
    ContextMenuItemCustomTagNoAction = 5998,
    ContextMenuItemLastCustomTag = 5999
};

enum ContextMenuItemType {
    ActionType,
    CheckableActionType,
    SeparatorType,
    SubmenuType
};

class PLATFORM_EXPORT ContextMenuItem {
    WTF_MAKE_FAST_ALLOCATED;
public:
    ContextMenuItem(ContextMenuItemType, ContextMenuAction, const String&, ContextMenu* subMenu = 0);
    ContextMenuItem(ContextMenuItemType, ContextMenuAction, const String&, bool enabled, bool checked);

    ~ContextMenuItem();

    void setType(ContextMenuItemType);
    ContextMenuItemType type() const;

    void setAction(ContextMenuAction);
    ContextMenuAction action() const;

    void setChecked(bool = true);
    bool checked() const;

    void setEnabled(bool = true);
    bool enabled() const;

    void setSubMenu(ContextMenu*);

    ContextMenuItem(ContextMenuAction, const String&, bool enabled, bool checked, const Vector<ContextMenuItem>& subMenuItems);

    void setTitle(const String& title) { m_title = title; }
    const String& title() const { return m_title; }

    const Vector<ContextMenuItem>& subMenuItems() const { return m_subMenuItems; }

private:
    ContextMenuItemType m_type;
    ContextMenuAction m_action;
    String m_title;
    bool m_enabled;
    bool m_checked;
    Vector<ContextMenuItem> m_subMenuItems;
};

}

#endif // ContextMenuItem_h
