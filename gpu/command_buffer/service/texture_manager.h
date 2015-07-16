// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_TEXTURE_MANAGER_H_
#define GPU_COMMAND_BUFFER_SERVICE_TEXTURE_MANAGER_H_

#include <algorithm>
#include <list>
#include <set>
#include <string>
#include <vector>
#include "base/basictypes.h"
#include "base/containers/hash_tables.h"
#include "base/memory/ref_counted.h"
#include "gpu/command_buffer/service/async_pixel_transfer_delegate.h"
#include "gpu/command_buffer/service/gl_utils.h"
#include "gpu/command_buffer/service/memory_tracking.h"
#include "gpu/gpu_export.h"
#include "ui/gl/gl_image.h"

namespace gpu {
namespace gles2 {

class GLES2Decoder;
struct ContextState;
struct DecoderFramebufferState;
class Display;
class ErrorState;
class FeatureInfo;
class FramebufferManager;
class MailboxManager;
class TextureManager;
class TextureRef;

// Info about Textures currently in the system.
// This class wraps a real GL texture, keeping track of its meta-data. It is
// jointly owned by possibly multiple TextureRef.
class GPU_EXPORT Texture {
 public:
  explicit Texture(GLuint service_id);

  GLenum min_filter() const {
    return min_filter_;
  }

  GLenum mag_filter() const {
    return mag_filter_;
  }

  GLenum wrap_s() const {
    return wrap_s_;
  }

  GLenum wrap_t() const {
    return wrap_t_;
  }

  GLenum usage() const {
    return usage_;
  }

  GLenum pool() const {
    return pool_;
  }

  int num_uncleared_mips() const {
    return num_uncleared_mips_;
  }

  uint32 estimated_size() const {
    return estimated_size_;
  }

  bool CanRenderTo() const {
    return target_ != GL_TEXTURE_EXTERNAL_OES;
  }

  // The service side OpenGL id of the texture.
  GLuint service_id() const {
    return service_id_;
  }

  void SetServiceId(GLuint service_id) {
    DCHECK(service_id);
    service_id_ = service_id;
  }

  // Returns the target this texure was first bound to or 0 if it has not
  // been bound. Once a texture is bound to a specific target it can never be
  // bound to a different target.
  GLenum target() const {
    return target_;
  }

  bool SafeToRenderFrom() const {
    return cleared_;
  }

  // Get the width and height for a particular level. Returns false if level
  // does not exist.
  bool GetLevelSize(
      GLint target, GLint level, GLsizei* width, GLsizei* height) const;

  // Get the type of a level. Returns false if level does not exist.
  bool GetLevelType(
      GLint target, GLint level, GLenum* type, GLenum* internal_format) const;

  // Get the image bound to a particular level. Returns NULL if level
  // does not exist.
  gfx::GLImage* GetLevelImage(GLint target, GLint level) const;

  bool HasImages() const {
    return has_images_;
  }

  // Returns true of the given dimensions are inside the dimensions of the
  // level and if the type matches the level.
  bool ValidForTexture(
      GLint target,
      GLint level,
      GLint xoffset,
      GLint yoffset,
      GLsizei width,
      GLsizei height,
      GLenum type) const;

  bool IsValid() const {
    return !!target();
  }

  bool IsAttachedToFramebuffer() const {
    return framebuffer_attachment_count_ != 0;
  }

  void AttachToFramebuffer() {
    ++framebuffer_attachment_count_;
  }

  void DetachFromFramebuffer() {
    DCHECK_GT(framebuffer_attachment_count_, 0);
    --framebuffer_attachment_count_;
  }

  void SetImmutable(bool immutable) {
    immutable_ = immutable;
  }

  bool IsImmutable() const {
    return immutable_;
  }

  // Whether a particular level/face is cleared.
  bool IsLevelCleared(GLenum target, GLint level) const;

