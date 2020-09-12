// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_WINDOW_POINTER_DATA_PACKET_CONVERTER_H_
#define FLUTTER_LIB_UI_WINDOW_POINTER_DATA_PACKET_CONVERTER_H_

#include <cstring>
#include <map>
#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/lib/ui/window/pointer_data_packet.h"

namespace flutter {

//------------------------------------------------------------------------------
/// The current information about a pointer. This struct is used by
/// PointerDataPacketConverter to fill in necesarry information for raw pointer
/// packet sent from embedding.
///
struct PointerState {
  int64_t pointer_identifier;
  bool isDown;
  double physical_x;
  double physical_y;
};

//------------------------------------------------------------------------------
/// Converter to convert the raw pointer data packet from the platforms.
///
/// Framework requires certain information to process pointer data. e.g. pointer
/// identifier and the delta of pointer moment. The converter keeps track each
/// pointer state and fill in those information appropriately.
///
/// The converter is also resposible for providing a clean pointer data stream.
/// It will attempt to correct the stream if the it contains illegal pointer
/// transitions.
///
/// Example 1 Missing Add:
///
///     Down(position x) -> Up(position x)
///
///     ###After Conversion###
///
///     Synthesized_Add(position x) -> Down(position x) -> Up(position x)
///
/// Example 2 Missing another move:
///
///     Add(position x) -> Down(position x) -> Move(position y) ->
///     Up(position z)
///
///     ###After Conversion###
///
///     Add(position x) -> Down(position x) -> Move(position y) ->
///     Synthesized_Move(position z) -> Up(position z)
///
/// Platform view is the only client that uses this class to convert all the
/// incoming pointer packet and is responsible for the life cycle of its
/// instance.
///
class PointerDataPacketConverter {
 public:
  PointerDataPacketConverter();
  ~PointerDataPacketConverter();

  //----------------------------------------------------------------------------
  /// @brief      Converts pointer data packet into a form that framework
  ///             understands. The raw pointer data packet from embedding does
  ///             not have sufficient information and may contain illegal
  ///             pointer transitions. This method will fill out that
  ///             information and attempt to correct pointer transitions.
  ///
  /// @param[in]  packet                   The raw pointer packet sent from
  ///                                      embedding.
  ///
  /// @return     A full converted packet with all the required information
  /// filled.
  ///             It may contain synthetic pointer data as the result of
  ///             converter's attempt to correct illegal pointer transitions.
  ///
  std::unique_ptr<PointerDataPacket> Convert(
      std::unique_ptr<PointerDataPacket> packet);

 private:
  std::map<int64_t, PointerState> states_;

  int64_t pointer_;

  void ConvertPointerData(PointerData pointer_data,
                          std::vector<PointerData>& converted_pointers);

  PointerState EnsurePointerState(PointerData pointer_data);

  void UpdateDeltaAndState(PointerData& pointer_data, PointerState& state);

  void UpdatePointerIdentifier(PointerData& pointer_data,
                               PointerState& state,
                               bool start_new_pointer);

  bool LocationNeedsUpdate(const PointerData pointer_data,
                           const PointerState state);

  FML_DISALLOW_COPY_AND_ASSIGN(PointerDataPacketConverter);
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_WINDOW_POINTER_DATA_PACKET_CONVERTER_H_
