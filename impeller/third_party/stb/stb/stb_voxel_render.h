// stb_voxel_render.h - v0.84 - Sean Barrett, 2015 - public domain
//
// This library helps render large-scale "voxel" worlds for games,
// in this case, one with blocks that can have textures and that
// can also be a few shapes other than cubes.
//
//    Video introduction:
//       http://www.youtube.com/watch?v=2vnTtiLrV1w
//
//    Minecraft-viewer sample app (not very simple though):
//       http://github.com/nothings/stb/tree/master/tests/caveview
//
// It works by creating triangle meshes. The library includes
//
//    - converter from dense 3D arrays of block info to vertex mesh
//    - shader for the vertex mesh
//    - assistance in setting up shader state
//
// For portability, none of the library code actually accesses
// the 3D graphics API. (At the moment, it's not actually portable
// since the shaders are GLSL only, but patches are welcome.)
//
// You have to do all the caching and tracking of vertex buffers
// yourself. However, you could also try making a game with
// a small enough world that it's fully loaded rather than
// streaming. Currently the preferred vertex format is 20 bytes
// per quad. There are plans to allow much more compact formats
// with a slight reduction in shader features.
//
//
// USAGE
//
//   #define the symbol STB_VOXEL_RENDER_IMPLEMENTATION in *one*
//   C/C++ file before the #include of this file; the implementation
//   will be generated in that file.
//
//   If you define the symbols STB_VOXEL_RENDER_STATIC, then the
//   implementation will be private to that file.
//
//
// FEATURES
//
//   - you can choose textured blocks with the features below,
//     or colored voxels with 2^24 colors and no textures.
//
//   - voxels are mostly just cubes, but there's support for
//     half-height cubes and diagonal slopes, half-height
//     diagonals, and even odder shapes especially for doing
//     more-continuous "ground".
//
//   - texture coordinates are projections along one of the major
//     axes, with the per-texture scaling.
//
//   - a number of aspects of the shader and the vertex format
//     are configurable; the library generally takes care of
//     coordinating the vertex format with the mesh for you.
//
//
// FEATURES (SHADER PERSPECTIVE)
//
//   - vertices aligned on integer lattice, z on multiples of 0.5
//   - per-vertex "lighting" or "ambient occlusion" value (6 bits)
//   - per-vertex texture crossfade (3 bits)
//
//   - per-face texture #1 id (8-bit index into array texture)
//   - per-face texture #2 id (8-bit index into second array texture)
//   - per-face color (6-bit palette index, 2 bits of per-texture boolean enable)
//   - per-face 5-bit normal for lighting calculations & texture coord computation
//   - per-face 2-bit texture matrix rotation to rotate faces
//
//   - indexed-by-texture-id scale factor (separate for texture #1 and texture #2)
//   - indexed-by-texture-#2-id blend mode (alpha composite or modulate/multiply);
//     the first is good for decals, the second for detail textures, "light maps",
//     etc; both modes are controlled by texture #2's alpha, scaled by the
//     per-vertex texture crossfade and the per-face color (if enabled on texture #2);
//     modulate/multiply multiplies by an extra factor of 2.0 so that if you
//     make detail maps whose average brightness is 0.5 everything works nicely.
//
//   - ambient lighting: half-lambert directional plus constant, all scaled by vertex ao
//   - face can be fullbright (emissive), controlled by per-face color
//   - installable lighting, with default single-point-light
//   - installable fog, with default hacked smoothstep
//
//  Note that all the variations of lighting selection and texture
//  blending are run-time conditions in the shader, so they can be
//  intermixed in a single mesh.
//
//
// INTEGRATION ARC
//
//   The way to get this library to work from scratch is to do the following:
//
//      Step 1. define STBVOX_CONFIG_MODE to 0
//
//        This mode uses only vertex attributes and uniforms, and is easiest
//        to get working. It requires 32 bytes per quad and limits the
//        size of some tables to avoid hitting uniform limits.
//
//      Step 2. define STBVOX_CONFIG_MODE to 1
//
//        This requires using a texture buffer to store the quad data,
//        reducing the size to 20 bytes per quad.
//
//      Step 3: define STBVOX_CONFIG_PREFER_TEXBUFFER
//
//        This causes some uniforms to be stored as texture buffers
//        instead. This increases the size of some of those tables,
//        and avoids a potential slow path (gathering non-uniform
//        data from uniforms) on some hardware.
//
//   In the future I hope to add additional modes that have significantly
//   smaller meshes but reduce features, down as small as 6 bytes per quad.
//   See elsewhere in this file for a table of candidate modes. Switching
//   to a mode will require changing some of your mesh creation code, but
//   everything else should be seamless. (And I'd like to change the API
//   so that mesh creation is data-driven the way the uniforms are, and
//   then you wouldn't even have to change anything but the mode number.)
//
//
// IMPROVEMENTS FOR SHIP-WORTHY PROGRAMS USING THIS LIBRARY
//
//   I currently tolerate a certain level of "bugginess" in this library.
//
//   I'm referring to things which look a little wrong (as long as they
//   don't cause holes or cracks in the output meshes), or things which
//   do not produce as optimal a mesh as possible. Notable examples:
//
//        -  incorrect lighting on slopes
//        -  inefficient meshes for vheight blocks
//
//   I am willing to do the work to improve these things if someone is
//   going to ship a substantial program that would be improved by them.
//   (It need not be commercial, nor need it be a game.) I just didn't
//   want to do the work up front if it might never be leveraged. So just
//   submit a bug report as usual (github is preferred), but add a note
//   that this is for a thing that is really going to ship. (That means
//   you need to be far enough into the project that it's clear you're
//   committed to it; not during early exploratory development.)
//
//
// VOXEL MESH API
//
//   Context
//
//     To understand the API, make sure you first understand the feature set
//     listed above.
//
//     Because the vertices are compact, they have very limited spatial
//     precision. Thus a single mesh can only contain the data for a limited
//     area. To make very large voxel maps, you'll need to build multiple
//     vertex buffers. (But you want this anyway for frustum culling.)
//
//     Each generated mesh has three components:
//             - vertex data (vertex buffer)
//             - face data (optional, stored in texture buffer)
//             - mesh transform (uniforms)
//
//     Once you've generated the mesh with this library, it's up to you
//     to upload it to the GPU, to keep track of the state, and to render
//     it.
//
//   Concept
//
//     The basic design is that you pass in one or more 3D arrays; each array
//     is (typically) one-byte-per-voxel and contains information about one
//     or more properties of some particular voxel property.
//
//     Because there is so much per-vertex and per-face data possible
//     in the output, and each voxel can have 6 faces and 8 vertices, it
//     would require an very large data structure to describe all
//     of the possibilities, and this would cause the mesh-creation
//     process to be slow. Instead, the API provides multiple ways
//     to express each property, some more compact, others less so;
//     each such way has some limitations on what it can express.
//
//     Note that there are so many paths and combinations, not all of them
//     have been tested. Just report bugs and I'll fix 'em.
//
//   Details
//
//     See the API documentation in the header-file section.
//
//
// CONTRIBUTORS
//
//   Features             Porting            Bugfixes & Warnings
//  Sean Barrett                          github:r-leyh   Jesus Fernandez
//                                        Miguel Lechon   github:Arbeiterunfallversicherungsgesetz
//                                        Thomas Frase    James Hofmann
//                                        Stephen Olsen
//
// VERSION HISTORY
//
//   0.84   (2016-04-02)  fix GLSL syntax error on glModelView path
//   0.83   (2015-09-13)  remove non-constant struct initializers to support more compilers
//   0.82   (2015-08-01)  added input.packed_compact to store rot, vheight & texlerp efficiently
//                        fix broken tex_overlay2
//   0.81   (2015-05-28)  fix broken STBVOX_CONFIG_OPTIMIZED_VHEIGHT
//   0.80   (2015-04-11)  fix broken STBVOX_CONFIG_ROTATION_IN_LIGHTING refactoring
//                        change STBVOX_MAKE_LIGHTING to STBVOX_MAKE_LIGHTING_EXT so
//                                    that header defs don't need to see config vars
//                        add STBVOX_CONFIG_VHEIGHT_IN_LIGHTING and other vheight fixes
//                        added documentation for vheight ("weird slopes")
//   0.79   (2015-04-01)  fix the missing types from 0.78; fix string constants being const
//   0.78   (2015-04-02)  bad "#else", compile as C++
//   0.77   (2015-04-01)  documentation tweaks, rename config var to STB_VOXEL_RENDER_STATIC
//   0.76   (2015-04-01)  typos, signed/unsigned shader issue, more documentation
//   0.75   (2015-04-01)  initial release
//
//
// HISTORICAL FOUNDATION
//
//   stb_voxel_render   20-byte quads   2015/01
//   zmc engine         32-byte quads   2013/12
//   zmc engine         96-byte quads   2011/10
//
//
// LICENSE
//
//   This software is dual-licensed to the public domain and under the following
//   license: you are granted a perpetual, irrevocable license to copy, modify,
//   publish, and distribute this file as you see fit.

#ifndef INCLUDE_STB_VOXEL_RENDER_H
#define INCLUDE_STB_VOXEL_RENDER_H

#include <stdlib.h>

typedef struct stbvox_mesh_maker stbvox_mesh_maker;
typedef struct stbvox_input_description stbvox_input_description;

#ifdef STB_VOXEL_RENDER_STATIC
#define STBVXDEC static
#else
#define STBVXDEC extern
#endif

#ifdef __cplusplus
extern "C" {
#endif

//////////////////////////////////////////////////////////////////////////////
//
// CONFIGURATION MACROS
//
//  #define STBVOX_CONFIG_MODE <integer>           // REQUIRED
//     Configures the overall behavior of stb_voxel_render. This
//     can affect the shaders, the uniform info, and other things.
//     (If you need more than one mode in the same app, you can
//     use STB_VOXEL_RENDER_STATIC to create multiple versions
//     in separate files, and then wrap them.)
//
//         Mode value       Meaning
//             0               Textured blocks, 32-byte quads
//             1               Textured blocks, 20-byte quads
//            20               Untextured blocks, 32-byte quads
//            21               Untextured blocks, 20-byte quads
//
//
//  #define STBVOX_CONFIG_PRECISION_Z  <integer>   // OPTIONAL
//     Defines the number of bits of fractional position for Z.
//     Only 0 or 1 are valid. 1 is the default. If 0, then a
//     single mesh has twice the legal Z range; e.g. in
//     modes 0,1,20,21, Z in the mesh can extend to 511 instead
//     of 255. However, half-height blocks cannot be used.
//
// All of the following just #ifdef tested so need no values, and are optional.
//
//    STBVOX_CONFIG_BLOCKTYPE_SHORT
//        use unsigned 16-bit values for 'blocktype' in the input instead of 8-bit values
//
//    STBVOX_CONFIG_OPENGL_MODELVIEW
//        use the gl_ModelView matrix rather than the explicit uniform
//
//    STBVOX_CONFIG_HLSL
//        NOT IMPLEMENTED! Define HLSL shaders instead of GLSL shaders
//
//    STBVOX_CONFIG_PREFER_TEXBUFFER
//        Stores many of the uniform arrays in texture buffers intead,
//        so they can be larger and may be more efficient on some hardware.
//
//    STBVOX_CONFIG_LIGHTING_SIMPLE
//        Creates a simple lighting engine with a single point light source
//        in addition to the default half-lambert ambient light.
//
//    STBVOX_CONFIG_LIGHTING
//        Declares a lighting function hook; you must append a lighting function
//        to the shader before compiling it:
//            vec3 compute_lighting(vec3 pos, vec3 norm, vec3 albedo, vec3 ambient);
//        'ambient' is the half-lambert ambient light with vertex ambient-occlusion applied
//
//    STBVOX_CONFIG_FOG_SMOOTHSTEP
//        Defines a simple unrealistic fog system designed to maximize
//        unobscured view distance while not looking too weird when things
//        emerge from the fog. Configured using an extra array element
//        in the STBVOX_UNIFORM_ambient uniform.
//
//    STBVOX_CONFIG_FOG
//        Defines a fog function hook; you must append a fog function to
//        the shader before compiling it:
//            vec3 compute_fog(vec3 color, vec3 relative_pos, float fragment_alpha);
//        "color" is the incoming pre-fogged color, fragment_alpha is the alpha value,
//        and relative_pos is the vector from the point to the camera in worldspace
//
//    STBVOX_CONFIG_DISABLE_TEX2
//        This disables all processing of texture 2 in the shader in case
//        you don't use it. Eventually this will be replaced with a mode
//        that omits the unused data entirely.
//
//    STBVOX_CONFIG_TEX1_EDGE_CLAMP
//    STBVOX_CONFIG_TEX2_EDGE_CLAMP
//        If you want to edge clamp the textures, instead of letting them wrap,
//        set this flag. By default stb_voxel_render relies on texture wrapping
//        to simplify texture coordinate generation. This flag forces it to do
//        it correctly, although there can still be minor artifacts.
//
//    STBVOX_CONFIG_ROTATION_IN_LIGHTING
//        Changes the meaning of the 'lighting' mesher input variable to also
//        store the rotation; see later discussion.
//
//    STBVOX_CONFIG_VHEIGHT_IN_LIGHTING
//        Changes the meaning of the 'lighting' mesher input variable to also
//        store the vheight; see later discussion. Cannot use both this and
//        the previous variable.
//
//    STBVOX_CONFIG_PREMULTIPLIED_ALPHA
//        Adjusts the shader calculations on the assumption that tex1.rgba,
//        tex2.rgba, and color.rgba all use premultiplied values, and that
//        the output of the fragment shader should be premultiplied.
//
//    STBVOX_CONFIG_UNPREMULTIPLY
//        Only meaningful if STBVOX_CONFIG_PREMULTIPLIED_ALPHA is defined.
//        Changes the behavior described above so that the inputs are
//        still premultiplied alpha, but the output of the fragment
//        shader is not premultiplied alpha. This is needed when allowing
//        non-unit alpha values but not doing alpha-blending (for example
//        when alpha testing).
//

//////////////////////////////////////////////////////////////////////////////
//
// MESHING
//
// A mesh represents a (typically) small chunk of a larger world.
// Meshes encode coordinates using small integers, so those
// coordinates must be relative to some base location.
// All of the coordinates in the functions below use
// these relative coordinates unless explicitly stated
// otherwise.
//
// Input to the meshing step is documented further down

STBVXDEC void stbvox_init_mesh_maker(stbvox_mesh_maker *mm);
// Call this function to initialize a mesh-maker context structure
// used to build meshes. You should have one context per thread
// that's building meshes.

STBVXDEC void stbvox_set_buffer(stbvox_mesh_maker *mm, int mesh, int slot, void *buffer, size_t len);
// Call this to set the buffer into which stbvox will write the mesh
// it creates. It can build more than one mesh in parallel (distinguished
// by the 'mesh' parameter), and each mesh can be made up of more than
// one buffer (distinguished by the 'slot' parameter).
//
// Multiple meshes are under your control; use the 'selector' input
// variable to choose which mesh each voxel's vertices are written to.
// For example, you can use this to generate separate meshes for opaque
// and transparent data.
//
// You can query the number of slots by calling stbvox_get_buffer_count
// described below. The meaning of the buffer for each slot depends
// on STBVOX_CONFIG_MODE.
//
//   In mode 0 & mode 20, there is only one slot. The mesh data for that
//   slot is two interleaved vertex attributes: attr_vertex, a single
//   32-bit uint, and attr_face, a single 32-bit uint.
//
//   In mode 1 & mode 21, there are two slots. The first buffer should
//   be four times as large as the second buffer. The first buffer
//   contains a single vertex attribute: 'attr_vertex', a single 32-bit uint.
//   The second buffer contains texture buffer data (an array of 32-bit uints)
//   that will be accessed through the sampler identified by STBVOX_UNIFORM_face_data.

STBVXDEC int stbvox_get_buffer_count(stbvox_mesh_maker *mm);
// Returns the number of buffers needed per mesh as described above.

STBVXDEC int stbvox_get_buffer_size_per_quad(stbvox_mesh_maker *mm, int slot);
// Returns how much of a given buffer will get used per quad. This
// allows you to choose correct relative sizes for each buffer, although
// the values are fixed based on the configuration you've selected at
// compile time, and the details are described in stbvox_set_buffer.

STBVXDEC void stbvox_set_default_mesh(stbvox_mesh_maker *mm, int mesh);
// Selects which mesh the mesher will output to (see previous function)
// if the input doesn't specify a per-voxel selector. (I doubt this is
// useful, but it's here just in case.)

STBVXDEC stbvox_input_description *stbvox_get_input_description(stbvox_mesh_maker *mm);
// This function call returns a pointer to the stbvox_input_description part
// of stbvox_mesh_maker (which you should otherwise treat as opaque). You
// zero this structure, then fill out the relevant pointers to the data
// describing your voxel object/world.
//
// See further documentation at the description of stbvox_input_description below.

STBVXDEC void stbvox_set_input_stride(stbvox_mesh_maker *mm, int x_stride_in_elements, int y_stride_in_elements);
// This sets the stride between successive elements of the 3D arrays
// in the stbvox_input_description. Z values are always stored consecutively.
// (The preferred coordinate system for stbvox is X right, Y forwards, Z up.)

STBVXDEC void stbvox_set_input_range(stbvox_mesh_maker *mm, int x0, int y0, int z0, int x1, int y1, int z1);
// This sets the range of values in the 3D array for the voxels that
// the mesh generator will convert. The lower values are inclusive,
// the higher values are exclusive, so (0,0,0) to (16,16,16) generates
// mesh data associated with voxels up to (15,15,15) but no higher.
//
// The mesh generate generates faces at the boundary between open space
// and solid space but associates them with the solid space, so if (15,0,0)
// is open and (16,0,0) is solid, then the mesh will contain the boundary
// between them if x0 <= 16 and x1 > 16.
//
// Note that the mesh generator will access array elements 1 beyond the
// limits set in these parameters. For example, if you set the limits
// to be (0,0,0) and (16,16,16), then the generator will access all of
// the voxels between (-1,-1,-1) and (16,16,16), including (16,16,16).
// You may have to do pointer arithmetic to make it work.
//
// For example, caveview processes mesh chunks that are 32x32x16, but it
// does this using input buffers that are 34x34x18.
//
// The lower limits are x0 >= 0, y0 >= 0, and z0 >= 0.
//
// The upper limits are mode dependent, but all the current methods are
// limited to x1 < 127, y1 < 127, z1 < 255. Note that these are not
// powers of two; if you want to use power-of-two chunks (to make
// it efficient to decide which chunk a coordinate falls in), you're
// limited to at most x1=64, y1=64, z1=128. For classic Minecraft-style
// worlds with limited vertical extent, I recommend using a single
// chunk for the entire height, which limits the height to 255 blocks
// (one less than Minecraft), and only chunk the map in X & Y.

STBVXDEC int stbvox_make_mesh(stbvox_mesh_maker *mm);
// Call this function to create mesh data for the currently configured
// set of input data. This appends to the currently configured mesh output
// buffer. Returns 1 on success. If there is not enough room in the buffer,
// it outputs as much as it can, and returns 0; you need to switch output
// buffers (either by calling stbvox_set_buffer to set new buffers, or
// by copying the data out and calling stbvox_reset_buffers), and then
// call this function again without changing any of the input parameters.
//
// Note that this function appends; you can call it multiple times to
// build a single mesh. For example, caveview uses chunks that are
// 32x32x255, but builds the mesh for it by processing 32x32x16 at atime
// (this is faster as it is reuses the same 34x34x18 input buffers rather
// than needing 34x34x257 input buffers).

// Once you're done creating a mesh into a given buffer,
// consider the following functions:

STBVXDEC int stbvox_get_quad_count(stbvox_mesh_maker *mm, int mesh);
// Returns the number of quads in the mesh currently generated by mm.
// This is the sum of all consecutive stbvox_make_mesh runs appending
// to the same buffer. 'mesh' distinguishes between the multiple user
// meshes available via 'selector' or stbvox_set_default_mesh.
//
// Typically you use this function when you're done building the mesh
// and want to record how to draw it.
//
// Note that there are no index buffers; the data stored in the buffers
// should be drawn as quads (e.g. with GL_QUAD); if your API does not
// support quads, you can create a single index buffer large enough to
// draw your largest vertex buffer, and reuse it for every rendering.
// (Note that if you use 32-bit indices, you'll use 24 bytes of bandwidth
// per quad, more than the 20 bytes for the vertex/face mesh data.)

STBVXDEC void stbvox_set_mesh_coordinates(stbvox_mesh_maker *mm, int x, int y, int z);
// Sets the global coordinates for this chunk, such that (0,0,0) relative
// coordinates will be at (x,y,z) in global coordinates.

STBVXDEC void stbvox_get_bounds(stbvox_mesh_maker *mm, float bounds[2][3]);
// Returns the bounds for the mesh in global coordinates. Use this
// for e.g. frustum culling the mesh. @BUG: this just uses the
// values from stbvox_set_input_range(), so if you build by
// appending multiple values, this will be wrong, and you need to
// set stbvox_set_input_range() to the full size. Someday this
// will switch to tracking the actual bounds of the *mesh*, though.

STBVXDEC void stbvox_get_transform(stbvox_mesh_maker *mm, float transform[3][3]);
// Returns the 'transform' data for the shader uniforms. It is your
// job to set this to the shader before drawing the mesh. It is the
// only uniform that needs to change per-mesh. Note that it is not
// a 3x3 matrix, but rather a scale to decode fixed point numbers as
// floats, a translate from relative to global space, and a special
// translation for texture coordinate generation that avoids
// floating-point precision issues. @TODO: currently we add the
// global translation to the vertex, than multiply by modelview,
// but this means if camera location and vertex are far from the
// origin, we lose precision. Need to make a special modelview with
// the translation (or some of it) factored out to avoid this.

STBVXDEC void stbvox_reset_buffers(stbvox_mesh_maker *mm);
// Call this function if you're done with the current output buffer
// but want to reuse it (e.g. you're done appending with
// stbvox_make_mesh and you've copied the data out to your graphics API
// so can reuse the buffer).

//////////////////////////////////////////////////////////////////////////////
//
// RENDERING
//

STBVXDEC char *stbvox_get_vertex_shader(void);
// Returns the (currently GLSL-only) vertex shader.

STBVXDEC char *stbvox_get_fragment_shader(void);
// Returns the (currently GLSL-only) fragment shader.
// You can override the lighting and fogging calculations
// by appending data to the end of these; see the #define
// documentation for more information.

STBVXDEC char *stbvox_get_fragment_shader_alpha_only(void);
// Returns a slightly cheaper fragment shader that computes
// alpha but not color. This is useful for e.g. a depth-only
// pass when using alpha test.

typedef struct stbvox_uniform_info stbvox_uniform_info;

STBVXDEC int stbvox_get_uniform_info(stbvox_uniform_info *info, int uniform);
// Gets the information about a uniform necessary for you to
// set up each uniform with a minimal amount of explicit code.
// See the sample code after the structure definition for stbvox_uniform_info,
// further down in this header section.
//
// "uniform" is from the list immediately following. For many
// of these, default values are provided which you can set.
// Most values are shared for most draw calls; e.g. for stateful
// APIs you can set most of the state only once. Only
// STBVOX_UNIFORM_transform needs to change per draw call.
//
// STBVOX_UNIFORM_texscale
//    64- or 128-long vec4 array. (128 only if STBVOX_CONFIG_PREFER_TEXBUFFER)
//    x: scale factor to apply to texture #1. must be a power of two. 1.0 means 'face-sized'
//    y: scale factor to apply to texture #2. must be a power of two. 1.0 means 'face-sized'
//    z: blend mode indexed by texture #2. 0.0 is alpha compositing; 1.0 is multiplication.
//    w: unused currently. @TODO use to support texture animation?
//
//    Texscale is indexed by the bottom 6 or 7 bits of the texture id; thus for
//    example the texture at index 0 in the array and the texture in index 128 of
//    the array must be scaled the same. This means that if you only have 64 or 128
//    unique textures, they all get distinct values anyway; otherwise you have
//    to group them in pairs or sets of four.
//
// STBVOX_UNIFORM_ambient
//    4-long vec4 array:
//      ambient[0].xyz   - negative of direction of a directional light for half-lambert
//      ambient[1].rgb   - color of light scaled by NdotL (can be negative)
//      ambient[2].rgb   - constant light added to above calculation;
//                         effectively light ranges from ambient[2]-ambient[1] to ambient[2]+ambient[1]
//      ambient[3].rgb   - fog color for STBVOX_CONFIG_FOG_SMOOTHSTEP
//      ambient[3].a     - reciprocal of squared distance of farthest fog point (viewing distance)


                               //  +----- has a default value
                               //  |  +-- you should always use the default value
enum                           //  V  V
{                              //  ------------------------------------------------
   STBVOX_UNIFORM_face_data,   //  n      the sampler with the face texture buffer
   STBVOX_UNIFORM_transform,   //  n      the transform data from stbvox_get_transform
   STBVOX_UNIFORM_tex_array,   //  n      an array of two texture samplers containing the two texture arrays
   STBVOX_UNIFORM_texscale,    //  Y      a table of texture properties, see above
   STBVOX_UNIFORM_color_table, //  Y      64 vec4 RGBA values; a default palette is provided; if A > 1.0, fullbright
   STBVOX_UNIFORM_normals,     //  Y  Y   table of normals, internal-only
   STBVOX_UNIFORM_texgen,      //  Y  Y   table of texgen vectors, internal-only
   STBVOX_UNIFORM_ambient,     //  n      lighting & fog info, see above
   STBVOX_UNIFORM_camera_pos,  //  Y      camera position in global voxel space (for lighting & fog)

   STBVOX_UNIFORM_count,
};

enum
{
   STBVOX_UNIFORM_TYPE_none,
   STBVOX_UNIFORM_TYPE_sampler,
   STBVOX_UNIFORM_TYPE_vec2,
   STBVOX_UNIFORM_TYPE_vec3,
   STBVOX_UNIFORM_TYPE_vec4,
};

struct stbvox_uniform_info
{
   int type;                    // which type of uniform
   int bytes_per_element;       // the size of each uniform array element (e.g. vec3 = 12 bytes)
   int array_length;            // length of the uniform array
   char *name;                  // name in the shader @TODO use numeric binding
   float *default_value;        // if not NULL, you can use this as the uniform pointer
   int use_tex_buffer;          // if true, then the uniform is a sampler but the data can come from default_value
};

//////////////////////////////////////////////////////////////////////////////
//
// Uniform sample code
//

#if 0
// Run this once per frame before drawing all the meshes.
// You still need to separately set the 'transform' uniform for every mesh.
void setup_uniforms(GLuint shader, float camera_pos[4], GLuint tex1, GLuint tex2)
{
   int i;
   glUseProgram(shader); // so uniform binding works
   for (i=0; i < STBVOX_UNIFORM_count; ++i) {
      stbvox_uniform_info sui;
      if (stbvox_get_uniform_info(&sui, i)) {
         GLint loc = glGetUniformLocation(shader, sui.name);
         if (loc != 0) {
            switch (i) {
               case STBVOX_UNIFORM_camera_pos: // only needed for fog
                  glUniform4fv(loc, sui.array_length, camera_pos);
                  break;

               case STBVOX_UNIFORM_tex_array: {
                  GLuint tex_unit[2] = { 0, 1 }; // your choice of samplers
                  glUniform1iv(loc, 2, tex_unit);

                  glActiveTexture(GL_TEXTURE0 + tex_unit[0]); glBindTexture(GL_TEXTURE_2D_ARRAY, tex1);
                  glActiveTexture(GL_TEXTURE0 + tex_unit[1]); glBindTexture(GL_TEXTURE_2D_ARRAY, tex2);
                  glActiveTexture(GL_TEXTURE0); // reset to default
                  break;
               }

               case STBVOX_UNIFORM_face_data:
                  glUniform1i(loc, SAMPLER_YOU_WILL_BIND_PER_MESH_FACE_DATA_TO);
                  break;

               case STBVOX_UNIFORM_ambient:     // you definitely want to override this
               case STBVOX_UNIFORM_color_table: // you might want to override this
               case STBVOX_UNIFORM_texscale:    // you may want to override this
                  glUniform4fv(loc, sui.array_length, sui.default_value);
                  break;

               case STBVOX_UNIFORM_normals:     // you never want to override this
               case STBVOX_UNIFORM_texgen:      // you never want to override this
                  glUniform3fv(loc, sui.array_length, sui.default_value);
                  break;
            }
         }
      }
   }
}
#endif

#ifdef __cplusplus
}
#endif

