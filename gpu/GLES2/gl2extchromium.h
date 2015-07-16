// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains Chromium-specific GLES2 extensions declarations.

#ifndef GPU_GLES2_GL2EXTCHROMIUM_H_
#define GPU_GLES2_GL2EXTCHROMIUM_H_

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>

#ifdef __cplusplus
extern "C" {
#endif

/* GL_CHROMIUM_iosurface */
#ifndef GL_CHROMIUM_iosurface
#define GL_CHROMIUM_iosurface 1
#ifdef GL_GLEXT_PROTOTYPES
GL_APICALL void GL_APIENTRY glTexImageIOSurface2DCHROMIUM(
    GLenum target, GLsizei width, GLsizei height, GLuint ioSurfaceId,
    GLuint plane);
#endif
typedef void (GL_APIENTRYP PFNGLTEXIMAGEIOSURFACE2DCHROMIUMPROC) (
    GLenum target, GLsizei width, GLsizei height, GLuint ioSurfaceId,
    GLuint plane);
#endif  /* GL_CHROMIUM_iosurface */

/* GL_CHROMIUM_gpu_memory_manager */
#ifndef GL_CHROMIUM_gpu_memory_manager
#define GL_CHROMIUM_gpu_memory_manager 1

#ifndef GL_TEXTURE_POOL_UNMANAGED_CHROMIUM
#define GL_TEXTURE_POOL_UNMANAGED_CHROMIUM 0x6002
#endif

#ifndef GL_TEXTURE_POOL_CHROMIUM
#define GL_TEXTURE_POOL_CHROMIUM 0x6000
#endif

#ifndef GL_TEXTURE_POOL_MANAGED_CHROMIUM
#define GL_TEXTURE_POOL_MANAGED_CHROMIUM 0x6001
#endif
#endif  /* GL_CHROMIUM_gpu_memory_manager */

/* GL_CHROMIUM_texture_mailbox */
#ifndef GL_CHROMIUM_texture_mailbox
#define GL_CHROMIUM_texture_mailbox 1

#ifndef GL_MAILBOX_SIZE_CHROMIUM
#define GL_MAILBOX_SIZE_CHROMIUM 64
#endif
#ifdef GL_GLEXT_PROTOTYPES
GL_APICALL void GL_APIENTRY glGenMailboxCHROMIUM(GLbyte* mailbox);
GL_APICALL void GL_APIENTRY glProduceTextureCHROMIUM(
    GLenum target, const GLbyte* mailbox);
GL_APICALL void GL_APIENTRY glProduceTextureDirectCHROMIUM(
    GLuint texture, GLenum target, const GLbyte* mailbox);
GL_APICALL void GL_APIENTRY glConsumeTextureCHROMIUM(
    GLenum target, const GLbyte* mailbox);
GL_APICALL GLuint GL_APIENTRY glCreateAndConsumeTextureCHROMIUM(
    GLenum target, const GLbyte* mailbox);
#endif
typedef void (GL_APIENTRYP PFNGLGENMAILBOXCHROMIUMPROC) (GLbyte* mailbox);
typedef void (GL_APIENTRYP PFNGLPRODUCETEXTURECHROMIUMPROC) (
    GLenum target, const GLbyte* mailbox);
typedef void (GL_APIENTRYP PFNGLPRODUCETEXTUREDIRECTCHROMIUMPROC) (
    GLuint texture, GLenum target, const GLbyte* mailbox);
typedef void (GL_APIENTRYP PFNGLCONSUMETEXTURECHROMIUMPROC) (
    GLenum target, const GLbyte* mailbox);
typedef GLuint (GL_APIENTRYP PFNGLCREATEANDCONSUMETEXTURECHROMIUMPROC) (
    GLenum target, const GLbyte* mailbox);
#endif  /* GL_CHROMIUM_texture_mailbox */

/* GL_CHROMIUM_pixel_transfer_buffer_object */
#ifndef GL_CHROMIUM_pixel_transfer_buffer_object
#define GL_CHROMIUM_pixel_transfer_buffer_object 1

#ifndef GL_PIXEL_UNPACK_TRANSFER_BUFFER_CHROMIUM
// TODO(reveman): Get official numbers for this constants.
#define GL_PIXEL_UNPACK_TRANSFER_BUFFER_CHROMIUM 0x78EC
#define GL_PIXEL_PACK_TRANSFER_BUFFER_CHROMIUM 0x78ED

#ifdef GL_GLEXT_PROTOTYPES
GL_APICALL void* GL_APIENTRY glMapBufferCHROMIUM(GLuint target,GLenum access);
GL_APICALL GLboolean GL_APIENTRY glUnmapBufferCHROMIUM(GLuint target);
#endif
typedef void* (GL_APIENTRY PFNGLMAPBUFFERCHROMIUM) (
    GLuint target,GLenum access);
typedef GLboolean (GL_APIENTRY PFNGLUNMAPBUFFERCHROMIUM) (GLuint target);
#endif  /* GL_CHROMIUM_pixel_transfer_buffer_object */

#ifndef GL_PIXEL_UNPACK_TRANSFER_BUFFER_BINDING_CHROMIUM
// TODO(reveman): Get official numbers for this constants.
#define GL_PIXEL_UNPACK_TRANSFER_BUFFER_BINDING_CHROMIUM 0x78EF
#define GL_PIXEL_PACK_TRANSFER_BUFFER_BINDING_CHROMIUM 0x78EE
#endif

#ifndef GL_STREAM_READ
#define GL_STREAM_READ 0x88E1
#endif
#endif  /* GL_CHROMIUM_pixel_transfer_buffer_object */

/* GL_CHROMIUM_image */
#ifndef GL_CHROMIUM_image
#define GL_CHROMIUM_image 1

typedef struct _ClientBuffer* ClientBuffer;

#ifdef GL_GLEXT_PROTOTYPES
GL_APICALL GLuint GL_APIENTRY glCreateImageCHROMIUM(ClientBuffer buffer,
                                                    GLsizei width,
                                                    GLsizei height,
                                                    GLenum internalformat);
GL_APICALL void GL_APIENTRY glDestroyImageCHROMIUM(GLuint image_id);
#endif
typedef GLuint(GL_APIENTRYP PFNGLCREATEIMAGECHROMIUMPROC)(
    ClientBuffer buffer,
    GLsizei width,
    GLsizei height,
    GLenum internalformat);
typedef void (
    GL_APIENTRYP PFNGLDESTROYIMAGECHROMIUMPROC)(GLuint image_id);
#endif  /* GL_CHROMIUM_image */

  /* GL_CHROMIUM_gpu_memory_buffer_image */
#ifndef GL_CHROMIUM_gpu_memory_buffer_image
#define GL_CHROMIUM_gpu_memory_buffer_image 1

#ifndef GL_MAP_CHROMIUM
#define GL_MAP_CHROMIUM 0x78F1
#endif

#ifndef GL_SCANOUT_CHROMIUM
#define GL_SCANOUT_CHROMIUM 0x78F2
#endif

#ifdef GL_GLEXT_PROTOTYPES
GL_APICALL GLuint GL_APIENTRY glCreateGpuMemoryBufferImageCHROMIUM(
    GLsizei width,
    GLsizei height,
    GLenum internalformat,
    GLenum usage);
#endif
typedef GLuint(GL_APIENTRYP PFNGLCREATEGPUMEMORYBUFFERIMAGECHROMIUMPROC)(
    GLsizei width,
    GLsizei height,
    GLenum internalformat,
    GLenum usage);
#endif  /* GL_CHROMIUM_gpu_memory_buffer_image */

/* GL_CHROMIUM_map_sub */
#ifndef GL_CHROMIUM_map_sub
#define GL_CHROMIUM_map_sub 1

#ifndef GL_READ_ONLY
#define GL_READ_ONLY 0x88B8
#endif

#ifndef GL_WRITE_ONLY
#define GL_WRITE_ONLY 0x88B9
#endif
#ifdef GL_GLEXT_PROTOTYPES
GL_APICALL void* GL_APIENTRY glMapBufferSubDataCHROMIUM(
    GLuint target, GLintptr offset, GLsizeiptr size, GLenum access);
GL_APICALL void GL_APIENTRY glUnmapBufferSubDataCHROMIUM(const void* mem);
GL_APICALL void* GL_APIENTRY glMapTexSubImage2DCHROMIUM(
    GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width,
    GLsizei height, GLenum format, GLenum type, GLenum access);
GL_APICALL void GL_APIENTRY glUnmapTexSubImage2DCHROMIUM(const void* mem);
#endif
typedef void* (GL_APIENTRYP PFNGLMAPBUFFERSUBDATACHROMIUMPROC) (
    GLuint target, GLintptr offset, GLsizeiptr size, GLenum access);
typedef void (
    GL_APIENTRYP PFNGLUNMAPBUFFERSUBDATACHROMIUMPROC) (const void* mem);
typedef void* (GL_APIENTRYP PFNGLMAPTEXSUBIMAGE2DCHROMIUMPROC) (
    GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width,
    GLsizei height, GLenum format, GLenum type, GLenum access);
typedef void (
    GL_APIENTRYP PFNGLUNMAPTEXSUBIMAGE2DCHROMIUMPROC) (const void* mem);
#endif  /* GL_CHROMIUM_map_sub */

/* GL_CHROMIUM_request_extension */
#ifndef GL_CHROMIUM_request_extension
#define GL_CHROMIUM_request_extension 1
#ifdef GL_GLEXT_PROTOTYPES
GL_APICALL const GLchar* GL_APIENTRY glGetRequestableExtensionsCHROMIUM();
GL_APICALL void GL_APIENTRY glRequestExtensionCHROMIUM(const char* extension);
#endif
typedef const GLchar* (GL_APIENTRYP PFNGLGETREQUESTABLEEXTENSIONSCHROMIUMPROC) (
    );
typedef void (GL_APIENTRYP PFNGLREQUESTEXTENSIONCHROMIUMPROC) (
    const char* extension);
#endif  /* GL_CHROMIUM_request_extension */

/* GL_CHROMIUM_get_error_query */
#ifndef GL_CHROMIUM_get_error_query
#define GL_CHROMIUM_get_error_query 1

#ifndef GL_GET_ERROR_QUERY_CHROMIUM
// TODO(gman): Get official numbers for this constants.
#define GL_GET_ERROR_QUERY_CHROMIUM 0x6003
#endif
#endif  /* GL_CHROMIUM_get_error_query */

/* GL_CHROMIUM_texture_from_image */
#ifndef GL_CHROMIUM_texture_from_image
#define GL_CHROMIUM_texture_from_image 1
#ifdef GL_GLEXT_PROTOTYPES
GL_APICALL void GL_APIENTRY glBindTexImage2DCHROMIUM(
    GLenum target, GLint imageId);
GL_APICALL void GL_APIENTRY glReleaseTexImage2DCHROMIUM(
    GLenum target, GLint imageId);
#endif
typedef void (GL_APIENTRYP PFNGLBINDTEXIMAGE2DCHROMIUMPROC) (
    GLenum target, GLint imageId);
typedef void (GL_APIENTRYP PFNGLRELEASETEXIMAGE2DCHROMIUMPROC) (
    GLenum target, GLint imageId);
#endif  /* GL_CHROMIUM_texture_from_image */

/* GL_CHROMIUM_rate_limit_offscreen_context */
#ifndef GL_CHROMIUM_rate_limit_offscreen_context
#define GL_CHROMIUM_rate_limit_offscreen_context 1
#ifdef GL_GLEXT_PROTOTYPES
GL_APICALL void GL_APIENTRY glRateLimitOffscreenContextCHROMIUM();
#endif
typedef void (GL_APIENTRYP PFNGLRATELIMITOFFSCREENCONTEXTCHROMIUMPROC) ();
#endif  /* GL_CHROMIUM_rate_limit_offscreen_context */

/* GL_CHROMIUM_post_sub_buffer */
#ifndef GL_CHROMIUM_post_sub_buffer
#define GL_CHROMIUM_post_sub_buffer 1
#ifdef GL_GLEXT_PROTOTYPES
GL_APICALL void GL_APIENTRY glPostSubBufferCHROMIUM(
    GLint x, GLint y, GLint width, GLint height);
#endif
typedef void (GL_APIENTRYP PFNGLPOSTSUBBUFFERCHROMIUMPROC) (
    GLint x, GLint y, GLint width, GLint height);
#endif  /* GL_CHROMIUM_post_sub_buffer */

/* GL_CHROMIUM_bind_uniform_location */
#ifndef GL_CHROMIUM_bind_uniform_location
#define GL_CHROMIUM_bind_uniform_location 1
#ifdef GL_GLEXT_PROTOTYPES
GL_APICALL void GL_APIENTRY glBindUniformLocationCHROMIUM(
    GLuint program, GLint location, const char* name);
#endif
typedef void (GL_APIENTRYP PFNGLBINDUNIFORMLOCATIONCHROMIUMPROC) (
    GLuint program, GLint location, const char* name);
#endif  /* GL_CHROMIUM_bind_uniform_location */

/* GL_CHROMIUM_command_buffer_query */
#ifndef GL_CHROMIUM_command_buffer_query
#define GL_CHROMIUM_command_buffer_query 1

#ifndef GL_COMMANDS_ISSUED_CHROMIUM
// TODO(gman): Get official numbers for this constants.
#define GL_COMMANDS_ISSUED_CHROMIUM 0x6004
#endif
#endif  /* GL_CHROMIUM_command_buffer_query */

/* GL_CHROMIUM_framebuffer_multisample */
#ifndef GL_CHROMIUM_framebuffer_multisample
#define GL_CHROMIUM_framebuffer_multisample 1

#ifdef GL_GLEXT_PROTOTYPES
GL_APICALL void GL_APIENTRY glRenderbufferStorageMultisampleCHROMIUM (GLenum, GLsizei, GLenum, GLsizei, GLsizei);
GL_APICALL void GL_APIENTRY glBlitFramebufferCHROMIUM (GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1, GLint dstX0, GLint dstY0, GLint dstX1, GLint dstY1, GLbitfield mask, GLenum filter);
#endif
typedef void (GL_APIENTRYP PFNGLRENDERBUFFERSTORAGEMULTISAMPLECHROMIUMPROC) (GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height);
typedef void (GL_APIENTRYP PFNGLBLITFRAMEBUFFERCHROMIUMPROC) (GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1, GLint dstX0, GLint dstY0, GLint dstX1, GLint dstY1, GLbitfield mask, GLenum filter);

#ifndef GL_FRAMEBUFFER_BINDING_EXT
#define GL_FRAMEBUFFER_BINDING_EXT GL_FRAMEBUFFER_BINDING
#endif

#ifndef GL_DRAW_FRAMEBUFFER_BINDING_EXT
#define GL_DRAW_FRAMEBUFFER_BINDING_EXT GL_DRAW_FRAMEBUFFER_BINDING
#endif

#ifndef GL_RENDERBUFFER_BINDING_EXT
#define GL_RENDERBUFFER_BINDING_EXT GL_RENDERBUFFER_BINDING
#endif

#ifndef GL_RENDERBUFFER_SAMPLES
#define GL_RENDERBUFFER_SAMPLES 0x8CAB
#endif

#ifndef GL_READ_FRAMEBUFFER_EXT
#define GL_READ_FRAMEBUFFER_EXT GL_READ_FRAMEBUFFER
#endif

#ifndef GL_RENDERBUFFER_SAMPLES_EXT
#define GL_RENDERBUFFER_SAMPLES_EXT GL_RENDERBUFFER_SAMPLES
#endif

#ifndef GL_RENDERBUFFER_BINDING
#define GL_RENDERBUFFER_BINDING 0x8CA7
#endif

#ifndef GL_READ_FRAMEBUFFER_BINDING
#define GL_READ_FRAMEBUFFER_BINDING 0x8CAA
#endif

#ifndef GL_MAX_SAMPLES
#define GL_MAX_SAMPLES 0x8D57
#endif

#ifndef GL_READ_FRAMEBUFFER_BINDING_EXT
#define GL_READ_FRAMEBUFFER_BINDING_EXT GL_READ_FRAMEBUFFER_BINDING
#endif

#ifndef GL_DRAW_FRAMEBUFFER_BINDING
#define GL_DRAW_FRAMEBUFFER_BINDING 0x8CA6
#endif

#ifndef GL_MAX_SAMPLES_EXT
#define GL_MAX_SAMPLES_EXT GL_MAX_SAMPLES
#endif

#ifndef GL_DRAW_FRAMEBUFFER
#define GL_DRAW_FRAMEBUFFER 0x8CA9
#endif

#ifndef GL_READ_FRAMEBUFFER
#define GL_READ_FRAMEBUFFER 0x8CA8
#endif

#ifndef GL_DRAW_FRAMEBUFFER_EXT
#define GL_DRAW_FRAMEBUFFER_EXT GL_DRAW_FRAMEBUFFER
#endif

#ifndef GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE
#define GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE 0x8D56
#endif

#ifndef GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE_EXT
#define GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE_EXT GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE  // NOLINT
#endif

#ifndef GL_FRAMEBUFFER_BINDING
#define GL_FRAMEBUFFER_BINDING 0x8CA6
#endif
#endif  /* GL_CHROMIUM_framebuffer_multisample */

/* GL_CHROMIUM_texture_compression_dxt3 */
#ifndef GL_CHROMIUM_texture_compression_dxt3
#define GL_CHROMIUM_texture_compression_dxt3 1

#ifndef GL_COMPRESSED_RGBA_S3TC_DXT3_EXT
#define GL_COMPRESSED_RGBA_S3TC_DXT3_EXT 0x83F2
#endif
#endif  /* GL_CHROMIUM_texture_compression_dxt3 */

/* GL_CHROMIUM_texture_compression_dxt5 */
#ifndef GL_CHROMIUM_texture_compression_dxt5
#define GL_CHROMIUM_texture_compression_dxt5 1

#ifndef GL_COMPRESSED_RGBA_S3TC_DXT5_EXT
#define GL_COMPRESSED_RGBA_S3TC_DXT5_EXT 0x83F3
#endif
#endif  /* GL_CHROMIUM_texture_compression_dxt5 */

/* GL_CHROMIUM_async_pixel_transfers */
#ifndef GL_CHROMIUM_async_pixel_transfers
#define GL_CHROMIUM_async_pixel_transfers 1

#ifndef GL_ASYNC_PIXEL_UNPACK_COMPLETED_CHROMIUM
#define GL_ASYNC_PIXEL_UNPACK_COMPLETED_CHROMIUM 0x6005
#endif
#ifndef GL_ASYNC_PIXEL_PACK_COMPLETED_CHROMIUM
#define GL_ASYNC_PIXEL_PACK_COMPLETED_CHROMIUM 0x6006
#endif
#endif  /* GL_CHROMIUM_async_pixel_transfers */

#ifndef GL_BIND_GENERATES_RESOURCE_CHROMIUM
#define GL_BIND_GENERATES_RESOURCE_CHROMIUM 0x9244
#endif

/* GL_CHROMIUM_copy_texture */
#ifndef GL_CHROMIUM_copy_texture
#define GL_CHROMIUM_copy_texture 1

#ifndef GL_UNPACK_COLORSPACE_CONVERSION_CHROMIUM
#define GL_UNPACK_COLORSPACE_CONVERSION_CHROMIUM 0x9243
#endif

#ifndef GL_UNPACK_UNPREMULTIPLY_ALPHA_CHROMIUM
#define GL_UNPACK_UNPREMULTIPLY_ALPHA_CHROMIUM 0x9242
#endif

#ifndef GL_UNPACK_PREMULTIPLY_ALPHA_CHROMIUM
#define GL_UNPACK_PREMULTIPLY_ALPHA_CHROMIUM 0x9241
#endif
#ifdef GL_GLEXT_PROTOTYPES
GL_APICALL void GL_APIENTRY glCopyTextureCHROMIUM(GLenum target,
                                                  GLenum source_id,
                                                  GLenum dest_id,
                                                  GLint internalformat,
                                                  GLenum dest_type);

GL_APICALL void GL_APIENTRY glCopySubTextureCHROMIUM(GLenum target,
                                                     GLenum source_id,
                                                     GLenum dest_id,
                                                     GLint xoffset,
                                                     GLint yoffset);
#endif
typedef void(GL_APIENTRYP PFNGLCOPYTEXTURECHROMIUMPROC)(GLenum target,
                                                        GLenum source_id,
                                                        GLenum dest_id,
                                                        GLint internalformat,
                                                        GLenum dest_type);

typedef void(GL_APIENTRYP PFNGLCOPYSUBTEXTURECHROMIUMPROC)(GLenum target,
                                                           GLenum source_id,
                                                           GLenum dest_id,
                                                           GLint xoffset,
                                                           GLint yoffset);
#endif  /* GL_CHROMIUM_copy_texture */

/* GL_CHROMIUM_lose_context */
#ifndef GL_CHROMIUM_lose_context
#define GL_CHROMIUM_lose_context 1
#ifdef GL_GLEXT_PROTOTYPES
GL_APICALL void GL_APIENTRY glLoseContextCHROMIUM(GLenum current, GLenum other);
#endif
typedef void (GL_APIENTRYP PFNGLLOSECONTEXTCHROMIUMPROC) (
    GLenum current, GLenum other);
#endif  /* GL_CHROMIUM_lose_context */

/* GL_CHROMIUM_flipy */
#ifndef GL_CHROMIUM_flipy
#define GL_CHROMIUM_flipy 1

#ifndef GL_UNPACK_FLIP_Y_CHROMIUM
#define GL_UNPACK_FLIP_Y_CHROMIUM 0x9240
#endif
#endif  /* GL_CHROMIUM_flipy */

/* GL_ARB_texture_rectangle */
#ifndef GL_ARB_texture_rectangle
#define GL_ARB_texture_rectangle 1

#ifndef GL_SAMPLER_2D_RECT_ARB
#define GL_SAMPLER_2D_RECT_ARB 0x8B63
#endif

#ifndef GL_TEXTURE_BINDING_RECTANGLE_ARB
#define GL_TEXTURE_BINDING_RECTANGLE_ARB 0x84F6
#endif

#ifndef GL_TEXTURE_RECTANGLE_ARB
#define GL_TEXTURE_RECTANGLE_ARB 0x84F5
#endif
#endif  /* GL_ARB_texture_rectangle */

/* GL_CHROMIUM_enable_feature */
#ifndef GL_CHROMIUM_enable_feature
#define GL_CHROMIUM_enable_feature 1
#ifdef GL_GLEXT_PROTOTYPES
GL_APICALL GLboolean GL_APIENTRY glEnableFeatureCHROMIUM(const char* feature);
#endif
typedef GLboolean (GL_APIENTRYP PFNGLENABLEFEATURECHROMIUMPROC) (
    const char* feature);
#endif  /* GL_CHROMIUM_enable_feature */

/* GL_CHROMIUM_command_buffer_latency_query */
#ifndef GL_CHROMIUM_command_buffer_latency_query
#define GL_CHROMIUM_command_buffer_latency_query 1

#ifndef GL_LATENCY_QUERY_CHROMIUM
// TODO(gman): Get official numbers for these constants.
#define GL_LATENCY_QUERY_CHROMIUM 0x6007
#endif
#endif  /* GL_CHROMIUM_command_buffer_latency_query */

/* GL_ARB_robustness */
#ifndef GL_ARB_robustness
#define GL_ARB_robustness 1

#ifndef GL_GUILTY_CONTEXT_RESET_ARB
#define GL_GUILTY_CONTEXT_RESET_ARB 0x8253
#endif

#ifndef GL_UNKNOWN_CONTEXT_RESET_ARB
#define GL_UNKNOWN_CONTEXT_RESET_ARB 0x8255
#endif

#ifndef GL_INNOCENT_CONTEXT_RESET_ARB
#define GL_INNOCENT_CONTEXT_RESET_ARB 0x8254
#endif
#endif  /* GL_ARB_robustness */

/* GL_EXT_framebuffer_blit */
#ifndef GL_EXT_framebuffer_blit
#define GL_EXT_framebuffer_blit 1
#ifdef GL_GLEXT_PROTOTYPES
GL_APICALL void GL_APIENTRY glBlitFramebufferEXT(
    GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1, GLint dstX0,
    GLint dstY0, GLint dstX1, GLint dstY1, GLbitfield mask, GLenum filter);
#endif
typedef void (GL_APIENTRYP PFNGLBLITFRAMEBUFFEREXTPROC) (
    GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1, GLint dstX0,
    GLint dstY0, GLint dstX1, GLint dstY1, GLbitfield mask, GLenum filter);
#endif  /* GL_EXT_framebuffer_blit */

/* GL_EXT_draw_buffers */
#ifndef GL_EXT_draw_buffers
#define GL_EXT_draw_buffers 1

#ifdef GL_GLEXT_PROTOTYPES
GL_APICALL void GL_APIENTRY glDrawBuffersEXT(
    GLsizei n, const GLenum* bufs);
#endif
typedef void (GL_APIENTRYP PFNGLDRAWBUFFERSEXTPROC) (
    GLsizei n, const GLenum* bufs);

#ifndef GL_COLOR_ATTACHMENT0_EXT
#define GL_COLOR_ATTACHMENT0_EXT 0x8CE0
#endif
#ifndef GL_COLOR_ATTACHMENT1_EXT
#define GL_COLOR_ATTACHMENT1_EXT 0x8CE1
#endif
#ifndef GL_COLOR_ATTACHMENT2_EXT
#define GL_COLOR_ATTACHMENT2_EXT 0x8CE2
#endif
#ifndef GL_COLOR_ATTACHMENT3_EXT
#define GL_COLOR_ATTACHMENT3_EXT 0x8CE3
#endif
#ifndef GL_COLOR_ATTACHMENT4_EXT
#define GL_COLOR_ATTACHMENT4_EXT 0x8CE4
#endif
#ifndef GL_COLOR_ATTACHMENT5_EXT
#define GL_COLOR_ATTACHMENT5_EXT 0x8CE5
#endif
#ifndef GL_COLOR_ATTACHMENT6_EXT
#define GL_COLOR_ATTACHMENT6_EXT 0x8CE6
#endif
#ifndef GL_COLOR_ATTACHMENT7_EXT
#define GL_COLOR_ATTACHMENT7_EXT 0x8CE7
#endif
#ifndef GL_COLOR_ATTACHMENT8_EXT
#define GL_COLOR_ATTACHMENT8_EXT 0x8CE8
#endif
#ifndef GL_COLOR_ATTACHMENT9_EXT
#define GL_COLOR_ATTACHMENT9_EXT 0x8CE9
#endif
#ifndef GL_COLOR_ATTACHMENT10_EXT
#define GL_COLOR_ATTACHMENT10_EXT 0x8CEA
#endif
#ifndef GL_COLOR_ATTACHMENT11_EXT
#define GL_COLOR_ATTACHMENT11_EXT 0x8CEB
#endif
#ifndef GL_COLOR_ATTACHMENT12_EXT
#define GL_COLOR_ATTACHMENT12_EXT 0x8CEC
#endif
#ifndef GL_COLOR_ATTACHMENT13_EXT
#define GL_COLOR_ATTACHMENT13_EXT 0x8CED
#endif
#ifndef GL_COLOR_ATTACHMENT14_EXT
#define GL_COLOR_ATTACHMENT14_EXT 0x8CEE
#endif
#ifndef GL_COLOR_ATTACHMENT15_EXT
#define GL_COLOR_ATTACHMENT15_EXT 0x8CEF
#endif

#ifndef GL_DRAW_BUFFER0_EXT
#define GL_DRAW_BUFFER0_EXT 0x8825
#endif
#ifndef GL_DRAW_BUFFER1_EXT
#define GL_DRAW_BUFFER1_EXT 0x8826
#endif
#ifndef GL_DRAW_BUFFER2_EXT
#define GL_DRAW_BUFFER2_EXT 0x8827
#endif
#ifndef GL_DRAW_BUFFER3_EXT
#define GL_DRAW_BUFFER3_EXT 0x8828
#endif
#ifndef GL_DRAW_BUFFER4_EXT
#define GL_DRAW_BUFFER4_EXT 0x8829
#endif
#ifndef GL_DRAW_BUFFER5_EXT
#define GL_DRAW_BUFFER5_EXT 0x882A
#endif
#ifndef GL_DRAW_BUFFER6_EXT
#define GL_DRAW_BUFFER6_EXT 0x882B
#endif
#ifndef GL_DRAW_BUFFER7_EXT
#define GL_DRAW_BUFFER7_EXT 0x882C
#endif
#ifndef GL_DRAW_BUFFER8_EXT
#define GL_DRAW_BUFFER8_EXT 0x882D
#endif
#ifndef GL_DRAW_BUFFER9_EXT
#define GL_DRAW_BUFFER9_EXT 0x882E
#endif
#ifndef GL_DRAW_BUFFER10_EXT
#define GL_DRAW_BUFFER10_EXT 0x882F
#endif
#ifndef GL_DRAW_BUFFER11_EXT
#define GL_DRAW_BUFFER11_EXT 0x8830
#endif
#ifndef GL_DRAW_BUFFER12_EXT
#define GL_DRAW_BUFFER12_EXT 0x8831
#endif
#ifndef GL_DRAW_BUFFER13_EXT
#define GL_DRAW_BUFFER13_EXT 0x8832
#endif
#ifndef GL_DRAW_BUFFER14_EXT
#define GL_DRAW_BUFFER14_EXT 0x8833
#endif
#ifndef GL_DRAW_BUFFER15_EXT
#define GL_DRAW_BUFFER15_EXT 0x8834
#endif

#ifndef GL_MAX_COLOR_ATTACHMENTS_EXT
#define GL_MAX_COLOR_ATTACHMENTS_EXT 0x8CDF
#endif

#ifndef GL_MAX_DRAW_BUFFERS_EXT
#define GL_MAX_DRAW_BUFFERS_EXT 0x8824
#endif

#endif  /* GL_EXT_draw_buffers */

/* GL_CHROMIUM_resize */
#ifndef GL_CHROMIUM_resize
#define GL_CHROMIUM_resize 1
#ifdef GL_GLEXT_PROTOTYPES
GL_APICALL void GL_APIENTRY glResizeCHROMIUM(
    GLuint width, GLuint height, GLfloat scale_factor);
#endif
typedef void (GL_APIENTRYP PFNGLRESIZECHROMIUMPROC) (
    GLuint width, GLuint height);
#endif  /* GL_CHROMIUM_resize */

/* GL_CHROMIUM_get_multiple */
#ifndef GL_CHROMIUM_get_multiple
#define GL_CHROMIUM_get_multiple 1
#ifdef GL_GLEXT_PROTOTYPES
GL_APICALL void GL_APIENTRY glGetProgramInfoCHROMIUM(
    GLuint program, GLsizei bufsize, GLsizei* size, void* info);
#endif
typedef void (GL_APIENTRYP PFNGLGETPROGRAMINFOCHROMIUMPROC) (
   GLuint program, GLsizei bufsize, GLsizei* size, void* info);
#endif  /* GL_CHROMIUM_get_multiple */

/* GL_CHROMIUM_sync_point */
#ifndef GL_CHROMIUM_sync_point
#define GL_CHROMIUM_sync_point 1
#ifdef GL_GLEXT_PROTOTYPES
GL_APICALL GLuint GL_APIENTRY glInsertSyncPointCHROMIUM();
GL_APICALL void GL_APIENTRY glWaitSyncPointCHROMIUM(GLuint sync_point);
#endif
typedef GLuint (GL_APIENTRYP PFNGLINSERTSYNCPOINTCHROMIUMPROC) ();
typedef void (GL_APIENTRYP PFNGLWAITSYNCPOINTCHROMIUMPROC) (GLuint sync_point);
#endif  /* GL_CHROMIUM_sync_point */

#ifndef GL_CHROMIUM_color_buffer_float_rgba
#define GL_CHROMIUM_color_buffer_float_rgba 1
#ifndef GL_RGBA32F
#define GL_RGBA32F 0x8814
#endif
#endif /* GL_CHROMIUM_color_buffer_float_rgba */

#ifndef GL_CHROMIUM_color_buffer_float_rgb
#define GL_CHROMIUM_color_buffer_float_rgb 1
#ifndef GL_RGB32F
#define GL_RGB32F 0x8815
#endif
#endif /* GL_CHROMIUM_color_buffer_float_rgb */

/* GL_CHROMIUM_schedule_overlay_plane */
#ifndef GL_CHROMIUM_schedule_overlay_plane
#define GL_CHROMIUM_schedule_overlay_plane 1

#ifndef GL_OVERLAY_TRANSFORM_NONE_CHROMIUM
#define GL_OVERLAY_TRANSFORM_NONE_CHROMIUM 0x9245
#endif

#ifndef GL_OVERLAY_TRANSFORM_FLIP_HORIZONTAL_CHROMIUM
#define GL_OVERLAY_TRANSFORM_FLIP_HORIZONTAL_CHROMIUM 0x9246
#endif

#ifndef GL_OVERLAY_TRANSFORM_FLIP_VERTICAL_CHROMIUM
#define GL_OVERLAY_TRANSFORM_FLIP_VERTICAL_CHROMIUM 0x9247
#endif

#ifndef GL_OVERLAY_TRANSFORM_ROTATE_90_CHROMIUM
#define GL_OVERLAY_TRANSFORM_ROTATE_90_CHROMIUM 0x9248
#endif

#ifndef GL_OVERLAY_TRANSFORM_ROTATE_180_CHROMIUM
#define GL_OVERLAY_TRANSFORM_ROTATE_180_CHROMIUM 0x9249
#endif

#ifndef GL_OVERLAY_TRANSFORM_ROTATE_270_CHROMIUM
#define GL_OVERLAY_TRANSFORM_ROTATE_270_CHROMIUM 0x924A
#endif

/* GL_CHROMIUM_subscribe_uniform */
#ifndef GL_CHROMIUM_subscribe_uniform
#define GL_CHROMIUM_subscribe_uniform 1

#ifndef GL_SUBSCRIBED_VALUES_BUFFER_CHROMIUM
#define GL_SUBSCRIBED_VALUES_BUFFER_CHROMIUM 0x924B
#endif

#ifndef GL_MOUSE_POSITION_CHROMIUM
#define GL_MOUSE_POSITION_CHROMIUM 0x924C
#endif

#ifdef GL_GLEXT_PROTOTYPES
GL_APICALL void GL_APIENTRY
glGenValuebuffersCHROMIUM(GLsizei n, GLuint* buffers);
GL_APICALL void GL_APIENTRY
glDeleteValuebuffersCHROMIUM(GLsizei n, const GLuint* valuebuffers);
GL_APICALL GLboolean GL_APIENTRY glIsValuebufferCHROMIUM(GLuint valuebuffer);
GL_APICALL void GL_APIENTRY
glBindValuebufferCHROMIUM(GLenum target, GLuint valuebuffer);
GL_APICALL void GL_APIENTRY
glSubscribeValueCHROMIUM(GLenum target, GLenum subscription);
GL_APICALL void GL_APIENTRY glPopulateSubscribedValuesCHROMIUM(GLenum target);
GL_APICALL void GL_APIENTRY glUniformValuebufferCHROMIUM(GLint location,
                                                         GLenum target,
                                                         GLenum subscription);
#endif
#endif /* GL_CHROMIUM_subscribe_uniform */

#ifdef GL_GLEXT_PROTOTYPES
GL_APICALL void GL_APIENTRY
    glScheduleOverlayPlaneCHROMIUM(GLint plane_z_order,
                                   GLenum plane_transform,
                                   GLuint overlay_texture_id,
                                   GLint bounds_x,
                                   GLint bounds_y,
                                   GLint bounds_width,
                                   GLint bounds_height,
                                   GLfloat uv_x,
                                   GLfloat uv_y,
                                   GLfloat uv_width,
                                   GLfloat uv_height);
#endif
typedef void(GL_APIENTRYP PFNGLSCHEDULEOVERLAYPLANECHROMIUMPROC)(
    GLint plane_z_order,
    GLenum plane_transform,
    GLuint overlay_texture_id,
    GLint bounds_x,
    GLint bounds_y,
    GLint bounds_width,
    GLint bounds_height,
    GLfloat uv_x,
    GLfloat uv_y,
    GLfloat uv_width,
    GLfloat uv_height);
#endif /* GL_CHROMIUM_schedule_overlay_plane */

/* GL_CHROMIUM_sync_query */
#ifndef GL_CHROMIUM_sync_query
#define GL_CHROMIUM_sync_query 1

#ifndef GL_COMMANDS_COMPLETED_CHROMIUM
#define GL_COMMANDS_COMPLETED_CHROMIUM 0x84F7
#endif
#endif  /* GL_CHROMIUM_sync_query */

#ifndef GL_CHROMIUM_path_rendering
#define GL_CHROMIUM_path_rendering 1

#ifdef GL_GLEXT_PROTOTYPES
GL_APICALL void GL_APIENTRY
    glMatrixLoadfCHROMIUM(GLenum mode, const GLfloat* m);
GL_APICALL void GL_APIENTRY glMatrixLoadIdentityCHROMIUM(GLenum mode);
#endif

typedef void(GL_APIENTRYP PFNGLMATRIXLOADFCHROMIUMPROC)(GLenum matrixMode,
                                                        const GLfloat* m);
typedef void(GL_APIENTRYP PFNGLMATRIXLOADIDENTITYCHROMIUMPROC)(
    GLenum matrixMode);

#endif /* GL_CHROMIUM_path_rendering */

#ifdef __cplusplus
}
#endif

#endif  // GPU_GLES2_GL2EXTCHROMIUM_H_
