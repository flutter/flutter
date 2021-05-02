#define STB_VORBIS_HEADER_ONLY
#include "stb_vorbis.c"
#include "stb.h"

extern void stb_vorbis_dumpmem(void);

#ifdef VORBIS_TEST
int main(int argc, char **argv)
{
   size_t memlen;
   unsigned char *mem = stb_fileu("c:/x/sketch008.ogg", &memlen);
   int chan, samplerate;
   short *output;
   int samples = stb_vorbis_decode_memory(mem, memlen, &chan, &samplerate, &output);
   stb_filewrite("c:/x/sketch008.raw", output, samples*4);
   return 0;
}
#endif
