// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_SEQUENTIAL_ID_GENERATOR_H_
#define UI_GFX_SEQUENTIAL_ID_GENERATOR_H_

#include <map>

#include "base/basictypes.h"
#include "base/containers/hash_tables.h"
#include "ui/gfx/gfx_export.h"

namespace ui {

// This is used to generate a series of sequential ID numbers in a way that a
// new ID is always the lowest possible ID in the sequence.
class GFX_EXPORT SequentialIDGenerator {
 public:
   // Creates a new generator with the specified lower bound for the IDs.
  explicit SequentialIDGenerator(uint32 min_id);
  ~SequentialIDGenerator();

  // Generates a unique ID to represent |number|. The generated ID is the
  // smallest available ID greater than or equal to the |min_id| specified
  // during creation of the generator.
  uint32 GetGeneratedID(uint32 number);

  // Checks to see if the generator currently has a unique ID generated for
  // |number|.
  bool HasGeneratedIDFor(uint32 number) const;

  // Removes the generated ID |id| from the internal mapping. Since the ID is
  // no longer mapped to any number, subsequent calls to |GetGeneratedID()| can
  // use this ID.
  void ReleaseGeneratedID(uint32 id);

  // Removes the ID previously generated for |number| by calling
  // |GetGeneratedID()|.
  void ReleaseNumber(uint32 number);

  void ResetForTest();

 private:
  typedef base::hash_map<uint32, uint32> IDMap;

  uint32 GetNextAvailableID();

  void UpdateNextAvailableIDAfterRelease(uint32 id);

  IDMap number_to_id_;
  IDMap id_to_number_;

  const uint32 min_id_;
  uint32 min_available_id_;

  DISALLOW_COPY_AND_ASSIGN(SequentialIDGenerator);
};

}  // namespace ui

#endif  // UI_GFX_SEQUENTIAL_ID_GENERATOR_H_
