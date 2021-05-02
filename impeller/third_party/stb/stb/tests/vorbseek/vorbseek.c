#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#define STB_VORBIS_HEADER_ONLY
#include "stb_vorbis.c"

#define SAMPLES_TO_TEST 3000

int test_count  [5] = { 5000, 3000, 2000, 50000, 50000 };
int test_spacing[5] = {    1,  111, 3337,  7779, 72717 };

int try_seeking(stb_vorbis *v, unsigned int pos, short *output, unsigned int num_samples)
{
   int count;
   short samples[SAMPLES_TO_TEST*2];
   assert(pos <= num_samples);

   if (!stb_vorbis_seek(v, pos)) {
      fprintf(stderr, "Seek to %u returned error from stb_vorbis\n", pos);
      return 0;
   }

   count = stb_vorbis_get_samples_short_interleaved(v, 2, samples, SAMPLES_TO_TEST*2);

   if (count > (int) (num_samples - pos)) {
      fprintf(stderr, "Seek to %u allowed decoding %d samples when only %d should have been valid.\n",
            pos, count, (int) (num_samples - pos));
      return 0;
   }

   if (count < SAMPLES_TO_TEST && count < (int) (num_samples - pos)) {
      fprintf(stderr, "Seek to %u only decoded %d samples of %d attempted when at least %d should have been valid.\n",
         pos, count, SAMPLES_TO_TEST, num_samples - pos);
      return 0;                      
   }

   if (0 != memcmp(samples, output + pos*2, count*2)) {
      int k;
      for (k=0; k < SAMPLES_TO_TEST*2; ++k) {
         if (samples[k] != output[k]) {
            fprintf(stderr, "Seek to %u produced incorrect samples starting at sample %u (short #%d in buffer).\n",
                    pos, pos + (k/2), k);
            break;
         }
      }
      assert(k != SAMPLES_TO_TEST*2);
      return 0;
   }

   return 1;
}

int main(int argc, char **argv)
{
   int num_chan, samprate;
   int i, j, test, phase;
   short *output;

   if (argc == 1) {
      fprintf(stderr, "Usage: vorbseek {vorbisfile} [{vorbisfile]*]\n");
      fprintf(stderr, "Tests various seek offsets to make sure they're sample exact.\n");
      return 0;
   }

   #if 0
   {
      // check that outofmem occurs correctly
      stb_vorbis_alloc va;
      va.alloc_buffer = malloc(1024*1024);
      for (i=0; i < 1024*1024; i += 10) {
         int error=0;
         stb_vorbis *v;
         va.alloc_buffer_length_in_bytes = i;
         v = stb_vorbis_open_filename(argv[1], &error, &va);
         if (v != NULL)
            break;
         printf("Error %d at %d\n", error, i);
      }
   }
   #endif

   for (j=1; j < argc; ++j) {
      unsigned int successes=0, attempts = 0;
      unsigned int num_samples = stb_vorbis_decode_filename(argv[j], &num_chan, &samprate, &output);

      break;

      if (num_samples == 0xffffffff) {
         fprintf(stderr, "Error: couldn't open file or not vorbis file: %s\n", argv[j]);
         goto fail;
      }

      if (num_chan != 2) {
         fprintf(stderr, "vorbseek testing only works with files with 2 channels, %s has %d\n", argv[j], num_chan);
         goto fail;
      }

      for (test=0; test < 5; ++test) {
         int error;
         stb_vorbis *v = stb_vorbis_open_filename(argv[j], &error, NULL);
         if (v == NULL) {
            fprintf(stderr, "Couldn't re-open %s for test #%d\n", argv[j], test);
            goto fail;
         }
         for (phase=0; phase < 3; ++phase) {
            unsigned int base = phase == 0 ? 0 : phase == 1 ? num_samples - test_count[test]*test_spacing[test] : num_samples/3;
            for (i=0; i < test_count[test]; ++i) {
               unsigned int pos = base + i*test_spacing[test];
               if (pos > num_samples) // this also catches underflows
                  continue;
               successes += try_seeking(v, pos, output, num_samples);
               attempts += 1;
            }
         }
         stb_vorbis_close(v);
      }
      printf("%d of %d seeks failed in %s (%d samples)\n", attempts-successes, attempts, argv[j], num_samples);
      free(output);
   }
   return 0;
  fail:
   return 1;
}