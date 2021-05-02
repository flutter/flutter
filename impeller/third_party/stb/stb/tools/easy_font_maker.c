// This program was used to encode the data for stb_simple_font.h

#define STB_DEFINE
#include "stb.h"
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

int w,h;
uint8 *data;

int last_x[2], last_y[2];
int num_seg[2], non_empty;
#if 0
typedef struct
{
   unsigned short first_segment;
   unsigned char advance;
} chardata;

typedef struct
{
   unsigned char x:4;
   unsigned char y:4;
   unsigned char len:3;
   unsigned char dir:1;
} segment;

segment *segments;

void add_seg(int x, int y, int len, int horizontal)
{
   segment s;
   s.x = x;
   s.y = y;
   s.len = len;
   s.dir = horizontal;
   assert(s.x == x);
   assert(s.y == y);
   assert(s.len == len);
   stb_arr_push(segments, s);
}
#else
typedef struct
{
   unsigned char first_segment:8;
   unsigned char first_v_segment:8;
   unsigned char advance:5;
   unsigned char voff:1;
} chardata;

#define X_LIMIT 1
#define LEN_LIMIT 7

typedef struct
{
   unsigned char dx:1;
   unsigned char y:4;
   unsigned char len:3;
} segment;

segment *segments;
segment *vsegments;

void add_seg(int x, int y, int len, int horizontal)
{
   segment s;

   while (x - last_x[horizontal] > X_LIMIT) {
      add_seg(last_x[horizontal] + X_LIMIT, 0, 0, horizontal);
   }
   while (len > LEN_LIMIT) {
      add_seg(x, y, LEN_LIMIT, horizontal);
      len -= LEN_LIMIT;
      x += LEN_LIMIT*horizontal;
      y += LEN_LIMIT*!horizontal;
   }

   s.dx = x - last_x[horizontal];
   s.y = y;
   s.len = len;
   non_empty += len != 0;
   //assert(s.x == x);
   assert(s.y == y);
   assert(s.len == len);
   ++num_seg[horizontal];
   if (horizontal)
      stb_arr_push(segments, s);
   else
      stb_arr_push(vsegments, s);
   last_x[horizontal] = x;
}

void print_segments(segment *s)
{
   int i, hpos;
   printf("   ");
   hpos = 4;
   for (i=0; i < stb_arr_len(s); ++i) {
      // repack for portability
      unsigned char seg = s[i].len + s[i].dx*8 + s[i].y*16;
      hpos += printf("%d,", seg);
      if (hpos > 72 && i+1 < stb_arr_len(s)) {
         hpos = 4;
         printf("\n    ");
      }
   }
   printf("\n");
}

#endif

chardata charinfo[128];

int parse_char(int x, chardata *c, int offset)
{
   int start_x = x, end_x, top_y = 0, y;

   c->first_segment = stb_arr_len(segments);
   c->first_v_segment = stb_arr_len(vsegments) - offset;
   assert(c->first_segment == stb_arr_len(segments));
   assert(c->first_v_segment + offset == stb_arr_len(vsegments));

   // find advance distance
   end_x = x+1;
   while (data[end_x*3] == 255)
      ++end_x;
   c->advance = end_x - start_x + 1;

   last_x[0] = last_x[1] = 0;
   last_y[0] = last_y[1] = 0;

   for (y=2; y < h; ++y) {
      for (x=start_x; x < end_x; ++x) {
         if (data[y*3*w+x*3+1] < 255) {
            top_y = y;
            break;
         }
      }
      if (top_y)
         break;
   }
   c->voff = top_y > 2;
   if (top_y > 2) 
      top_y = 3;

   for (x=start_x; x < end_x; ++x) {
      int y;
      for (y=2; y < h; ++y) {
         if (data[y*3*w+x*3+1] < 255) {
            if (data[y*3*w+x*3+0] == 255) { // red
               int len=0;
               while (y+len < h && data[(y+len)*3*w+x*3+0] == 255 && data[(y+len)*3*w+x*3+1] == 0) {
                  data[(y+len)*3*w+x*3+0] = 0;
                  ++len;
               }
               add_seg(x-start_x,y-top_y,len,0);
            }
            if (data[y*3*w+x*3+2] == 255) { // blue
               int len=0;
               while (x+len < end_x && data[y*3*w+(x+len)*3+2] == 255 && data[y*3*w+(x+len)*3+1] == 0) {
                  data[y*3*w+(x+len)*3+2] = 0;
                  ++len;
               }
               add_seg(x-start_x,y-top_y,len,1);
            }
         }
      }
   }
   return end_x;
}


int main(int argc, char **argv)
{
   int c, x=0;
   data = stbi_load("easy_font_raw.png", &w, &h, 0, 3);
   for (c=32; c < 127; ++c) {
      x = parse_char(x, &charinfo[c], 0);
      printf("%3d -- %3d %3d\n", c, charinfo[c].first_segment, charinfo[c].first_v_segment);
   }
   printf("===\n");
   printf("%d %d %d\n", num_seg[0], num_seg[1], non_empty);
   printf("%d\n", sizeof(segments[0]) * stb_arr_len(segments));
   printf("%d\n", sizeof(segments[0]) * stb_arr_len(segments) + sizeof(segments[0]) * stb_arr_len(vsegments) + sizeof(charinfo[32])*95);

   printf("struct {\n"
          "    unsigned char advance;\n"
          "    unsigned char h_seg;\n"
          "    unsigned char v_seg;\n"
          "} stb_easy_font_charinfo[96] = {\n");
   charinfo[c].first_segment = stb_arr_len(segments);
   charinfo[c].first_v_segment = stb_arr_len(vsegments);
   for (c=32; c < 128; ++c) {
      if ((c & 3) == 0) printf("    ");
      printf("{ %2d,%3d,%3d },",
         charinfo[c].advance + 16*charinfo[c].voff,
         charinfo[c].first_segment,
         charinfo[c].first_v_segment);
      if ((c & 3) == 3) printf("\n"); else printf("  ");
   }
   printf("};\n\n");

   printf("unsigned char stb_easy_font_hseg[%d] = {\n", stb_arr_len(segments));
      print_segments(segments);
   printf("};\n\n");

   printf("unsigned char stb_easy_font_vseg[%d] = {\n", stb_arr_len(vsegments));
      print_segments(vsegments);
   printf("};\n");
   return 0;
}
