/*
 * Fill Window with SSE2-optimized hash shifting
 *
 * Copyright (C) 2013 Intel Corporation
 * Authors:
 *  Arjan van de Ven    <arjan@linux.intel.com>
 *  Jim Kukunas         <james.t.kukunas@linux.intel.com>
 *
 * For conditions of distribution and use, see copyright notice in zlib.h
 */

#include "deflate.h"

#ifdef DEFLATE_FILL_WINDOW_SSE2

#define UPDATE_HASH(s,h,i) \
    {\
        if (s->level < 6) { \
            h = (3483 * (s->window[i]) +\
                 23081* (s->window[i+1]) +\
                 6954 * (s->window[i+2]) +\
                 20947* (s->window[i+3])) & s->hash_mask;\
        } else {\
            h = (25881* (s->window[i]) +\
                 24674* (s->window[i+1]) +\
                 25811* (s->window[i+2])) & s->hash_mask;\
        }\
    }\

extern int deflate_read_buf OF((z_streamp strm, Bytef *buf, unsigned size));

#include <immintrin.h>

void fill_window_sse(deflate_state *s)
{
    const __m128i xmm_wsize = _mm_set1_epi16(s->w_size);

    register unsigned n;
    register Posf *p;
    unsigned more;    /* Amount of free space at the end of the window. */
    uInt wsize = s->w_size;

    Assert(s->lookahead < MIN_LOOKAHEAD, "already enough lookahead");

    do {
        more = (unsigned)(s->window_size -(ulg)s->lookahead -(ulg)s->strstart);

        /* Deal with !@#$% 64K limit: */
        if (sizeof(int) <= 2) {
            if (more == 0 && s->strstart == 0 && s->lookahead == 0) {
                more = wsize;

            } else if (more == (unsigned)(-1)) {
                /* Very unlikely, but possible on 16 bit machine if
                 * strstart == 0 && lookahead == 1 (input done a byte at time)
                 */
                more--;
            }
        }

        /* If the window is almost full and there is insufficient lookahead,
         * move the upper half to the lower one to make room in the upper half.
         */
        if (s->strstart >= wsize+MAX_DIST(s)) {

            zmemcpy(s->window, s->window+wsize, (unsigned)wsize);
            s->match_start -= wsize;
            s->strstart    -= wsize; /* we now have strstart >= MAX_DIST */
            s->block_start -= (long) wsize;

            /* Slide the hash table (could be avoided with 32 bit values
               at the expense of memory usage). We slide even when level == 0
               to keep the hash table consistent if we switch back to level > 0
               later. (Using level 0 permanently is not an optimal usage of
               zlib, so we don't care about this pathological case.)
             */
            n = s->hash_size;
            p = &s->head[n];
            p -= 8;
            do {
                __m128i value, result;

                value = _mm_loadu_si128((__m128i *)p);
                result = _mm_subs_epu16(value, xmm_wsize);
                _mm_storeu_si128((__m128i *)p, result);

                p -= 8;
                n -= 8;
            } while (n > 0);

            n = wsize;
#ifndef FASTEST
            p = &s->prev[n];
            p -= 8;
            do {
                __m128i value, result;

                value = _mm_loadu_si128((__m128i *)p);
                result = _mm_subs_epu16(value, xmm_wsize);
                _mm_storeu_si128((__m128i *)p, result);

                p -= 8;
                n -= 8;
            } while (n > 0);
#endif
            more += wsize;
        }
        if (s->strm->avail_in == 0) break;

        /* If there was no sliding:
         *    strstart <= WSIZE+MAX_DIST-1 && lookahead <= MIN_LOOKAHEAD - 1 &&
         *    more == window_size - lookahead - strstart
         * => more >= window_size - (MIN_LOOKAHEAD-1 + WSIZE + MAX_DIST-1)
         * => more >= window_size - 2*WSIZE + 2
         * In the BIG_MEM or MMAP case (not yet supported),
         *   window_size == input_size + MIN_LOOKAHEAD  &&
         *   strstart + s->lookahead <= input_size => more >= MIN_LOOKAHEAD.
         * Otherwise, window_size == 2*WSIZE so more >= 2.
         * If there was sliding, more >= WSIZE. So in all cases, more >= 2.
         */
        Assert(more >= 2, "more < 2");

        n = deflate_read_buf(s->strm,
                             s->window + s->strstart + s->lookahead,
                             more);
        s->lookahead += n;

        /* Initialize the hash value now that we have some input: */
        if (s->lookahead >= MIN_MATCH) {
            uInt str = s->strstart;
            s->ins_h = s->window[str];
            if (str >= 1)
                UPDATE_HASH(s, s->ins_h, str + 1 - (MIN_MATCH-1));
#if MIN_MATCH != 3
            Call UPDATE_HASH() MIN_MATCH-3 more times
#endif
        }
        /* If the whole input has less than MIN_MATCH bytes, ins_h is garbage,
         * but this is not important since only literal bytes will be emitted.
         */

    } while (s->lookahead < MIN_LOOKAHEAD && s->strm->avail_in != 0);

    /* If the WIN_INIT bytes after the end of the current data have never been
     * written, then zero those bytes in order to avoid memory check reports of
     * the use of uninitialized (or uninitialised as Julian writes) bytes by
     * the longest match routines.  Update the high water mark for the next
     * time through here.  WIN_INIT is set to MAX_MATCH since the longest match
     * routines allow scanning to strstart + MAX_MATCH, ignoring lookahead.
     */
    if (s->high_water < s->window_size) {
        ulg curr = s->strstart + (ulg)(s->lookahead);
        ulg init;

        if (s->high_water < curr) {
            /* Previous high water mark below current data -- zero WIN_INIT
             * bytes or up to end of window, whichever is less.
             */
            init = s->window_size - curr;
            if (init > WIN_INIT)
                init = WIN_INIT;
            zmemzero(s->window + curr, (unsigned)init);
            s->high_water = curr + init;
        }
        else if (s->high_water < (ulg)curr + WIN_INIT) {
            /* High water mark at or above current data, but below current data
             * plus WIN_INIT -- zero out to current data plus WIN_INIT, or up
             * to end of window, whichever is less.
             */
            init = (ulg)curr + WIN_INIT - s->high_water;
            if (init > s->window_size - s->high_water)
                init = s->window_size - s->high_water;
            zmemzero(s->window + s->high_water, (unsigned)init);
            s->high_water += init;
        }
    }

    Assert((ulg)s->strstart <= s->window_size - MIN_LOOKAHEAD,
           "not enough room for search");
}

#endif  /* DEFLATE_FILL_WINDOW_SSE2 */