  // Whether the texture has been defined
  bool IsDefined() const {
    return estimated_size() > 0;
  }

  // Initialize TEXTURE_MAX_ANISOTROPY to 1 if we haven't done so yet.
  void InitTextureMaxAnisotropyIfNeeded(GLenum target);

  void OnWillModifyPixels();
  void OnDidModifyPixels();

 private:
  friend class MailboxManagerImpl;
  friend class MailboxManagerSync;
  friend class MailboxManagerTest;
  friend class TextureDefinition;
  friend class TextureManager;
  friend class TextureRef;
  friend class TextureTestHelper;

  ~Texture();
  void AddTextureRef(TextureRef* ref);
  void RemoveTextureRef(TextureRef* ref, bool have_context);
  MemoryTypeTracker* GetMemTracker();

  // Condition on which this texture is renderable. Can be ONLY_IF_NPOT if it
  // depends on context support for non-power-of-two textures (i.e. will be
  // renderable if NPOT support is in the context, otherwise not, e.g. texture
  // with a NPOT level). ALWAYS means it doesn't depend on context features
  // (e.g. complete POT), NEVER means it's not renderable regardless (e.g.
  // incomplete).
  enum CanRenderCondition {
    CAN_RENDER_ALWAYS,
    CAN_RENDER_NEVER,
    CAN_RENDER_ONLY_IF_NPOT
  };

  struct LevelInfo {
    LevelInfo();
    LevelInfo(const LevelInfo& rhs);
    ~LevelInfo();

    bool cleared;
    GLenum target;
    GLint level;
    GLenum internal_format;
    GLsizei width;
    GLsizei height;
    GLsizei depth;
    GLint border;
    GLenum format;
    GLenum type;
    scoped_refptr<gfx::GLImage> image;
    uint32 estimated_size;
  };

  struct FaceInfo {
    FaceInfo();
    ~FaceInfo();

    GLsizei num_mip_levels;
    std::vector<LevelInfo> level_infos;
  };

  // Set the info for a particular level.
  void SetLevelInfo(
      const FeatureInfo* feature_info,
      GLenum target,
      GLint level,
      GLenum internal_format,
      GLsizei width,
      GLsizei height,
      GLsizei depth,
      GLint border,
      GLenum format,
      GLenum type,
      bool cleared);

  // In GLES2 "texture complete" means it has all required mips for filtering
  // down to a 1x1 pixel texture, they are in the correct order, they are all
  // the same format.
  bool texture_complete() const {
    return texture_complete_;
  }

  // In GLES2 "cube complete" means all 6 faces level 0 are defined, all the
  // same format, all the same dimensions and all width = height.
  bool cube_complete() const {
    return cube_complete_;
  }

  // Whether or not this texture is a non-power-of-two texture.
  bool npot() const {
    return npot_;
  }

  // Marks a particular level as cleared or uncleared.
  void SetLevelCleared(GLenum target, GLint level, bool cleared);

  // Updates the cleared flag for this texture by inspecting all the mips.
  void UpdateCleared();

  // Clears any renderable uncleared levels.
  // Returns false if a GL error was generated.
  bool ClearRenderableLevels(GLES2Decoder* decoder);

  // Clears the level.
  // Returns false if a GL error was generated.
  bool ClearLevel(GLES2Decoder* decoder, GLenum target, GLint level);

  // Sets a texture parameter.
  // TODO(gman): Expand to SetParameteriv,fv
  // Returns GL_NO_ERROR on success. Otherwise the error to generate.
  GLenum SetParameteri(
      const FeatureInfo* feature_info, GLenum pname, GLint param);
  GLenum SetParameterf(
      const FeatureInfo* feature_info, GLenum pname, GLfloat param);

  // Makes each of the mip levels as though they were generated.
  bool MarkMipmapsGenerated(const FeatureInfo* feature_info);

  bool NeedsMips() const {
    return min_filter_ != GL_NEAREST && min_filter_ != GL_LINEAR;
  }