//////////////////////////////////////////////////////////////////////////////
//
// INPUT TO MESHING
//

// Shapes of blocks that aren't always cubes
enum
{
   STBVOX_GEOM_empty,
   STBVOX_GEOM_knockout,  // creates a hole in the mesh
   STBVOX_GEOM_solid,
   STBVOX_GEOM_transp,    // solid geometry, but transparent contents so neighbors generate normally, unless same blocktype

   // following 4 can be represented by vheight as well
   STBVOX_GEOM_slab_upper,
   STBVOX_GEOM_slab_lower,
   STBVOX_GEOM_floor_slope_north_is_top,
   STBVOX_GEOM_ceil_slope_north_is_bottom,

   STBVOX_GEOM_floor_slope_north_is_top_as_wall_UNIMPLEMENTED,   // same as floor_slope above, but uses wall's texture & texture projection
   STBVOX_GEOM_ceil_slope_north_is_bottom_as_wall_UNIMPLEMENTED,
   STBVOX_GEOM_crossed_pair,    // corner-to-corner pairs, with normal vector bumped upwards
   STBVOX_GEOM_force,           // like GEOM_transp, but faces visible even if neighbor is same type, e.g. minecraft fancy leaves

   // these access vheight input
   STBVOX_GEOM_floor_vheight_03 = 12,  // diagonal is SW-NE
   STBVOX_GEOM_floor_vheight_12,       // diagonal is SE-NW
   STBVOX_GEOM_ceil_vheight_03,
   STBVOX_GEOM_ceil_vheight_12,

   STBVOX_GEOM_count, // number of geom cases
};

enum
{
   STBVOX_FACE_east,
   STBVOX_FACE_north,
   STBVOX_FACE_west,
   STBVOX_FACE_south,
   STBVOX_FACE_up,
   STBVOX_FACE_down,

   STBVOX_FACE_count,
};

#ifdef STBVOX_CONFIG_BLOCKTYPE_SHORT
typedef unsigned short stbvox_block_type;
#else
typedef unsigned char stbvox_block_type;
#endif

// 24-bit color
typedef struct
{
   unsigned char r,g,b;
} stbvox_rgb;

#define STBVOX_COLOR_TEX1_ENABLE   64
#define STBVOX_COLOR_TEX2_ENABLE  128

// This is the data structure you fill out. Most of the arrays can be
// NULL, except when one is required to get the value to index another.
//
// The compass system used in the following descriptions is:
//     east means increasing x
//     north means increasing y
//     up means increasing z
struct stbvox_input_description
{
   unsigned char lighting_at_vertices;
   // The default is lighting values (i.e. ambient occlusion) are at block
   // center, and the vertex light is gathered from those adjacent block
   // centers that the vertex is facing. This makes smooth lighting
   // consistent across adjacent faces with the same orientation.
   //
   // Setting this flag to non-zero gives you explicit control
   // of light at each vertex, but now the lighting/ao will be
   // shared by all vertices at the same point, even if they
   // have different normals.

   // these are mostly 3D maps you use to define your voxel world, using x_stride and y_stride
   // note that for cache efficiency, you want to use the block_foo palettes as much as possible instead

   stbvox_rgb *rgb;
   // Indexed by 3D coordinate.
   // 24-bit voxel color for STBVOX_CONFIG_MODE = 20 or 21 only

   unsigned char *lighting;
   // Indexed by 3D coordinate. The lighting value / ambient occlusion
   // value that is used to define the vertex lighting values.
   // The raw lighting values are defined at the center of blocks
   // (or at vertex if 'lighting_at_vertices' is true).
   //
   // If the macro STBVOX_CONFIG_ROTATION_IN_LIGHTING is defined,
   // then an additional 2-bit block rotation value is stored
   // in this field as well.
   //
   // Encode with STBVOX_MAKE_LIGHTING_EXT(lighting,rot)--here
   // 'lighting' should still be 8 bits, as the macro will
   // discard the bottom bits automatically. Similarly, if
   // using STBVOX_CONFIG_VHEIGHT_IN_LIGHTING, encode with
   // STBVOX_MAKE_LIGHTING_EXT(lighting,vheight).
   //
   // (Rationale: rotation needs to be independent of blocktype,
   // but is only 2 bits so doesn't want to be its own array.
   // Lighting is the one thing that was likely to already be
   // in use and that I could easily steal 2 bits from.)

   stbvox_block_type *blocktype;
   // Indexed by 3D coordinate. This is a core "block type" value, which is used
   // to index into other arrays; essentially a "palette". This is much more
   // memory-efficient and performance-friendly than storing the values explicitly,
   // but only makes sense if the values are always synchronized.
   //
   // If a voxel's blocktype is 0, it is assumed to be empty (STBVOX_GEOM_empty),
   // and no other blocktypes should be STBVOX_GEOM_empty. (Only if you do not
   // have blocktypes should STBVOX_GEOM_empty ever used.)
   //
   // Normally it is an unsigned byte, but you can override it to be
   // a short if you have too many blocktypes.

   unsigned char *geometry;
   // Indexed by 3D coordinate. Contains the geometry type for the block.
   // Also contains a 2-bit rotation for how the whole block is rotated.
   // Also includes a 2-bit vheight value when using shared vheight values.
   // See the separate vheight documentation.
   // Encode with STBVOX_MAKE_GEOMETRY(geom, rot, vheight)

   unsigned char *block_geometry;
   // Array indexed by blocktype containing the geometry for this block, plus
   // a 2-bit "simple rotation". Note rotation has limited use since it's not
   // independent of blocktype.
   //
   // Encode with STBVOX_MAKE_GEOMETRY(geom,simple_rot,0)

   unsigned char *block_tex1;
   // Array indexed by blocktype containing the texture id for texture #1.

   unsigned char (*block_tex1_face)[6];
   // Array indexed by blocktype and face containing the texture id for texture #1.
   // The N/E/S/W face choices can be rotated by one of the rotation selectors;
   // The top & bottom face textures will rotate to match.
   // Note that it only makes sense to use one of block_tex1 or block_tex1_face;
   // this pattern repeats throughout and this notice is not repeated.

   unsigned char *tex2;
   // Indexed by 3D coordinate. Contains the texture id for texture #2
   // to use on all faces of the block.

   unsigned char *block_tex2;
   // Array indexed by blocktype containing the texture id for texture #2.

   unsigned char (*block_tex2_face)[6];
   // Array indexed by blocktype and face containing the texture id for texture #2.
   // The N/E/S/W face choices can be rotated by one of the rotation selectors;
   // The top & bottom face textures will rotate to match.

   unsigned char *color;
   // Indexed by 3D coordinate. Contains the color for all faces of the block.
   // The core color value is 0..63.
   // Encode with STBVOX_MAKE_COLOR(color_number, tex1_enable, tex2_enable)
   
   unsigned char *block_color;
   // Array indexed by blocktype containing the color value to apply to the faces.
   // The core color value is 0..63.
   // Encode with STBVOX_MAKE_COLOR(color_number, tex1_enable, tex2_enable)

   unsigned char (*block_color_face)[6];
   // Array indexed by blocktype and face containing the color value to apply to that face.
   // The core color value is 0..63.
   // Encode with STBVOX_MAKE_COLOR(color_number, tex1_enable, tex2_enable)

   unsigned char *block_texlerp;
   // Array indexed by blocktype containing 3-bit scalar for texture #2 alpha
   // (known throughout as 'texlerp'). This is constant over every face even
   // though the property is potentially per-vertex.

   unsigned char (*block_texlerp_face)[6];
   // Array indexed by blocktype and face containing 3-bit scalar for texture #2 alpha.
   // This is constant over the face even though the property is potentially per-vertex.

   unsigned char *block_vheight;
   // Array indexed by blocktype containing the vheight values for the
   // top or bottom face of this block. These will rotate properly if the
   // block is rotated. See discussion of vheight.
   // Encode with STBVOX_MAKE_VHEIGHT(sw_height, se_height, nw_height, ne_height)

   unsigned char *selector;
   // Array indexed by 3D coordinates indicating which output mesh to select.

   unsigned char *block_selector;
   // Array indexed by blocktype indicating which output mesh to select.

   unsigned char *side_texrot;
   // Array indexed by 3D coordinates encoding 2-bit texture rotations for the
   // faces on the E/N/W/S sides of the block.
   // Encode with STBVOX_MAKE_SIDE_TEXROT(rot_e, rot_n, rot_w, rot_s)

   unsigned char *block_side_texrot;
   // Array indexed by blocktype encoding 2-bit texture rotations for the faces
   // on the E/N/W/S sides of the block.
   // Encode with STBVOX_MAKE_SIDE_TEXROT(rot_e, rot_n, rot_w, rot_s)

   unsigned char *overlay;                 // index into palettes listed below
   // Indexed by 3D coordinate. If 0, there is no overlay. If non-zero,
   // it indexes into to the below arrays and overrides the values
   // defined by the blocktype.

   unsigned char (*overlay_tex1)[6];
   // Array indexed by overlay value and face, containing an override value
   // for the texture id for texture #1. If 0, the value defined by blocktype
   // is used.

   unsigned char (*overlay_tex2)[6];
   // Array indexed by overlay value and face, containing an override value
   // for the texture id for texture #2. If 0, the value defined by blocktype
   // is used.

   unsigned char (*overlay_color)[6];
   // Array indexed by overlay value and face, containing an override value
   // for the face color. If 0, the value defined by blocktype is used.

   unsigned char *overlay_side_texrot;
   // Array indexed by overlay value, encoding 2-bit texture rotations for the faces
   // on the E/N/W/S sides of the block.
   // Encode with STBVOX_MAKE_SIDE_TEXROT(rot_e, rot_n, rot_w, rot_s)

   unsigned char *rotate;
   // Indexed by 3D coordinate. Allows independent rotation of several
   // parts of the voxel, where by rotation I mean swapping textures
   // and colors between E/N/S/W faces.
   //    Block: rotates anything indexed by blocktype
   //    Overlay: rotates anything indexed by overlay
   //    EColor: rotates faces defined in ecolor_facemask
   // Encode with STBVOX_MAKE_MATROT(block,overlay,ecolor)

   unsigned char *tex2_for_tex1;
   // Array indexed by tex1 containing the texture id for texture #2.
   // You can use this if the two are always/almost-always strictly
   // correlated (e.g. if tex2 is a detail texture for tex1), as it
   // will be more efficient (touching fewer cache lines) than using
   // e.g. block_tex2_face.

   unsigned char *tex2_replace;
   // Indexed by 3D coordinate. Specifies the texture id for texture #2
   // to use on a single face of the voxel, which must be E/N/W/S (not U/D).
   // The texture id is limited to 6 bits unless tex2_facemask is also
   // defined (see below).
   // Encode with STBVOX_MAKE_TEX2_REPLACE(tex2, face)

   unsigned char *tex2_facemask;
   // Indexed by 3D coordinate. Specifies which of the six faces should
   // have their tex2 replaced by the value of tex2_replace. In this
   // case, all 8 bits of tex2_replace are used as the texture id.
   // Encode with STBVOX_MAKE_FACE_MASK(east,north,west,south,up,down)

   unsigned char *extended_color;
   // Indexed by 3D coordinate. Specifies a value that indexes into
   // the ecolor arrays below (both of which must be defined).

   unsigned char *ecolor_color;
   // Indexed by extended_color value, specifies an optional override
   // for the color value on some faces.
   // Encode with STBVOX_MAKE_COLOR(color_number, tex1_enable, tex2_enable)

   unsigned char *ecolor_facemask;
   // Indexed by extended_color value, this specifies which faces the
   // color in ecolor_color should be applied to. The faces can be
   // independently rotated by the ecolor value of 'rotate', if it exists.
   // Encode with STBVOX_MAKE_FACE_MASK(e,n,w,s,u,d)

   unsigned char *color2;
   // Indexed by 3D coordinates, specifies an alternative color to apply
   // to some of the faces of the block.
   // Encode with STBVOX_MAKE_COLOR(color_number, tex1_enable, tex2_enable)

   unsigned char *color2_facemask;
   // Indexed by 3D coordinates, specifies which faces should use the
   // color defined in color2. No rotation value is applied.
   // Encode with STBVOX_MAKE_FACE_MASK(e,n,w,s,u,d)
   
   unsigned char *color3;
   // Indexed by 3D coordinates, specifies an alternative color to apply
   // to some of the faces of the block.
   // Encode with STBVOX_MAKE_COLOR(color_number, tex1_enable, tex2_enable)

   unsigned char *color3_facemask;
   // Indexed by 3D coordinates, specifies which faces should use the
   // color defined in color3. No rotation value is applied. 
   // Encode with STBVOX_MAKE_FACE_MASK(e,n,w,s,u,d)
   
   unsigned char *texlerp_simple;
   // Indexed by 3D coordinates, this is the smallest texlerp encoding
   // that can do useful work. It consits of three values: baselerp,
   // vertlerp, and face_vertlerp. Baselerp defines the value
   // to use on all of the faces but one, from the STBVOX_TEXLERP_BASE
   // values. face_vertlerp is one of the 6 face values (or STBVOX_FACE_NONE)
   // which specifies the face should use the vertlerp values.
   // Vertlerp defines a lerp value at every vertex of the mesh.
   // Thus, one face can have per-vertex texlerp values, and those
   // values are encoded in the space so that they will be shared
   // by adjacent faces that also use vertlerp, allowing continuity
   // (this is used for the "texture crossfade" bit of the release video).
   // Encode with STBVOX_MAKE_TEXLERP_SIMPLE(baselerp, vertlerp, face_vertlerp)

   // The following texlerp encodings are experimental and maybe not
   // that useful. 

   unsigned char *texlerp;
   // Indexed by 3D coordinates, this defines four values:
   //   vertlerp is a lerp value at every vertex of the mesh (using STBVOX_TEXLERP_BASE values).
   //   ud is the value to use on up and down faces, from STBVOX_TEXLERP_FACE values
   //   ew is the value to use on east and west faces, from STBVOX_TEXLERP_FACE values
   //   ns is the value to use on north and south faces, from STBVOX_TEXLERP_FACE values
   // If any of ud, ew, or ns is STBVOX_TEXLERP_FACE_use_vert, then the
   // vertlerp values for the vertices are gathered and used for those faces.
   // Encode with STBVOX_MAKE_TEXLERP(vertlerp,ud,ew,sw)

   unsigned short *texlerp_vert3;
   // Indexed by 3D coordinates, this works with texlerp and
   // provides a unique texlerp value for every direction at
   // every vertex. The same rules of whether faces share values
   // applies. The STBVOX_TEXLERP_FACE vertlerp value defined in
   // texlerp is only used for the down direction. The values at
   // each vertex in other directions are defined in this array,
   // and each uses the STBVOX_TEXLERP3 values (i.e. full precision
   // 3-bit texlerp values).
   // Encode with STBVOX_MAKE_VERT3(vertlerp_e,vertlerp_n,vertlerp_w,vertlerp_s,vertlerp_u)

   unsigned short *texlerp_face3;          // e:3,n:3,w:3,s:3,u:2,d:2
   // Indexed by 3D coordinates, this provides a compact way to
   // fully specify the texlerp value indepenendly for every face,
   // but doesn't allow per-vertex variation. E/N/W/S values are
   // encoded using STBVOX_TEXLERP3 values, whereas up and down
   // use STBVOX_TEXLERP_SIMPLE values.
   // Encode with STBVOX_MAKE_FACE3(face_e,face_n,face_w,face_s,face_u,face_d)

   unsigned char *vheight;                 // STBVOX_MAKE_VHEIGHT   -- sw:2, se:2, nw:2, ne:2, doesn't rotate
   // Indexed by 3D coordinates, this defines the four
   // vheight values to use if the geometry is STBVOX_GEOM_vheight*.
   // See the vheight discussion.

   unsigned char *packed_compact;
   // Stores block rotation, vheight, and texlerp values:
   //    block rotation: 2 bits
   //    vertex vheight: 2 bits
   //    use_texlerp   : 1 bit
   //    vertex texlerp: 3 bits
   // If STBVOX_CONFIG_UP_TEXLERP_PACKED is defined, then 'vertex texlerp' is
   // used for up faces if use_texlerp is 1. If STBVOX_CONFIG_DOWN_TEXLERP_PACKED
   // is defined, then 'vertex texlerp' is used for down faces if use_texlerp is 1.
   // Note if those symbols are defined but packed_compact is NULL, the normal
   // texlerp default will be used.
   // Encode with STBVOX_MAKE_PACKED_COMPACT(rot, vheight, texlerp, use_texlerp)
};
// @OPTIMIZE allow specializing; build a single struct with all of the
// 3D-indexed arrays combined so it's AoS instead of SoA for better
// cache efficiency


//////////////////////////////////////////////////////////////////////////////
//
//  VHEIGHT DOCUMENTATION
//
//  "vheight" is the internal name for the special block types
//  with sloped tops or bottoms. "vheight" stands for "vertex height".
//
//  Note that these blocks are very flexible (there are 256 of them,
//  although at least 17 of them should never be used), but they
//  also have a disadvantage that they generate extra invisible
//  faces; the generator does not currently detect whether adjacent
//  vheight blocks hide each others sides, so those side faces are
//  always generated. For a continuous ground terrain, this means
//  that you may generate 5x as many quads as needed. See notes
//  on "improvements for shipping products" in the introduction.

