/*
 * Copyright (C) 2010 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/ContextMenuItem.h"

#include "platform/ContextMenu.h"

namespace blink {

ContextMenuItem::ContextMenuItem(ContextMenuItemType type, ContextMenuAction action, const String& title, ContextMenu* subMenu)
    : m_type(type)
    , m_action(action)
    , m_title(title)
    , m_enabled(true)
    , m_checked(false)
{
    if (subMenu)
        setSubMenu(subMenu);
}

ContextMenuItem::ContextMenuItem(ContextMenuItemType type, ContextMenuAction action, const String& title, bool enabled, bool checked)
    : m_type(type)
    , m_action(action)
    , m_title(title)
    , m_enabled(enabled)
    , m_checked(checked)
{
}

ContextMenuItem::ContextMenuItem(ContextMenuAction action, const String& title, bool enabled, bool checked, const Vector<ContextMenuItem>& subMenuItems)
    : m_type(SubmenuType)
    , m_action(action)
    , m_title(title)
    , m_enabled(enabled)
    , m_checked(checked)
    , m_subMenuItems(subMenuItems)
{
}

ContextMenuItem::~ContextMenuItem()
{
}

void ContextMenuItem::setSubMenu(ContextMenu* subMenu)
{
    if (subMenu) {
        m_type = SubmenuType;
        m_subMenuItems = subMenu->items();
    } else {
        m_type = ActionType;
        m_subMenuItems.clear();
    }
}

void ContextMenuItem::setType(ContextMenuItemType type)
{
    m_type = type;
}

ContextMenuItemType ContextMenuItem::type() const
{
    return m_type;
}

void ContextMenuItem::setAction(ContextMenuAction action)
{
    m_action = action;
}

ContextMenuAction ContextMenuItem::action() const
{
    return m_action;
}

void ContextMenuItem::setChecked(bool checked)
{
    m_checked = checked;
}

bool ContextMenuItem::checked() const
{
    return m_checked;
}

void ContextMenuItem::setEnabled(bool enabled)
{
    m_enabled = enabled;
}

bool ContextMenuItem::enabled() const
{
    return m_enabled;
}

} // namespace blink
