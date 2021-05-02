// stbgl - v0.04 - Sean Barrett 2008 - public domain
//
// Note that the gl extensions support requires glext.h. In fact, it works
// if you just concatenate glext.h onto the end of this file. In that case,
// this file is covered by the SGI FreeB license, and is not public domain.
//
// Extension usage:
//
//    1. Make a file called something like "extlist.txt" which contains stuff like:
//         GLE(ShaderSourceARB,SHADERSOURCEARB)
//         GLE(Uniform1iARB,UNIFORM1IARB)
//         GLARB(ActiveTexture,ACTIVETEXTURE)   // same as GLE(ActiveTextureARB,ACTIVETEXTUREARB)
//         GLARB(ClientActiveTexture,CLIENTACTIVETEXTURE)
//         GLE(MultiTexCoord2f,MULTITEXCOORD2F)
//
//    2. To declare functions (to make a header file), do this:
//         #define STB_GLEXT_DECLARE "extlist.txt"
//         #include "stb_gl.h"
//
//       A good way to do this is to define STB_GLEXT_DECLARE project-wide.
//
//    3. To define functions (implement), do this in some C file:
//         #define STB_GLEXT_DEFINE "extlist.txt"
//         #include "stb_gl.h"
//
//       If you've already defined STB_GLEXT_DECLARE, you can just do:
//         #define STB_GLEXT_DEFINE_DECLARE
//         #include "stb_gl.h"
//
//    4. Now you need to initialize:
//
//         stbgl_initExtensions();


#ifndef INCLUDE_STB_GL_H
#define INCLUDE_STB_GL_H

#define STB_GL

#ifdef _WIN32
#ifndef WINGDIAPI
#define CALLBACK    __stdcall
#define WINGDIAPI   __declspec(dllimport)
#define APIENTRY    __stdcall
#endif
#endif //_WIN32

#include <stddef.h>

#include <gl/gl.h>
#include <gl/glu.h>

#ifndef M_PI
#define M_PI  3.14159265358979323846f
#endif

#ifdef __cplusplus
extern "C" {
#endif

// like gluPerspective, but:
//    fov is chosen to satisfy both hfov <= max_hfov & vfov <= max_vfov;
//            set one to 179 or 0 to ignore it
//    zoom is applied separately, so you can do linear zoom without
//            mucking with trig with fov; 1 -> use exact fov
//    'aspect' is inferred from the current viewport, and ignores the
//            possibility of non-square pixels
extern void stbgl_Perspective(float zoom, float max_hfov, float max_vfov, float znear, float zfar);
extern void stbgl_PerspectiveViewport(int x, int y, int w, int h, float zoom, float max_hfov, float max_vfov, float znear, float zfar);
extern void stbgl_initCamera_zup_facing_x(void);
extern void stbgl_initCamera_zup_facing_y(void);
extern void stbgl_positionCameraWithEulerAngles(float *loc, float *ang);
extern void stbgl_drawRect(float x0, float y0, float x1, float y1);
extern void stbgl_drawRectTC(float x0, float y0, float x1, float y1, float s0, float t0, float s1, float t1);
extern void stbgl_drawBox(float x, float y, float z, float sx, float sy, float sz, int cw);

extern int stbgl_hasExtension(char *ext);
extern void stbgl_SimpleLight(int index, float bright, float x, float y, float z);
extern void stbgl_GlobalAmbient(float r, float g, float b);

extern int stbgl_LoadTexture(char *filename, char *props); // only if stb_image is available

extern int stbgl_TestTexture(int w);
extern int stbgl_TestTextureEx(int w, char *scale_table, int checks_log2, int r1,int g1,int b1, int r2, int b2, int g2);
extern unsigned int stbgl_rand(void); // internal, but exposed just in case; LCG, so use middle bits

extern int stbgl_TexImage2D(int texid, int w, int h, void *data, char *props);
extern int stbgl_TexImage2D_Extra(int texid, int w, int h, void *data, int chan, char *props, int preserve_data);
// "props" is a series of characters (and blocks of characters), a la fopen()'s mode,
// e.g.:
//   GLuint texid = stbgl_LoadTexture("myfile.jpg", "mbc")
//      means: load the image "myfile.jpg", and do the following:
//                generate mipmaps
//                use bilinear filtering (not trilinear)
//                use clamp-to-edge on both channels
//
// input descriptor: AT MOST ONE
//   TEXT     MEANING
//    1         1 channel of input (intensity/alpha)
//    2         2 channels of input (luminance, alpha)
//    3         3 channels of input (RGB)
//    4         4 channels of input (RGBA)
//    l         1 channel of input (luminance)
//    a         1 channel of input (alpha)
//    la        2 channels of input (lum/alpha)
//    rgb       3 channels of input (RGB)
//    ycocg     3 channels of input (YCoCg - forces YCoCg output)
//    ycocgj    4 channels of input (YCoCgJunk - forces YCoCg output)
//    rgba      4 channels of input (RGBA)
//    
// output descriptor: AT MOST ONE
//   TEXT     MEANING
//    A         1 channel of output (alpha)
//    I         1 channel of output (intensity)
//    LA        2 channels of output (lum/alpha)
//    RGB       3 channels of output (RGB)
//    RGBA      4 channels of output (RGBA)
//    DXT1      encode as a DXT1 texture (RGB unless input has RGBA)
//    DXT3      encode as a DXT3 texture
//    DXT5      encode as a DXT5 texture
//    YCoCg     encode as a DXT5 texture with Y in alpha, CoCg in RG
//    D         GL_DEPTH_COMPONENT
//    NONE      no input/output, don't call TexImage2D at all
//
// when reading from a file or using another interface with an explicit
// channel count, the input descriptor is ignored and instead the channel
// count is used as the input descriptor. if the file read is a DXT DDS,
// then it is passed directly to OpenGL in the file format.
//
// if an input descriptor is supplied but no output descriptor, the output
// is assumed to be the same as the input. if an output descriptor is supplied
// but no input descriptor, the input is assumed to be the same as the
// output. if neither is supplied, the input is assumed to be 4-channel.
// If DXT1 or YCoCG output is requested with no input, the input is assumed
// to be 4-channel but the alpha channel is ignored.
//
// filtering descriptor (default is no mipmaps)
//   TEXT     MEANING
//    m         generate mipmaps
//    M         mipmaps are provided, concatenated at end of data (from largest to smallest)
//    t         use trilinear filtering (default if mipmapped)
//    b         use bilinear filtering (default if not-mipmapped)
//    n         use nearest-neighbor sampling
//
// wrapping descriptor
//   TEXT     MEANING
//    w         wrap (default)
//    c         clamp-to-edge
//    C         GL_CLAMP (uses border color)
//
// If only one wrapping descriptor is supplied, it is applied to both channels.
//
// special:
//   TEXT     MEANING
//    f         input data is floats (default unsigned bytes)
//    F         input&output data is floats (default unsigned bytes)
//    p         explicitly pre-multiply the alpha
//    P         pad to power-of-two (default stretches)
//    NP2       non-power-of-two
//    +         can overwrite the texture data with temp data
//    !         free the texture data with "free"
//
// the properties string can also include spaces

#ifdef __cplusplus
}
#endif


