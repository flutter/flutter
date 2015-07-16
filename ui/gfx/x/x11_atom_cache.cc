// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/x/x11_atom_cache.h"

#include <X11/Xatom.h>
#include <X11/Xlib.h>

#include "base/logging.h"
#include "base/memory/scoped_ptr.h"

namespace ui {

X11AtomCache::X11AtomCache(XDisplay* xdisplay, const char** to_cache)
    : xdisplay_(xdisplay),
      uncached_atoms_allowed_(false) {
  int cache_count = 0;
  for (const char** i = to_cache; *i != NULL; i++)
    cache_count++;

  scoped_ptr<XAtom[]> cached_atoms(new XAtom[cache_count]);

  // Grab all the atoms we need now to minimize roundtrips to the X11 server.
  XInternAtoms(xdisplay_,
               const_cast<char**>(to_cache), cache_count, False,
               cached_atoms.get());

  for (int i = 0; i < cache_count; ++i)
    cached_atoms_.insert(std::make_pair(to_cache[i], cached_atoms[i]));
}

X11AtomCache::~X11AtomCache() {}

XAtom X11AtomCache::GetAtom(const char* name) const {
  std::map<std::string, Atom>::const_iterator it = cached_atoms_.find(name);

  if (uncached_atoms_allowed_ && it == cached_atoms_.end()) {
    XAtom atom = XInternAtom(xdisplay_, name, false);
    cached_atoms_.insert(std::make_pair(name, atom));
    return atom;
  }

  CHECK(it != cached_atoms_.end()) << " Atom " << name << " not found";
  return it->second;
}

}  // namespace ui
