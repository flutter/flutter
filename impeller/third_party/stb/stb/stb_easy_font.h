// stb_easy_font.h - v0.7 - bitmap font for 3D rendering - public domain
// Sean Barrett, Feb 2015
//
//    Easy-to-deploy,
//    reasonably compact,
//    extremely inefficient performance-wise,
//    crappy-looking,
//    ASCII-only,
//    bitmap font for use in 3D APIs.
//
// Intended for when you just want to get some text displaying
// in a 3D app as quickly as possible.
//
// Doesn't use any textures, instead builds characters out of quads.
//
// DOCUMENTATION:
//
//   int stb_easy_font_width(char *text)
//   int stb_easy_font_height(char *text)
//
//      Takes a string and returns the horizontal size and the
//      vertical size (which can vary if 'text' has newlines).
//
//   int stb_easy_font_print(float x, float y,
//                           char *text, unsigned char color[4],
//                           void *vertex_buffer, int vbuf_size)
//
//      Takes a string (which can contain '\n') and fills out a
//      vertex buffer with renderable data to draw the string.
//      Output data assumes increasing x is rightwards, increasing y
//      is downwards.
//
//      The vertex data is divided into quads, i.e. there are four
//      vertices in the vertex buffer for each quad.
//
//      The vertices are stored in an interleaved format:
//
//         x:float
//         y:float
//         z:float
//         color:uint8[4]
//
//      You can ignore z and color if you get them from elsewhere
//      This format was chosen in the hopes it would make it
//      easier for you to reuse existing vertex-buffer-drawing code.
//
//      If you pass in NULL for color, it becomes 255,255,255,255.
//
//      Returns the number of quads.
//
//      If the buffer isn't large enough, it will truncate.
//      Expect it to use an average of ~270 bytes per character.
//
//      If your API doesn't draw quads, build a reusable index
//      list that allows you to render quads as indexed triangles.
//
//   void stb_easy_font_spacing(float spacing)
//
//      Use positive values to expand the space between characters,
//      and small negative values (no smaller than -1.5) to contract
//      the space between characters. 
//
//      E.g. spacing = 1 adds one "pixel" of spacing between the
//      characters. spacing = -1 is reasonable but feels a bit too
//      compact to me; -0.5 is a reasonable compromise as long as
//      you're scaling the font up.
//
// LICENSE
//
//   This software is dual-licensed to the public domain and under the following
//   license: you are granted a perpetual, irrevocable license to copy, modify,
//   publish, and distribute this file as you see fit.
//
// VERSION HISTORY
//
//   (2016-01-22)  0.7   width() supports multiline text; add height()
//   (2015-09-13)  0.6   #include <math.h>; updated license
//   (2015-02-01)  0.5   First release

#if 0
// SAMPLE CODE:
//
//    Here's sample code for old OpenGL; it's a lot more complicated
//    to make work on modern APIs, and that's your problem.
//
void print_string(float x, float y, char *text, float r, float g, float b)
{
  static char buffer[99999]; // ~500 chars
  int num_quads;

  num_quads = stb_easy_font_print(x, y, text, NULL, buffer, sizeof(buffer));

  glColor3f(r,g,b);
  glEnableClientState(GL_VERTEX_ARRAY);
  glVertexPointer(2, GL_FLOAT, 16, buffer);
  glDrawArrays(GL_QUADS, 0, num_quads*4);
  glDisableClientState(GL_VERTEX_ARRAY);
}
#endif

#ifndef INCLUDE_STB_EASY_FONT_H
#define INCLUDE_STB_EASY_FONT_H

#include <stdlib.h>
#include <math.h>

