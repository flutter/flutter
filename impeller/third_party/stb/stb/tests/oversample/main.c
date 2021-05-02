#pragma warning(disable:4244; disable:4305; disable:4018)
#include <assert.h>
#include <ctype.h>

#define STB_WINMAIN
#include "stb_wingraph.h"

#define STB_TRUETYPE_IMPLEMENTATION
#define STB_RECT_PACK_IMPLEMENTATION
#include "stb_rect_pack.h"
#include "stb_truetype.h"

#ifndef WINGDIAPI
#define CALLBACK    __stdcall
#define WINGDIAPI   __declspec(dllimport)
#define APIENTRY    __stdcall
#endif

#include <gl/gl.h>
#include <gl/glu.h>

#define GL_FRAMEBUFFER_SRGB_EXT           0x8DB9

#define SIZE_X  1024
#define SIZE_Y  768

stbtt_packedchar chardata[6][128];

int sx=SIZE_X, sy=SIZE_Y;

#define BITMAP_W 512
#define BITMAP_H 512
unsigned char temp_bitmap[BITMAP_W][BITMAP_H];
unsigned char ttf_buffer[1 << 25];
GLuint font_tex;

float scale[2] = { 24.0f, 14.0f };

int sf[6] = { 0,1,2, 0,1,2 };

void load_fonts(void)
{
   stbtt_pack_context pc;
   int i;
   FILE *f;
   char filename[256];
   char *win = getenv("windir");
   if (win == NULL) win = getenv("SystemRoot");

   f = fopen(stb_wingraph_commandline, "rb");
   if (!f) {
      if (win == NULL)
         sprintf(filename, "arial.ttf", win);
      else
         sprintf(filename, "%s/fonts/arial.ttf", win);
      f = fopen(filename, "rb");
      if (!f) exit(0);
   }

   fread(ttf_buffer, 1, 1<<25, f);

   stbtt_PackBegin(&pc, temp_bitmap[0], BITMAP_W, BITMAP_H, 0, 1, NULL);
   for (i=0; i < 2; ++i) {
      stbtt_PackSetOversampling(&pc, 1, 1);
      stbtt_PackFontRange(&pc, ttf_buffer, 0, scale[i], 32, 95, chardata[i*3+0]+32);
      stbtt_PackSetOversampling(&pc, 2, 2);
      stbtt_PackFontRange(&pc, ttf_buffer, 0, scale[i], 32, 95, chardata[i*3+1]+32);
      stbtt_PackSetOversampling(&pc, 3, 1);
      stbtt_PackFontRange(&pc, ttf_buffer, 0, scale[i], 32, 95, chardata[i*3+2]+32);
   }
   stbtt_PackEnd(&pc);

   glGenTextures(1, &font_tex);
   glBindTexture(GL_TEXTURE_2D, font_tex);
   glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, BITMAP_W, BITMAP_H, 0, GL_ALPHA, GL_UNSIGNED_BYTE, temp_bitmap);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
}

int black_on_white;

void draw_init(void)
{
   glDisable(GL_CULL_FACE);
   glDisable(GL_TEXTURE_2D);
   glDisable(GL_LIGHTING);
   glDisable(GL_DEPTH_TEST);

   glViewport(0,0,sx,sy);
   if (black_on_white)
      glClearColor(255,255,255,0);
   else
      glClearColor(0,0,0,0);
   glClear(GL_COLOR_BUFFER_BIT);

   glMatrixMode(GL_PROJECTION);
   glLoadIdentity();
   gluOrtho2D(0,sx,sy,0);
   glMatrixMode(GL_MODELVIEW);
   glLoadIdentity();
}


void drawBoxTC(float x0, float y0, float x1, float y1, float s0, float t0, float s1, float t1)
{
   glTexCoord2f(s0,t0); glVertex2f(x0,y0);
   glTexCoord2f(s1,t0); glVertex2f(x1,y0);
   glTexCoord2f(s1,t1); glVertex2f(x1,y1);
   glTexCoord2f(s0,t1); glVertex2f(x0,y1);
}

int integer_align;

void print(float x, float y, int font, char *text)
{
   glEnable(GL_TEXTURE_2D);
   glBindTexture(GL_TEXTURE_2D, font_tex);
   glBegin(GL_QUADS);
   while (*text) {
      stbtt_aligned_quad q;
      stbtt_GetPackedQuad(chardata[font], BITMAP_W, BITMAP_H, *text++, &x, &y, &q, font ? 0 : integer_align);
      drawBoxTC(q.x0,q.y0,q.x1,q.y1, q.s0,q.t0,q.s1,q.t1);
   }
   glEnd();
}

int font=3;
int translating;
int rotating=0;
int srgb=0;
float rotate_t, translate_t;
int show_tex;

