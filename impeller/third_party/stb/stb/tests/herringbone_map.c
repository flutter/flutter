#include <stdio.h>

#define STB_HBWANG_MAX_X  500
#define STB_HBWANG_MAX_Y  500

#define STB_HERRINGBONE_WANG_TILE_IMPLEMENTATION
#include "stb_herringbone_wang_tile.h"

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

int main(int argc, char **argv)
{
   if (argc < 5) {
      fprintf(stderr, "Usage: herringbone_map {inputfile} {output-width} {output-height} {outputfile}\n");
      return 1;
   } else {
      char *filename = argv[1];
      int out_w = atoi(argv[2]);
      int out_h = atoi(argv[3]);
      char *outfile = argv[4];

      unsigned char *pixels, *out_pixels;
      stbhw_tileset ts;
      int w,h;

      pixels = stbi_load(filename, &w, &h, 0, 3);
      if (pixels == 0) {
         fprintf(stderr, "Couldn't open input file '%s'\n", filename);
			exit(1);
      }

      if (!stbhw_build_tileset_from_image(&ts, pixels, w*3, w, h)) {
         fprintf(stderr, "Error: %s\n", stbhw_get_last_error());
         return 1;
      }

      free(pixels);

      #ifdef DEBUG_OUTPUT
      {
         int i,j,k;
         // add blue borders to top-left edges of the tiles
         int hstride = (ts.short_side_len*2)*3;
         int vstride = (ts.short_side_len  )*3;
         for (i=0; i < ts.num_h_tiles; ++i) {
            unsigned char *pix = ts.h_tiles[i]->pixels;
            for (j=0; j < ts.short_side_len*2; ++j)
               for (k=0; k < 3; ++k)
                  pix[j*3+k] = (pix[j*3+k]*0.5+100+k*75)/1.5;
            for (j=1; j < ts.short_side_len; ++j)
               for (k=0; k < 3; ++k)
                  pix[j*hstride+k] = (pix[j*hstride+k]*0.5+100+k*75)/1.5;
         }
         for (i=0; i < ts.num_v_tiles; ++i) {
            unsigned char *pix = ts.v_tiles[i]->pixels;
            for (j=0; j < ts.short_side_len; ++j)
               for (k=0; k < 3; ++k)
                  pix[j*3+k] = (pix[j*3+k]*0.5+100+k*75)/1.5;
            for (j=1; j < ts.short_side_len*2; ++j)
               for (k=0; k < 3; ++k)
                  pix[j*vstride+k] = (pix[j*vstride+k]*0.5+100+k*75)/1.5;
         }
      }
      #endif

      out_pixels = malloc(out_w * out_h * 3);

      if (!stbhw_generate_image(&ts, NULL, out_pixels, out_w*3, out_w, out_h)) {
         fprintf(stderr, "Error: %s\n", stbhw_get_last_error());
         return 1;
      }

      stbi_write_png(argv[4], out_w, out_h, 3, out_pixels, out_w*3);
      free(out_pixels);

      stbhw_free_tileset(&ts);
      return 0;
   }
}