struct {
    unsigned char advance;
    unsigned char h_seg;
    unsigned char v_seg;
} stb_easy_font_charinfo[96] = {
    {  5,  0,  0 },  {  3,  0,  0 },  {  5,  1,  1 },  {  7,  1,  4 },
    {  7,  3,  7 },  {  7,  6, 12 },  {  7,  8, 19 },  {  4, 16, 21 },
    {  4, 17, 22 },  {  4, 19, 23 },  { 23, 21, 24 },  { 23, 22, 31 },
    { 20, 23, 34 },  { 22, 23, 36 },  { 19, 24, 36 },  { 21, 25, 36 },
    {  6, 25, 39 },  {  6, 27, 43 },  {  6, 28, 45 },  {  6, 30, 49 },
    {  6, 33, 53 },  {  6, 34, 57 },  {  6, 40, 58 },  {  6, 46, 59 },
    {  6, 47, 62 },  {  6, 55, 64 },  { 19, 57, 68 },  { 20, 59, 68 },
    { 21, 61, 69 },  { 22, 66, 69 },  { 21, 68, 69 },  {  7, 73, 69 },
    {  9, 75, 74 },  {  6, 78, 81 },  {  6, 80, 85 },  {  6, 83, 90 },
    {  6, 85, 91 },  {  6, 87, 95 },  {  6, 90, 96 },  {  7, 92, 97 },
    {  6, 96,102 },  {  5, 97,106 },  {  6, 99,107 },  {  6,100,110 },
    {  6,100,115 },  {  7,101,116 },  {  6,101,121 },  {  6,101,125 },
    {  6,102,129 },  {  7,103,133 },  {  6,104,140 },  {  6,105,145 },
    {  7,107,149 },  {  6,108,151 },  {  7,109,155 },  {  7,109,160 },
    {  7,109,165 },  {  7,118,167 },  {  6,118,172 },  {  4,120,176 },
    {  6,122,177 },  {  4,122,181 },  { 23,124,182 },  { 22,129,182 },
    {  4,130,182 },  { 22,131,183 },  {  6,133,187 },  { 22,135,191 },
    {  6,137,192 },  { 22,139,196 },  {  5,144,197 },  { 22,147,198 },
    {  6,150,202 },  { 19,151,206 },  { 21,152,207 },  {  6,155,209 },
    {  3,160,210 },  { 23,160,211 },  { 22,164,216 },  { 22,165,220 },
    { 22,167,224 },  { 22,169,228 },  { 21,171,232 },  { 21,173,233 },
    {  5,178,233 },  { 22,179,234 },  { 23,180,238 },  { 23,180,243 },
    { 23,180,248 },  { 22,189,248 },  { 22,191,252 },  {  5,196,252 },
    {  3,203,252 },  {  5,203,253 },  { 22,210,253 },  {  0,214,253 },
};

unsigned char stb_easy_font_hseg[214] = {
   97,37,69,84,28,51,2,18,10,49,98,41,65,25,81,105,33,9,97,1,97,37,37,36,
    81,10,98,107,3,100,3,99,58,51,4,99,58,8,73,81,10,50,98,8,73,81,4,10,50,
    98,8,25,33,65,81,10,50,17,65,97,25,33,25,49,9,65,20,68,1,65,25,49,41,
    11,105,13,101,76,10,50,10,50,98,11,99,10,98,11,50,99,11,50,11,99,8,57,
    58,3,99,99,107,10,10,11,10,99,11,5,100,41,65,57,41,65,9,17,81,97,3,107,
    9,97,1,97,33,25,9,25,41,100,41,26,82,42,98,27,83,42,98,26,51,82,8,41,
    35,8,10,26,82,114,42,1,114,8,9,73,57,81,41,97,18,8,8,25,26,26,82,26,82,
    26,82,41,25,33,82,26,49,73,35,90,17,81,41,65,57,41,65,25,81,90,114,20,
    84,73,57,41,49,25,33,65,81,9,97,1,97,25,33,65,81,57,33,25,41,25,
};

unsigned char stb_easy_font_vseg[253] = {
   4,2,8,10,15,8,15,33,8,15,8,73,82,73,57,41,82,10,82,18,66,10,21,29,1,65,
    27,8,27,9,65,8,10,50,97,74,66,42,10,21,57,41,29,25,14,81,73,57,26,8,8,
    26,66,3,8,8,15,19,21,90,58,26,18,66,18,105,89,28,74,17,8,73,57,26,21,
    8,42,41,42,8,28,22,8,8,30,7,8,8,26,66,21,7,8,8,29,7,7,21,8,8,8,59,7,8,
    8,15,29,8,8,14,7,57,43,10,82,7,7,25,42,25,15,7,25,41,15,21,105,105,29,
    7,57,57,26,21,105,73,97,89,28,97,7,57,58,26,82,18,57,57,74,8,30,6,8,8,
    14,3,58,90,58,11,7,74,43,74,15,2,82,2,42,75,42,10,67,57,41,10,7,2,42,
    74,106,15,2,35,8,8,29,7,8,8,59,35,51,8,8,15,35,30,35,8,8,30,7,8,8,60,
    36,8,45,7,7,36,8,43,8,44,21,8,8,44,35,8,8,43,23,8,8,43,35,8,8,31,21,15,
    20,8,8,28,18,58,89,58,26,21,89,73,89,29,20,8,8,30,7,
};