void draw_world(void)
{
   int sfont = sf[font];
   float x = 20;
   glEnable(GL_BLEND);
   glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

   if (black_on_white)
      glColor3f(0,0,0);
   else
      glColor3f(1,1,1);


   print(80, 30, sfont, "Controls:");
   print(100, 60, sfont, "S: toggle font size");
   print(100, 85, sfont, "O: toggle oversampling");
   print(100,110, sfont, "T: toggle translation");
   print(100,135, sfont, "R: toggle rotation");
   print(100,160, sfont, "P: toggle pixel-snap (only non-oversampled)");
   print(100,185, sfont, "G: toggle srgb gamma-correction");
   if (black_on_white)
      print(100,210, sfont, "B: toggle to white-on-black");
   else
      print(100,210, sfont, "B: toggle to black-on-white");
   print(100,235, sfont, "V: view font texture");

   print(80, 300, sfont, "Current font:");

   if (!show_tex) {
      if (font < 3)
         print(100, 350, sfont, "Font height: 24 pixels");
      else
         print(100, 350, sfont, "Font height: 14 pixels");
   }

   if (font%3==1)
      print(100, 325, sfont, "2x2 oversampled text at 1:1");
   else if (font%3 == 2)
      print(100, 325, sfont, "3x1 oversampled text at 1:1");
   else if (integer_align)
      print(100, 325, sfont, "1:1 text, one texel = one pixel, snapped to integer coordinates");
   else
      print(100, 325, sfont, "1:1 text, one texel = one pixel");

   if (show_tex) {
      glBegin(GL_QUADS);
      drawBoxTC(200,400, 200+BITMAP_W,300+BITMAP_H, 0,0,1,1);
      glEnd();
   } else {
      glMatrixMode(GL_MODELVIEW);
      glTranslatef(200,350,0);

      if (translating)
         x += fmod(translate_t*8,30);

      if (rotating) {
         glTranslatef(100,150,0);
         glRotatef(rotate_t*2,0,0,1);
         glTranslatef(-100,-150,0);
      }
      print(x,100, font, "This is a test");
      print(x,130, font, "Now is the time for all good men to come to the aid of their country.");
      print(x,160, font, "The quick brown fox jumps over the lazy dog.");
      print(x,190, font, "0123456789");
   }
}

void draw(void)
{
   draw_init();
   draw_world();
   stbwingraph_SwapBuffers(NULL);
}

static int initialized=0;
static float last_dt;

int move[4];
int raw_mouse_x, raw_mouse_y;

int loopmode(float dt, int real, int in_client)
{
   float actual_dt = dt;

   if (!initialized) return 0;

   rotate_t += dt;
   translate_t += dt;

//   music_sim();
   if (!real)
      return 0;

   if (dt > 0.25) dt = 0.25;
   if (dt < 0.01) dt = 0.01;

   draw();

   return 0;
}

int winproc(void *data, stbwingraph_event *e)
{
   switch (e->type) {
      case STBWGE_create:
         break;

      case STBWGE_char:
         switch(e->key) {
            case 27:
               stbwingraph_ShowCursor(NULL,1);
               return STBWINGRAPH_winproc_exit;
               break;
            case 'o': case 'O':
               font = (font+1) % 3 + (font/3)*3;
               break;
            case 's': case 'S':
               font = (font+3) % 6;
               break;
            case 't': case 'T':
               translating = !translating;
               translate_t = 0;
               break;
            case 'r': case 'R':
               rotating = !rotating;
               rotate_t = 0;
               break;
            case 'p': case 'P':
               integer_align = !integer_align;
               break;
            case 'g': case 'G':
               srgb = !srgb;
               if (srgb)
                  glEnable(GL_FRAMEBUFFER_SRGB_EXT);
               else
                  glDisable(GL_FRAMEBUFFER_SRGB_EXT);
               break;
            case 'v': case 'V':
               show_tex = !show_tex;
               break;
            case 'b': case 'B':
               black_on_white = !black_on_white;
               break;
         }
         break;

      case STBWGE_mousemove:
         raw_mouse_x = e->mx;
         raw_mouse_y = e->my;
         break;

#if 0
      case STBWGE_mousewheel:  do_mouse(e,0,0); break;
      case STBWGE_leftdown:    do_mouse(e, 1,0); break;
      case STBWGE_leftup:      do_mouse(e,-1,0); break;
      case STBWGE_rightdown:   do_mouse(e,0, 1); break;
      case STBWGE_rightup:     do_mouse(e,0,-1); break;
#endif

      case STBWGE_keydown:
         if (e->key == VK_RIGHT) move[0] = 1;
         if (e->key == VK_LEFT)  move[1] = 1;
         if (e->key == VK_UP)    move[2] = 1;
         if (e->key == VK_DOWN)  move[3] = 1;
         break;
      case STBWGE_keyup:
         if (e->key == VK_RIGHT) move[0] = 0;
         if (e->key == VK_LEFT)  move[1] = 0;
         if (e->key == VK_UP)    move[2] = 0;
         if (e->key == VK_DOWN)  move[3] = 0;
         break;

      case STBWGE_size:
         sx = e->width;
         sy = e->height;
         loopmode(0,1,0);
         break;

      case STBWGE_draw:
         if (initialized)
            loopmode(0,1,0);
         break;

      default:
         return STBWINGRAPH_unprocessed;
   }
   return 0;
}

void stbwingraph_main(void)
{
   stbwingraph_Priority(2);
   stbwingraph_CreateWindow(1, winproc, NULL, "tt", SIZE_X,SIZE_Y, 0, 1, 0, 0);
   stbwingraph_ShowCursor(NULL, 0);
   load_fonts();
   initialized = 1;
   stbwingraph_MainLoop(loopmode, 0.016f);   // 30 fps = 0.33
}

