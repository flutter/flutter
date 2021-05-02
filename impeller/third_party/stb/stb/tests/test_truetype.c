#include "stb_rect_pack.h"
#define STB_TRUETYPE_IMPLEMENTATION
#include "stb_truetype.h"
#include "stb_image_write.h"

#include <stdio.h>

char ttf_buffer[1<<25];
unsigned char output[512*100];

#ifdef TT_TEST

void debug(void)
{
   stbtt_fontinfo font;
   fread(ttf_buffer, 1, 1<<25, fopen("c:/x/lm/LiberationMono-Regular.ttf", "rb"));
   stbtt_InitFont(&font, ttf_buffer, 0);

   stbtt_MakeGlyphBitmap(&font, output, 6, 9, 512, 5.172414E-03f, 5.172414E-03f, 54);
}

#define BITMAP_W  256
#define BITMAP_H  512
unsigned char temp_bitmap[BITMAP_H][BITMAP_W];
stbtt_bakedchar cdata[256*2]; // ASCII 32..126 is 95 glyphs
stbtt_packedchar pdata[256*2];

int main(int argc, char **argv)
{
   stbtt_fontinfo font;
   unsigned char *bitmap;
   int w,h,i,j,c = (argc > 1 ? atoi(argv[1]) : 34807), s = (argc > 2 ? atoi(argv[2]) : 32);

   //debug();

   // @TODO: why is minglui.ttc failing? 
   fread(ttf_buffer, 1, 1<<25, fopen(argc > 3 ? argv[3] : "c:/windows/fonts/mingliu.ttc", "rb"));

   //fread(ttf_buffer, 1, 1<<25, fopen(argc > 3 ? argv[3] : "c:/x/DroidSansMono.ttf", "rb"));
   {
      static stbtt_pack_context pc;
      static stbtt_packedchar cd[256];
      static unsigned char atlas[1024*1024];

      stbtt_PackBegin(&pc, atlas, 1024,1024,1024,1,NULL);
      stbtt_PackFontRange(&pc, ttf_buffer, 0, 32.0, 0, 256, cd);
      stbtt_PackEnd(&pc);
   }

#if 0
   stbtt_BakeFontBitmap(ttf_buffer,stbtt_GetFontOffsetForIndex(ttf_buffer,0), 40.0, temp_bitmap[0],BITMAP_W,BITMAP_H, 32,96, cdata); // no guarantee this fits!
   stbi_write_png("fonttest1.png", BITMAP_W, BITMAP_H, 1, temp_bitmap, 0);

   {
      stbtt_pack_context pc;
      stbtt_PackBegin(&pc, temp_bitmap[0], BITMAP_W, BITMAP_H, 0, 1, NULL);
      stbtt_PackFontRange(&pc, ttf_buffer, 0, 20.0, 32, 95, pdata);
      stbtt_PackFontRange(&pc, ttf_buffer, 0, 20.0, 0xa0, 0x100-0xa0, pdata);
      stbtt_PackEnd(&pc);
      stbi_write_png("fonttest2.png", BITMAP_W, BITMAP_H, 1, temp_bitmap, 0);
   }

   {
      stbtt_pack_context pc;
      stbtt_pack_range pr[2];
      stbtt_PackBegin(&pc, temp_bitmap[0], BITMAP_W, BITMAP_H, 0, 1, NULL);

      pr[0].chardata_for_range = pdata;
      pr[0].first_unicode_char_in_range = 32;
      pr[0].num_chars_in_range = 95;
      pr[0].font_size = 20.0f;
      pr[1].chardata_for_range = pdata+256;
      pr[1].first_unicode_char_in_range = 0xa0;
      pr[1].num_chars_in_range = 0x100 - 0xa0;
      pr[1].font_size = 20.0f;

      stbtt_PackSetOversampling(&pc, 2, 2);
      stbtt_PackFontRanges(&pc, ttf_buffer, 0, pr, 2);
      stbtt_PackEnd(&pc);
      stbi_write_png("fonttest3.png", BITMAP_W, BITMAP_H, 1, temp_bitmap, 0);
   }
   return 0;
#endif

   stbtt_InitFont(&font, ttf_buffer, stbtt_GetFontOffsetForIndex(ttf_buffer,0));
   bitmap = stbtt_GetCodepointBitmap(&font, 0,stbtt_ScaleForPixelHeight(&font, (float)s), c, &w, &h, 0,0);

   for (j=0; j < h; ++j) {
      for (i=0; i < w; ++i)
         putchar(" .:ioVM@"[bitmap[j*w+i]>>5]);
      putchar('\n');
   }
   return 0;
}
#endif