typedef struct
{
   unsigned char c[4];
} stb_easy_font_color;

static int stb_easy_font_draw_segs(float x, float y, unsigned char *segs, int num_segs, int vertical, stb_easy_font_color c, char *vbuf, int vbuf_size, int offset)
{
    int i,j;
    for (i=0; i < num_segs; ++i) {
        int len = segs[i] & 7;
        x += (float) ((segs[i] >> 3) & 1);
        if (len && offset+64 <= vbuf_size) {
            float y0 = y + (float) (segs[i]>>4);
            for (j=0; j < 4; ++j) {
                * (float *) (vbuf+offset+0) = x  + (j==1 || j==2 ? (vertical ? 1 : len) : 0);
                * (float *) (vbuf+offset+4) = y0 + (    j >= 2   ? (vertical ? len : 1) : 0);
                * (float *) (vbuf+offset+8) = 0.f;
                * (stb_easy_font_color *) (vbuf+offset+12) = c;
                offset += 16;
            }
        }
    }
    return offset;
}

float stb_easy_font_spacing_val = 0;
static void stb_easy_font_spacing(float spacing)
{
   stb_easy_font_spacing_val = spacing;
}

static int stb_easy_font_print(float x, float y, char *text, unsigned char color[4], void *vertex_buffer, int vbuf_size)
{
    char *vbuf = (char *) vertex_buffer;
    float start_x = x;
    int offset = 0;

    stb_easy_font_color c = { 255,255,255,255 }; // use structure copying to avoid needing depending on memcpy()
    if (color) { c.c[0] = color[0]; c.c[1] = color[1]; c.c[2] = color[2]; c.c[3] = color[3]; }

    while (*text && offset < vbuf_size) {
        if (*text == '\n') {
            y += 12;
            x = start_x;
        } else {
            unsigned char advance = stb_easy_font_charinfo[*text-32].advance;
            float y_ch = advance & 16 ? y+1 : y;
            int h_seg, v_seg, num_h, num_v;
            h_seg = stb_easy_font_charinfo[*text-32  ].h_seg;
            v_seg = stb_easy_font_charinfo[*text-32  ].v_seg;
            num_h = stb_easy_font_charinfo[*text-32+1].h_seg - h_seg;
            num_v = stb_easy_font_charinfo[*text-32+1].v_seg - v_seg;
            offset = stb_easy_font_draw_segs(x, y_ch, &stb_easy_font_hseg[h_seg], num_h, 0, c, vbuf, vbuf_size, offset);
            offset = stb_easy_font_draw_segs(x, y_ch, &stb_easy_font_vseg[v_seg], num_v, 1, c, vbuf, vbuf_size, offset);
            x += advance & 15;
            x += stb_easy_font_spacing_val;
        }
        ++text;
    }
    return (unsigned) offset/64;
}

static int stb_easy_font_width(char *text)
{
    float len = 0;
    float max_len = 0;
    while (*text) {
        if (*text == '\n') {
            if (len > max_len) max_len = len;
            len = 0;
        } else {
            len += stb_easy_font_charinfo[*text-32].advance & 15;
            len += stb_easy_font_spacing_val;
        }
        ++text;
    }
    if (len > max_len) max_len = len;
    return (int) ceil(max_len);
}

static int stb_easy_font_height(char *text)
{
    float y = 0;
    int nonempty_line=0;
    while (*text) {
        if (*text == '\n') {
            y += 12;
            nonempty_line = 0;
        } else {
            nonempty_line = 1;
        }
        ++text;
    }
    return (int) ceil(y + (nonempty_line ? 12 : 0));
}
#endif