#ifdef STB_GL_IMPLEMENTATION
#include <math.h>
#include <stdlib.h>
#include <assert.h>
#include <memory.h>

int stbgl_hasExtension(char *ext)
{
   const char *s = glGetString(GL_EXTENSIONS);
   for(;;) {
      char *e = ext;
      for (;;) {
         if (*e == 0) {
            if (*s == 0 || *s == ' ') return 1;
            break;
         }
         if (*s != *e)
            break;
         ++s, ++e;
      }
      while (*s && *s != ' ') ++s;
      if (!*s) return 0;
      ++s; // skip space
   }
}

void stbgl_drawRect(float x0, float y0, float x1, float y1)
{
   glBegin(GL_POLYGON);
      glTexCoord2f(0,0); glVertex2f(x0,y0);
      glTexCoord2f(1,0); glVertex2f(x1,y0);
      glTexCoord2f(1,1); glVertex2f(x1,y1);
      glTexCoord2f(0,1); glVertex2f(x0,y1);
   glEnd();
}

void stbgl_drawRectTC(float x0, float y0, float x1, float y1, float s0, float t0, float s1, float t1)
{
   glBegin(GL_POLYGON);
      glTexCoord2f(s0,t0); glVertex2f(x0,y0);
      glTexCoord2f(s1,t0); glVertex2f(x1,y0);
      glTexCoord2f(s1,t1); glVertex2f(x1,y1);
      glTexCoord2f(s0,t1); glVertex2f(x0,y1);
   glEnd();
}

void stbgl_drawBox(float x, float y, float z, float sx, float sy, float sz, int cw)
{
   float x0,y0,z0,x1,y1,z1;
   sx /=2, sy/=2, sz/=2;
   x0 = x-sx; y0 = y-sy; z0 = z-sz;
   x1 = x+sx; y1 = y+sy; z1 = z+sz;

   glBegin(GL_QUADS);
      if (cw) {
         glNormal3f(0,0,-1);
         glTexCoord2f(0,0); glVertex3f(x0,y0,z0);
         glTexCoord2f(1,0); glVertex3f(x1,y0,z0);
         glTexCoord2f(1,1); glVertex3f(x1,y1,z0);
         glTexCoord2f(0,1); glVertex3f(x0,y1,z0);

         glNormal3f(0,0,1);
         glTexCoord2f(0,0); glVertex3f(x1,y0,z1);
         glTexCoord2f(1,0); glVertex3f(x0,y0,z1);
         glTexCoord2f(1,1); glVertex3f(x0,y1,z1);
         glTexCoord2f(0,1); glVertex3f(x1,y1,z1);

         glNormal3f(-1,0,0);
         glTexCoord2f(0,0); glVertex3f(x0,y1,z1);
         glTexCoord2f(1,0); glVertex3f(x0,y0,z1);
         glTexCoord2f(1,1); glVertex3f(x0,y0,z0);
         glTexCoord2f(0,1); glVertex3f(x0,y1,z0);

         glNormal3f(1,0,0);
         glTexCoord2f(0,0); glVertex3f(x1,y0,z1);
         glTexCoord2f(1,0); glVertex3f(x1,y1,z1);
         glTexCoord2f(1,1); glVertex3f(x1,y1,z0);
         glTexCoord2f(0,1); glVertex3f(x1,y0,z0);

         glNormal3f(0,-1,0);
         glTexCoord2f(0,0); glVertex3f(x0,y0,z1);
         glTexCoord2f(1,0); glVertex3f(x1,y0,z1);
         glTexCoord2f(1,1); glVertex3f(x1,y0,z0);
         glTexCoord2f(0,1); glVertex3f(x0,y0,z0);

         glNormal3f(0,1,0);
         glTexCoord2f(0,0); glVertex3f(x1,y1,z1);
         glTexCoord2f(1,0); glVertex3f(x0,y1,z1);
         glTexCoord2f(1,1); glVertex3f(x0,y1,z0);
         glTexCoord2f(0,1); glVertex3f(x1,y1,z0);
      } else {
         glNormal3f(0,0,-1);
         glTexCoord2f(0,0); glVertex3f(x0,y0,z0);
         glTexCoord2f(0,1); glVertex3f(x0,y1,z0);
         glTexCoord2f(1,1); glVertex3f(x1,y1,z0);
         glTexCoord2f(1,0); glVertex3f(x1,y0,z0);

         glNormal3f(0,0,1);
         glTexCoord2f(0,0); glVertex3f(x1,y0,z1);
         glTexCoord2f(0,1); glVertex3f(x1,y1,z1);
         glTexCoord2f(1,1); glVertex3f(x0,y1,z1);
         glTexCoord2f(1,0); glVertex3f(x0,y0,z1);

         glNormal3f(-1,0,0);
         glTexCoord2f(0,0); glVertex3f(x0,y1,z1);
         glTexCoord2f(0,1); glVertex3f(x0,y1,z0);
         glTexCoord2f(1,1); glVertex3f(x0,y0,z0);
         glTexCoord2f(1,0); glVertex3f(x0,y0,z1);

         glNormal3f(1,0,0);
         glTexCoord2f(0,0); glVertex3f(x1,y0,z1);
         glTexCoord2f(0,1); glVertex3f(x1,y0,z0);
         glTexCoord2f(1,1); glVertex3f(x1,y1,z0);
         glTexCoord2f(1,0); glVertex3f(x1,y1,z1);

         glNormal3f(0,-1,0);
         glTexCoord2f(0,0); glVertex3f(x0,y0,z1);
         glTexCoord2f(0,1); glVertex3f(x0,y0,z0);
         glTexCoord2f(1,1); glVertex3f(x1,y0,z0);
         glTexCoord2f(1,0); glVertex3f(x1,y0,z1);

         glNormal3f(0,1,0);
         glTexCoord2f(0,0); glVertex3f(x1,y1,z1);
         glTexCoord2f(0,1); glVertex3f(x1,y1,z0);
         glTexCoord2f(1,1); glVertex3f(x0,y1,z0);
         glTexCoord2f(1,0); glVertex3f(x0,y1,z1);
      }
   glEnd();
}