  // True if this texture meets all the GLES2 criteria for rendering.
  // See section 3.8.2 of the GLES2 spec.
  bool CanRender(const FeatureInfo* feature_info) const;

  // Returns true if mipmaps can be generated by GL.
  bool CanGenerateMipmaps(const FeatureInfo* feature_info) const;

  // Returns true if any of the texture dimensions are not a power of two.
  static bool TextureIsNPOT(GLsizei width, GLsizei height, GLsizei depth);

  // Returns true if texture face is complete relative to the first face.
  static bool TextureFaceComplete(const Texture::LevelInfo& first_face,
                                  size_t face_index,
                                  GLenum target,
                                  GLenum internal_format,
                                  GLsizei width,
                                  GLsizei height,
                                  GLsizei depth,
                                  GLenum format,
                                  GLenum type);

  // Returns true if texture mip level is complete relative to first level.
  static bool TextureMipComplete(const Texture::LevelInfo& level0_face,
                                 GLenum target,
                                 GLint level,
                                 GLenum internal_format,
                                 GLsizei width,
                                 GLsizei height,
                                 GLsizei depth,
                                 GLenum format,
                                 GLenum type);

  // Sets the Texture's target
  // Parameters:
  //   target: GL_TEXTURE_2D or GL_TEXTURE_CUBE_MAP or
  //           GL_TEXTURE_EXTERNAL_OES or GL_TEXTURE_RECTANGLE_ARB
  //   max_levels: The maximum levels this type of target can have.
  void SetTarget(
      const FeatureInfo* feature_info, GLenum target, GLint max_levels);

  // Update info about this texture.
  void Update(const FeatureInfo* feature_info);

  // Set the image for a particular level.
  void SetLevelImage(
      const FeatureInfo* feature_info,
      GLenum target,
      GLint level,
      gfx::GLImage* image);

  // Appends a signature for the given level.
  void AddToSignature(
      const FeatureInfo* feature_info,
      GLenum target, GLint level, std::string* signature) const;

  void SetMailboxManager(MailboxManager* mailbox_manager);

  // Updates the unsafe textures count in all the managers referencing this
  // texture.
  void UpdateSafeToRenderFrom(bool cleared);

  // Updates the uncleared mip count in all the managers referencing this
  // texture.
  void UpdateMipCleared(LevelInfo* info, bool cleared);

  // Computes the CanRenderCondition flag.
  CanRenderCondition GetCanRenderCondition() const;

  // Updates the unrenderable texture count in all the managers referencing this
  // texture.
  void UpdateCanRenderCondition();

  // Updates the images count in all the managers referencing this
  // texture.
  void UpdateHasImages();

  // Increment the framebuffer state change count in all the managers
  // referencing this texture.
  void IncAllFramebufferStateChangeCount();

  MailboxManager* mailbox_manager_;

  // Info about each face and level of texture.
  std::vector<FaceInfo> face_infos_;

  // The texture refs that point to this Texture.
  typedef std::set<TextureRef*> RefSet;
  RefSet refs_;

  // The single TextureRef that accounts for memory for this texture. Must be
  // one of refs_.
  TextureRef* memory_tracking_ref_;

  // The id of the texure
  GLuint service_id_;

  // Whether all renderable mips of this texture have been cleared.
  bool cleared_;

  int num_uncleared_mips_;
  int num_npot_faces_;

  // The target. 0 if unset, otherwise GL_TEXTURE_2D or GL_TEXTURE_CUBE_MAP.
  GLenum target_;

  // Texture parameters.
  GLenum min_filter_;
  GLenum mag_filter_;
  GLenum wrap_s_;
  GLenum wrap_t_;
  GLenum usage_;
  GLenum pool_;

  // The maximum level that has been set.
  GLint max_level_set_;

  // Whether or not this texture is "texture complete"
  bool texture_complete_;

