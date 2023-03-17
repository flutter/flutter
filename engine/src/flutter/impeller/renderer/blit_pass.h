// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <string>
#include <variant>

#include "impeller/renderer/blit_command.h"
#include "impeller/renderer/device_buffer.h"
#include "impeller/renderer/texture.h"

namespace impeller {

class HostBuffer;
class Allocator;

//------------------------------------------------------------------------------
/// @brief      Blit passes encode blit into the underlying command buffer.
///
///             Blit passes can be obtained from the command buffer in which
///             the pass is meant to encode commands into.
///
/// @see        `CommandBuffer`
///
class BlitPass {
 public:
  virtual ~BlitPass();

  virtual bool IsValid() const = 0;

  void SetLabel(std::string label);

  HostBuffer& GetTransientsBuffer();

  //----------------------------------------------------------------------------
  /// @brief      Record a command to copy the contents of one texture to
  ///             another texture. The blit area is limited by the intersection
  ///             of the texture coverage with respect the source region and
  ///             destination origin.
  ///             No work is encoded into the command buffer at this time.
  ///
  /// @param[in]  source              The texture to read for copying.
  /// @param[in]  destination         The texture to overwrite using the source
  ///                                 contents.
  /// @param[in]  source_region       The optional region of the source texture
  ///                                 to use for copying. If not specified, the
  ///                                 full size of the source texture is used.
  /// @param[in]  destination_origin  The origin to start writing to in the
  ///                                 destination texture.
  /// @param[in]  label               The optional debug label to give the
  ///                                 command.
  ///
  /// @return     If the command was valid for subsequent commitment.
  ///
  bool AddCopy(std::shared_ptr<Texture> source,
               std::shared_ptr<Texture> destination,
               std::optional<IRect> source_region = std::nullopt,
               IPoint destination_origin = {},
               std::string label = "");

  //----------------------------------------------------------------------------
  /// @brief      Record a command to copy the contents of the texture to
  ///             the buffer.
  ///             No work is encoded into the command buffer at this time.
  ///
  /// @param[in]  source              The texture to read for copying.
  /// @param[in]  destination         The buffer to overwrite using the source
  ///                                 contents.
  /// @param[in]  source_region       The optional region of the source texture
  ///                                 to use for copying. If not specified, the
  ///                                 full size of the source texture is used.
  /// @param[in]  destination_offset  The offset to start writing to in the
  ///                                 destination buffer.
  /// @param[in]  label               The optional debug label to give the
  ///                                 command.
  ///
  /// @return     If the command was valid for subsequent commitment.
  ///
  bool AddCopy(std::shared_ptr<Texture> source,
               std::shared_ptr<DeviceBuffer> destination,
               std::optional<IRect> source_region = std::nullopt,
               size_t destination_offset = 0,
               std::string label = "");

  //----------------------------------------------------------------------------
  /// @brief      Record a command to generate all mip levels for a texture.
  ///             No work is encoded into the command buffer at this time.
  ///
  /// @param[in]  texture  The texture to generate mipmaps for.
  /// @param[in]  label    The optional debug label to give the command.
  ///
  /// @return     If the command was valid for subsequent commitment.
  ///
  bool GenerateMipmap(std::shared_ptr<Texture> texture, std::string label = "");

  //----------------------------------------------------------------------------
  /// @brief      Encode the recorded commands to the underlying command buffer.
  ///
  /// @param      transients_allocator  The transients allocator.
  ///
  /// @return     If the commands were encoded to the underlying command
  ///             buffer.
  ///
  virtual bool EncodeCommands(
      const std::shared_ptr<Allocator>& transients_allocator) const = 0;

 protected:
  std::shared_ptr<HostBuffer> transients_buffer_;

  explicit BlitPass();

  virtual void OnSetLabel(std::string label) = 0;

  virtual bool OnCopyTextureToTextureCommand(
      std::shared_ptr<Texture> source,
      std::shared_ptr<Texture> destination,
      IRect source_region,
      IPoint destination_origin,
      std::string label) = 0;

  virtual bool OnCopyTextureToBufferCommand(
      std::shared_ptr<Texture> source,
      std::shared_ptr<DeviceBuffer> destination,
      IRect source_region,
      size_t destination_offset,
      std::string label) = 0;

  virtual bool OnGenerateMipmapCommand(std::shared_ptr<Texture> texture,
                                       std::string label) = 0;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(BlitPass);
};

}  // namespace impeller