void stbgl_SimpleLight(int index, float bright, float x, float y, float z)
{
   float d = (float) (1.0f/sqrt(x*x+y*y+z*z));
   float dir[4] = { x*d,y*d,z*d,0 }, zero[4] = { 0,0,0,0 };
   float c[4] = { bright,bright,bright,0 };
   GLuint light = GL_LIGHT0 + index;
   glLightfv(light, GL_POSITION, dir);
   glLightfv(light, GL_DIFFUSE, c);
   glLightfv(light, GL_AMBIENT, zero);
   glLightfv(light, GL_SPECULAR, zero);
   glEnable(light);
   glColorMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE);
   glEnable(GL_COLOR_MATERIAL);
}

void stbgl_GlobalAmbient(float r, float g, float b)
{
   float v[4] = { r,g,b,0 };
   glLightModelfv(GL_LIGHT_MODEL_AMBIENT, v);
}


#define stbgl_rad2deg(r)  ((r)*180.0f / M_PI)
#define stbgl_deg2rad(r)  ((r)/180.0f * M_PI)

void stbgl_Perspective(float zoom, float max_hfov, float max_vfov, float znear, float zfar)
{
   float unit_width, unit_height, aspect, vfov;
   int data[4],w,h;
   glGetIntegerv(GL_VIEWPORT, data);
   w = data[2];
   h = data[3];
   aspect = (float) w / h;

   if (max_hfov <= 0) max_hfov = 179;
   if (max_vfov <= 0) max_vfov = 179;

   // convert max_hfov, max_vfov to worldspace width at depth=1
   unit_width  = (float) tan(stbgl_deg2rad(max_hfov/2)) * 2;
   unit_height = (float) tan(stbgl_deg2rad(max_vfov/2)) * 2;
   // check if hfov = max_hfov is enough to satisfy it
   if (unit_width <= aspect * unit_height) {
      float height = unit_width / aspect;
      vfov = (float) atan((     height/2) / zoom);
   } else {
      vfov = (float) atan((unit_height/2) / zoom);
   }
   vfov = (float) stbgl_rad2deg(vfov * 2);
   gluPerspective(vfov, aspect, znear, zfar);
}

void stbgl_PerspectiveViewport(int x, int y, int w, int h, float zoom, float min_hfov, float min_vfov, float znear, float zfar)
{
   if (znear <= 0.0001f) znear = 0.0001f;
   glViewport(x,y,w,h);
   glScissor(x,y,w,h);
   glMatrixMode(GL_PROJECTION);
   glLoadIdentity();
   stbgl_Perspective(zoom, min_hfov, min_vfov, znear, zfar);
   glMatrixMode(GL_MODELVIEW);
}

// point the camera along the positive X axis, Z-up
void stbgl_initCamera_zup_facing_x(void)
{
   glRotatef(-90, 1,0,0);
   glRotatef( 90, 0,0,1);
}

// point the camera along the positive Y axis, Z-up
void stbgl_initCamera_zup_facing_y(void)
{
   glRotatef(-90, 1,0,0);
}

// setup a camera using Euler angles
void stbgl_positionCameraWithEulerAngles(float *loc, float *ang)
{
   glRotatef(-ang[1], 0,1,0);
   glRotatef(-ang[0], 1,0,0);
   glRotatef(-ang[2], 0,0,1);
   glTranslatef(-loc[0], -loc[1], -loc[2]);
}

static int stbgl_m(char *a, char *b)
{
   // skip first character
   do { ++a,++b; } while (*b && *a == *b);
   return *b == 0;
}

#ifdef STBI_VERSION
#ifndef STBI_NO_STDIO
int stbgl_LoadTexture(char *filename, char *props)
{
   // @TODO: handle DDS files directly
   int res;
   void *data;
   int w,h,c;
   #ifndef STBI_NO_HDR
   if (stbi_is_hdr(filename)) {
      data = stbi_loadf(filename, &w, &h, &c, 0);
      if (!data) return 0;
      res = stbgl_TexImage2D_Extra(0, w,h,data, -c, props, 0);
      free(data);
      return res;
   }
   #endif

   data = stbi_load(filename, &w, &h, &c, 0);
   if (!data) return 0;
   res = stbgl_TexImage2D_Extra(0, w,h,data, c, props, 0);
   free(data);
   return res;
}
#endif
#endif // STBI_VERSION