  // Whether mip levels have changed and should be reverified.
  bool texture_mips_dirty_;
  bool texture_mips_complete_;

  // Whether or not this texture is "cube complete"
  bool cube_complete_;

  // Whether any level 0 faces have changed and should be reverified.
  bool texture_level0_dirty_;
  bool texture_level0_complete_;

  // Whether or not this texture is non-power-of-two
  bool npot_;

  // Whether this texture has ever been bound.
  bool has_been_bound_;

  // The number of framebuffers this texture is attached to.
  int framebuffer_attachment_count_;

  // Whether the texture is immutable and no further changes to the format
  // or dimensions of the texture object can be made.
  bool immutable_;

  // Whether or not this texture has images.
  bool has_images_;

  // Size in bytes this texture is assumed to take in memory.
  uint32 estimated_size_;

  // Cache of the computed CanRenderCondition flag.
  CanRenderCondition can_render_condition_;

  // Whether we have initialized TEXTURE_MAX_ANISOTROPY to 1.
  bool texture_max_anisotropy_initialized_;

  DISALLOW_COPY_AND_ASSIGN(Texture);
};

// This class represents a texture in a client context group. It's mostly 1:1
// with a client id, though it can outlive the client id if it's still bound to
// a FBO or another context when destroyed.
// Multiple TextureRef can point to the same texture with cross-context sharing.
class GPU_EXPORT TextureRef : public base::RefCounted<TextureRef> {
 public:
  TextureRef(TextureManager* manager, GLuint client_id, Texture* texture);
  static scoped_refptr<TextureRef> Create(TextureManager* manager,
                                          GLuint client_id,
                                          GLuint service_id);

  void AddObserver() { num_observers_++; }
  void RemoveObserver() { num_observers_--; }

  const Texture* texture() const { return texture_; }
  Texture* texture() { return texture_; }
  GLuint client_id() const { return client_id_; }
  GLuint service_id() const { return texture_->service_id(); }
  GLint num_observers() const { return num_observers_; }

 private:
  friend class base::RefCounted<TextureRef>;
  friend class Texture;
  friend class TextureManager;

  ~TextureRef();
  const TextureManager* manager() const { return manager_; }
  TextureManager* manager() { return manager_; }
  void reset_client_id() { client_id_ = 0; }

  TextureManager* manager_;
  Texture* texture_;
  GLuint client_id_;
  GLint num_observers_;

  DISALLOW_COPY_AND_ASSIGN(TextureRef);
};

// Holds data that is per gles2_cmd_decoder, but is related to to the
// TextureManager.
struct DecoderTextureState {
  // total_texture_upload_time automatically initialized to 0 in default
  // constructor.
  explicit DecoderTextureState(bool texsubimage2d_faster_than_teximage2d)
      : tex_image_2d_failed(false),
        texture_upload_count(0),
        texsubimage2d_faster_than_teximage2d(
            texsubimage2d_faster_than_teximage2d) {}

  // This indicates all the following texSubImage2D calls that are part of the
  // failed texImage2D call should be ignored.
  bool tex_image_2d_failed;

  // Command buffer stats.
  int texture_upload_count;
  base::TimeDelta total_texture_upload_time;

  bool texsubimage2d_faster_than_teximage2d;
};

// This class keeps track of the textures and their sizes so we can do NPOT and
// texture complete checking.
//
// NOTE: To support shared resources an instance of this class will need to be
// shared by multiple GLES2Decoders.
class GPU_EXPORT TextureManager {
 public:
  class GPU_EXPORT DestructionObserver {
   public:
    DestructionObserver();
    virtual ~DestructionObserver();

    // Called in ~TextureManager.
    virtual void OnTextureManagerDestroying(TextureManager* manager) = 0;

    // Called via ~TextureRef.
    virtual void OnTextureRefDestroying(TextureRef* texture) = 0;