enum
{
   STBVOX_VERTEX_HEIGHT_0,
   STBVOX_VERTEX_HEIGHT_half,
   STBVOX_VERTEX_HEIGHT_1,
   STBVOX_VERTEX_HEIGHT_one_and_a_half,
};
// These are the "vheight" values. Vheight stands for "vertex height".
// The idea is that for a "floor vheight" block, you take a cube and
// reposition the top-most vertices at various heights as specified by
// the vheight values. Similarly, a "ceiling vheight" block takes a
// cube and repositions the bottom-most vertices.
//
// A floor block only adjusts the top four vertices; the bottom four vertices
// remain at the bottom of the block. The height values are 2 bits,
// measured in halves of a block; so you can specify heights of 0/2,
// 1/2, 2/2, or 3/2. 0 is the bottom of the block, 1 is halfway
// up the block, 2 is the top of the block, and 3 is halfway up the
// next block (and actually outside of the block). The value 3 is
// actually legal for floor vheight (but not ceiling), and allows you to:
//
//     (A) have smoother terrain by having slopes that cross blocks,
//         e.g. (1,1,3,3) is a regular-seeming slope halfway between blocks
//     (B) make slopes steeper than 45-degrees, e.g. (0,0,3,3)
//
// (Because only z coordinates have half-block precision, and x&y are
// limited to block corner precision, it's not possible to make these
// things "properly" out of blocks, e.g. a half-slope block on its side
// or a sloped block halfway between blocks that's made out of two blocks.)
//
// If you define STBVOX_CONFIG_OPTIMIZED_VHEIGHT, then the top face
// (or bottom face for a ceiling vheight block) will be drawn as a
// single quad even if the four vertex heights aren't planar, and a
// single normal will be used over the entire quad. If you
// don't define it, then if the top face is non-planar, it will be
// split into two triangles, each with their own normal/lighting.
// (Note that since all output from stb_voxel_render is quad meshes,
// triangles are actually rendered as degenerate quads.) In this case,
// the distinction betwen STBVOX_GEOM_floor_vheight_03 and
// STBVOX_GEOM_floor_vheight_12 comes into play; the former introduces
// an edge from the SW to NE corner (i.e. from <0,0,?> to <1,1,?>),
// while the latter introduces an edge from the NW to SE corner
// (i.e. from <0,1,?> to <1,0,?>.) For a "lazy mesh" look, use
// exclusively _03 or _12. For a "classic mesh" look, alternate
// _03 and _12 in a checkerboard pattern. For a "smoothest surface"
// look, choose the edge based on actual vertex heights.
//
// The four vertex heights can come from several places. The simplest
// encoding is to just use the 'vheight' parameter which stores four
// explicit vertex heights for every block. This allows total independence,
// but at the cost of the largest memory usage, 1 byte per 3D block.
// Encode this with STBVOX_MAKE_VHEIGHT(vh_sw, vh_se, vh_nw, vh_ne).
// These coordinates are absolute, not affected by block rotations.
//
// An alternative if you just want to encode some very specific block
// types, not all the possibilities--say you just want half-height slopes,
// so you want (0,0,1,1) and (1,1,2,2)--then you can use block_vheight
// to specify them. The geometry rotation will cause block_vheight values
// to be rotated (because it's as if you're just defining a type of
// block). This value is also encoded with STBVOX_MAKE_VHEIGHT.
//
// If you want to save memory and you're creating a "continuous ground"
// sort of effect, you can make each vertex of the lattice share the
// vheight value; that is, two adjacent blocks that share a vertex will
// always get the same vheight value for that vertex. Then you need to
// store two bits of vheight for every block, which you do by storing it
// as part another data structure. Store the south-west vertex's vheight
// with the block. You can either use the "geometry" mesh variable (it's
// a parameter to STBVOX_MAKE_GEOMETRY) or you can store it in the
// "lighting" mesh variable if you defined STBVOX_CONFIG_VHEIGHT_IN_LIGHTING,
// using STBVOX_MAKE_LIGHTING_EXT(lighting,vheight).
//
// Note that if you start with a 2D height map and generate vheight data from
// it, you don't necessarily store only one value per (x,y) coordinate,
// as the same value may need to be set up at multiple z heights. For
// example, if height(8,8) = 13.5, then you want the block at (8,8,13)
// to store STBVOX_VERTEX_HEIGHT_half, and this will be used by blocks
// at (7,7,13), (8,7,13), (7,8,13), and (8,8,13). However, if you're
// allowing steep slopes, it might be the case that you have a block
// at (7,7,12) which is supposed to stick up to 13.5; that means
// you also need to store STBVOX_VERTEX_HEIGHT_one_and_a_half at (8,8,12).

enum
{
   STBVOX_TEXLERP_FACE_0,
   STBVOX_TEXLERP_FACE_half,
   STBVOX_TEXLERP_FACE_1,
   STBVOX_TEXLERP_FACE_use_vert,
};

enum
{
   STBVOX_TEXLERP_BASE_0,    // 0.0
   STBVOX_TEXLERP_BASE_2_7,  // 2/7
   STBVOX_TEXLERP_BASE_5_7,  // 4/7
   STBVOX_TEXLERP_BASE_1     // 1.0
};

enum
{
   STBVOX_TEXLERP3_0_8,
   STBVOX_TEXLERP3_1_8,
   STBVOX_TEXLERP3_2_8,
   STBVOX_TEXLERP3_3_8,
   STBVOX_TEXLERP3_4_8,
   STBVOX_TEXLERP3_5_8,
   STBVOX_TEXLERP3_6_8,
   STBVOX_TEXLERP3_7_8,
};

#define STBVOX_FACE_NONE  7

#define STBVOX_BLOCKTYPE_EMPTY    0

#ifdef STBVOX_BLOCKTYPE_SHORT
#define STBVOX_BLOCKTYPE_HOLE  65535
#else
#define STBVOX_BLOCKTYPE_HOLE    255
#endif

#define STBVOX_MAKE_GEOMETRY(geom, rotate, vheight) ((geom) + (rotate)*16 + (vheight)*64)
#define STBVOX_MAKE_VHEIGHT(v_sw, v_se, v_nw, v_ne) ((v_sw) + (v_se)*4 + (v_nw)*16 + (v_ne)*64)
#define STBVOX_MAKE_MATROT(block, overlay, color)  ((block) + (overlay)*4 + (color)*64)
#define STBVOX_MAKE_TEX2_REPLACE(tex2, tex2_replace_face) ((tex2) + ((tex2_replace_face) & 3)*64)
#define STBVOX_MAKE_TEXLERP(ns2, ew2, ud2, vert)  ((ew2) + (ns2)*4 + (ud2)*16 + (vert)*64)
#define STBVOX_MAKE_TEXLERP_SIMPLE(baselerp,vert,face)   ((vert)*32 + (face)*4 + (baselerp))
#define STBVOX_MAKE_TEXLERP1(vert,e2,n2,w2,s2,u4,d2) STBVOX_MAKE_TEXLERP(s2, w2, d2, vert)
#define STBVOX_MAKE_TEXLERP2(vert,e2,n2,w2,s2,u4,d2) ((u2)*16 + (n2)*4 + (s2))
#define STBVOX_MAKE_FACE_MASK(e,n,w,s,u,d)  ((e)+(n)*2+(w)*4+(s)*8+(u)*16+(d)*32)
#define STBVOX_MAKE_SIDE_TEXROT(e,n,w,s) ((e)+(n)*4+(w)*16+(s)*64)
#define STBVOX_MAKE_COLOR(color,t1,t2) ((color)+(t1)*64+(t2)*128)
#define STBVOX_MAKE_TEXLERP_VERT3(e,n,w,s,u)   ((e)+(n)*8+(w)*64+(s)*512+(u)*4096)
#define STBVOX_MAKE_TEXLERP_FACE3(e,n,w,s,u,d) ((e)+(n)*8+(w)*64+(s)*512+(u)*4096+(d)*16384)
#define STBVOX_MAKE_PACKED_COMPACT(rot, vheight, texlerp, def) ((rot)+4*(vheight)+16*(use)+32*(texlerp))

#define STBVOX_MAKE_LIGHTING_EXT(lighting, rot)  (((lighting)&~3)+(rot))
#define STBVOX_MAKE_LIGHTING(lighting)       (lighting)

#ifndef STBVOX_MAX_MESHES
#define STBVOX_MAX_MESHES      2           // opaque & transparent
#endif

#define STBVOX_MAX_MESH_SLOTS  3           // one vertex & two faces, or two vertex and one face


// don't mess with this directly, it's just here so you can
// declare stbvox_mesh_maker on the stack or as a global
struct stbvox_mesh_maker
{
   stbvox_input_description input;
   int cur_x, cur_y, cur_z;       // last unprocessed voxel if it splits into multiple buffers
   int x0,y0,z0,x1,y1,z1;
   int x_stride_in_bytes;
   int y_stride_in_bytes;
   int config_dirty;
   int default_mesh;
   unsigned int tags;

   int cube_vertex_offset[6][4]; // this allows access per-vertex data stored block-centered (like texlerp, ambient)
   int vertex_gather_offset[6][4];

   int pos_x,pos_y,pos_z;
   int full;

   // computed from user input
   char *output_cur   [STBVOX_MAX_MESHES][STBVOX_MAX_MESH_SLOTS];
   char *output_end   [STBVOX_MAX_MESHES][STBVOX_MAX_MESH_SLOTS];
   char *output_buffer[STBVOX_MAX_MESHES][STBVOX_MAX_MESH_SLOTS];
   int   output_len   [STBVOX_MAX_MESHES][STBVOX_MAX_MESH_SLOTS];

   // computed from config
   int   output_size  [STBVOX_MAX_MESHES][STBVOX_MAX_MESH_SLOTS]; // per quad
   int   output_step  [STBVOX_MAX_MESHES][STBVOX_MAX_MESH_SLOTS]; // per vertex or per face, depending
   int   num_mesh_slots;

   float default_tex_scale[128][2];
};

#endif //  INCLUDE_STB_VOXEL_RENDER_H


#ifdef STB_VOXEL_RENDER_IMPLEMENTATION

#include <stdlib.h>
#include <assert.h>
#include <string.h> // memset

// have to use our own names to avoid the _MSC_VER path having conflicting type names
#ifndef _MSC_VER
   #include <stdint.h>
   typedef uint16_t stbvox_uint16;
   typedef uint32_t stbvox_uint32;
#else
   typedef unsigned short stbvox_uint16;
   typedef unsigned int   stbvox_uint32;
#endif

#ifdef _MSC_VER
   #define STBVOX_NOTUSED(v)  (void)(v)
#else
   #define STBVOX_NOTUSED(v)  (void)sizeof(v)
#endif



#ifndef STBVOX_CONFIG_MODE
#error "Must defined STBVOX_CONFIG_MODE to select the mode"
#endif

#if defined(STBVOX_CONFIG_ROTATION_IN_LIGHTING) && defined(STBVOX_CONFIG_VHEIGHT_IN_LIGHTING)
#error "Can't store both rotation and vheight in lighting"
#endif


// The following are candidate voxel modes. Only modes 0, 1, and 20, and 21 are
// currently implemented. Reducing the storage-per-quad further
// shouldn't improve performance, although obviously it allow you
// to create larger worlds without streaming.
//
//        
//                      -----------  Two textures -----------       -- One texture --     ---- Color only ----
//            Mode:     0     1     2     3     4     5     6        10    11    12      20    21    22    23    24
// ============================================================================================================
//  uses Tex Buffer     n     Y     Y     Y     Y     Y     Y         Y     Y     Y       n     Y     Y     Y     Y
//   bytes per quad    32    20    14    12    10     6     6         8     8     4      32    20    10     6     4
//       non-blocks   all   all   some  some  some slabs stairs     some  some  none    all   all  slabs slabs  none
//             tex1   256   256   256   256   256   256   256       256   256   256       n     n     n     n     n
//             tex2   256   256   256   256   256   256   128         n     n     n       n     n     n     n     n
//           colors    64    64    64    64    64    64    64         8     n     n     2^24  2^24  2^24  2^24  256
//        vertex ao     Y     Y     Y     Y     Y     n     n         Y     Y     n       Y     Y     Y     n     n
//   vertex texlerp     Y     Y     Y     n     n     n     n         -     -     -       -     -     -     -     -
//      x&y extents   127   127   128    64    64   128    64        64   128   128     127   127   128   128   128
//        z extents   255   255   128    64?   64?   64    64        32    64   128     255   255   128    64   128

// not sure why I only wrote down the above "result data" and didn't preserve
// the vertex formats, but here I've tried to reconstruct the designs...
//     mode # 3 is wrong, one byte too large, but they may have been an error originally

//            Mode:     0     1     2     3     4     5     6        10    11    12      20    21    22    23    24
// =============================================================================================================
//   bytes per quad    32    20    14    12    10     6     6         8     8     4            20    10     6     4
//                                                                 
//    vertex x bits     7     7     0     6     0     0     0         0     0     0             7     0     0     0
//    vertex y bits     7     7     0     0     0     0     0         0     0     0             7     0     0     0
//    vertex z bits     9     9     7     4     2     0     0         2     2     0             9     2     0     0
//   vertex ao bits     6     6     6     6     6     0     0         6     6     0             6     6     0     0
//  vertex txl bits     3     3     3     0     0     0     0         0     0     0            (3)    0     0     0
//
//   face tex1 bits    (8)    8     8     8     8     8     8         8     8     8                    
//   face tex2 bits    (8)    8     8     8     8     8     7         -     -     -         
//  face color bits    (8)    8     8     8     8     8     8         3     0     0            24    24    24     8
// face normal bits    (8)    8     8     8     6     4     7         4     4     3             8     3     4     3
//      face x bits                 7     0     6     7     6         6     7     7             0     7     7     7
//      face y bits                 7     6     6     7     6         6     7     7             0     7     7     7
//      face z bits                 2     2     6     6     6         5     6     7             0     7     6     7


#if STBVOX_CONFIG_MODE==0 || STBVOX_CONFIG_MODE==1

   #define STBVOX_ICONFIG_VERTEX_32
   #define STBVOX_ICONFIG_FACE1_1

#elif STBVOX_CONFIG_MODE==20 || STBVOX_CONFIG_MODE==21

   #define STBVOX_ICONFIG_VERTEX_32
   #define STBVOX_ICONFIG_FACE1_1
   #define STBVOX_ICONFIG_UNTEXTURED

#else
#error "Selected value of STBVOX_CONFIG_MODE is not supported"
#endif

#if STBVOX_CONFIG_MODE==0 || STBVOX_CONFIG_MODE==20
#define STBVOX_ICONFIG_FACE_ATTRIBUTE
#endif

#ifndef STBVOX_CONFIG_HLSL
// the fallback if all others are exhausted is GLSL
#define STBVOX_ICONFIG_GLSL
#endif

#ifdef STBVOX_CONFIG_OPENGL_MODELVIEW
#define STBVOX_ICONFIG_OPENGL_3_1_COMPATIBILITY
#endif

#if defined(STBVOX_ICONFIG_VERTEX_32)
   typedef stbvox_uint32 stbvox_mesh_vertex;
   #define stbvox_vertex_encode(x,y,z,ao,texlerp) \
      ((stbvox_uint32) ((x)+((y)<<7)+((z)<<14)+((ao)<<23)+((texlerp)<<29)))