int stbgl_TexImage2D(int texid, int w, int h, void *data, char *props)
{
   return stbgl_TexImage2D_Extra(texid, w, h, data, 0, props,1);
}

int stbgl_TestTexture(int w)
{
   char scale_table[] = { 10,20,30,30,35,40,5,18,25,13,7,5,3,3,2,2,2,2,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0 };
   return stbgl_TestTextureEx(w, scale_table, 2, 140,130,200, 180,200,170);
}

unsigned int stbgl_rand(void)
{
   static unsigned int stbgl__rand_seed = 3248980923; // random typing
   return stbgl__rand_seed = stbgl__rand_seed * 2147001325 + 715136305; // BCPL generator
}

// wish this could be smaller, since it's so frivolous
int stbgl_TestTextureEx(int w, char *scale_table, int checks_log2, int r1,int g1,int b1, int r2, int b2, int g2)
{
   int rt[2] = {r1,r2}, gt[2] = {g1,g2}, bt[2] = {b1,b2};
   signed char modded[256];
   int i,j, m = w-1, s,k,scale;
   unsigned char *data = (unsigned char *) malloc(w*w*3);
   assert((m & w) == 0);
   data[0] = 128;
   for (s=0; s < 16; ++s) if ((1 << s) == w) break;
   assert(w == (1 << s));
   // plasma fractal noise
   for (k=s-1; k >= 0; --k) {
      int step = 1 << k;
      // interpolate from "parents"
      for (j=0; j < w; j += step*2) {
         for (i=0; i < w; i += step*2) {
            int i1 = i+step, j1=j+step;
            int i2 = (i+step*2)&m, j2 = (j+step*2)&m;
            int p00 = data[(j*w+i )*3], p01 = data[(j2*w+i )*3];
            int p10 = data[(j*w+i2)*3], p11 = data[(j2*w+i2)*3];
            data[(j*w+i1)*3] = (p00+p10)>>1;
            data[(j1*w+i)*3] = (p00+p01)>>1;
            data[(j1*w+i1)*3]= (p00+p01+p10+p11)>>2;
         }
      }
      scale = scale_table[s-k+1];
      if (!scale) continue; // just interpolate down the remaining data
      for (j=0,i=0; i < 256; i += 2, j == scale ? j=0 : ++j)
         modded[i] = j, modded[i+1] = -j; // precompute i%scale (plus sign)
      for (j=0; j < w; j += step)
         for (i=0; i < w; i += step) {
            int x = data[(j*w+i)*3] + modded[(stbgl_rand() >> 12) & 255];
            data[(j*w+i)*3] = x < 0 ? 0 : x > 255 ? 255 : x;
         }
   }
   for (j=0; j < w; ++j)
      for (i=0; i < w; ++i) {
         int check = ((i^j) & (1 << (s-checks_log2))) == 0;
         int v = data[(j*w+i)*3] >> 2;
         data[(j*w+i)*3+0] = rt[check]-v;
         data[(j*w+i)*3+1] = gt[check]-v;
         data[(j*w+i)*3+2] = bt[check]-v;
      }
   return stbgl_TexImage2D(0, w, w, data, "3m!"); // 3 channels, mipmap, free
}

#ifdef _WIN32
#ifndef WINGDIAPI
typedef int (__stdcall *stbgl__voidfunc)(void);
__declspec(dllimport) stbgl__voidfunc wglGetProcAddress(char *);
#endif
#define STB__HAS_WGLPROC
static void (__stdcall *stbgl__CompressedTexImage2DARB)(int target, int level,
                                   int internalformat, int width,
                                   int height, int border, 
                                   int imageSize, void *data);
static void stbgl__initCompTex(void)
{
   *((void **) &stbgl__CompressedTexImage2DARB) = (void *) wglGetProcAddress("glCompressedTexImage2DARB");
}
#else
static void (*stbgl__CompressedTexImage2DARB)(int target, int level,
                                   int internalformat, int width,
                                   int height, int border, 
                                   int imageSize, void *data);
static void stbgl__initCompTex(void)
{
}
#endif // _WIN32

#define STBGL_COMPRESSED_RGB_S3TC_DXT1    0x83F0
#define STBGL_COMPRESSED_RGBA_S3TC_DXT1   0x83F1
#define STBGL_COMPRESSED_RGBA_S3TC_DXT3   0x83F2
#define STBGL_COMPRESSED_RGBA_S3TC_DXT5   0x83F3

#ifdef STB_COMPRESS_DXT_BLOCK
static void stbgl__convert(uint8 *p, uint8 *q, int n, int input_desc, uint8 *end)
{
   int i;
   switch (input_desc) {
      case GL_RED:
      case GL_LUMINANCE: for (i=0; i < n; ++i,p+=4) p[0] = p[1] = p[2] = q[0], p[3]=255, q+=1; break;
      case GL_ALPHA:     for (i=0; i < n; ++i,p+=4) p[0] = p[1] = p[2] = 0, p[3] = q[0], q+=1; break;
      case GL_LUMINANCE_ALPHA: for (i=0; i < n; ++i,p+=4) p[0] = p[1] = p[2] = q[0], p[3]=q[1], q+=2; break;
      case GL_RGB:       for (i=0; i < n; ++i,p+=4) p[0]=q[0],p[1]=q[1],p[2]=q[2],p[3]=255,q+=3; break;
      case GL_RGBA:      memcpy(p, q, n*4); break;
      case GL_INTENSITY: for (i=0; i < n; ++i,p+=4) p[0] = p[1] = p[2] = p[3] = q[0], q+=1; break;
   }
   assert(p <= end);
}