   private:
    DISALLOW_COPY_AND_ASSIGN(DestructionObserver);
  };

  enum DefaultAndBlackTextures {
    kTexture2D,
    kCubeMap,
    kExternalOES,
    kRectangleARB,
    kNumDefaultTextures
  };

  TextureManager(MemoryTracker* memory_tracker,
                 FeatureInfo* feature_info,
                 GLsizei max_texture_size,
                 GLsizei max_cube_map_texture_size,
                 GLsizei max_rectangle_texture_size,
                 bool use_default_textures);
  ~TextureManager();

  void set_framebuffer_manager(FramebufferManager* manager) {
    framebuffer_manager_ = manager;
  }

  // Init the texture manager.
  bool Initialize();

  // Must call before destruction.
  void Destroy(bool have_context);

  // Returns the maximum number of levels.
  GLint MaxLevelsForTarget(GLenum target) const {
    switch (target) {
      case GL_TEXTURE_2D:
        return  max_levels_;
      case GL_TEXTURE_EXTERNAL_OES:
        return 1;
      default:
        return max_cube_map_levels_;
    }
  }

  // Returns the maximum size.
  GLsizei MaxSizeForTarget(GLenum target) const {
    switch (target) {
      case GL_TEXTURE_2D:
      case GL_TEXTURE_EXTERNAL_OES:
        return max_texture_size_;
      case GL_TEXTURE_RECTANGLE:
        return max_rectangle_texture_size_;
      default:
        return max_cube_map_texture_size_;
    }
  }

  // Returns the maxium number of levels a texture of the given size can have.
  static GLsizei ComputeMipMapCount(GLenum target,
                                    GLsizei width,
                                    GLsizei height,
                                    GLsizei depth);

  // Checks if a dimensions are valid for a given target.
  bool ValidForTarget(
      GLenum target, GLint level,
      GLsizei width, GLsizei height, GLsizei depth);

  // True if this texture meets all the GLES2 criteria for rendering.
  // See section 3.8.2 of the GLES2 spec.
  bool CanRender(const TextureRef* ref) const {
    return ref->texture()->CanRender(feature_info_.get());
  }

  // Returns true if mipmaps can be generated by GL.
  bool CanGenerateMipmaps(const TextureRef* ref) const {
    return ref->texture()->CanGenerateMipmaps(feature_info_.get());
  }

  // Sets the Texture's target
  // Parameters:
  //   target: GL_TEXTURE_2D or GL_TEXTURE_CUBE_MAP
  //   max_levels: The maximum levels this type of target can have.
  void SetTarget(
      TextureRef* ref,
      GLenum target);

  // Set the info for a particular level in a TexureInfo.
  void SetLevelInfo(
      TextureRef* ref,
      GLenum target,
      GLint level,
      GLenum internal_format,
      GLsizei width,
      GLsizei height,
      GLsizei depth,
      GLint border,
      GLenum format,
      GLenum type,
      bool cleared);

  // Adapter to call above function.
  void SetLevelInfoFromParams(TextureRef* ref,
                              const gpu::AsyncTexImage2DParams& params) {
    SetLevelInfo(
        ref, params.target, params.level, params.internal_format,
        params.width, params.height, 1 /* depth */,
        params.border, params.format,
        params.type, true /* cleared */);
  }

  Texture* Produce(TextureRef* ref);

  // Maps an existing texture into the texture manager, at a given client ID.
  TextureRef* Consume(GLuint client_id, Texture* texture);

  // Sets a mip as cleared.
  void SetLevelCleared(TextureRef* ref, GLenum target,
                       GLint level, bool cleared);

  // Sets a texture parameter of a Texture
  // Returns GL_NO_ERROR on success. Otherwise the error to generate.
  // TODO(gman): Expand to SetParameteriv,fv
  void SetParameteri(
      const char* function_name, ErrorState* error_state,
      TextureRef* ref, GLenum pname, GLint param);
  void SetParameterf(
      const char* function_name, ErrorState* error_state,
      TextureRef* ref, GLenum pname, GLfloat param);