#elif defined(STBVOX_ICONFIG_VERTEX_16_1)  // mode=2
   typedef stbvox_uint16 stbvox_mesh_vertex;
   #define stbvox_vertex_encode(x,y,z,ao,texlerp) \
      ((stbvox_uint16) ((z)+((ao)<<7)+((texlerp)<<13)
#elif defined(STBVOX_ICONFIG_VERTEX_16_2)  // mode=3
   typedef stbvox_uint16 stbvox_mesh_vertex;
   #define stbvox_vertex_encode(x,y,z,ao,texlerp) \
      ((stbvox_uint16) ((x)+((z)<<6))+((ao)<<10))
#elif defined(STBVOX_ICONFIG_VERTEX_8)
   typedef stbvox_uint8 stbvox_mesh_vertex;
   #define stbvox_vertex_encode(x,y,z,ao,texlerp) \
      ((stbvox_uint8) ((z)+((ao)<<6))
#else
   #error "internal error, no vertex type"
#endif

#ifdef STBVOX_ICONFIG_FACE1_1
   typedef struct
   {
      unsigned char tex1,tex2,color,face_info;
   } stbvox_mesh_face;
#else
   #error "internal error, no face type"
#endif


// 20-byte quad format:
//
// per vertex:
//
//     x:7
//     y:7
//     z:9
//     ao:6
//     tex_lerp:3
//
// per face:
//
//     tex1:8
//     tex2:8
//     face:8
//     color:8


// Faces:
//
// Faces use the bottom 3 bits to choose the texgen
// mode, and all the bits to choose the normal.
// Thus the bottom 3 bits have to be:
//      e, n, w, s, u, d, u, d
//
// These use compact names so tables are readable

enum
{
   STBVF_e,
   STBVF_n,
   STBVF_w,
   STBVF_s,
   STBVF_u,
   STBVF_d,
   STBVF_eu,
   STBVF_ed,

   STBVF_eu_wall,
   STBVF_nu_wall,
   STBVF_wu_wall,
   STBVF_su_wall,
   STBVF_ne_u,
   STBVF_ne_d,
   STBVF_nu,
   STBVF_nd,

   STBVF_ed_wall,
   STBVF_nd_wall,
   STBVF_wd_wall,
   STBVF_sd_wall,
   STBVF_nw_u,
   STBVF_nw_d,
   STBVF_wu,
   STBVF_wd,

   STBVF_ne_u_cross,
   STBVF_nw_u_cross,
   STBVF_sw_u_cross,
   STBVF_se_u_cross,
   STBVF_sw_u,
   STBVF_sw_d,
   STBVF_su,
   STBVF_sd,

   // @TODO we need more than 5 bits to encode the normal to fit the following
   // so for now we use the right projection but the wrong normal
   STBVF_se_u = STBVF_su,
   STBVF_se_d = STBVF_sd,

   STBVF_count,
};

/////////////////////////////////////////////////////////////////////////////
//
//    tables -- i'd prefer if these were at the end of the file, but: C++
//

static float stbvox_default_texgen[2][32][3] =
{
   { {  0, 1,0 }, { 0, 0, 1 }, {  0,-1,0 }, { 0, 0,-1 },
     { -1, 0,0 }, { 0, 0, 1 }, {  1, 0,0 }, { 0, 0,-1 },
     {  0,-1,0 }, { 0, 0, 1 }, {  0, 1,0 }, { 0, 0,-1 },
     {  1, 0,0 }, { 0, 0, 1 }, { -1, 0,0 }, { 0, 0,-1 },

     {  1, 0,0 }, { 0, 1, 0 }, { -1, 0,0 }, { 0,-1, 0 },
     { -1, 0,0 }, { 0,-1, 0 }, {  1, 0,0 }, { 0, 1, 0 },
     {  1, 0,0 }, { 0, 1, 0 }, { -1, 0,0 }, { 0,-1, 0 },
     { -1, 0,0 }, { 0,-1, 0 }, {  1, 0,0 }, { 0, 1, 0 },
   },
   { { 0, 0,-1 }, {  0, 1,0 }, { 0, 0, 1 }, {  0,-1,0 },
     { 0, 0,-1 }, { -1, 0,0 }, { 0, 0, 1 }, {  1, 0,0 },
     { 0, 0,-1 }, {  0,-1,0 }, { 0, 0, 1 }, {  0, 1,0 },
     { 0, 0,-1 }, {  1, 0,0 }, { 0, 0, 1 }, { -1, 0,0 },

     { 0,-1, 0 }, {  1, 0,0 }, { 0, 1, 0 }, { -1, 0,0 },
     { 0, 1, 0 }, { -1, 0,0 }, { 0,-1, 0 }, {  1, 0,0 },
     { 0,-1, 0 }, {  1, 0,0 }, { 0, 1, 0 }, { -1, 0,0 },
     { 0, 1, 0 }, { -1, 0,0 }, { 0,-1, 0 }, {  1, 0,0 },
   },
};

#define STBVOX_RSQRT2   0.7071067811865f
#define STBVOX_RSQRT3   0.5773502691896f

static float stbvox_default_normals[32][3] =
{
   { 1,0,0 },  // east
   { 0,1,0 },  // north
   { -1,0,0 }, // west
   { 0,-1,0 }, // south
   { 0,0,1 },  // up
   { 0,0,-1 }, // down
   {  STBVOX_RSQRT2,0, STBVOX_RSQRT2 }, // east & up
   {  STBVOX_RSQRT2,0, -STBVOX_RSQRT2 }, // east & down

   {  STBVOX_RSQRT2,0, STBVOX_RSQRT2 }, // east & up
   { 0, STBVOX_RSQRT2, STBVOX_RSQRT2 }, // north & up
   { -STBVOX_RSQRT2,0, STBVOX_RSQRT2 }, // west & up
   { 0,-STBVOX_RSQRT2, STBVOX_RSQRT2 }, // south & up
   {  STBVOX_RSQRT3, STBVOX_RSQRT3, STBVOX_RSQRT3 }, // ne & up
   {  STBVOX_RSQRT3, STBVOX_RSQRT3,-STBVOX_RSQRT3 }, // ne & down
   { 0, STBVOX_RSQRT2, STBVOX_RSQRT2 }, // north & up
   { 0, STBVOX_RSQRT2, -STBVOX_RSQRT2 }, // north & down

   {  STBVOX_RSQRT2,0, -STBVOX_RSQRT2 }, // east & down
   { 0, STBVOX_RSQRT2, -STBVOX_RSQRT2 }, // north & down
   { -STBVOX_RSQRT2,0, -STBVOX_RSQRT2 }, // west & down
   { 0,-STBVOX_RSQRT2, -STBVOX_RSQRT2 }, // south & down
   { -STBVOX_RSQRT3, STBVOX_RSQRT3, STBVOX_RSQRT3 }, // NW & up
   { -STBVOX_RSQRT3, STBVOX_RSQRT3,-STBVOX_RSQRT3 }, // NW & down
   { -STBVOX_RSQRT2,0, STBVOX_RSQRT2 }, // west & up
   { -STBVOX_RSQRT2,0, -STBVOX_RSQRT2 }, // west & down

   {  STBVOX_RSQRT3, STBVOX_RSQRT3,STBVOX_RSQRT3 }, // NE & up crossed
   { -STBVOX_RSQRT3, STBVOX_RSQRT3,STBVOX_RSQRT3 }, // NW & up crossed
   { -STBVOX_RSQRT3,-STBVOX_RSQRT3,STBVOX_RSQRT3 }, // SW & up crossed
   {  STBVOX_RSQRT3,-STBVOX_RSQRT3,STBVOX_RSQRT3 }, // SE & up crossed
   { -STBVOX_RSQRT3,-STBVOX_RSQRT3, STBVOX_RSQRT3 }, // SW & up
   { -STBVOX_RSQRT3,-STBVOX_RSQRT3,-STBVOX_RSQRT3 }, // SW & up
   { 0,-STBVOX_RSQRT2, STBVOX_RSQRT2 }, // south & up
   { 0,-STBVOX_RSQRT2, -STBVOX_RSQRT2 }, // south & down
};

static float stbvox_default_texscale[128][4] =
{
   {1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},
   {1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},
   {1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},
   {1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},
   {1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},
   {1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},
   {1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},
   {1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},
   {1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},
   {1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},
   {1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},
   {1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},
   {1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},
   {1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},
   {1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},
   {1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},{1,1,0,0},
};

static unsigned char stbvox_default_palette_compact[64][3] =
{
   { 255,255,255 }, { 238,238,238 }, { 221,221,221 }, { 204,204,204 },
   { 187,187,187 }, { 170,170,170 }, { 153,153,153 }, { 136,136,136 },
   { 119,119,119 }, { 102,102,102 }, {  85, 85, 85 }, {  68, 68, 68 },
   {  51, 51, 51 }, {  34, 34, 34 }, {  17, 17, 17 }, {   0,  0,  0 },
   { 255,240,240 }, { 255,220,220 }, { 255,160,160 }, { 255, 32, 32 },
   { 200,120,160 }, { 200, 60,150 }, { 220,100,130 }, { 255,  0,128 },
   { 240,240,255 }, { 220,220,255 }, { 160,160,255 }, {  32, 32,255 },
   { 120,160,200 }, {  60,150,200 }, { 100,130,220 }, {   0,128,255 },
   { 240,255,240 }, { 220,255,220 }, { 160,255,160 }, {  32,255, 32 },
   { 160,200,120 }, { 150,200, 60 }, { 130,220,100 }, { 128,255,  0 },
   { 255,255,240 }, { 255,255,220 }, { 220,220,180 }, { 255,255, 32 },
   { 200,160,120 }, { 200,150, 60 }, { 220,130,100 }, { 255,128,  0 },
   { 255,240,255 }, { 255,220,255 }, { 220,180,220 }, { 255, 32,255 },
   { 160,120,200 }, { 150, 60,200 }, { 130,100,220 }, { 128,  0,255 },
   { 240,255,255 }, { 220,255,255 }, { 180,220,220 }, {  32,255,255 },
   { 120,200,160 }, {  60,200,150 }, { 100,220,130 }, {   0,255,128 },
};

static float stbvox_default_ambient[4][4] =
{
   { 0,0,1      ,0 }, // reversed lighting direction
   { 0.5,0.5,0.5,0 }, // directional color
   { 0.5,0.5,0.5,0 }, // constant color
   { 0.5,0.5,0.5,1.0f/1000.0f/1000.0f }, // fog data for simple_fog
};

static float stbvox_default_palette[64][4];

static void stbvox_build_default_palette(void)
{
   int i;
   for (i=0; i < 64; ++i) {
      stbvox_default_palette[i][0] = stbvox_default_palette_compact[i][0] / 255.0f;
      stbvox_default_palette[i][1] = stbvox_default_palette_compact[i][1] / 255.0f;
      stbvox_default_palette[i][2] = stbvox_default_palette_compact[i][2] / 255.0f;
      stbvox_default_palette[i][3] = 1.0f;
   }
}

//////////////////////////////////////////////////////////////////////////////
//
// Shaders
//

#if defined(STBVOX_ICONFIG_OPENGL_3_1_COMPATIBILITY)
   #define STBVOX_SHADER_VERSION "#version 150 compatibility\n"
#elif defined(STBVOX_ICONFIG_OPENGL_3_0)
   #define STBVOX_SHADER_VERSION "#version 130\n"
#elif defined(STBVOX_ICONFIG_GLSL)
   #define STBVOX_SHADER_VERSION "#version 150\n"
#else
   #define STBVOX_SHADER_VERSION ""
#endif

static const char *stbvox_vertex_program =
{
      STBVOX_SHADER_VERSION

   #ifdef STBVOX_ICONFIG_FACE_ATTRIBUTE  // NOT TAG_face_sampled
      "in uvec4 attr_face;\n"
   #else
      "uniform usamplerBuffer facearray;\n"
   #endif

   #ifdef STBVOX_ICONFIG_FACE_ARRAY_2
      "uniform usamplerBuffer facearray2;\n"
   #endif

      // vertex input data
      "in uint attr_vertex;\n"

      // per-buffer data
      "uniform vec3 transform[3];\n"

      // per-frame data
      "uniform vec4 camera_pos;\n"  // 4th value is used for arbitrary hacking

      // to simplify things, we avoid using more than 256 uniform vectors
      // in fragment shader to avoid possible 1024 component limit, so
      // we access this table in the fragment shader.
      "uniform vec3 normal_table[32];\n"

      #ifndef STBVOX_CONFIG_OPENGL_MODELVIEW
         "uniform mat4x4 model_view;\n"
      #endif

      // fragment output data
      "flat out uvec4  facedata;\n"
      "     out  vec3  voxelspace_pos;\n"
      "     out  vec3  vnormal;\n"
      "     out float  texlerp;\n"
      "     out float  amb_occ;\n"

      // @TODO handle the HLSL way to do this
      "void main()\n"
      "{\n"
      #ifdef STBVOX_ICONFIG_FACE_ATTRIBUTE
         "   facedata = attr_face;\n"
      #else
         "   int faceID = gl_VertexID >> 2;\n"
         "   facedata   = texelFetch(facearray, faceID);\n"
      #endif

      // extract data for vertex
      "   vec3 offset;\n"
      "   offset.x = float( (attr_vertex       ) & 127u );\n"             // a[0..6]
      "   offset.y = float( (attr_vertex >>  7u) & 127u );\n"             // a[7..13]
      "   offset.z = float( (attr_vertex >> 14u) & 511u );\n"             // a[14..22]
      "   amb_occ  = float( (attr_vertex >> 23u) &  63u ) / 63.0;\n"      // a[23..28]
      "   texlerp  = float( (attr_vertex >> 29u)        ) /  7.0;\n"      // a[29..31]

      "   vnormal = normal_table[(facedata.w>>2u) & 31u];\n"
      "   voxelspace_pos = offset * transform[0];\n"  // mesh-to-object scale
      "   vec3 position  = voxelspace_pos + transform[1];\n"  // mesh-to-object translate

      #ifdef STBVOX_DEBUG_TEST_NORMALS
         "   if ((facedata.w & 28u) == 16u || (facedata.w & 28u) == 24u)\n"
         "      position += vnormal.xyz * camera_pos.w;\n"
      #endif

      #ifndef STBVOX_CONFIG_OPENGL_MODELVIEW
         "   gl_Position = model_view * vec4(position,1.0);\n"
      #else
         "   gl_Position = gl_ModelViewProjectionMatrix * vec4(position,1.0);\n"
      #endif

      "}\n"
};


static const char *stbvox_fragment_program =
{
      STBVOX_SHADER_VERSION

      // rlerp is lerp but with t on the left, like god intended
      #if defined(STBVOX_ICONFIG_GLSL)
         "#define rlerp(t,x,y) mix(x,y,t)\n"
      #elif defined(STBVOX_CONFIG_HLSL)
         "#define rlerp(t,x,y) lerp(x,y,t)\n"
      #else
         #error "need definition of rlerp()"
      #endif


      // vertex-shader output data
      "flat in uvec4  facedata;\n"
      "     in  vec3  voxelspace_pos;\n"
      "     in  vec3  vnormal;\n"
      "     in float  texlerp;\n"
      "     in float  amb_occ;\n"

      // per-buffer data
      "uniform vec3 transform[3];\n"

      // per-frame data
      "uniform vec4 camera_pos;\n"  // 4th value is used for arbitrary hacking

      // probably constant data
      "uniform vec4 ambient[4];\n"

      #ifndef STBVOX_ICONFIG_UNTEXTURED
         // generally constant data
         "uniform sampler2DArray tex_array[2];\n"

         #ifdef STBVOX_CONFIG_PREFER_TEXBUFFER
            "uniform samplerBuffer color_table;\n"
            "uniform samplerBuffer texscale;\n"
            "uniform samplerBuffer texgen;\n"
         #else
            "uniform vec4 color_table[64];\n"
            "uniform vec4 texscale[64];\n" // instead of 128, to avoid running out of uniforms
            "uniform vec3 texgen[64];\n"
         #endif
      #endif

      "out vec4  outcolor;\n"

      #if defined(STBVOX_CONFIG_LIGHTING) || defined(STBVOX_CONFIG_LIGHTING_SIMPLE)
      "vec3 compute_lighting(vec3 pos, vec3 norm, vec3 albedo, vec3 ambient);\n"
      #endif
      #if defined(STBVOX_CONFIG_FOG) || defined(STBVOX_CONFIG_FOG_SMOOTHSTEP)
      "vec3 compute_fog(vec3 color, vec3 relative_pos, float fragment_alpha);\n"
      #endif

      "void main()\n"
      "{\n"
      "   vec3 albedo;\n"
      "   float fragment_alpha;\n"

      #ifndef STBVOX_ICONFIG_UNTEXTURED
         // unpack the values
         "   uint tex1_id = facedata.x;\n"
         "   uint tex2_id = facedata.y;\n"
         "   uint texprojid = facedata.w & 31u;\n"
         "   uint color_id  = facedata.z;\n"

         #ifndef STBVOX_CONFIG_PREFER_TEXBUFFER
            // load from uniforms / texture buffers 
            "   vec3 texgen_s = texgen[texprojid];\n"
            "   vec3 texgen_t = texgen[texprojid+32u];\n"
            "   float tex1_scale = texscale[tex1_id & 63u].x;\n"
            "   vec4 color = color_table[color_id & 63u];\n"
            #ifndef STBVOX_CONFIG_DISABLE_TEX2
            "   vec4 tex2_props = texscale[tex2_id & 63u];\n"
            #endif
         #else
            "   vec3 texgen_s = texelFetch(texgen, int(texprojid)).xyz;\n"
            "   vec3 texgen_t = texelFetch(texgen, int(texprojid+32u)).xyz;\n"
            "   float tex1_scale = texelFetch(texscale, int(tex1_id & 127u)).x;\n"
            "   vec4 color = texelFetch(color_table, int(color_id & 63u));\n"
            #ifndef STBVOX_CONFIG_DISABLE_TEX2
            "   vec4 tex2_props = texelFetch(texscale, int(tex1_id & 127u));\n"
            #endif
         #endif

         #ifndef STBVOX_CONFIG_DISABLE_TEX2
         "   float tex2_scale = tex2_props.y;\n"
         "   bool texblend_mode = tex2_props.z != 0.0;\n"
         #endif
         "   vec2 texcoord;\n"
         "   vec3 texturespace_pos = voxelspace_pos + transform[2].xyz;\n"
         "   texcoord.s = dot(texturespace_pos, texgen_s);\n"
         "   texcoord.t = dot(texturespace_pos, texgen_t);\n"

         "   vec2  texcoord_1 = tex1_scale * texcoord;\n"
         #ifndef STBVOX_CONFIG_DISABLE_TEX2
         "   vec2  texcoord_2 = tex2_scale * texcoord;\n"
         #endif

         #ifdef STBVOX_CONFIG_TEX1_EDGE_CLAMP
         "   texcoord_1 = texcoord_1 - floor(texcoord_1);\n"
         "   vec4 tex1 = textureGrad(tex_array[0], vec3(texcoord_1, float(tex1_id)), dFdx(tex1_scale*texcoord), dFdy(tex1_scale*texcoord));\n"
         #else
         "   vec4 tex1 = texture(tex_array[0], vec3(texcoord_1, float(tex1_id)));\n"
         #endif

         #ifndef STBVOX_CONFIG_DISABLE_TEX2
         #ifdef STBVOX_CONFIG_TEX2_EDGE_CLAMP
         "   texcoord_2 = texcoord_2 - floor(texcoord_2);\n"
         "   vec4 tex2 = textureGrad(tex_array[0], vec3(texcoord_2, float(tex2_id)), dFdx(tex2_scale*texcoord), dFdy(tex2_scale*texcoord));\n"
         #else
         "   vec4 tex2 = texture(tex_array[1], vec3(texcoord_2, float(tex2_id)));\n"
         #endif
         #endif

         "   bool emissive = (color.a > 1.0);\n"
         "   color.a = min(color.a, 1.0);\n"

         // recolor textures
         "   if ((color_id &  64u) != 0u) tex1.rgba *= color.rgba;\n"
         "   fragment_alpha = tex1.a;\n"
         #ifndef STBVOX_CONFIG_DISABLE_TEX2
            "   if ((color_id & 128u) != 0u) tex2.rgba *= color.rgba;\n"

            #ifdef STBVOX_CONFIG_PREMULTIPLIED_ALPHA
            "   tex2.rgba *= texlerp;\n"
            #else
            "   tex2.a *= texlerp;\n"
            #endif

            "   if (texblend_mode)\n"
            "      albedo = tex1.xyz * rlerp(tex2.a, vec3(1.0,1.0,1.0), 2.0*tex2.xyz);\n"
            "   else {\n"
            #ifdef STBVOX_CONFIG_PREMULTIPLIED_ALPHA
            "      albedo = (1.0-tex2.a)*tex1.xyz + tex2.xyz;\n"
            #else
            "      albedo = rlerp(tex2.a, tex1.xyz, tex2.xyz);\n"
            #endif
            "      fragment_alpha = tex1.a*(1-tex2.a)+tex2.a;\n"
            "   }\n"
         #else
            "      albedo = tex1.xyz;\n"
         #endif

      #else // UNTEXTURED
         "   vec4 color;"
         "   color.xyz = vec3(facedata.xyz) / 255.0;\n"
         "   bool emissive = false;\n"
         "   albedo = color.xyz;\n"
         "   fragment_alpha = 1.0;\n"
      #endif

      #ifdef STBVOX_ICONFIG_VARYING_VERTEX_NORMALS
         // currently, there are no modes that trigger this path; idea is that there
         // could be a couple of bits per vertex to perturb the normal to e.g. get curved look
         "   vec3 normal = normalize(vnormal);\n"
      #else
         "   vec3 normal = vnormal;\n"
      #endif

      "   vec3 ambient_color = dot(normal, ambient[0].xyz) * ambient[1].xyz + ambient[2].xyz;\n"

      "   ambient_color = clamp(ambient_color, 0.0, 1.0);"
      "   ambient_color *= amb_occ;\n"

      "   vec3 lit_color;\n"
      "   if (!emissive)\n"
      #if defined(STBVOX_ICONFIG_LIGHTING) || defined(STBVOX_CONFIG_LIGHTING_SIMPLE)
         "      lit_color = compute_lighting(voxelspace_pos + transform[1], normal, albedo, ambient_color);\n"
      #else
         "      lit_color = albedo * ambient_color ;\n"
      #endif
      "   else\n"
      "      lit_color = albedo;\n"

      #if defined(STBVOX_ICONFIG_FOG) || defined(STBVOX_CONFIG_FOG_SMOOTHSTEP)
         "   vec3 dist = voxelspace_pos + (transform[1] - camera_pos.xyz);\n"
         "   lit_color = compute_fog(lit_color, dist, fragment_alpha);\n"
      #endif
      
      #ifdef STBVOX_CONFIG_UNPREMULTIPLY
      "   vec4 final_color = vec4(lit_color/fragment_alpha, fragment_alpha);\n"
      #else
      "   vec4 final_color = vec4(lit_color, fragment_alpha);\n"
      #endif
      "   outcolor = final_color;\n"
      "}\n"

   #ifdef STBVOX_CONFIG_LIGHTING_SIMPLE
      "\n"
      "uniform vec3 light_source[2];\n"
      "vec3 compute_lighting(vec3 pos, vec3 norm, vec3 albedo, vec3 ambient)\n"
      "{\n"
      "   vec3 light_dir = light_source[0] - pos;\n"
      "   float lambert = dot(light_dir, norm) / dot(light_dir, light_dir);\n"
      "   vec3 diffuse = clamp(light_source[1] * clamp(lambert, 0.0, 1.0), 0.0, 1.0);\n"
      "   return (diffuse + ambient) * albedo;\n"
      "}\n"
   #endif

   #ifdef STBVOX_CONFIG_FOG_SMOOTHSTEP
      "\n"
      "vec3 compute_fog(vec3 color, vec3 relative_pos, float fragment_alpha)\n"
      "{\n"
      "   float f = dot(relative_pos,relative_pos)*ambient[3].w;\n"
      //"   f = rlerp(f, -2,1);\n"
      "   f = clamp(f, 0.0, 1.0);\n" 
      "   f = 3.0*f*f - 2.0*f*f*f;\n" // smoothstep
      //"   f = f*f;\n"  // fade in more smoothly
      #ifdef STBVOX_CONFIG_PREMULTIPLIED_ALPHA
      "   return rlerp(f, color.xyz, ambient[3].xyz*fragment_alpha);\n"
      #else
      "   return rlerp(f, color.xyz, ambient[3].xyz);\n"
      #endif
      "}\n"
   #endif
};


// still requires full alpha lookups, including tex2 if texblend is enabled
static const char *stbvox_fragment_program_alpha_only =
{
   STBVOX_SHADER_VERSION

   // vertex-shader output data
   "flat in uvec4  facedata;\n"
   "     in  vec3  voxelspace_pos;\n"
   "     in float  texlerp;\n"

   // per-buffer data
   "uniform vec3 transform[3];\n"

   #ifndef STBVOX_ICONFIG_UNTEXTURED
      // generally constant data
      "uniform sampler2DArray tex_array[2];\n"

      #ifdef STBVOX_CONFIG_PREFER_TEXBUFFER
         "uniform samplerBuffer texscale;\n"
         "uniform samplerBuffer texgen;\n"
      #else
         "uniform vec4 texscale[64];\n" // instead of 128, to avoid running out of uniforms
         "uniform vec3 texgen[64];\n"
      #endif
   #endif

   "out vec4  outcolor;\n"

   "void main()\n"
   "{\n"
   "   vec3 albedo;\n"
   "   float fragment_alpha;\n"

   #ifndef STBVOX_ICONFIG_UNTEXTURED
      // unpack the values
      "   uint tex1_id = facedata.x;\n"
      "   uint tex2_id = facedata.y;\n"
      "   uint texprojid = facedata.w & 31u;\n"
      "   uint color_id  = facedata.z;\n"

      #ifndef STBVOX_CONFIG_PREFER_TEXBUFFER
         // load from uniforms / texture buffers 
         "   vec3 texgen_s = texgen[texprojid];\n"
         "   vec3 texgen_t = texgen[texprojid+32u];\n"
         "   float tex1_scale = texscale[tex1_id & 63u].x;\n"
         "   vec4 color = color_table[color_id & 63u];\n"
         "   vec4 tex2_props = texscale[tex2_id & 63u];\n"
      #else
         "   vec3 texgen_s = texelFetch(texgen, int(texprojid)).xyz;\n"
         "   vec3 texgen_t = texelFetch(texgen, int(texprojid+32u)).xyz;\n"
         "   float tex1_scale = texelFetch(texscale, int(tex1_id & 127u)).x;\n"
         "   vec4 color = texelFetch(color_table, int(color_id & 63u));\n"
         "   vec4 tex2_props = texelFetch(texscale, int(tex2_id & 127u));\n"
      #endif

      #ifndef STBVOX_CONFIG_DISABLE_TEX2
      "   float tex2_scale = tex2_props.y;\n"
      "   bool texblend_mode = tex2_props.z &((facedata.w & 128u) != 0u);\n"
      #endif

      "   color.a = min(color.a, 1.0);\n"

      "   vec2 texcoord;\n"
      "   vec3 texturespace_pos = voxelspace_pos + transform[2].xyz;\n"
      "   texcoord.s = dot(texturespace_pos, texgen_s);\n"
      "   texcoord.t = dot(texturespace_pos, texgen_t);\n"

      "   vec2  texcoord_1 = tex1_scale * texcoord;\n"
      "   vec2  texcoord_2 = tex2_scale * texcoord;\n"

      #ifdef STBVOX_CONFIG_TEX1_EDGE_CLAMP
      "   texcoord_1 = texcoord_1 - floor(texcoord_1);\n"
      "   vec4 tex1 = textureGrad(tex_array[0], vec3(texcoord_1, float(tex1_id)), dFdx(tex1_scale*texcoord), dFdy(tex1_scale*texcoord));\n"
      #else
      "   vec4 tex1 = texture(tex_array[0], vec3(texcoord_1, float(tex1_id)));\n"
      #endif

      "   if ((color_id &  64u) != 0u) tex1.a *= color.a;\n"
      "   fragment_alpha = tex1.a;\n"

      #ifndef STBVOX_CONFIG_DISABLE_TEX2
      "   if (!texblend_mode) {\n"
         #ifdef STBVOX_CONFIG_TEX2_EDGE_CLAMP
         "      texcoord_2 = texcoord_2 - floor(texcoord_2);\n"
         "      vec4 tex2 = textureGrad(tex_array[0], vec3(texcoord_2, float(tex2_id)), dFdx(tex2_scale*texcoord), dFdy(tex2_scale*texcoord));\n"
         #else
         "      vec4 tex2 = texture(tex_array[1], vec3(texcoord_2, float(tex2_id)));\n"
         #endif

         "      tex2.a *= texlerp;\n"
         "      if ((color_id & 128u) != 0u) tex2.rgba *= color.a;\n"
         "      fragment_alpha = tex1.a*(1-tex2.a)+tex2.a;\n"
         "}\n"
      "\n"
      #endif

   #else // UNTEXTURED
      "   fragment_alpha = 1.0;\n"
   #endif

   "   outcolor = vec4(0.0, 0.0, 0.0, fragment_alpha);\n"
   "}\n"
};


STBVXDEC char *stbvox_get_vertex_shader(void)
{
   return (char *) stbvox_vertex_program;
}

STBVXDEC char *stbvox_get_fragment_shader(void)
{
   return (char *) stbvox_fragment_program;
}

STBVXDEC char *stbvox_get_fragment_shader_alpha_only(void)
{
   return (char *) stbvox_fragment_program_alpha_only;
}

static float stbvox_dummy_transform[3][3];

#ifdef STBVOX_CONFIG_PREFER_TEXBUFFER
#define STBVOX_TEXBUF 1
#else
#define STBVOX_TEXBUF 0
#endif

static stbvox_uniform_info stbvox_uniforms[] =
{
   { STBVOX_UNIFORM_TYPE_sampler  ,  4,   1, (char*) "facearray"    , 0                           },
   { STBVOX_UNIFORM_TYPE_vec3     , 12,   3, (char*) "transform"    , stbvox_dummy_transform[0]   },
   { STBVOX_UNIFORM_TYPE_sampler  ,  4,   2, (char*) "tex_array"    , 0                           },
   { STBVOX_UNIFORM_TYPE_vec4     , 16, 128, (char*) "texscale"     , stbvox_default_texscale[0] , STBVOX_TEXBUF },
   { STBVOX_UNIFORM_TYPE_vec4     , 16,  64, (char*) "color_table"  , stbvox_default_palette[0]  , STBVOX_TEXBUF },
   { STBVOX_UNIFORM_TYPE_vec3     , 12,  32, (char*) "normal_table" , stbvox_default_normals[0]   },
   { STBVOX_UNIFORM_TYPE_vec3     , 12,  64, (char*) "texgen"       , stbvox_default_texgen[0][0], STBVOX_TEXBUF },
   { STBVOX_UNIFORM_TYPE_vec4     , 16,   4, (char*) "ambient"      , stbvox_default_ambient[0]   },
   { STBVOX_UNIFORM_TYPE_vec4     , 16,   1, (char*) "camera_pos"   , stbvox_dummy_transform[0]   },
};

STBVXDEC int stbvox_get_uniform_info(stbvox_uniform_info *info, int uniform)
{
   if (uniform < 0 || uniform >= STBVOX_UNIFORM_count)
      return 0;

   *info = stbvox_uniforms[uniform];
   return 1;
}

#define STBVOX_GET_GEO(geom_data)  ((geom_data) & 15)

typedef struct
{
   unsigned char block:2;
   unsigned char overlay:2;
   unsigned char facerot:2;
   unsigned char ecolor:2;
} stbvox_rotate;

typedef struct
{
   unsigned char x,y,z;
} stbvox_pos;

static unsigned char stbvox_rotate_face[6][4] =
{
   { 0,1,2,3 },
   { 1,2,3,0 },
   { 2,3,0,1 },
   { 3,0,1,2 },
   { 4,4,4,4 },
   { 5,5,5,5 },   
};

#define STBVOX_ROTATE(x,r)   stbvox_rotate_face[x][r] // (((x)+(r))&3)

stbvox_mesh_face stbvox_compute_mesh_face_value(stbvox_mesh_maker *mm, stbvox_rotate rot, int face, int v_off, int normal)
{
   stbvox_mesh_face face_data = { 0 };
   stbvox_block_type bt = mm->input.blocktype[v_off];
   unsigned char bt_face = STBVOX_ROTATE(face, rot.block);
   int facerot = rot.facerot;

   #ifdef STBVOX_ICONFIG_UNTEXTURED
   if (mm->input.rgb) {
      face_data.tex1  = mm->input.rgb[v_off].r;
      face_data.tex2  = mm->input.rgb[v_off].g;
      face_data.color = mm->input.rgb[v_off].b;
      face_data.face_info = (normal<<2);
      return face_data;
   }
   #else
   unsigned char color_face;

   if (mm->input.color)
      face_data.color = mm->input.color[v_off];

   if (mm->input.block_tex1)
      face_data.tex1 = mm->input.block_tex1[bt];
   else if (mm->input.block_tex1_face)
      face_data.tex1 = mm->input.block_tex1_face[bt][bt_face];
   else
      face_data.tex1 = bt;

   if (mm->input.block_tex2)
      face_data.tex2 = mm->input.block_tex2[bt];
   else if (mm->input.block_tex2_face)
      face_data.tex2 = mm->input.block_tex2_face[bt][bt_face];

   if (mm->input.block_color) {
      unsigned char mcol = mm->input.block_color[bt];
      if (mcol)
         face_data.color = mcol;
   } else if (mm->input.block_color_face) {
      unsigned char mcol = mm->input.block_color_face[bt][bt_face];
      if (mcol)
         face_data.color = mcol;
   }

   if (face <= STBVOX_FACE_south) {
      if (mm->input.side_texrot)
         facerot = mm->input.side_texrot[v_off] >> (2 * face);
      else if (mm->input.block_side_texrot)
         facerot = mm->input.block_side_texrot[v_off] >> (2 * bt_face);
   }

   if (mm->input.overlay) {
      int over_face = STBVOX_ROTATE(face, rot.overlay);
      unsigned char over = mm->input.overlay[v_off];
      if (over) {
         if (mm->input.overlay_tex1) {
            unsigned char rep1 = mm->input.overlay_tex1[over][over_face];
            if (rep1)
               face_data.tex1 = rep1;
         }
         if (mm->input.overlay_tex2) {
            unsigned char rep2 = mm->input.overlay_tex2[over][over_face];
            if (rep2)
               face_data.tex2 = rep2;
         }
         if (mm->input.overlay_color) {
            unsigned char rep3 = mm->input.overlay_color[over][over_face];
            if (rep3)
               face_data.color = rep3;
         }

         if (mm->input.overlay_side_texrot && face <= STBVOX_FACE_south)
            facerot = mm->input.overlay_side_texrot[over] >> (2*over_face);
      }
   }

   if (mm->input.tex2_for_tex1)
      face_data.tex2 = mm->input.tex2_for_tex1[face_data.tex1];
   if (mm->input.tex2)
      face_data.tex2 = mm->input.tex2[v_off];
   if (mm->input.tex2_replace) {
      if (mm->input.tex2_facemask[v_off] & (1 << face))
         face_data.tex2 = mm->input.tex2_replace[v_off];
   }

   color_face = STBVOX_ROTATE(face, rot.ecolor);
   if (mm->input.extended_color) {
      unsigned char ec = mm->input.extended_color[v_off];
      if (mm->input.ecolor_facemask[ec] & (1 << color_face))
         face_data.color = mm->input.ecolor_color[ec];
   }

   if (mm->input.color2) {
      if (mm->input.color2_facemask[v_off] & (1 << color_face))
         face_data.color = mm->input.color2[v_off];
      if (mm->input.color3 && (mm->input.color3_facemask[v_off] & (1 << color_face)))
         face_data.color = mm->input.color3[v_off];
   }
   #endif

   face_data.face_info = (normal<<2) + facerot;
   return face_data;
}

// these are the types of faces each block can have
enum
{
   STBVOX_FT_none    ,
   STBVOX_FT_upper   ,
   STBVOX_FT_lower   ,
   STBVOX_FT_solid   ,
   STBVOX_FT_diag_012,
   STBVOX_FT_diag_023,
   STBVOX_FT_diag_013,
   STBVOX_FT_diag_123,
   STBVOX_FT_force   , // can't be covered up, used for internal faces, also hides nothing
   STBVOX_FT_partial , // only covered by solid, never covers anything else

   STBVOX_FT_count
};

static unsigned char stbvox_face_lerp[6] = { 0,2,0,2,4,4 };
static unsigned char stbvox_vert3_lerp[5] = { 0,3,6,9,12 };
static unsigned char stbvox_vert_lerp_for_face_lerp[4] = { 0, 4, 7, 7 };
static unsigned char stbvox_face3_lerp[6] = { 0,3,6,9,12,14 };
static unsigned char stbvox_vert_lerp_for_simple[4] = { 0,2,5,7 };
static unsigned char stbvox_face3_updown[8] = { 0,2,5,7,0,2,5,7 }; // ignore top bit

// vertex offsets for face vertices
static unsigned char stbvox_vertex_vector[6][4][3] =
{
   { { 1,0,1 }, { 1,1,1 }, { 1,1,0 }, { 1,0,0 } }, // east
   { { 1,1,1 }, { 0,1,1 }, { 0,1,0 }, { 1,1,0 } }, // north
   { { 0,1,1 }, { 0,0,1 }, { 0,0,0 }, { 0,1,0 } }, // west
   { { 0,0,1 }, { 1,0,1 }, { 1,0,0 }, { 0,0,0 } }, // south
   { { 0,1,1 }, { 1,1,1 }, { 1,0,1 }, { 0,0,1 } }, // up
   { { 0,0,0 }, { 1,0,0 }, { 1,1,0 }, { 0,1,0 } }, // down
};

// stbvox_vertex_vector, but read coordinates as binary numbers, zyx
static unsigned char stbvox_vertex_selector[6][4] =
{
   { 5,7,3,1 },
   { 7,6,2,3 },
   { 6,4,0,2 },
   { 4,5,1,0 },
   { 6,7,5,4 },
   { 0,1,3,2 },
};

static stbvox_mesh_vertex stbvox_vmesh_delta_normal[6][4] =
{
   {  stbvox_vertex_encode(1,0,1,0,0) , 
      stbvox_vertex_encode(1,1,1,0,0) ,
      stbvox_vertex_encode(1,1,0,0,0) ,
      stbvox_vertex_encode(1,0,0,0,0)  },
   {  stbvox_vertex_encode(1,1,1,0,0) ,
      stbvox_vertex_encode(0,1,1,0,0) ,
      stbvox_vertex_encode(0,1,0,0,0) ,
      stbvox_vertex_encode(1,1,0,0,0)  },
   {  stbvox_vertex_encode(0,1,1,0,0) ,
      stbvox_vertex_encode(0,0,1,0,0) ,
      stbvox_vertex_encode(0,0,0,0,0) ,
      stbvox_vertex_encode(0,1,0,0,0)  },
   {  stbvox_vertex_encode(0,0,1,0,0) ,
      stbvox_vertex_encode(1,0,1,0,0) ,
      stbvox_vertex_encode(1,0,0,0,0) ,
      stbvox_vertex_encode(0,0,0,0,0)  },
   {  stbvox_vertex_encode(0,1,1,0,0) ,
      stbvox_vertex_encode(1,1,1,0,0) ,
      stbvox_vertex_encode(1,0,1,0,0) ,
      stbvox_vertex_encode(0,0,1,0,0)  },
   {  stbvox_vertex_encode(0,0,0,0,0) ,
      stbvox_vertex_encode(1,0,0,0,0) ,
      stbvox_vertex_encode(1,1,0,0,0) ,
      stbvox_vertex_encode(0,1,0,0,0)  }
};

static stbvox_mesh_vertex stbvox_vmesh_pre_vheight[6][4] =
{
   {  stbvox_vertex_encode(1,0,0,0,0) , 
      stbvox_vertex_encode(1,1,0,0,0) ,
      stbvox_vertex_encode(1,1,0,0,0) ,
      stbvox_vertex_encode(1,0,0,0,0)  },
   {  stbvox_vertex_encode(1,1,0,0,0) ,
      stbvox_vertex_encode(0,1,0,0,0) ,
      stbvox_vertex_encode(0,1,0,0,0) ,
      stbvox_vertex_encode(1,1,0,0,0)  },
   {  stbvox_vertex_encode(0,1,0,0,0) ,
      stbvox_vertex_encode(0,0,0,0,0) ,
      stbvox_vertex_encode(0,0,0,0,0) ,
      stbvox_vertex_encode(0,1,0,0,0)  },
   {  stbvox_vertex_encode(0,0,0,0,0) ,
      stbvox_vertex_encode(1,0,0,0,0) ,
      stbvox_vertex_encode(1,0,0,0,0) ,
      stbvox_vertex_encode(0,0,0,0,0)  },
   {  stbvox_vertex_encode(0,1,0,0,0) ,
      stbvox_vertex_encode(1,1,0,0,0) ,
      stbvox_vertex_encode(1,0,0,0,0) ,
      stbvox_vertex_encode(0,0,0,0,0)  },
   {  stbvox_vertex_encode(0,0,0,0,0) ,
      stbvox_vertex_encode(1,0,0,0,0) ,
      stbvox_vertex_encode(1,1,0,0,0) ,
      stbvox_vertex_encode(0,1,0,0,0)  }
};

static stbvox_mesh_vertex stbvox_vmesh_delta_half_z[6][4] =
{
   { stbvox_vertex_encode(1,0,2,0,0) , 
     stbvox_vertex_encode(1,1,2,0,0) ,
     stbvox_vertex_encode(1,1,0,0,0) ,
     stbvox_vertex_encode(1,0,0,0,0)  },
   { stbvox_vertex_encode(1,1,2,0,0) ,
     stbvox_vertex_encode(0,1,2,0,0) ,
     stbvox_vertex_encode(0,1,0,0,0) ,
     stbvox_vertex_encode(1,1,0,0,0)  },
   { stbvox_vertex_encode(0,1,2,0,0) ,
     stbvox_vertex_encode(0,0,2,0,0) ,
     stbvox_vertex_encode(0,0,0,0,0) ,
     stbvox_vertex_encode(0,1,0,0,0)  },
   { stbvox_vertex_encode(0,0,2,0,0) ,
     stbvox_vertex_encode(1,0,2,0,0) ,
     stbvox_vertex_encode(1,0,0,0,0) ,
     stbvox_vertex_encode(0,0,0,0,0)  },
   { stbvox_vertex_encode(0,1,2,0,0) ,
     stbvox_vertex_encode(1,1,2,0,0) ,
     stbvox_vertex_encode(1,0,2,0,0) ,
     stbvox_vertex_encode(0,0,2,0,0)  },
   { stbvox_vertex_encode(0,0,0,0,0) ,
     stbvox_vertex_encode(1,0,0,0,0) ,
     stbvox_vertex_encode(1,1,0,0,0) ,
     stbvox_vertex_encode(0,1,0,0,0)  }
};

static stbvox_mesh_vertex stbvox_vmesh_crossed_pair[6][4] =
{
   { stbvox_vertex_encode(1,0,2,0,0) , 
     stbvox_vertex_encode(0,1,2,0,0) ,
     stbvox_vertex_encode(0,1,0,0,0) ,
     stbvox_vertex_encode(1,0,0,0,0)  },
   { stbvox_vertex_encode(1,1,2,0,0) ,
     stbvox_vertex_encode(0,0,2,0,0) ,
     stbvox_vertex_encode(0,0,0,0,0) ,
     stbvox_vertex_encode(1,1,0,0,0)  },
   { stbvox_vertex_encode(0,1,2,0,0) ,
     stbvox_vertex_encode(1,0,2,0,0) ,
     stbvox_vertex_encode(1,0,0,0,0) ,
     stbvox_vertex_encode(0,1,0,0,0)  },
   { stbvox_vertex_encode(0,0,2,0,0) ,
     stbvox_vertex_encode(1,1,2,0,0) ,
     stbvox_vertex_encode(1,1,0,0,0) ,
     stbvox_vertex_encode(0,0,0,0,0)  },
   // not used, so we leave it non-degenerate to make sure it doesn't get gen'd accidentally
   { stbvox_vertex_encode(0,1,2,0,0) ,
     stbvox_vertex_encode(1,1,2,0,0) ,
     stbvox_vertex_encode(1,0,2,0,0) ,
     stbvox_vertex_encode(0,0,2,0,0)  },
   { stbvox_vertex_encode(0,0,0,0,0) ,
     stbvox_vertex_encode(1,0,0,0,0) ,
     stbvox_vertex_encode(1,1,0,0,0) ,
     stbvox_vertex_encode(0,1,0,0,0)  }
};

#define STBVOX_MAX_GEOM     16
#define STBVOX_NUM_ROTATION  4

// this is used to determine if a face is ever generated at all
static unsigned char stbvox_hasface[STBVOX_MAX_GEOM][STBVOX_NUM_ROTATION] =
{
   { 0,0,0,0 }, // empty
   { 0,0,0,0 }, // knockout
   { 63,63,63,63 }, // solid
   { 63,63,63,63 }, // transp
   { 63,63,63,63 }, // slab
   { 63,63,63,63 }, // slab
   { 1|2|4|48, 8|1|2|48, 4|8|1|48, 2|4|8|48, }, // floor slopes
   { 1|2|4|48, 8|1|2|48, 4|8|1|48, 2|4|8|48, }, // ceil slopes
   { 47,47,47,47 }, // wall-projected diagonal with down face
   { 31,31,31,31 }, // wall-projected diagonal with up face
   { 63,63,63,63 }, // crossed-pair has special handling, but avoid early-out
   { 63,63,63,63 }, // force
   { 63,63,63,63 }, // vheight
   { 63,63,63,63 }, // vheight
   { 63,63,63,63 }, // vheight
   { 63,63,63,63 }, // vheight
};

// this determines which face type above is visible on each side of the geometry
static unsigned char stbvox_facetype[STBVOX_GEOM_count][6] =
{
   { 0, },  // STBVOX_GEOM_empty
   { STBVOX_FT_solid, STBVOX_FT_solid, STBVOX_FT_solid, STBVOX_FT_solid, STBVOX_FT_solid, STBVOX_FT_solid }, // knockout
   { STBVOX_FT_solid, STBVOX_FT_solid, STBVOX_FT_solid, STBVOX_FT_solid, STBVOX_FT_solid, STBVOX_FT_solid }, // solid
   { STBVOX_FT_force, STBVOX_FT_force, STBVOX_FT_force, STBVOX_FT_force, STBVOX_FT_force, STBVOX_FT_force }, // transp

   { STBVOX_FT_upper, STBVOX_FT_upper, STBVOX_FT_upper, STBVOX_FT_upper, STBVOX_FT_solid, STBVOX_FT_force },
   { STBVOX_FT_lower, STBVOX_FT_lower, STBVOX_FT_lower, STBVOX_FT_lower, STBVOX_FT_force, STBVOX_FT_solid },
   { STBVOX_FT_diag_123, STBVOX_FT_solid, STBVOX_FT_diag_023, STBVOX_FT_none, STBVOX_FT_force, STBVOX_FT_solid },
   { STBVOX_FT_diag_012, STBVOX_FT_solid, STBVOX_FT_diag_013, STBVOX_FT_none, STBVOX_FT_solid, STBVOX_FT_force },

   { STBVOX_FT_diag_123, STBVOX_FT_solid, STBVOX_FT_diag_023, STBVOX_FT_force, STBVOX_FT_none, STBVOX_FT_solid },
   { STBVOX_FT_diag_012, STBVOX_FT_solid, STBVOX_FT_diag_013, STBVOX_FT_force, STBVOX_FT_solid, STBVOX_FT_none },
   { STBVOX_FT_force, STBVOX_FT_force, STBVOX_FT_force, STBVOX_FT_force, 0,0 }, // crossed pair
   { STBVOX_FT_force, STBVOX_FT_force, STBVOX_FT_force, STBVOX_FT_force, STBVOX_FT_force, STBVOX_FT_force }, // GEOM_force

   { STBVOX_FT_partial,STBVOX_FT_partial,STBVOX_FT_partial,STBVOX_FT_partial, STBVOX_FT_force, STBVOX_FT_solid }, // floor vheight, all neighbors forced
   { STBVOX_FT_partial,STBVOX_FT_partial,STBVOX_FT_partial,STBVOX_FT_partial, STBVOX_FT_force, STBVOX_FT_solid }, // floor vheight, all neighbors forced
   { STBVOX_FT_partial,STBVOX_FT_partial,STBVOX_FT_partial,STBVOX_FT_partial, STBVOX_FT_solid, STBVOX_FT_force }, // ceil vheight, all neighbors forced
   { STBVOX_FT_partial,STBVOX_FT_partial,STBVOX_FT_partial,STBVOX_FT_partial, STBVOX_FT_solid, STBVOX_FT_force }, // ceil vheight, all neighbors forced
};

// This table indicates what normal to use for the "up" face of a sloped geom
// @TODO this could be done with math given the current arrangement of the enum, but let's not require it
static unsigned char stbvox_floor_slope_for_rot[4] =
{
   STBVF_su,
   STBVF_wu, // @TODO: why is this reversed from what it should be? this is a north-is-up face, so slope should be south&up
   STBVF_nu,
   STBVF_eu,
};

static unsigned char stbvox_ceil_slope_for_rot[4] =
{
   STBVF_sd,
   STBVF_ed,
   STBVF_nd,
   STBVF_wd,
};

// this table indicates whether, for each pair of types above, a face is visible.
// each value indicates whether a given type is visible for all neighbor types
static unsigned short stbvox_face_visible[STBVOX_FT_count] =
{
   // we encode the table by listing which cases cause *obscuration*, and bitwise inverting that
   // table is pre-shifted by 5 to save a shift when it's accessed
   (unsigned short) ((~0x07ff                                          )<<5),  // none is completely obscured by everything
   (unsigned short) ((~((1<<STBVOX_FT_solid) | (1<<STBVOX_FT_upper)   ))<<5),  // upper
   (unsigned short) ((~((1<<STBVOX_FT_solid) | (1<<STBVOX_FT_lower)   ))<<5),  // lower
   (unsigned short) ((~((1<<STBVOX_FT_solid)                          ))<<5),  // solid is only completely obscured only by solid
   (unsigned short) ((~((1<<STBVOX_FT_solid) | (1<<STBVOX_FT_diag_013)))<<5),  // diag012 matches diag013
   (unsigned short) ((~((1<<STBVOX_FT_solid) | (1<<STBVOX_FT_diag_123)))<<5),  // diag023 matches diag123
   (unsigned short) ((~((1<<STBVOX_FT_solid) | (1<<STBVOX_FT_diag_012)))<<5),  // diag013 matches diag012
   (unsigned short) ((~((1<<STBVOX_FT_solid) | (1<<STBVOX_FT_diag_023)))<<5),  // diag123 matches diag023
   (unsigned short) ((~0                                               )<<5),  // force is always rendered regardless, always forces neighbor
   (unsigned short) ((~((1<<STBVOX_FT_solid)                          ))<<5),  // partial is only completely obscured only by solid
};

// the vertex heights of the block types, in binary vertex order (zyx):
// lower: SW, SE, NW, NE; upper: SW, SE, NW, NE
static stbvox_mesh_vertex stbvox_geometry_vheight[8][8] =
{
   #define STBVOX_HEIGHTS(a,b,c,d,e,f,g,h) \
     { stbvox_vertex_encode(0,0,a,0,0),  \
       stbvox_vertex_encode(0,0,b,0,0),  \
       stbvox_vertex_encode(0,0,c,0,0),  \
       stbvox_vertex_encode(0,0,d,0,0),  \
       stbvox_vertex_encode(0,0,e,0,0),  \
       stbvox_vertex_encode(0,0,f,0,0),  \
       stbvox_vertex_encode(0,0,g,0,0),  \
       stbvox_vertex_encode(0,0,h,0,0) }

   STBVOX_HEIGHTS(0,0,0,0, 2,2,2,2),
   STBVOX_HEIGHTS(0,0,0,0, 2,2,2,2),
   STBVOX_HEIGHTS(0,0,0,0, 2,2,2,2),
   STBVOX_HEIGHTS(0,0,0,0, 2,2,2,2),
   STBVOX_HEIGHTS(1,1,1,1, 2,2,2,2),
   STBVOX_HEIGHTS(0,0,0,0, 1,1,1,1),
   STBVOX_HEIGHTS(0,0,0,0, 0,0,2,2),
   STBVOX_HEIGHTS(2,2,0,0, 2,2,2,2),
};

// rotate vertices defined as [z][y][x] coords
static unsigned char stbvox_rotate_vertex[8][4] =
{
   { 0,1,3,2 }, // zyx=000
   { 1,3,2,0 }, // zyx=001
   { 2,0,1,3 }, // zyx=010
   { 3,2,0,1 }, // zyx=011
   { 4,5,7,6 }, // zyx=100
   { 5,7,6,4 }, // zyx=101
   { 6,4,5,7 }, // zyx=110
   { 7,6,4,5 }, // zyx=111
};

#ifdef STBVOX_CONFIG_OPTIMIZED_VHEIGHT
// optimized vheight generates a single normal over the entire face, even if it's not planar
static unsigned char stbvox_optimized_face_up_normal[4][4][4][4] =
{
   {
      {
         { STBVF_u   , STBVF_ne_u, STBVF_ne_u, STBVF_ne_u, },
         { STBVF_nw_u, STBVF_nu  , STBVF_nu  , STBVF_ne_u, },
         { STBVF_nw_u, STBVF_nu  , STBVF_nu  , STBVF_nu  , },
         { STBVF_nw_u, STBVF_nw_u, STBVF_nu  , STBVF_nu  , },
      },{
         { STBVF_su  , STBVF_eu  , STBVF_eu  , STBVF_ne_u, },
         { STBVF_u   , STBVF_ne_u, STBVF_ne_u, STBVF_ne_u, },
         { STBVF_nw_u, STBVF_nu  , STBVF_nu  , STBVF_ne_u, },
         { STBVF_nw_u, STBVF_nu  , STBVF_nu  , STBVF_nu  , },
      },{
         { STBVF_eu  , STBVF_eu  , STBVF_eu  , STBVF_eu  , },
         { STBVF_su  , STBVF_eu  , STBVF_eu  , STBVF_ne_u, },
         { STBVF_u   , STBVF_ne_u, STBVF_ne_u, STBVF_ne_u, },
         { STBVF_nw_u, STBVF_nu  , STBVF_nu  , STBVF_ne_u, },
      },{
         { STBVF_eu  , STBVF_eu  , STBVF_eu  , STBVF_eu  , },
         { STBVF_eu  , STBVF_eu  , STBVF_eu  , STBVF_eu  , },
         { STBVF_su  , STBVF_eu  , STBVF_eu  , STBVF_ne_u, },
         { STBVF_u   , STBVF_ne_u, STBVF_ne_u, STBVF_ne_u, },
      },
   },{
      {
         { STBVF_sw_u, STBVF_u   , STBVF_ne_u, STBVF_ne_u, },
         { STBVF_wu  , STBVF_nw_u, STBVF_nu  , STBVF_nu  , },
         { STBVF_wu  , STBVF_nw_u, STBVF_nu  , STBVF_nu  , },
         { STBVF_nw_u, STBVF_nw_u, STBVF_nw_u, STBVF_nu  , },
      },{
         { STBVF_su  , STBVF_su  , STBVF_eu  , STBVF_eu  , },
         { STBVF_sw_u, STBVF_u   , STBVF_ne_u, STBVF_ne_u, },
         { STBVF_wu  , STBVF_nw_u, STBVF_nu  , STBVF_nu  , },
         { STBVF_wu  , STBVF_nw_u, STBVF_nu  , STBVF_nu  , },
      },{
         { STBVF_su  , STBVF_eu  , STBVF_eu  , STBVF_eu  , },
         { STBVF_su  , STBVF_su  , STBVF_eu  , STBVF_eu  , },
         { STBVF_sw_u, STBVF_u   , STBVF_ne_u, STBVF_ne_u, },
         { STBVF_wu  , STBVF_nw_u, STBVF_nu  , STBVF_nu  , },
      },{
         { STBVF_su  , STBVF_eu  , STBVF_eu  , STBVF_eu  , },
         { STBVF_su  , STBVF_eu  , STBVF_eu  , STBVF_eu  , },
         { STBVF_su  , STBVF_su  , STBVF_eu  , STBVF_eu  , },
         { STBVF_sw_u, STBVF_u   , STBVF_ne_u, STBVF_ne_u, },
      },
   },{
      {
         { STBVF_sw_u, STBVF_sw_u, STBVF_u   , STBVF_ne_u, },
         { STBVF_wu  , STBVF_wu  , STBVF_nw_u, STBVF_nu  , },
         { STBVF_wu  , STBVF_wu  , STBVF_nw_u, STBVF_nu  , },
         { STBVF_wu  , STBVF_nw_u, STBVF_nw_u, STBVF_nw_u, },
      },{
         { STBVF_su  , STBVF_su  , STBVF_su  , STBVF_eu  , },
         { STBVF_sw_u, STBVF_sw_u, STBVF_u   , STBVF_ne_u, },
         { STBVF_wu  , STBVF_wu  , STBVF_nw_u, STBVF_nu  , },
         { STBVF_wu  , STBVF_wu  , STBVF_nw_u, STBVF_nu  , },
      },{
         { STBVF_su  , STBVF_su  , STBVF_eu  , STBVF_eu  , },
         { STBVF_su  , STBVF_su  , STBVF_su  , STBVF_eu  , },
         { STBVF_sw_u, STBVF_sw_u, STBVF_u   , STBVF_ne_u, },
         { STBVF_wu  , STBVF_wu  , STBVF_nw_u, STBVF_nu  , },
      },{
         { STBVF_su  , STBVF_su  , STBVF_eu  , STBVF_eu  , },
         { STBVF_su  , STBVF_su  , STBVF_eu  , STBVF_eu  , },
         { STBVF_su  , STBVF_su  , STBVF_su  , STBVF_eu  , },
         { STBVF_sw_u, STBVF_sw_u, STBVF_u   , STBVF_ne_u, },
      },
   },{
      {
         { STBVF_sw_u, STBVF_sw_u, STBVF_sw_u, STBVF_u   , },
         { STBVF_sw_u, STBVF_wu  , STBVF_wu  , STBVF_nw_u, },
         { STBVF_wu  , STBVF_wu  , STBVF_wu  , STBVF_nw_u, },
         { STBVF_wu  , STBVF_wu  , STBVF_nw_u, STBVF_nw_u, },
      },{
         { STBVF_sw_u, STBVF_su  , STBVF_su  , STBVF_su  , },
         { STBVF_sw_u, STBVF_sw_u, STBVF_sw_u, STBVF_u   , },
         { STBVF_sw_u, STBVF_wu  , STBVF_wu  , STBVF_nw_u, },
         { STBVF_wu  , STBVF_wu  , STBVF_wu  , STBVF_nw_u, },
      },{
         { STBVF_su  , STBVF_su  , STBVF_su  , STBVF_eu  , },
         { STBVF_sw_u, STBVF_su  , STBVF_su  , STBVF_su  , },
         { STBVF_sw_u, STBVF_sw_u, STBVF_sw_u, STBVF_u   , },
         { STBVF_sw_u, STBVF_wu  , STBVF_wu  , STBVF_nw_u, },
      },{
         { STBVF_su  , STBVF_su  , STBVF_su  , STBVF_eu  , },
         { STBVF_su  , STBVF_su  , STBVF_su  , STBVF_eu  , },
         { STBVF_sw_u, STBVF_su  , STBVF_su  , STBVF_su  , },
         { STBVF_sw_u, STBVF_sw_u, STBVF_sw_u, STBVF_u   , },
      },
   },
};
#else
// which normal to use for a given vheight that's planar
// @TODO: this table was constructed by hand and may have bugs
//                                 nw se sw
static unsigned char stbvox_planar_face_up_normal[4][4][4] =
{   
   {                                                      // sw,se,nw,ne;  ne = se+nw-sw
      { STBVF_u   , 0         , 0         , 0          }, //  0,0,0,0; 1,0,0,-1; 2,0,0,-2; 3,0,0,-3;
      { STBVF_u   , STBVF_u   , 0         , 0          }, //  0,1,0,1; 1,1,0, 0; 2,1,0,-1; 3,1,0,-2;
      { STBVF_wu  , STBVF_nw_u, STBVF_nu  , 0          }, //  0,2,0,2; 1,2,0, 1; 2,2,0, 0; 3,2,0,-1;
      { STBVF_wu  , STBVF_nw_u, STBVF_nw_u, STBVF_nu   }, //  0,3,0,3; 1,3,0, 2; 2,3,0, 1; 3,3,0, 0;
   },{
      { STBVF_u   , STBVF_u   , 0         , 0          }, //  0,0,1,1; 1,0,1, 0; 2,0,1,-1; 3,0,1,-2;
      { STBVF_sw_u, STBVF_u   , STBVF_ne_u, 0          }, //  0,1,1,2; 1,1,1, 1; 2,1,1, 0; 3,1,1,-1;
      { STBVF_sw_u, STBVF_u   , STBVF_u   , STBVF_ne_u }, //  0,2,1,3; 1,2,1, 2; 2,2,1, 1; 3,2,1, 0;
      { 0         , STBVF_wu  , STBVF_nw_u, STBVF_nu   }, //  0,3,1,4; 1,3,1, 3; 2,3,1, 2; 3,3,1, 1;
   },{
      { STBVF_su  , STBVF_se_u, STBVF_eu  , 0          }, //  0,0,2,2; 1,0,2, 1; 2,0,2, 0; 3,0,2,-1;
      { STBVF_sw_u, STBVF_u   , STBVF_u   , STBVF_ne_u }, //  0,1,2,3; 1,1,2, 2; 2,1,2, 1; 3,1,2, 0;
      { 0         , STBVF_sw_u, STBVF_u   , STBVF_ne_u }, //  0,2,2,4; 1,2,2, 3; 2,2,2, 2; 3,2,2, 1;
      { 0         , 0         , STBVF_u   , STBVF_u    }, //  0,3,2,5; 1,3,2, 4; 2,3,2, 3; 3,3,2, 2;
   },{
      { STBVF_su  , STBVF_se_u, STBVF_se_u, STBVF_eu   }, //  0,0,3,3; 1,0,3, 2; 2,0,3, 1; 3,0,3, 0;
      { 0         , STBVF_su  , STBVF_se_u, STBVF_eu   }, //  0,1,3,4; 1,1,3, 3; 2,1,3, 2; 3,1,3, 1;
      { 0         , 0         , STBVF_u   , STBVF_u    }, //  0,2,3,5; 1,2,3, 4; 2,2,3, 3; 3,2,3, 2;
      { 0         , 0         , 0         , STBVF_u    }, //  0,3,3,6; 1,3,3, 5; 2,3,3, 4; 3,3,3, 3;
   }
};

// these tables were constructed automatically using a variant of the code
// below; however, they seem wrong, so who knows
static unsigned char stbvox_face_up_normal_012[4][4][4] =
{
   {
      { STBVF_u   , STBVF_ne_u, STBVF_ne_u, STBVF_ne_u, },
      { STBVF_wu  , STBVF_nu  , STBVF_ne_u, STBVF_ne_u, },
      { STBVF_wu  , STBVF_nw_u, STBVF_nu  , STBVF_ne_u, },
      { STBVF_wu  , STBVF_nw_u, STBVF_nw_u, STBVF_nu  , },
   },{
      { STBVF_su  , STBVF_eu  , STBVF_ne_u, STBVF_ne_u, },
      { STBVF_sw_u, STBVF_u   , STBVF_ne_u, STBVF_ne_u, },
      { STBVF_sw_u, STBVF_wu  , STBVF_nu  , STBVF_ne_u, },
      { STBVF_sw_u, STBVF_wu  , STBVF_nw_u, STBVF_nu  , },
   },{
      { STBVF_su  , STBVF_eu  , STBVF_eu  , STBVF_ne_u, },
      { STBVF_sw_u, STBVF_su  , STBVF_eu  , STBVF_ne_u, },
      { STBVF_sw_u, STBVF_sw_u, STBVF_u   , STBVF_ne_u, },
      { STBVF_sw_u, STBVF_sw_u, STBVF_wu  , STBVF_nu  , },
   },{
      { STBVF_su  , STBVF_su  , STBVF_eu  , STBVF_eu  , },
      { STBVF_sw_u, STBVF_su  , STBVF_eu  , STBVF_eu  , },
      { STBVF_sw_u, STBVF_sw_u, STBVF_su  , STBVF_eu  , },
      { STBVF_sw_u, STBVF_sw_u, STBVF_sw_u, STBVF_u   , },
   }
};

static unsigned char stbvox_face_up_normal_013[4][4][4] =
{
   {
      { STBVF_u   , STBVF_eu  , STBVF_eu  , STBVF_eu  , },
      { STBVF_nw_u, STBVF_nu  , STBVF_ne_u, STBVF_ne_u, },
      { STBVF_nw_u, STBVF_nw_u, STBVF_nu  , STBVF_ne_u, },
      { STBVF_nw_u, STBVF_nw_u, STBVF_nw_u, STBVF_nu  , },
   },{
      { STBVF_su  , STBVF_eu  , STBVF_eu  , STBVF_eu  , },
      { STBVF_wu  , STBVF_u   , STBVF_eu  , STBVF_eu  , },
      { STBVF_nw_u, STBVF_nw_u, STBVF_nu  , STBVF_ne_u, },
      { STBVF_nw_u, STBVF_nw_u, STBVF_nw_u, STBVF_nu  , },
   },{
      { STBVF_su  , STBVF_su  , STBVF_su  , STBVF_eu  , },
      { STBVF_sw_u, STBVF_su  , STBVF_eu  , STBVF_eu  , },
      { STBVF_wu  , STBVF_wu  , STBVF_u   , STBVF_eu  , },
      { STBVF_nw_u, STBVF_nw_u, STBVF_nw_u, STBVF_nu  , },
   },{
      { STBVF_su  , STBVF_su  , STBVF_su  , STBVF_eu  , },
      { STBVF_sw_u, STBVF_su  , STBVF_su  , STBVF_su  , },
      { STBVF_sw_u, STBVF_sw_u, STBVF_su  , STBVF_eu  , },
      { STBVF_wu  , STBVF_wu  , STBVF_wu  , STBVF_u   , },
   }
};

static unsigned char stbvox_face_up_normal_023[4][4][4] =
{
   {
      { STBVF_u   , STBVF_nu  , STBVF_nu  , STBVF_nu  , },
      { STBVF_eu  , STBVF_eu  , STBVF_ne_u, STBVF_ne_u, },
      { STBVF_su  , STBVF_eu  , STBVF_eu  , STBVF_ne_u, },
      { STBVF_eu  , STBVF_eu  , STBVF_eu  , STBVF_eu  , },
   },{
      { STBVF_wu  , STBVF_nw_u, STBVF_nw_u, STBVF_nw_u, },
      { STBVF_su  , STBVF_u   , STBVF_nu  , STBVF_nu  , },
      { STBVF_su  , STBVF_eu  , STBVF_eu  , STBVF_ne_u, },
      { STBVF_su  , STBVF_su  , STBVF_eu  , STBVF_eu  , },
   },{
      { STBVF_wu  , STBVF_nw_u, STBVF_nw_u, STBVF_nw_u, },
      { STBVF_sw_u, STBVF_wu  , STBVF_nw_u, STBVF_nw_u, },
      { STBVF_su  , STBVF_su  , STBVF_u   , STBVF_nu  , },
      { STBVF_su  , STBVF_su  , STBVF_eu  , STBVF_eu  , },
   },{
      { STBVF_wu  , STBVF_nw_u, STBVF_nw_u, STBVF_nw_u, },
      { STBVF_sw_u, STBVF_wu  , STBVF_nw_u, STBVF_nw_u, },
      { STBVF_sw_u, STBVF_sw_u, STBVF_wu  , STBVF_nw_u, },
      { STBVF_su  , STBVF_su  , STBVF_su  , STBVF_u   , },
   }
};

static unsigned char stbvox_face_up_normal_123[4][4][4] =
{
   {
      { STBVF_u   , STBVF_nu  , STBVF_nu  , STBVF_nu  , },
      { STBVF_eu  , STBVF_ne_u, STBVF_ne_u, STBVF_ne_u, },
      { STBVF_eu  , STBVF_ne_u, STBVF_ne_u, STBVF_ne_u, },
      { STBVF_eu  , STBVF_ne_u, STBVF_ne_u, STBVF_ne_u, },
   },{
      { STBVF_sw_u, STBVF_wu  , STBVF_nw_u, STBVF_nw_u, },
      { STBVF_su  , STBVF_u   , STBVF_nu  , STBVF_nu  , },
      { STBVF_eu  , STBVF_eu  , STBVF_ne_u, STBVF_ne_u, },
      { STBVF_eu  , STBVF_eu  , STBVF_ne_u, STBVF_ne_u, },
   },{
      { STBVF_sw_u, STBVF_sw_u, STBVF_wu  , STBVF_nw_u, },
      { STBVF_sw_u, STBVF_sw_u, STBVF_wu  , STBVF_nw_u, },
      { STBVF_su  , STBVF_su  , STBVF_u   , STBVF_nu  , },
      { STBVF_su  , STBVF_eu  , STBVF_eu  , STBVF_ne_u, },
   },{
      { STBVF_sw_u, STBVF_sw_u, STBVF_sw_u, STBVF_wu  , },
      { STBVF_sw_u, STBVF_sw_u, STBVF_sw_u, STBVF_wu  , },
      { STBVF_sw_u, STBVF_sw_u, STBVF_sw_u, STBVF_wu  , },
      { STBVF_su  , STBVF_su  , STBVF_su  , STBVF_u   , },
   }
};
#endif

void stbvox_get_quad_vertex_pointer(stbvox_mesh_maker *mm, int mesh, stbvox_mesh_vertex **vertices, stbvox_mesh_face face)
{
   char *p = mm->output_cur[mesh][0];
   int step = mm->output_step[mesh][0];

   // allocate a new quad from the mesh
   vertices[0] = (stbvox_mesh_vertex *) p; p += step;
   vertices[1] = (stbvox_mesh_vertex *) p; p += step;
   vertices[2] = (stbvox_mesh_vertex *) p; p += step;
   vertices[3] = (stbvox_mesh_vertex *) p; p += step;
   mm->output_cur[mesh][0] = p;

   // output the face
   #ifdef STBVOX_ICONFIG_FACE_ATTRIBUTE
      // write face as interleaved vertex data
      *(stbvox_mesh_face *) (vertices[0]+1) = face;
      *(stbvox_mesh_face *) (vertices[1]+1) = face;
      *(stbvox_mesh_face *) (vertices[2]+1) = face;
      *(stbvox_mesh_face *) (vertices[3]+1) = face;
   #else
      *(stbvox_mesh_face *) mm->output_cur[mesh][1] = face;
      mm->output_cur[mesh][1] += 4;
   #endif
}

void stbvox_make_mesh_for_face(stbvox_mesh_maker *mm, stbvox_rotate rot, int face, int v_off, stbvox_pos pos, stbvox_mesh_vertex vertbase, stbvox_mesh_vertex *face_coord, unsigned char mesh, int normal)
{
   stbvox_mesh_face face_data = stbvox_compute_mesh_face_value(mm,rot,face,v_off, normal);

   // still need to compute ao & texlerp for each vertex

   // first compute texlerp into p1
   stbvox_mesh_vertex p1[4] = { 0 };

   #if defined(STBVOX_CONFIG_DOWN_TEXLERP_PACKED) && defined(STBVOX_CONFIG_UP_TEXLERP_PACKED)
      #define STBVOX_USE_PACKED(f) ((f) == STBVOX_FACE_up || (f) == STBVOX_FACE_down)
   #elif defined(STBVOX_CONFIG_UP_TEXLERP_PACKED)
      #define STBVOX_USE_PACKED(f) ((f) == STBVOX_FACE_up                           )
   #elif defined(STBVOX_CONFIG_DOWN_TEXLERP_PACKED)
      #define STBVOX_USE_PACKED(f) (                         (f) == STBVOX_FACE_down)
   #endif

   #if defined(STBVOX_CONFIG_DOWN_TEXLERP_PACKED) || defined(STBVOX_CONFIG_UP_TEXLERP_PACKED)
   if (STBVOX_USE_PACKED(face)) {
      if (!mm->input.packed_compact || 0==(mm->input.packed_compact[v_off]&16))
         goto set_default;
      p1[0] = (mm->input.packed_compact[v_off + mm->cube_vertex_offset[face][0]] >> 5);
      p1[1] = (mm->input.packed_compact[v_off + mm->cube_vertex_offset[face][1]] >> 5);
      p1[2] = (mm->input.packed_compact[v_off + mm->cube_vertex_offset[face][2]] >> 5);
      p1[3] = (mm->input.packed_compact[v_off + mm->cube_vertex_offset[face][3]] >> 5);
      p1[0] = stbvox_vertex_encode(0,0,0,0,p1[0]);
      p1[1] = stbvox_vertex_encode(0,0,0,0,p1[1]);
      p1[2] = stbvox_vertex_encode(0,0,0,0,p1[2]);
      p1[3] = stbvox_vertex_encode(0,0,0,0,p1[3]);
      goto skip;
   }
   #endif

   if (mm->input.block_texlerp) {
      stbvox_block_type bt = mm->input.blocktype[v_off];
      unsigned char val = mm->input.block_texlerp[bt];
      p1[0] = p1[1] = p1[2] = p1[3] = stbvox_vertex_encode(0,0,0,0,val);
   } else if (mm->input.block_texlerp_face) {
      stbvox_block_type bt = mm->input.blocktype[v_off];
      unsigned char bt_face = STBVOX_ROTATE(face, rot.block);
      unsigned char val = mm->input.block_texlerp_face[bt][bt_face];
      p1[0] = p1[1] = p1[2] = p1[3] = stbvox_vertex_encode(0,0,0,0,val);
   } else if (mm->input.texlerp_face3) {
      unsigned char val = (mm->input.texlerp_face3[v_off] >> stbvox_face3_lerp[face]) & 7;
      if (face >= STBVOX_FACE_up)
         val = stbvox_face3_updown[val];
      p1[0] = p1[1] = p1[2] = p1[3] = stbvox_vertex_encode(0,0,0,0,val);
   } else if (mm->input.texlerp_simple) {
      unsigned char val = mm->input.texlerp_simple[v_off];
      unsigned char lerp_face = (val >> 2) & 7;
      if (lerp_face == face) {
         p1[0] = (mm->input.texlerp_simple[v_off + mm->cube_vertex_offset[face][0]] >> 5) & 7;
         p1[1] = (mm->input.texlerp_simple[v_off + mm->cube_vertex_offset[face][1]] >> 5) & 7;
         p1[2] = (mm->input.texlerp_simple[v_off + mm->cube_vertex_offset[face][2]] >> 5) & 7;
         p1[3] = (mm->input.texlerp_simple[v_off + mm->cube_vertex_offset[face][3]] >> 5) & 7;
         p1[0] = stbvox_vertex_encode(0,0,0,0,p1[0]);
         p1[1] = stbvox_vertex_encode(0,0,0,0,p1[1]);
         p1[2] = stbvox_vertex_encode(0,0,0,0,p1[2]);
         p1[3] = stbvox_vertex_encode(0,0,0,0,p1[3]);
      } else {
         unsigned char base = stbvox_vert_lerp_for_simple[val&3];
         p1[0] = p1[1] = p1[2] = p1[3] = stbvox_vertex_encode(0,0,0,0,base);
      }
   } else if (mm->input.texlerp) {
      unsigned char facelerp = (mm->input.texlerp[v_off] >> stbvox_face_lerp[face]) & 3;
      if (facelerp == STBVOX_TEXLERP_FACE_use_vert) {
         if (mm->input.texlerp_vert3 && face != STBVOX_FACE_down) {
            unsigned char shift = stbvox_vert3_lerp[face];
            p1[0] = (mm->input.texlerp_vert3[mm->cube_vertex_offset[face][0]] >> shift) & 7;
            p1[1] = (mm->input.texlerp_vert3[mm->cube_vertex_offset[face][1]] >> shift) & 7;
            p1[2] = (mm->input.texlerp_vert3[mm->cube_vertex_offset[face][2]] >> shift) & 7;
            p1[3] = (mm->input.texlerp_vert3[mm->cube_vertex_offset[face][3]] >> shift) & 7;
         } else {
            p1[0] = stbvox_vert_lerp_for_simple[mm->input.texlerp[mm->cube_vertex_offset[face][0]]>>6];
            p1[1] = stbvox_vert_lerp_for_simple[mm->input.texlerp[mm->cube_vertex_offset[face][1]]>>6];
            p1[2] = stbvox_vert_lerp_for_simple[mm->input.texlerp[mm->cube_vertex_offset[face][2]]>>6];
            p1[3] = stbvox_vert_lerp_for_simple[mm->input.texlerp[mm->cube_vertex_offset[face][3]]>>6];
         }
         p1[0] = stbvox_vertex_encode(0,0,0,0,p1[0]);
         p1[1] = stbvox_vertex_encode(0,0,0,0,p1[1]);
         p1[2] = stbvox_vertex_encode(0,0,0,0,p1[2]);
         p1[3] = stbvox_vertex_encode(0,0,0,0,p1[3]);
      } else {
         p1[0] = p1[1] = p1[2] = p1[3] = stbvox_vertex_encode(0,0,0,0,stbvox_vert_lerp_for_face_lerp[facelerp]);
      }
   } else {
      #if defined(STBVOX_CONFIG_UP_TEXLERP_PACKED) || defined(STBVOX_CONFIG_DOWN_TEXLERP_PACKED)
      set_default:
      #endif
      p1[0] = p1[1] = p1[2] = p1[3] = stbvox_vertex_encode(0,0,0,0,7); // @TODO make this configurable
   }

   #if defined(STBVOX_CONFIG_UP_TEXLERP_PACKED) || defined(STBVOX_CONFIG_DOWN_TEXLERP_PACKED)
   skip:
   #endif

   // now compute lighting and store to vertices
   {
      stbvox_mesh_vertex *mv[4];
      stbvox_get_quad_vertex_pointer(mm, mesh, mv, face_data);

      if (mm->input.lighting) {
         // @TODO: lighting at block centers, but not gathered, instead constant-per-face
         if (mm->input.lighting_at_vertices) {
            int i;
            for (i=0; i < 4; ++i) {
               *mv[i] = vertbase + face_coord[i]
                          + stbvox_vertex_encode(0,0,0,mm->input.lighting[v_off + mm->cube_vertex_offset[face][i]] & 63,0)
                          + p1[i];
            }
         } else {
            unsigned char *amb = &mm->input.lighting[v_off];
            int i,j;
            #if defined(STBVOX_CONFIG_ROTATION_IN_LIGHTING) || defined(STBVOX_CONFIG_VHEIGHT_IN_LIGHTING)
            #define STBVOX_GET_LIGHTING(light) ((light) & ~3)
            #define STBVOX_LIGHTING_ROUNDOFF   8
            #else
            #define STBVOX_GET_LIGHTING(light) (light)
            #define STBVOX_LIGHTING_ROUNDOFF   2
            #endif

            for (i=0; i < 4; ++i) {
               // for each vertex, gather from the four neighbor blocks it's facing
               unsigned char *vamb = &amb[mm->cube_vertex_offset[face][i]];
               int total=0;
               for (j=0; j < 4; ++j)
                  total += STBVOX_GET_LIGHTING(vamb[mm->vertex_gather_offset[face][j]]);
               *mv[i] = vertbase + face_coord[i]
                          + stbvox_vertex_encode(0,0,0,(total+STBVOX_LIGHTING_ROUNDOFF)>>4,0)
                          + p1[i];
                          // >> 4 is because:
                          //   >> 2 to divide by 4 to get average over 4 samples
                          //   >> 2 because input is 8 bits, output is 6 bits
            }

            // @TODO: note that gathering baked *lighting*
            // is different from gathering baked ao; baked ao can count
            // solid blocks as 0 ao, but baked lighting wants average
            // of non-blocked--not take average & treat blocked as 0. And
            // we can't bake the right value into the solid blocks
            // because they can have different lighting values on
            // different sides. So we need to actually gather and
            // then divide by 0..4 (which we can do with a table-driven
            // multiply, or have an 'if' for the 3 case)

         }
      } else {
         vertbase += stbvox_vertex_encode(0,0,0,63,0);
         *mv[0] = vertbase + face_coord[0] + p1[0];
         *mv[1] = vertbase + face_coord[1] + p1[1];
         *mv[2] = vertbase + face_coord[2] + p1[2];
         *mv[3] = vertbase + face_coord[3] + p1[3];
      }
   }
}

// get opposite-facing normal & texgen for opposite face, used to map up-facing vheight data to down-facing data
static unsigned char stbvox_reverse_face[STBVF_count] =
{
   STBVF_w, STBVF_s, STBVF_e, STBVF_n, STBVF_d   , STBVF_u   , STBVF_wd, STBVF_wu,
         0,       0,       0,       0, STBVF_sw_d, STBVF_sw_u, STBVF_sd, STBVF_su,
         0,       0,       0,       0, STBVF_se_d, STBVF_se_u, STBVF_ed, STBVF_eu,
         0,       0,       0,       0, STBVF_ne_d, STBVF_ne_d, STBVF_nd, STBVF_nu
};

#ifndef STBVOX_CONFIG_OPTIMIZED_VHEIGHT
// render non-planar quads by splitting into two triangles, rendering each as a degenerate quad
static void stbvox_make_12_split_mesh_for_face(stbvox_mesh_maker *mm, stbvox_rotate rot, int face, int v_off, stbvox_pos pos, stbvox_mesh_vertex vertbase, stbvox_mesh_vertex *face_coord, unsigned char mesh, unsigned char *ht)
{
   stbvox_mesh_vertex v[4];

   unsigned char normal1 = stbvox_face_up_normal_012[ht[2]][ht[1]][ht[0]];
   unsigned char normal2 = stbvox_face_up_normal_123[ht[3]][ht[2]][ht[1]];

   if (face == STBVOX_FACE_down) {
      normal1 = stbvox_reverse_face[normal1];
      normal2 = stbvox_reverse_face[normal2];
   }

   // the floor side face_coord is stored in order NW,NE,SE,SW, but ht[] is stored SW,SE,NW,NE
   v[0] = face_coord[2];
   v[1] = face_coord[3];
   v[2] = face_coord[0];
   v[3] = face_coord[2];
   stbvox_make_mesh_for_face(mm, rot, face, v_off, pos, vertbase, v, mesh, normal1);
   v[1] = face_coord[0];
   v[2] = face_coord[1];
   stbvox_make_mesh_for_face(mm, rot, face, v_off, pos, vertbase, v, mesh, normal2);
}

static void stbvox_make_03_split_mesh_for_face(stbvox_mesh_maker *mm, stbvox_rotate rot, int face, int v_off, stbvox_pos pos, stbvox_mesh_vertex vertbase, stbvox_mesh_vertex *face_coord, unsigned char mesh, unsigned char *ht)
{
   stbvox_mesh_vertex v[4];

   unsigned char normal1 = stbvox_face_up_normal_013[ht[3]][ht[1]][ht[0]];
   unsigned char normal2 = stbvox_face_up_normal_023[ht[3]][ht[2]][ht[0]];

   if (face == STBVOX_FACE_down) {
      normal1 = stbvox_reverse_face[normal1];
      normal2 = stbvox_reverse_face[normal2];
   }

   v[0] = face_coord[1];
   v[1] = face_coord[2];
   v[2] = face_coord[3];
   v[3] = face_coord[1];
   stbvox_make_mesh_for_face(mm, rot, face, v_off, pos, vertbase, v, mesh, normal1);
   v[1] = face_coord[3];
   v[2] = face_coord[0];
   stbvox_make_mesh_for_face(mm, rot, face, v_off, pos, vertbase, v, mesh, normal2);  // this one is correct!
}
#endif

#ifndef STBVOX_CONFIG_PRECISION_Z
#define STBVOX_CONFIG_PRECISION_Z 1
#endif

// simple case for mesh generation: we have only solid and empty blocks
static void stbvox_make_mesh_for_block(stbvox_mesh_maker *mm, stbvox_pos pos, int v_off, stbvox_mesh_vertex *vmesh)
{
   int ns_off = mm->y_stride_in_bytes;
   int ew_off = mm->x_stride_in_bytes;

   unsigned char *blockptr = &mm->input.blocktype[v_off];
   stbvox_mesh_vertex basevert = stbvox_vertex_encode(pos.x, pos.y, pos.z << STBVOX_CONFIG_PRECISION_Z , 0,0);

   stbvox_rotate rot = { 0,0,0,0 };
   unsigned char simple_rot = 0;

   unsigned char mesh = mm->default_mesh;

   if (mm->input.selector)
      mesh = mm->input.selector[v_off];

   // check if we're going off the end
   if (mm->output_cur[mesh][0] + mm->output_size[mesh][0]*6 > mm->output_end[mesh][0]) {
      mm->full = 1;
      return;
   }

   #ifdef STBVOX_CONFIG_ROTATION_IN_LIGHTING
   simple_rot = mm->input.lighting[v_off] & 3;
   #endif

   if (mm->input.packed_compact)
      simple_rot = mm->input.packed_compact[v_off] & 3;

   if (blockptr[ 1]==0) {
      rot.facerot = simple_rot;
      stbvox_make_mesh_for_face(mm, rot, STBVOX_FACE_up  , v_off, pos, basevert, vmesh+4*STBVOX_FACE_up, mesh, STBVOX_FACE_up);
   }
   if (blockptr[-1]==0) {
      rot.facerot = (-simple_rot) & 3;
      stbvox_make_mesh_for_face(mm, rot, STBVOX_FACE_down, v_off, pos, basevert, vmesh+4*STBVOX_FACE_down, mesh, STBVOX_FACE_down);
   }

   if (mm->input.rotate) {
      unsigned char val = mm->input.rotate[v_off];
      rot.block   = (val >> 0) & 3;
      rot.overlay = (val >> 2) & 3;
      //rot.tex2    = (val >> 4) & 3;
      rot.ecolor  = (val >> 6) & 3;
   } else {
      rot.block = rot.overlay = rot.ecolor = simple_rot;
   }
   rot.facerot = 0;

   if (blockptr[ ns_off]==0)
      stbvox_make_mesh_for_face(mm, rot, STBVOX_FACE_north, v_off, pos, basevert, vmesh+4*STBVOX_FACE_north, mesh, STBVOX_FACE_north);
   if (blockptr[-ns_off]==0)
      stbvox_make_mesh_for_face(mm, rot, STBVOX_FACE_south, v_off, pos, basevert, vmesh+4*STBVOX_FACE_south, mesh, STBVOX_FACE_south);
   if (blockptr[ ew_off]==0)
      stbvox_make_mesh_for_face(mm, rot, STBVOX_FACE_east , v_off, pos, basevert, vmesh+4*STBVOX_FACE_east, mesh, STBVOX_FACE_east);
   if (blockptr[-ew_off]==0)
      stbvox_make_mesh_for_face(mm, rot, STBVOX_FACE_west , v_off, pos, basevert, vmesh+4*STBVOX_FACE_west, mesh, STBVOX_FACE_west);
}

// complex case for mesh generation: we have lots of different
// block types, and we don't want to generate faces of blocks
// if they're hidden by neighbors.
//
// we use lots of tables to determine this: we have a table
// which tells us what face type is generated for each type of
// geometry, and then a table that tells us whether that type
// is hidden by a neighbor.
static void stbvox_make_mesh_for_block_with_geo(stbvox_mesh_maker *mm, stbvox_pos pos, int v_off)
{
   int ns_off = mm->y_stride_in_bytes;
   int ew_off = mm->x_stride_in_bytes;
   int visible_faces, visible_base;
   unsigned char mesh;

   // first gather the geometry info for this block and all neighbors

   unsigned char bt, nbt[6];
   unsigned char geo, ngeo[6];
   unsigned char rot, nrot[6];

   bt = mm->input.blocktype[v_off];
   nbt[0] = mm->input.blocktype[v_off + ew_off];
   nbt[1] = mm->input.blocktype[v_off + ns_off];
   nbt[2] = mm->input.blocktype[v_off - ew_off];
   nbt[3] = mm->input.blocktype[v_off - ns_off];
   nbt[4] = mm->input.blocktype[v_off +      1];
   nbt[5] = mm->input.blocktype[v_off -      1];
   if (mm->input.geometry) {
      int i;
      geo = mm->input.geometry[v_off];
      ngeo[0] = mm->input.geometry[v_off + ew_off];
      ngeo[1] = mm->input.geometry[v_off + ns_off];
      ngeo[2] = mm->input.geometry[v_off - ew_off];
      ngeo[3] = mm->input.geometry[v_off - ns_off];
      ngeo[4] = mm->input.geometry[v_off +      1];
      ngeo[5] = mm->input.geometry[v_off -      1];

      rot = (geo >> 4) & 3;
      geo &= 15;
      for (i=0; i < 6; ++i) {
         nrot[i] = (ngeo[i] >> 4) & 3;
         ngeo[i] &= 15;
      }
   } else {
      int i;
      assert(mm->input.block_geometry);
      geo = mm->input.block_geometry[bt];
      for (i=0; i < 6; ++i)
         ngeo[i] = mm->input.block_geometry[nbt[i]];
      if (mm->input.selector) {
         #ifndef STBVOX_CONFIG_ROTATION_IN_LIGHTING
         if (mm->input.packed_compact == NULL) {
            rot     = (mm->input.selector[v_off         ] >> 4) & 3;
            nrot[0] = (mm->input.selector[v_off + ew_off] >> 4) & 3;
            nrot[1] = (mm->input.selector[v_off + ns_off] >> 4) & 3;
            nrot[2] = (mm->input.selector[v_off - ew_off] >> 4) & 3;
            nrot[3] = (mm->input.selector[v_off - ns_off] >> 4) & 3;
            nrot[4] = (mm->input.selector[v_off +      1] >> 4) & 3;
            nrot[5] = (mm->input.selector[v_off -      1] >> 4) & 3;
         }
         #endif
      } else {
         #ifndef STBVOX_CONFIG_ROTATION_IN_LIGHTING
         if (mm->input.packed_compact == NULL) {
            rot = (geo>>4)&3;
            geo &= 15;
            for (i=0; i < 6; ++i) {
               nrot[i] = (ngeo[i]>>4)&3;
               ngeo[i] &= 15;
            }
         }
         #endif
      }
   }

   #ifndef STBVOX_CONFIG_ROTATION_IN_LIGHTING
   if (mm->input.packed_compact) {
      rot = mm->input.packed_compact[rot] & 3;
      nrot[0] = mm->input.packed_compact[v_off + ew_off] & 3;
      nrot[1] = mm->input.packed_compact[v_off + ns_off] & 3;
      nrot[2] = mm->input.packed_compact[v_off - ew_off] & 3;
      nrot[3] = mm->input.packed_compact[v_off - ns_off] & 3;
      nrot[4] = mm->input.packed_compact[v_off +      1] & 3;
      nrot[5] = mm->input.packed_compact[v_off -      1] & 3;
   }
   #else
   rot = mm->input.lighting[v_off] & 3;
   nrot[0] = (mm->input.lighting[v_off + ew_off]) & 3;
   nrot[1] = (mm->input.lighting[v_off + ns_off]) & 3;
   nrot[2] = (mm->input.lighting[v_off - ew_off]) & 3;
   nrot[3] = (mm->input.lighting[v_off - ns_off]) & 3;
   nrot[4] = (mm->input.lighting[v_off +      1]) & 3;
   nrot[5] = (mm->input.lighting[v_off -      1]) & 3;
   #endif

   if (geo == STBVOX_GEOM_transp) {
      // transparency has a special rule: if the blocktype is the same,
      // and the faces are compatible, then can hide them; otherwise,
      // force them on
      // Note that this means we don't support any transparentshapes other
      // than solid blocks, since detecting them is too complicated. If
      // you wanted to do something like minecraft water, you probably
      // should just do that with a separate renderer anyway. (We don't
      // support transparency sorting so you need to use alpha test
      // anyway)
      int i;
      for (i=0; i < 6; ++i)
         if (nbt[i] != bt) {
            nbt[i] = 0;
            ngeo[i] = STBVOX_GEOM_empty;
         } else
            ngeo[i] = STBVOX_GEOM_solid;
      geo = STBVOX_GEOM_solid;
   }

   // now compute the face visibility
   visible_base = stbvox_hasface[geo][rot];
   // @TODO: assert(visible_base != 0); // we should have early-outted earlier in this case
   visible_faces = 0;

   // now, for every face that might be visible, check if neighbor hides it
   if (visible_base & (1 << STBVOX_FACE_east)) {
      int  type = stbvox_facetype[ geo   ][(STBVOX_FACE_east+ rot   )&3];
      int ntype = stbvox_facetype[ngeo[0]][(STBVOX_FACE_west+nrot[0])&3];
      visible_faces |= ((stbvox_face_visible[type]) >> (ntype + 5 - STBVOX_FACE_east)) & (1 << STBVOX_FACE_east);
   }
   if (visible_base & (1 << STBVOX_FACE_north)) {
      int  type = stbvox_facetype[ geo   ][(STBVOX_FACE_north+ rot   )&3];
      int ntype = stbvox_facetype[ngeo[1]][(STBVOX_FACE_south+nrot[1])&3];
      visible_faces |= ((stbvox_face_visible[type]) >> (ntype + 5 - STBVOX_FACE_north)) & (1 << STBVOX_FACE_north);
   }
   if (visible_base & (1 << STBVOX_FACE_west)) {
      int  type = stbvox_facetype[ geo   ][(STBVOX_FACE_west+ rot   )&3];
      int ntype = stbvox_facetype[ngeo[2]][(STBVOX_FACE_east+nrot[2])&3];
      visible_faces |= ((stbvox_face_visible[type]) >> (ntype + 5 - STBVOX_FACE_west)) & (1 << STBVOX_FACE_west);
   }
   if (visible_base & (1 << STBVOX_FACE_south)) {
      int  type = stbvox_facetype[ geo   ][(STBVOX_FACE_south+ rot   )&3];
      int ntype = stbvox_facetype[ngeo[3]][(STBVOX_FACE_north+nrot[3])&3];
      visible_faces |= ((stbvox_face_visible[type]) >> (ntype + 5 - STBVOX_FACE_south)) & (1 << STBVOX_FACE_south);
   }
   if (visible_base & (1 << STBVOX_FACE_up)) {
      int  type = stbvox_facetype[ geo   ][STBVOX_FACE_up];
      int ntype = stbvox_facetype[ngeo[4]][STBVOX_FACE_down];
      visible_faces |= ((stbvox_face_visible[type]) >> (ntype + 5 - STBVOX_FACE_up)) & (1 << STBVOX_FACE_up);
   }
   if (visible_base & (1 << STBVOX_FACE_down)) {
      int  type = stbvox_facetype[ geo   ][STBVOX_FACE_down];
      int ntype = stbvox_facetype[ngeo[5]][STBVOX_FACE_up];
      visible_faces |= ((stbvox_face_visible[type]) >> (ntype + 5 - STBVOX_FACE_down)) & (1 << STBVOX_FACE_down);
   }

   if (geo == STBVOX_GEOM_force)
      geo = STBVOX_GEOM_solid;

   assert((geo == STBVOX_GEOM_crossed_pair) ? (visible_faces == 15) : 1);

   // now we finally know for sure which faces are getting generated
   if (visible_faces == 0)
      return;

   mesh = mm->default_mesh;
   if (mm->input.selector)
      mesh = mm->input.selector[v_off];

   if (geo <= STBVOX_GEOM_ceil_slope_north_is_bottom) {
      // this is the simple case, we can just use regular block gen with special vmesh calculated with vheight
      stbvox_mesh_vertex basevert;
      stbvox_mesh_vertex vmesh[6][4];
      stbvox_rotate rotate = { 0,0,0,0 };
      unsigned char simple_rot = rot;
      int i;
      // we only need to do this for the displayed faces, but it's easier
      // to just do it up front; @OPTIMIZE check if it's faster to do it
      // for visible faces only
      for (i=0; i < 6*4; ++i) {
         int vert = stbvox_vertex_selector[0][i];
         vert = stbvox_rotate_vertex[vert][rot];
         vmesh[0][i] = stbvox_vmesh_pre_vheight[0][i]
                     + stbvox_geometry_vheight[geo][vert];
      }

      basevert = stbvox_vertex_encode(pos.x, pos.y, pos.z << STBVOX_CONFIG_PRECISION_Z, 0,0);
      if (mm->input.selector) {
         mesh = mm->input.selector[v_off];
      }

      // check if we're going off the end
      if (mm->output_cur[mesh][0] + mm->output_size[mesh][0]*6 > mm->output_end[mesh][0]) {
         mm->full = 1;
         return;
      }

      if (geo >= STBVOX_GEOM_floor_slope_north_is_top) {
         if (visible_faces & (1 << STBVOX_FACE_up)) {
            int normal = geo == STBVOX_GEOM_floor_slope_north_is_top ? stbvox_floor_slope_for_rot[simple_rot] : STBVOX_FACE_up;
            rotate.facerot = simple_rot;
            stbvox_make_mesh_for_face(mm, rotate, STBVOX_FACE_up  , v_off, pos, basevert, vmesh[STBVOX_FACE_up], mesh, normal);
         }
         if (visible_faces & (1 << STBVOX_FACE_down)) {
            int normal = geo == STBVOX_GEOM_ceil_slope_north_is_bottom ? stbvox_ceil_slope_for_rot[simple_rot] : STBVOX_FACE_down;
            rotate.facerot = (-rotate.facerot) & 3;
            stbvox_make_mesh_for_face(mm, rotate, STBVOX_FACE_down, v_off, pos, basevert, vmesh[STBVOX_FACE_down], mesh, normal);
         }
      } else {
         if (visible_faces & (1 << STBVOX_FACE_up)) {
            rotate.facerot = simple_rot;
            stbvox_make_mesh_for_face(mm, rotate, STBVOX_FACE_up  , v_off, pos, basevert, vmesh[STBVOX_FACE_up], mesh, STBVOX_FACE_up);
         }
         if (visible_faces & (1 << STBVOX_FACE_down)) {
            rotate.facerot = (-rotate.facerot) & 3;
            stbvox_make_mesh_for_face(mm, rotate, STBVOX_FACE_down, v_off, pos, basevert, vmesh[STBVOX_FACE_down], mesh, STBVOX_FACE_down);
         }
      }

      if (mm->input.rotate) {
         unsigned char val = mm->input.rotate[v_off];
         rotate.block   = (val >> 0) & 3;
         rotate.overlay = (val >> 2) & 3;
         //rotate.tex2    = (val >> 4) & 3;
         rotate.ecolor  = (val >> 6) & 3;
      } else {
         rotate.block = rotate.overlay = rotate.ecolor = simple_rot;
      }

      rotate.facerot = 0;

      if (visible_faces & (1 << STBVOX_FACE_north))
         stbvox_make_mesh_for_face(mm, rotate, STBVOX_FACE_north, v_off, pos, basevert, vmesh[STBVOX_FACE_north], mesh, STBVOX_FACE_north);
      if (visible_faces & (1 << STBVOX_FACE_south))
         stbvox_make_mesh_for_face(mm, rotate, STBVOX_FACE_south, v_off, pos, basevert, vmesh[STBVOX_FACE_south], mesh, STBVOX_FACE_south);
      if (visible_faces & (1 << STBVOX_FACE_east))
         stbvox_make_mesh_for_face(mm, rotate, STBVOX_FACE_east , v_off, pos, basevert, vmesh[STBVOX_FACE_east ], mesh, STBVOX_FACE_east);
      if (visible_faces & (1 << STBVOX_FACE_west))
         stbvox_make_mesh_for_face(mm, rotate, STBVOX_FACE_west , v_off, pos, basevert, vmesh[STBVOX_FACE_west ], mesh, STBVOX_FACE_west);
   }
   if (geo >= STBVOX_GEOM_floor_vheight_03) {
      // this case can also be generated with regular block gen with special vmesh,
      // except:
      //     if we want to generate middle diagonal for 'weird' blocks
      //     it's more complicated to detect neighbor matchups
      stbvox_mesh_vertex vmesh[6][4];
      stbvox_mesh_vertex cube[8];
      stbvox_mesh_vertex basevert;
      stbvox_rotate rotate = { 0,0,0,0 };
      unsigned char simple_rot = rot;
      unsigned char ht[4];
      int extreme;

      // extract the heights
      #ifdef STBVOX_CONFIG_VHEIGHT_IN_LIGHTING
      ht[0] = mm->input.lighting[v_off              ] & 3;
      ht[1] = mm->input.lighting[v_off+ew_off       ] & 3;
      ht[2] = mm->input.lighting[v_off       +ns_off] & 3;
      ht[3] = mm->input.lighting[v_off+ew_off+ns_off] & 3;
      #else
      if (mm->input.vheight) {
         unsigned char v =  mm->input.vheight[v_off];
         ht[0] = (v >> 0) & 3;
         ht[1] = (v >> 2) & 3;
         ht[2] = (v >> 4) & 3;
         ht[3] = (v >> 6) & 3;
      } else if (mm->input.block_vheight) {
         unsigned char v = mm->input.block_vheight[bt];
         unsigned char raw[4];
         int i;

         raw[0] = (v >> 0) & 3;
         raw[1] = (v >> 2) & 3;
         raw[2] = (v >> 4) & 3;
         raw[3] = (v >> 6) & 3;

         for (i=0; i < 4; ++i)
            ht[i] = raw[stbvox_rotate_vertex[i][rot]];
      } else if (mm->input.packed_compact) {
         ht[0] = (mm->input.packed_compact[v_off              ] >> 2) & 3;
         ht[1] = (mm->input.packed_compact[v_off+ew_off       ] >> 2) & 3;
         ht[2] = (mm->input.packed_compact[v_off       +ns_off] >> 2) & 3;
         ht[3] = (mm->input.packed_compact[v_off+ew_off+ns_off] >> 2) & 3;
      } else if (mm->input.geometry) {
         ht[0] = mm->input.geometry[v_off              ] >> 6;
         ht[1] = mm->input.geometry[v_off+ew_off       ] >> 6;
         ht[2] = mm->input.geometry[v_off       +ns_off] >> 6;
         ht[3] = mm->input.geometry[v_off+ew_off+ns_off] >> 6;
      } else {
         assert(0);
      }
      #endif

      // flag whether any sides go off the top of the block, which means
      // our visible_faces test was wrong
      extreme = (ht[0] == 3 || ht[1] == 3 || ht[2] == 3 || ht[3] == 3);

      if (geo >= STBVOX_GEOM_ceil_vheight_03) {
         cube[0] = stbvox_vertex_encode(0,0,ht[0],0,0);
         cube[1] = stbvox_vertex_encode(0,0,ht[1],0,0);
         cube[2] = stbvox_vertex_encode(0,0,ht[2],0,0);
         cube[3] = stbvox_vertex_encode(0,0,ht[3],0,0);
         cube[4] = stbvox_vertex_encode(0,0,2,0,0);
         cube[5] = stbvox_vertex_encode(0,0,2,0,0);
         cube[6] = stbvox_vertex_encode(0,0,2,0,0);
         cube[7] = stbvox_vertex_encode(0,0,2,0,0);
      } else {
         cube[0] = stbvox_vertex_encode(0,0,0,0,0);
         cube[1] = stbvox_vertex_encode(0,0,0,0,0);
         cube[2] = stbvox_vertex_encode(0,0,0,0,0);
         cube[3] = stbvox_vertex_encode(0,0,0,0,0);
         cube[4] = stbvox_vertex_encode(0,0,ht[0],0,0);
         cube[5] = stbvox_vertex_encode(0,0,ht[1],0,0);
         cube[6] = stbvox_vertex_encode(0,0,ht[2],0,0);
         cube[7] = stbvox_vertex_encode(0,0,ht[3],0,0);
      }
      if (!mm->input.vheight && mm->input.block_vheight) {
         // @TODO: support block vheight here, I've forgotten what needs to be done specially
      }

      // build vertex mesh
      {
         int i;
         for (i=0; i < 6*4; ++i) {
            int vert = stbvox_vertex_selector[0][i];
            vmesh[0][i] = stbvox_vmesh_pre_vheight[0][i]
                        + cube[vert];
         }
      }

      basevert = stbvox_vertex_encode(pos.x, pos.y, pos.z << STBVOX_CONFIG_PRECISION_Z, 0,0);
      // check if we're going off the end
      if (mm->output_cur[mesh][0] + mm->output_size[mesh][0]*6 > mm->output_end[mesh][0]) {
         mm->full = 1;
         return;
      }

      // @TODO generate split faces
      if (visible_faces & (1 << STBVOX_FACE_up)) {
         if (geo >= STBVOX_GEOM_ceil_vheight_03)
            // flat
            stbvox_make_mesh_for_face(mm, rotate, STBVOX_FACE_up  , v_off, pos, basevert, vmesh[STBVOX_FACE_up], mesh, STBVOX_FACE_up);
         else {
         #ifndef STBVOX_CONFIG_OPTIMIZED_VHEIGHT
            // check if it's non-planar
            if (cube[5] + cube[6] != cube[4] + cube[7]) {
               // not planar, split along diagonal and make degenerate quads
               if (geo == STBVOX_GEOM_floor_vheight_03)
                  stbvox_make_03_split_mesh_for_face(mm, rotate, STBVOX_FACE_up, v_off, pos, basevert, vmesh[STBVOX_FACE_up], mesh, ht);
               else
                  stbvox_make_12_split_mesh_for_face(mm, rotate, STBVOX_FACE_up, v_off, pos, basevert, vmesh[STBVOX_FACE_up], mesh, ht);
            } else
               stbvox_make_mesh_for_face(mm, rotate, STBVOX_FACE_up  , v_off, pos, basevert, vmesh[STBVOX_FACE_up], mesh, stbvox_planar_face_up_normal[ht[2]][ht[1]][ht[0]]);
         #else
            stbvox_make_mesh_for_face(mm, rotate, STBVOX_FACE_up  , v_off, pos, basevert, vmesh[STBVOX_FACE_up], mesh, stbvox_optimized_face_up_normal[ht[3]][ht[2]][ht[1]][ht[0]]);
         #endif
         }
      }
      if (visible_faces & (1 << STBVOX_FACE_down)) {
         if (geo < STBVOX_GEOM_ceil_vheight_03)
            // flat
            stbvox_make_mesh_for_face(mm, rotate, STBVOX_FACE_down, v_off, pos, basevert, vmesh[STBVOX_FACE_down], mesh, STBVOX_FACE_down);
         else {
         #ifndef STBVOX_CONFIG_OPTIMIZED_VHEIGHT
            // check if it's non-planar
            if (cube[1] + cube[2] != cube[0] + cube[3]) {
               // not planar, split along diagonal and make degenerate quads
               if (geo == STBVOX_GEOM_ceil_vheight_03)
                  stbvox_make_03_split_mesh_for_face(mm, rotate, STBVOX_FACE_down, v_off, pos, basevert, vmesh[STBVOX_FACE_down], mesh, ht);
               else
                  stbvox_make_12_split_mesh_for_face(mm, rotate, STBVOX_FACE_down, v_off, pos, basevert, vmesh[STBVOX_FACE_down], mesh, ht);
            } else
               stbvox_make_mesh_for_face(mm, rotate, STBVOX_FACE_down, v_off, pos, basevert, vmesh[STBVOX_FACE_down], mesh, stbvox_reverse_face[stbvox_planar_face_up_normal[ht[2]][ht[1]][ht[0]]]);
         #else
            stbvox_make_mesh_for_face(mm, rotate, STBVOX_FACE_down, v_off, pos, basevert, vmesh[STBVOX_FACE_down], mesh, stbvox_reverse_face[stbvox_optimized_face_up_normal[ht[3]][ht[2]][ht[1]][ht[0]]]);
         #endif
         }
      }

      if (mm->input.rotate) {
         unsigned char val = mm->input.rotate[v_off];
         rotate.block   = (val >> 0) & 3;
         rotate.overlay = (val >> 2) & 3;
         //rotate.tex2    = (val >> 4) & 3;
         rotate.ecolor  = (val >> 6) & 3;
      } else if (mm->input.selector) {
         rotate.block = rotate.overlay = rotate.ecolor = simple_rot;
      }

      if ((visible_faces & (1 << STBVOX_FACE_north)) || (extreme && (ht[2] == 3 || ht[3] == 3)))
         stbvox_make_mesh_for_face(mm, rotate, STBVOX_FACE_north, v_off, pos, basevert, vmesh[STBVOX_FACE_north], mesh, STBVOX_FACE_north);
      if ((visible_faces & (1 << STBVOX_FACE_south)) || (extreme && (ht[0] == 3 || ht[1] == 3))) 
         stbvox_make_mesh_for_face(mm, rotate, STBVOX_FACE_south, v_off, pos, basevert, vmesh[STBVOX_FACE_south], mesh, STBVOX_FACE_south);
      if ((visible_faces & (1 << STBVOX_FACE_east)) || (extreme && (ht[1] == 3 || ht[3] == 3)))
         stbvox_make_mesh_for_face(mm, rotate, STBVOX_FACE_east , v_off, pos, basevert, vmesh[STBVOX_FACE_east ], mesh, STBVOX_FACE_east);
      if ((visible_faces & (1 << STBVOX_FACE_west)) || (extreme && (ht[0] == 3 || ht[2] == 3)))
         stbvox_make_mesh_for_face(mm, rotate, STBVOX_FACE_west , v_off, pos, basevert, vmesh[STBVOX_FACE_west ], mesh, STBVOX_FACE_west);
   }

   if (geo == STBVOX_GEOM_crossed_pair) {
      // this can be generated with a special vmesh
      stbvox_mesh_vertex basevert = stbvox_vertex_encode(pos.x, pos.y, pos.z << STBVOX_CONFIG_PRECISION_Z , 0,0);
      unsigned char simple_rot=0;
      stbvox_rotate rot = { 0,0,0,0 };
      unsigned char mesh = mm->default_mesh;
      if (mm->input.selector) {
         mesh = mm->input.selector[v_off];
         simple_rot = mesh >> 4;
         mesh &= 15;
      }

      // check if we're going off the end
      if (mm->output_cur[mesh][0] + mm->output_size[mesh][0]*4 > mm->output_end[mesh][0]) {
         mm->full = 1;
         return;
      }

      if (mm->input.rotate) {
         unsigned char val = mm->input.rotate[v_off];
         rot.block   = (val >> 0) & 3;
         rot.overlay = (val >> 2) & 3;
         //rot.tex2    = (val >> 4) & 3;
         rot.ecolor  = (val >> 6) & 3;
      } else if (mm->input.selector) {
         rot.block = rot.overlay = rot.ecolor = simple_rot;
      }
      rot.facerot = 0;

      stbvox_make_mesh_for_face(mm, rot, STBVOX_FACE_north, v_off, pos, basevert, stbvox_vmesh_crossed_pair[STBVOX_FACE_north], mesh, STBVF_ne_u_cross);
      stbvox_make_mesh_for_face(mm, rot, STBVOX_FACE_south, v_off, pos, basevert, stbvox_vmesh_crossed_pair[STBVOX_FACE_south], mesh, STBVF_sw_u_cross);
      stbvox_make_mesh_for_face(mm, rot, STBVOX_FACE_east , v_off, pos, basevert, stbvox_vmesh_crossed_pair[STBVOX_FACE_east ], mesh, STBVF_se_u_cross);
      stbvox_make_mesh_for_face(mm, rot, STBVOX_FACE_west , v_off, pos, basevert, stbvox_vmesh_crossed_pair[STBVOX_FACE_west ], mesh, STBVF_nw_u_cross);
   }


   // @TODO
   // STBVOX_GEOM_floor_slope_north_is_top_as_wall,
   // STBVOX_GEOM_ceil_slope_north_is_bottom_as_wall,
}

static void stbvox_make_mesh_for_column(stbvox_mesh_maker *mm, int x, int y, int z0)
{
   stbvox_pos pos;
   int v_off = x * mm->x_stride_in_bytes + y * mm->y_stride_in_bytes;
   int ns_off = mm->y_stride_in_bytes;
   int ew_off = mm->x_stride_in_bytes;
   pos.x = x;
   pos.y = y;
   pos.z = 0;
   if (mm->input.geometry) {
      unsigned char *bt  = mm->input.blocktype + v_off;
      unsigned char *geo = mm->input.geometry + v_off;
      int z;
      for (z=z0; z < mm->z1; ++z) {
         if (bt[z] && ( !bt[z+ns_off] || !STBVOX_GET_GEO(geo[z+ns_off]) || !bt[z-ns_off] || !STBVOX_GET_GEO(geo[z-ns_off])
                      || !bt[z+ew_off] || !STBVOX_GET_GEO(geo[z+ew_off]) || !bt[z-ew_off] || !STBVOX_GET_GEO(geo[z-ew_off])
                      || !bt[z-1] || !STBVOX_GET_GEO(geo[z-1]) || !bt[z+1] || !STBVOX_GET_GEO(geo[z+1])))
         {  // TODO check up and down
            pos.z = z;
            stbvox_make_mesh_for_block_with_geo(mm, pos, v_off+z);
            if (mm->full) {
               mm->cur_z = z;
               return;
            }
         }
      }
   } else if (mm->input.block_geometry) {
      int z;
      unsigned char *bt  = mm->input.blocktype + v_off;
      unsigned char *geo = mm->input.block_geometry;
      for (z=z0; z < mm->z1; ++z) {
         if (bt[z] && (    geo[bt[z+ns_off]] != STBVOX_GEOM_solid
                        || geo[bt[z-ns_off]] != STBVOX_GEOM_solid
                        || geo[bt[z+ew_off]] != STBVOX_GEOM_solid
                        || geo[bt[z-ew_off]] != STBVOX_GEOM_solid
                        || geo[bt[z-1]] != STBVOX_GEOM_solid
                        || geo[bt[z+1]] != STBVOX_GEOM_solid))
         {
            pos.z = z;
            stbvox_make_mesh_for_block_with_geo(mm, pos, v_off+z);
            if (mm->full) {
               mm->cur_z = z;
               return;
            }
         }
      }
   } else {
      unsigned char *bt = mm->input.blocktype + v_off;
      int z;
      #if STBVOX_CONFIG_PRECISION_Z == 1
      stbvox_mesh_vertex *vmesh = stbvox_vmesh_delta_half_z[0];
      #else
      stbvox_mesh_vertex *vmesh = stbvox_vmesh_delta_normal[0];
      #endif
      for (z=z0; z < mm->z1; ++z) {
         // if it's solid and at least one neighbor isn't solid
         if (bt[z] && (!bt[z+ns_off] || !bt[z-ns_off] || !bt[z+ew_off] || !bt[z-ew_off] || !bt[z-1] || !bt[z+1])) {
            pos.z = z;
            stbvox_make_mesh_for_block(mm, pos, v_off+z, vmesh);
            if (mm->full) {
               mm->cur_z = z;
               return;
            }
         }
      }
   }
}

static void stbvox_bring_up_to_date(stbvox_mesh_maker *mm)
{
   if (mm->config_dirty) {
      int i;
      #ifdef STBVOX_ICONFIG_FACE_ATTRIBUTE
         mm->num_mesh_slots = 1;
         for (i=0; i < STBVOX_MAX_MESHES; ++i) {
            mm->output_size[i][0] = 32;
            mm->output_step[i][0] = 8;
         }
      #else
         mm->num_mesh_slots = 2;
         for (i=0; i < STBVOX_MAX_MESHES; ++i) {
            mm->output_size[i][0] = 16;
            mm->output_step[i][0] = 4;
            mm->output_size[i][1] = 4;
            mm->output_step[i][1] = 4;
         }
      #endif

      mm->config_dirty = 0;
   }
}

int stbvox_make_mesh(stbvox_mesh_maker *mm)
{
   int x,y;
   stbvox_bring_up_to_date(mm);
   mm->full = 0;
   if (mm->cur_x > mm->x0 || mm->cur_y > mm->y0 || mm->cur_z > mm->z0) {
      stbvox_make_mesh_for_column(mm, mm->cur_x, mm->cur_y, mm->cur_z);
      if (mm->full)
         return 0;
      ++mm->cur_y;
      while (mm->cur_y < mm->y1 && !mm->full) {
         stbvox_make_mesh_for_column(mm, mm->cur_x, mm->cur_y, mm->z0);
         if (mm->full)
            return 0;
         ++mm->cur_y;
      }
      ++mm->cur_x;
   }
   for (x=mm->cur_x; x < mm->x1; ++x) {
      for (y=mm->y0; y < mm->y1; ++y) {
         stbvox_make_mesh_for_column(mm, x, y, mm->z0);
         if (mm->full) {
            mm->cur_x = x;
            mm->cur_y = y;
            return 0;
         }
      }
   }
   return 1;
}

void stbvox_init_mesh_maker(stbvox_mesh_maker *mm)
{
   memset(mm, 0, sizeof(*mm));
   stbvox_build_default_palette();

   mm->config_dirty = 1;
   mm->default_mesh = 0;
}

int stbvox_get_buffer_count(stbvox_mesh_maker *mm)
{
   stbvox_bring_up_to_date(mm);
   return mm->num_mesh_slots;
}

int stbvox_get_buffer_size_per_quad(stbvox_mesh_maker *mm, int n)
{
   return mm->output_size[0][n];
}

void stbvox_reset_buffers(stbvox_mesh_maker *mm)
{
   int i;
   for (i=0; i < STBVOX_MAX_MESHES*STBVOX_MAX_MESH_SLOTS; ++i) {
      mm->output_cur[0][i] = 0;
      mm->output_buffer[0][i] = 0;
   }
}

void stbvox_set_buffer(stbvox_mesh_maker *mm, int mesh, int slot, void *buffer, size_t len)
{
   int i;
   stbvox_bring_up_to_date(mm);
   mm->output_buffer[mesh][slot] = (char *) buffer;
   mm->output_cur   [mesh][slot] = (char *) buffer;
   mm->output_len   [mesh][slot] = len;
   mm->output_end   [mesh][slot] = (char *) buffer + len;
   for (i=0; i < STBVOX_MAX_MESH_SLOTS; ++i) {
      if (mm->output_buffer[mesh][i]) {
         assert(mm->output_len[mesh][i] / mm->output_size[mesh][i] == mm->output_len[mesh][slot] / mm->output_size[mesh][slot]);
      }
   }
}

void stbvox_set_default_mesh(stbvox_mesh_maker *mm, int mesh)
{
   mm->default_mesh = mesh;
}

int stbvox_get_quad_count(stbvox_mesh_maker *mm, int mesh)
{
   return (mm->output_cur[mesh][0] - mm->output_buffer[mesh][0]) / mm->output_size[mesh][0];
}

stbvox_input_description *stbvox_get_input_description(stbvox_mesh_maker *mm)
{
   return &mm->input;
}

void stbvox_set_input_range(stbvox_mesh_maker *mm, int x0, int y0, int z0, int x1, int y1, int z1)
{
   mm->x0 = x0;
   mm->y0 = y0;
   mm->z0 = z0;

   mm->x1 = x1;
   mm->y1 = y1;
   mm->z1 = z1;

   mm->cur_x = x0;
   mm->cur_y = y0;
   mm->cur_z = z0;

   // @TODO validate that this range is representable in this mode
}

void stbvox_get_transform(stbvox_mesh_maker *mm, float transform[3][3])
{
   // scale
   transform[0][0] = 1.0;
   transform[0][1] = 1.0;
   #if STBVOX_CONFIG_PRECISION_Z==1
   transform[0][2] = 0.5f;
   #else
   transform[0][2] = 1.0f;
   #endif
   // translation
   transform[1][0] = (float) (mm->pos_x);
   transform[1][1] = (float) (mm->pos_y);
   transform[1][2] = (float) (mm->pos_z);
   // texture coordinate projection translation
   transform[2][0] = (float) (mm->pos_x & 255); // @TODO depends on max texture scale
   transform[2][1] = (float) (mm->pos_y & 255);
   transform[2][2] = (float) (mm->pos_z & 255);
}

void stbvox_get_bounds(stbvox_mesh_maker *mm, float bounds[2][3])
{
   bounds[0][0] = (float) (mm->pos_x + mm->x0);
   bounds[0][1] = (float) (mm->pos_y + mm->y0);
   bounds[0][2] = (float) (mm->pos_z + mm->z0);
   bounds[1][0] = (float) (mm->pos_x + mm->x1);
   bounds[1][1] = (float) (mm->pos_y + mm->y1);
   bounds[1][2] = (float) (mm->pos_z + mm->z1);
}

void stbvox_set_mesh_coordinates(stbvox_mesh_maker *mm, int x, int y, int z)
{
   mm->pos_x = x;
   mm->pos_y = y;
   mm->pos_z = z;
}

void stbvox_set_input_stride(stbvox_mesh_maker *mm, int x_stride_in_bytes, int y_stride_in_bytes)
{
   int f,v;
   mm->x_stride_in_bytes = x_stride_in_bytes;
   mm->y_stride_in_bytes = y_stride_in_bytes;
   for (f=0; f < 6; ++f) {
      for (v=0; v < 4; ++v) {
         mm->cube_vertex_offset[f][v]   =   stbvox_vertex_vector[f][v][0]    * mm->x_stride_in_bytes
                                         +  stbvox_vertex_vector[f][v][1]    * mm->y_stride_in_bytes
                                         +  stbvox_vertex_vector[f][v][2]                           ;
         mm->vertex_gather_offset[f][v] =  (stbvox_vertex_vector[f][v][0]-1) * mm->x_stride_in_bytes
                                         + (stbvox_vertex_vector[f][v][1]-1) * mm->y_stride_in_bytes
                                         + (stbvox_vertex_vector[f][v][2]-1)                        ; 
      }
   }
}

/////////////////////////////////////////////////////////////////////////////
//
//    offline computation of tables
//

#if 0
// compute optimized vheight table
static char *normal_names[32] =
{
   0,0,0,0,"u   ",0, "eu  ",0,
   0,0,0,0,"ne_u",0, "nu  ",0,
   0,0,0,0,"nw_u",0, "wu  ",0,
   0,0,0,0,"sw_u",0, "su  ",0,
};

static char *find_best_normal(float x, float y, float z)
{
   int best_slot = 4;
   float best_dot = 0;
   int i;
   for (i=0; i < 32; ++i) {
      if (normal_names[i]) {
         float dot = x * stbvox_default_normals[i][0] + y * stbvox_default_normals[i][1] + z * stbvox_default_normals[i][2];
         if (dot > best_dot) {
            best_dot = dot;
            best_slot = i;
         }
      }
   }
   return normal_names[best_slot];
}

int main(int argc, char **argv)
{
   int sw,se,nw,ne;
   for (ne=0; ne < 4; ++ne) {
      for (nw=0; nw < 4; ++nw) {
         for (se=0; se < 4; ++se) {
            printf("        { ");
            for (sw=0; sw < 4; ++sw) {
               float x = (float) (nw + sw - ne - se);
               float y = (float) (sw + se - nw - ne);
               float z = 2;
               printf("STBVF_%s, ", find_best_normal(x,y,z));
            }
            printf("},\n");
         }
      }
   }
   return 0;
}
#endif

// @TODO
//
//   - test API for texture rotation on side faces
//   - API for texture rotation on top & bottom
//   - better culling of vheight faces with vheight neighbors
//   - better culling of non-vheight faces with vheight neighbors
//   - gather vertex lighting from slopes correctly
//   - better support texture edge_clamp: currently if you fall
//     exactly on 1.0 you get wrapped incorrectly; this is rare, but
//     can avoid: compute texcoords in vertex shader, offset towards
//     center before modding, need 2 bits per vertex to know offset direction)
//   - other mesh modes (10,6,4-byte quads)
//
//
// With TexBuffer for the fixed vertex data, we can actually do
// minecrafty non-blocks like stairs -- we still probably only
// want 256 or so, so we can't do the equivalent of all the vheight
// combos, but that's ok. The 256 includes baked rotations, but only
// some of them need it, and lots of block types share some faces.
//
// mode 5 (6 bytes):   mode 6 (6 bytes)
//   x:7                x:6
//   y:7                y:6
//   z:6                z:6
//   tex1:8             tex1:8
//   tex2:8             tex2:7
//   color:8            color:8
//   face:4             face:7
//
//
//  side faces (all x4)        top&bottom faces (2x)    internal faces (1x)
//     1  regular                1 regular
//     2  slabs                                             2
//     8  stairs                 4 stairs                  16
//     4  diag side                                         8
//     4  upper diag side                                   8
//     4  lower diag side                                   8
//                                                          4 crossed pairs
//
//    23*4                   +   5*4                    +  46
//  == 92 + 20 + 46 = 158
//
//   Must drop 30 of them to fit in 7 bits:
//       ceiling half diagonals: 16+8 = 24
//   Need to get rid of 6 more.
//       ceiling diagonals: 8+4 = 12
//   This brings it to 122, so can add a crossed-pair variant.
//       (diagonal and non-diagonal, or randomly offset)
//   Or carpet, which would be 5 more.
//
//
// Mode 4 (10 bytes):
//  v:  z:2,light:6
//  f:  x:6,y:6,z:7, t1:8,t2:8,c:8,f:5
//
// Mode ? (10 bytes)
//  v:  xyz:5 (27 values), light:3
//  f:  x:7,y:7,z:6, t1:8,t2:8,c:8,f:4
// (v:  x:2,y:2,z:2,light:2)

#endif // STB_VOXEL_RENDER_IMPLEMENTATION