static void stbgl__compress(uint8 *p, uint8 *rgba, int w, int h, int output_desc, uint8 *end)
{
   int i,j,y,y2;
   int alpha = (output_desc == STBGL_COMPRESSED_RGBA_S3TC_DXT5);
   for (j=0; j < w; j += 4) {
      int x=4;
      for (i=0; i < h; i += 4) {
         uint8 block[16*4];
         if (i+3 >= w) x = w-i;
         for (y=0; y < 4; ++y) {
            if (j+y >= h) break;
            memcpy(block+y*16, rgba + w*4*(j+y) + i*4, x*4);
         }
         if (x < 4) {
            switch (x) {
               case 0: assert(0);
               case 1:
                  for (y2=0; y2 < y; ++y2) {
                     memcpy(block+y2*16+1*4, block+y2*16+0*4, 4);
                     memcpy(block+y2*16+2*4, block+y2*16+0*4, 8);
                  }
                  break;
               case 2:
                  for (y2=0; y2 < y; ++y2)
                     memcpy(block+y2*16+2*4, block+y2*16+0*4, 8);
                  break;
               case 3:
                  for (y2=0; y2 < y; ++y2)
                     memcpy(block+y2*16+3*4, block+y2*16+1*4, 4);
                  break;
            }
         }
         y2 = 0;
         for(; y<4; ++y,++y2)
            memcpy(block+y*16, block+y2*16, 4*4);
         stb_compress_dxt_block(p, block, alpha, 10);
         p += alpha ? 16 : 8;
      }
   }
   assert(p <= end);
}
#endif // STB_COMPRESS_DXT_BLOCK

// use the reserved temporary-use enumerant range, since no
// OpenGL enumerants should fall in that range
enum
{
   STBGL_UNDEFINED = 0x6000,
   STBGL_YCOCG,
   STBGL_YCOCGJ,
   STBGL_GEN_MIPMAPS,
   STBGL_MIPMAPS,
   STBGL_NO_DOWNLOAD,
};

#define STBGL_CLAMP_TO_EDGE               0x812F
#define STBGL_CLAMP_TO_BORDER             0x812D

#define STBGL_DEPTH_COMPONENT16           0x81A5
#define STBGL_DEPTH_COMPONENT24           0x81A6
#define STBGL_DEPTH_COMPONENT32           0x81A7