  // Makes each of the mip levels as though they were generated.
  // Returns false if that's not allowed for the given texture.
  bool MarkMipmapsGenerated(TextureRef* ref);

  // Clears any uncleared renderable levels.
  bool ClearRenderableLevels(GLES2Decoder* decoder, TextureRef* ref);

  // Clear a specific level.
  bool ClearTextureLevel(
      GLES2Decoder* decoder, TextureRef* ref, GLenum target, GLint level);

  // Creates a new texture info.
  TextureRef* CreateTexture(GLuint client_id, GLuint service_id);

  // Gets the texture info for the given texture.
  TextureRef* GetTexture(GLuint client_id) const;

  // Removes a texture info.
  void RemoveTexture(GLuint client_id);

  // Gets a Texture for a given service id (note: it assumes the texture object
  // is still mapped in this TextureManager).
  Texture* GetTextureForServiceId(GLuint service_id) const;

  TextureRef* GetDefaultTextureInfo(GLenum target) {
    switch (target) {
      case GL_TEXTURE_2D:
        return default_textures_[kTexture2D].get();
      case GL_TEXTURE_CUBE_MAP:
        return default_textures_[kCubeMap].get();
      case GL_TEXTURE_EXTERNAL_OES:
        return default_textures_[kExternalOES].get();
      case GL_TEXTURE_RECTANGLE_ARB:
        return default_textures_[kRectangleARB].get();
      default:
        NOTREACHED();
        return NULL;
    }
  }

  bool HaveUnrenderableTextures() const {
    return num_unrenderable_textures_ > 0;
  }

  bool HaveUnsafeTextures() const {
    return num_unsafe_textures_ > 0;
  }

  bool HaveUnclearedMips() const {
    return num_uncleared_mips_ > 0;
  }

  bool HaveImages() const {
    return num_images_ > 0;
  }

  GLuint black_texture_id(GLenum target) const {
    switch (target) {
      case GL_SAMPLER_2D:
        return black_texture_ids_[kTexture2D];
      case GL_SAMPLER_CUBE:
        return black_texture_ids_[kCubeMap];
      case GL_SAMPLER_EXTERNAL_OES:
        return black_texture_ids_[kExternalOES];
      case GL_SAMPLER_2D_RECT_ARB:
        return black_texture_ids_[kRectangleARB];
      default:
        NOTREACHED();
        return 0;
    }
  }

  size_t mem_represented() const {
    return
        memory_tracker_managed_->GetMemRepresented() +
        memory_tracker_unmanaged_->GetMemRepresented();
  }

  void SetLevelImage(
      TextureRef* ref,
      GLenum target,
      GLint level,
      gfx::GLImage* image);

  size_t GetSignatureSize() const;

  void AddToSignature(
      TextureRef* ref,
      GLenum target,
      GLint level,
      std::string* signature) const;

  void AddObserver(DestructionObserver* observer) {
    destruction_observers_.push_back(observer);
  }

  void RemoveObserver(DestructionObserver* observer) {
    for (unsigned int i = 0; i < destruction_observers_.size(); i++) {
      if (destruction_observers_[i] == observer) {
        std::swap(destruction_observers_[i], destruction_observers_.back());
        destruction_observers_.pop_back();
        return;
      }
    }
    NOTREACHED();
  }

  struct DoTextImage2DArguments {
    GLenum target;
    GLint level;
    GLenum internal_format;
    GLsizei width;
    GLsizei height;
    GLint border;
    GLenum format;
    GLenum type;
    const void* pixels;
    uint32 pixels_size;
  };

  bool ValidateTexImage2D(
    ContextState* state,
    const char* function_name,
    const DoTextImage2DArguments& args,
    // Pointer to TextureRef filled in if validation successful.
    // Presumes the pointer is valid.
    TextureRef** texture_ref);