int stbgl_TexImage2D_Extra(int texid, int w, int h, void *data, int chan, char *props, int preserve_data)
{
   static int has_s3tc = -1; // haven't checked yet
   int free_data = 0, is_compressed = 0;
   int pad_to_power_of_two = 0, non_power_of_two = 0;
   int premultiply_alpha = 0; // @TODO
   int float_tex   = 0; // @TODO
   int input_type  = GL_UNSIGNED_BYTE;
   int input_desc  = STBGL_UNDEFINED;
   int output_desc = STBGL_UNDEFINED;
   int mipmaps     = STBGL_UNDEFINED;
   int filter      = STBGL_UNDEFINED, mag_filter;
   int wrap_s = STBGL_UNDEFINED, wrap_t = STBGL_UNDEFINED;

   // parse out the properties
   if (props == NULL) props = "";
   while (*props) {
      switch (*props) {
         case '1' :  input_desc = GL_LUMINANCE; break;
         case '2' :  input_desc = GL_LUMINANCE_ALPHA; break;
         case '3' :  input_desc = GL_RGB; break;
         case '4' :  input_desc = GL_RGBA; break;
         case 'l' :  if (props[1] == 'a') { input_desc = GL_LUMINANCE_ALPHA; ++props; }
                     else input_desc = GL_LUMINANCE;
                     break;
         case 'a' :  input_desc = GL_ALPHA; break;
         case 'r' :  if (stbgl_m(props, "rgba")) { input_desc = GL_RGBA; props += 3; break; }
                     if (stbgl_m(props, "rgb")) { input_desc = GL_RGB; props += 2; break; }
                     input_desc = GL_RED;
                     break;
         case 'y' :  if (stbgl_m(props, "ycocg")) {
                        if (props[5] == 'j') { props += 5; input_desc = STBGL_YCOCGJ; }
                        else { props += 4; input_desc = STBGL_YCOCG; }
                        break;
                     }
                     return 0;
         case 'L' :  if (props[1] == 'A') { output_desc = GL_LUMINANCE_ALPHA; ++props; }
                     else output_desc = GL_LUMINANCE;
                     break;
         case 'I' :  output_desc = GL_INTENSITY; break;
         case 'A' :  output_desc = GL_ALPHA; break;
         case 'R' :  if (stbgl_m(props, "RGBA")) { output_desc = GL_RGBA; props += 3; break; }
                     if (stbgl_m(props, "RGB")) { output_desc = GL_RGB; props += 2; break; }
                     output_desc = GL_RED;
                     break;
         case 'Y' :  if (stbgl_m(props, "YCoCg") || stbgl_m(props, "YCOCG")) {
                        props += 4;
                        output_desc = STBGL_YCOCG;
                        break;
                     }
                     return 0;
         case 'D' :  if (stbgl_m(props, "DXT")) {
                        switch (props[3]) {
                           case '1': output_desc = STBGL_COMPRESSED_RGB_S3TC_DXT1; break;
                           case '3': output_desc = STBGL_COMPRESSED_RGBA_S3TC_DXT3; break;
                           case '5': output_desc = STBGL_COMPRESSED_RGBA_S3TC_DXT5; break;
                           default: return 0;
                        }
                        props += 3;
                     } else if (stbgl_m(props, "D16")) {
                        output_desc = STBGL_DEPTH_COMPONENT16;
                        input_desc  = GL_DEPTH_COMPONENT;
                        props += 2;
                     } else if (stbgl_m(props, "D24")) {
                        output_desc = STBGL_DEPTH_COMPONENT24;
                        input_desc  = GL_DEPTH_COMPONENT;
                        props += 2;
                     } else if (stbgl_m(props, "D32")) {
                        output_desc = STBGL_DEPTH_COMPONENT32;
                        input_desc  = GL_DEPTH_COMPONENT;
                        props += 2;
                     } else {
                        output_desc = GL_DEPTH_COMPONENT;
                        input_desc  = GL_DEPTH_COMPONENT;
                     }
                     break;
         case 'N' :  if (stbgl_m(props, "NONE")) {
                        props += 3;
                        input_desc = STBGL_NO_DOWNLOAD;
                        output_desc = STBGL_NO_DOWNLOAD;
                        break;
                     }
                     if (stbgl_m(props, "NP2")) {
                        non_power_of_two = 1;
                        props += 2;
                        break;
                     }
                     return 0;
         case 'm' :  mipmaps = STBGL_GEN_MIPMAPS; break;
         case 'M' :  mipmaps = STBGL_MIPMAPS; break;
         case 't' :  filter = GL_LINEAR_MIPMAP_LINEAR; break;
         case 'b' :  filter = GL_LINEAR; break;
         case 'n' :  filter = GL_NEAREST; break;
         case 'w' :  if (wrap_s == STBGL_UNDEFINED) wrap_s = GL_REPEAT; else wrap_t = GL_REPEAT; break;
         case 'C' :  if (wrap_s == STBGL_UNDEFINED) wrap_s = STBGL_CLAMP_TO_BORDER; else wrap_t = STBGL_CLAMP_TO_BORDER; break;
         case 'c' :  if (wrap_s == STBGL_UNDEFINED) wrap_s = STBGL_CLAMP_TO_EDGE; else wrap_t = STBGL_CLAMP_TO_EDGE; break;
         case 'f' :  input_type = GL_FLOAT; break;
         case 'F' :  input_type = GL_FLOAT; float_tex = 1; break;
         case 'p' :  premultiply_alpha = 1; break;
         case 'P' :  pad_to_power_of_two = 1; break;
         case '+' :  preserve_data = 0; break;
         case '!' :  preserve_data = 0; free_data = 1; break;
         case ' ' :  break;
         case '-' :  break;
         default  :  if (free_data) free(data);
                     return 0;
      }
      ++props;
   }
   
   // override input_desc based on channel count
   if (output_desc != STBGL_NO_DOWNLOAD) {
      switch (abs(chan)) {
         case 1: input_desc = GL_LUMINANCE; break;
         case 2: input_desc = GL_LUMINANCE_ALPHA; break;
         case 3: input_desc = GL_RGB; break;
         case 4: input_desc = GL_RGBA; break;
         case 0: break;
         default: return 0;
      }
   }

   // override input_desc based on channel info
   if (chan > 0) { input_type = GL_UNSIGNED_BYTE; }
   if (chan < 0) { input_type = GL_FLOAT; }

   if (output_desc == GL_ALPHA) {
      if (input_desc == GL_LUMINANCE)
         input_desc = GL_ALPHA;
      if (input_desc == GL_RGB) {
         // force a presumably-mono image to alpha
         // @TODO handle 'preserve_data' case?
         if (data && !preserve_data && input_type == GL_UNSIGNED_BYTE) {
            int i;
            unsigned char *p = (unsigned char *) data, *q = p;
            for (i=0; i < w*h; ++i) {
               *q = (p[0] + 2*p[1] + p[2]) >> 2;
               p += 3;
               q += 1;
            }
            input_desc = GL_ALPHA;
         }
      }
   }

   // set undefined input/output based on the other
   if (input_desc == STBGL_UNDEFINED && output_desc == STBGL_UNDEFINED) {
      input_desc = output_desc = GL_RGBA;
   } else if (output_desc == STBGL_UNDEFINED) {
      switch (input_desc) {
         case GL_LUMINANCE:
         case GL_ALPHA:
         case GL_LUMINANCE_ALPHA:
         case GL_RGB:
         case GL_RGBA:
            output_desc = input_desc;
            break;
         case GL_RED:
            output_desc = GL_INTENSITY;
            break;
         case STBGL_YCOCG:
         case STBGL_YCOCGJ:
            output_desc = STBGL_YCOCG;
            break;
         default: assert(0); return 0;
      }
   } else if (input_desc == STBGL_UNDEFINED) {
      switch (output_desc) {
         case GL_LUMINANCE:
         case GL_ALPHA:
         case GL_LUMINANCE_ALPHA:
         case GL_RGB:
         case GL_RGBA:
            input_desc = output_desc;
            break;
         case GL_INTENSITY:
            input_desc = GL_RED;
            break;
         case STBGL_YCOCG:
         case STBGL_COMPRESSED_RGB_S3TC_DXT1:
         case STBGL_COMPRESSED_RGBA_S3TC_DXT3:
         case STBGL_COMPRESSED_RGBA_S3TC_DXT5:
            input_desc = GL_RGBA;
            break;
      }
   } else {
      if (output_desc == STBGL_COMPRESSED_RGB_S3TC_DXT1) {
         // if input has alpha, force output alpha
         switch (input_desc) {
            case GL_ALPHA:
            case GL_LUMINANCE_ALPHA:
            case GL_RGBA:
               output_desc = STBGL_COMPRESSED_RGBA_S3TC_DXT5;
               break;
         }
      }
   }

   switch(input_desc) {
      case GL_LUMINANCE:
      case GL_RED:
      case GL_ALPHA:
         chan = 1;
         break;
      case GL_LUMINANCE_ALPHA:
         chan = 2;
         break;
      case GL_RGB:
         chan = 3;
         break;
      case GL_RGBA:
         chan = 4;
         break;
   }

   if (pad_to_power_of_two && ((w & (w-1)) || (h & (h-1)))) {
      if (output_desc != STBGL_NO_DOWNLOAD && input_type == GL_UNSIGNED_BYTE && chan > 0) {
         unsigned char *new_data;
         int w2 = w, h2 = h, j;
         while (w & (w-1))
            w = (w | (w>>1))+1;
         while (h & (h-1))
            h = (h | (h>>1))+1;
         new_data = malloc(w * h * chan);
         for (j=0; j < h2; ++j) {
            memcpy(new_data + j * w * chan, (char *) data+j*w2*chan, w2*chan);
            memset(new_data + (j * w+w2) * chan, 0, (w-w2)*chan);
         }
         for (; j < h; ++j)
            memset(new_data + j*w*chan, 0, w*chan);
         if (free_data)
            free(data);
         data = new_data;
         free_data = 1;
      }
   }

   switch (output_desc) {
      case STBGL_COMPRESSED_RGB_S3TC_DXT1:
      case STBGL_COMPRESSED_RGBA_S3TC_DXT1:
      case STBGL_COMPRESSED_RGBA_S3TC_DXT3:
      case STBGL_COMPRESSED_RGBA_S3TC_DXT5:
         is_compressed = 1;
         if (has_s3tc == -1) {
            has_s3tc = stbgl_hasExtension("GL_EXT_texture_compression_s3tc");
            if (has_s3tc) stbgl__initCompTex();
         }
         if (!has_s3tc) {
            is_compressed = 0;
            if (output_desc == STBGL_COMPRESSED_RGB_S3TC_DXT1)
               output_desc = GL_RGB;
            else
               output_desc = GL_RGBA;
         }
   }

   if (output_desc == STBGL_YCOCG) {
      assert(0);
      output_desc = GL_RGB; // @TODO!
      if (free_data) free(data);
      return 0;
   }

   mag_filter = 0;
   if (mipmaps != STBGL_UNDEFINED) {
      switch (filter) {
         case STBGL_UNDEFINED: filter = GL_LINEAR_MIPMAP_LINEAR; break;
         case GL_NEAREST     : mag_filter = GL_NEAREST; filter = GL_LINEAR_MIPMAP_LINEAR; break;
         case GL_LINEAR      : filter = GL_LINEAR_MIPMAP_NEAREST; break;
      }
   } else {
      if (filter == STBGL_UNDEFINED)
         filter = GL_LINEAR;
   }

   // update filtering
   if (!mag_filter) {
      if (filter == GL_NEAREST)
         mag_filter = GL_NEAREST;
      else
         mag_filter = GL_LINEAR;
   }

   // update wrap/clamp
   if (wrap_s == STBGL_UNDEFINED) wrap_s = GL_REPEAT;
   if (wrap_t == STBGL_UNDEFINED) wrap_t = wrap_s;

   // if no texture id, generate one
   if (texid == 0) {
      GLuint tex;
      glGenTextures(1, &tex);
      if (tex == 0) { if (free_data) free(data); return 0; }
      texid = tex;
   }

   if (data == NULL && mipmaps == STBGL_GEN_MIPMAPS)
      mipmaps = STBGL_MIPMAPS;

   if (output_desc == STBGL_NO_DOWNLOAD)
      mipmaps = STBGL_NO_DOWNLOAD;

   glBindTexture(GL_TEXTURE_2D, texid);

#ifdef STB_COMPRESS_DXT_BLOCK
   if (!is_compressed || !stbgl__CompressedTexImage2DARB || output_desc == STBGL_COMPRESSED_RGBA_S3TC_DXT3 || data == NULL)
#endif
   {
      switch (mipmaps) {
         case STBGL_NO_DOWNLOAD:
            break;

         case STBGL_UNDEFINED:
            // check if actually power-of-two
            if (non_power_of_two || ((w & (w-1)) == 0 && (h & (h-1)) == 0))
               glTexImage2D(GL_TEXTURE_2D, 0, output_desc, w, h, 0, input_desc, input_type, data);
            else
               gluBuild2DMipmaps(GL_TEXTURE_2D, output_desc, w, h, input_desc, input_type, data);
               // not power of two, so use glu to resize (generates mipmaps needlessly)
            break;

         case STBGL_MIPMAPS: {
            int level = 0;
            int size = input_type == GL_FLOAT ? sizeof(float) : 1;
            if (data == NULL) size = 0; // reuse same block of memory for all mipmaps
            assert((w & (w-1)) == 0 && (h & (h-1)) == 0); // verify power-of-two
            while (w > 1 && h > 1) {
               glTexImage2D(GL_TEXTURE_2D, level, output_desc, w, h, 0, input_desc, input_type, data);
               data = (void *) ((char *) data + w * h * size * chan);
               if (w > 1) w >>= 1;
               if (h > 1) h >>= 1;
               ++level;
            }
            break;
         }
         case STBGL_GEN_MIPMAPS:
            gluBuild2DMipmaps(GL_TEXTURE_2D, output_desc, w, h, input_desc, input_type, data);
            break;

         default:
            assert(0);
            if (free_data) free(data);
            return 0;
      }
#ifdef STB_COMPRESS_DXT_BLOCK
   } else {
      uint8 *out, *rgba=0, *end_out, *end_rgba;
      int level = 0, alpha = (output_desc != STBGL_COMPRESSED_RGB_S3TC_DXT1);
      int size = input_type == GL_FLOAT ? sizeof(float) : 1;
      int osize = alpha ? 16 : 8;
      if (!free_data && mipmaps == STBGL_GEN_MIPMAPS) {
         uint8 *temp = malloc(w*h*chan);
         if (!temp) { if (free_data) free(data); return 0; }
         memcpy(temp, data, w*h*chan);
         if (free_data) free(data);
         free_data = 1;
         data = temp;
      }
      if (chan != 4 || size != 1) {
         rgba = malloc(w*h*4);
         if (!rgba) return 0;
         end_rgba = rgba+w*h*4;
      }
      out = malloc((w+3)*(h+3)/16*osize); // enough storage for the s3tc data
      if (!out) return 0;
      end_out = out + ((w+3)*(h+3))/16*osize;

      for(;;) {
         if (chan != 4)
            stbgl__convert(rgba, data, w*h, input_desc, end_rgba);
         stbgl__compress(out, rgba ? rgba : data, w, h, output_desc, end_out);
         stbgl__CompressedTexImage2DARB(GL_TEXTURE_2D, level, output_desc, w, h, 0, ((w+3)&~3)*((h+3)&~3)/16*osize, out);
         //glTexImage2D(GL_TEXTURE_2D, level, alpha?GL_RGBA:GL_RGB, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, rgba ? rgba : data);

         if (mipmaps == STBGL_UNDEFINED) break;
         if (w <= 1 && h <= 1) break;
         if (mipmaps == STBGL_MIPMAPS) data = (void *) ((char *) data + w * h * size * chan);
         if (mipmaps == STBGL_GEN_MIPMAPS) {
            int w2 = w>>1, h2=h>>1, i,j,k, s=w*chan;
            uint8 *p = data, *q=data;
            if (w == 1) {
               for (j=0; j < h2; ++j) {
                  for (k=0; k < chan; ++k)
                     *p++ = (q[k] + q[s+k] + 1) >> 1;
                  q += s*2;
               }
            } else if (h == 1) {
               for (i=0; i < w2; ++i) {
                  for (k=0; k < chan; ++k)
                     *p++ = (q[k] + q[k+chan] + 1) >> 1;
                  q += chan*2;
               }
            } else {
               for (j=0; j < h2; ++j) {
                  for (i=0; i < w2; ++i) {
                     for (k=0; k < chan; ++k)
                        *p++ = (q[k] + q[k+chan] + q[s+k] + q[s+k+chan] + 2) >> 2;
                     q += chan*2;
                  }
                  q += s;
               }
            }
         }
         if (w > 1) w >>= 1;
         if (h > 1) h >>= 1;
         ++level;
      }
      if (out) free(out);
      if (rgba) free(rgba);
#endif // STB_COMPRESS_DXT_BLOCK
   }

   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrap_s);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrap_t);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, mag_filter);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filter);

   if (free_data) free(data);
   return texid;
}

#endif // STB_DEFINE
#undef STB_EXTERN

#endif //INCLUDE_STB_GL_H

// Extension handling... must be outside the INCLUDE_ brackets

#if defined(STB_GLEXT_DEFINE) || defined(STB_GLEXT_DECLARE)

#ifndef STB_GLEXT_SKIP_DURING_RECURSION

#ifndef GL_GLEXT_VERSION

   // First check if glext.h is concatenated on the end of this file
   // (if it's concatenated on the beginning, we'll have GL_GLEXT_VERSION)

   #define  STB_GLEXT_SKIP_DURING_RECURSION
   #include __FILE__
   #undef   STB_GLEXT_SKIP_DURING_RECURSION

   // now check if it's still undefined; if so, try going for it by name;
   // if this errors, that's fine, since we can't compile without it

   #ifndef GL_GLEXT_VERSION
   #include "glext.h"
   #endif
#endif

#define GLARB(a,b) GLE(a##ARB,b##ARB)
#define GLEXT(a,b) GLE(a##EXT,b##EXT)
#define GLNV(a,b)  GLE(a##NV ,b##NV)
#define GLATI(a,b) GLE(a##ATI,b##ATI)
#define GLCORE(a,b) GLE(a,b)

#ifdef STB_GLEXT_DEFINE_DECLARE
#define STB_GLEXT_DEFINE STB_GLEXT_DECLARE
#endif