  void ValidateAndDoTexImage2D(
    DecoderTextureState* texture_state,
    ContextState* state,
    DecoderFramebufferState* framebuffer_state,
    const DoTextImage2DArguments& args);

  // TODO(kloveless): Make GetTexture* private once this is no longer called
  // from gles2_cmd_decoder.
  TextureRef* GetTextureInfoForTarget(ContextState* state, GLenum target);
  TextureRef* GetTextureInfoForTargetUnlessDefault(
      ContextState* state, GLenum target);

  bool ValidateFormatAndTypeCombination(
    ErrorState* error_state, const char* function_name,
    GLenum format, GLenum type);

  // Note that internal_format is only checked in relation to the format
  // parameter, so that this function may be used to validate texSubImage2D.
  bool ValidateTextureParameters(
    ErrorState* error_state, const char* function_name,
    GLenum format, GLenum type, GLenum internal_format, GLint level);

 private:
  friend class Texture;
  friend class TextureRef;

  // Helper for Initialize().
  scoped_refptr<TextureRef> CreateDefaultAndBlackTextures(
      GLenum target,
      GLuint* black_texture);

  void DoTexImage2D(
    DecoderTextureState* texture_state,
    ErrorState* error_state,
    DecoderFramebufferState* framebuffer_state,
    TextureRef* texture_ref,
    const DoTextImage2DArguments& args);

  void StartTracking(TextureRef* texture);
  void StopTracking(TextureRef* texture);

  void UpdateSafeToRenderFrom(int delta);
  void UpdateUnclearedMips(int delta);
  void UpdateCanRenderCondition(Texture::CanRenderCondition old_condition,
                                Texture::CanRenderCondition new_condition);
  void UpdateNumImages(int delta);
  void IncFramebufferStateChangeCount();

  GLenum AdjustTexFormat(GLenum format) const;

  MemoryTypeTracker* GetMemTracker(GLenum texture_pool);
  scoped_ptr<MemoryTypeTracker> memory_tracker_managed_;
  scoped_ptr<MemoryTypeTracker> memory_tracker_unmanaged_;

  scoped_refptr<FeatureInfo> feature_info_;

  FramebufferManager* framebuffer_manager_;

  // Info for each texture in the system.
  typedef base::hash_map<GLuint, scoped_refptr<TextureRef> > TextureMap;
  TextureMap textures_;

  GLsizei max_texture_size_;
  GLsizei max_cube_map_texture_size_;
  GLsizei max_rectangle_texture_size_;
  GLint max_levels_;
  GLint max_cube_map_levels_;

  const bool use_default_textures_;

  int num_unrenderable_textures_;
  int num_unsafe_textures_;
  int num_uncleared_mips_;
  int num_images_;

  // Counts the number of Textures allocated with 'this' as its manager.
  // Allows to check no Texture will outlive this.
  unsigned int texture_count_;

  bool have_context_;

  // Black (0,0,0,1) textures for when non-renderable textures are used.
  // NOTE: There is no corresponding Texture for these textures.
  // TextureInfos are only for textures the client side can access.
  GLuint black_texture_ids_[kNumDefaultTextures];

  // The default textures for each target (texture name = 0)
  scoped_refptr<TextureRef> default_textures_[kNumDefaultTextures];

  std::vector<DestructionObserver*> destruction_observers_;

  DISALLOW_COPY_AND_ASSIGN(TextureManager);
};

// This class records texture upload time when in scope.
class ScopedTextureUploadTimer {
 public:
  explicit ScopedTextureUploadTimer(DecoderTextureState* texture_state);
  ~ScopedTextureUploadTimer();

 private:
  DecoderTextureState* texture_state_;
  base::TimeTicks begin_time_;
  DISALLOW_COPY_AND_ASSIGN(ScopedTextureUploadTimer);
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_TEXTURE_MANAGER_H_