#if defined(STB_GLEXT_DECLARE) && defined(STB_GLEXT_DEFINE)
#undef STB_GLEXT_DECLARE
#endif

#if defined(STB_GLEXT_DECLARE) && !defined(STB_GLEXT_DEFINE)
   #define GLE(a,b) extern PFNGL##b##PROC gl##a;

   #ifdef __cplusplus
   extern "C" {
   #endif

   extern void stbgl_initExtensions(void);

   #include STB_GLEXT_DECLARE

   #ifdef __cplusplus
   };
   #endif

#else

   #ifndef STB_GLEXT_DEFINE
   #error "Header file is screwed up somehow"
   #endif

   #ifdef _WIN32
   #ifndef WINGDIAPI
   #ifndef STB__HAS_WGLPROC
   typedef int (__stdcall *stbgl__voidfunc)(void);
   __declspec(dllimport) stbgl__voidfunc wglGetProcAddress(char *);
   #endif
   #endif
   #define STBGL__GET_FUNC(x)   wglGetProcAddress(x)
   #endif

   #ifdef GLE
   #undef GLE
   #endif

   #define GLE(a,b)  PFNGL##b##PROC gl##a;
   #include STB_GLEXT_DEFINE

   #undef GLE
   #define GLE(a,b) gl##a = (PFNGL##b##PROC) STBGL__GET_FUNC("gl" #a );

   void stbgl_initExtensions(void)
   {
      #include STB_GLEXT_DEFINE
   }

   #undef GLE

#endif // STB_GLEXT_DECLARE

#endif // STB_GLEXT_SKIP

#endif // STB_GLEXT_DEFINE || STB_GLEXT_DECLARE
