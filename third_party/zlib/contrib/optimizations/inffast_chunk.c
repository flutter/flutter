/* inffast_chunk.c -- fast decoding
 * Copyright (C) 1995-2017 Mark Adler
 * For conditions of distribution and use, see copyright notice in zlib.h
 */

#include "zutil.h"
#include "inftrees.h"
#include "inflate.h"
#include "contrib/optimizations/inffast_chunk.h"
#include "contrib/optimizations/chunkcopy.h"

#ifdef ASMINF
#  pragma message("Assembler code may have bugs -- use at your own risk")
#else

/*
   Decode literal, length, and distance codes and write out the resulting
   literal and match bytes until either not enough input or output is
   available, an end-of-block is encountered, or a data error is encountered.
   When large enough input and output buffers are supplied to inflate(), for
   example, a 16K input buffer and a 64K output buffer, more than 95% of the
   inflate() execution time is spent in this routine.

   Entry assumptions:

        state->mode == LEN
        strm->avail_in >= INFLATE_FAST_MIN_INPUT (6 or 8 bytes)
        strm->avail_out >= INFLATE_FAST_MIN_OUTPUT (258 bytes)
        start >= strm->avail_out
        state->bits < 8
        (state->hold >> state->bits) == 0
        strm->next_out[0..strm->avail_out] does not overlap with
              strm->next_in[0..strm->avail_in]
        strm->state->window is allocated with an additional
              CHUNKCOPY_CHUNK_SIZE-1 bytes of padding beyond strm->state->wsize

   On return, state->mode is one of:

        LEN -- ran out of enough output space or enough available input
        TYPE -- reached end of block code, inflate() to interpret next block
        BAD -- error in block data

   Notes:

    INFLATE_FAST_MIN_INPUT: 6 or 8 bytes

    - The maximum input bits used by a length/distance pair is 15 bits for the
      length code, 5 bits for the length extra, 15 bits for the distance code,
      and 13 bits for the distance extra.  This totals 48 bits, or six bytes.
      Therefore if strm->avail_in >= 6, then there is enough input to avoid
      checking for available input while decoding.

    - The wide input data reading option reads 64 input bits at a time. Thus,
      if strm->avail_in >= 8, then there is enough input to avoid checking for
      available input while decoding. Reading consumes the input with:

          hold |= read64le(in) << bits;
          in += 6;
          bits += 48;

      reporting 6 bytes of new input because |bits| is 0..15 (2 bytes rounded
      up, worst case) and 6 bytes is enough to decode as noted above. At exit,
      hold &= (1U << bits) - 1 drops excess input to keep the invariant:

          (state->hold >> state->bits) == 0

    INFLATE_FAST_MIN_OUTPUT: 258 bytes

    - The maximum bytes that a single length/distance pair can output is 258
      bytes, which is the maximum length that can be coded.  inflate_fast()
      requires strm->avail_out >= 258 for each loop to avoid checking for
      available output space while decoding.
 */
void ZLIB_INTERNAL inflate_fast_chunk_(strm, start)
z_streamp strm;
unsigned start;         /* inflate()'s starting value for strm->avail_out */
{
    struct inflate_state FAR *state;
    z_const unsigned char FAR *in;      /* local strm->next_in */
    z_const unsigned char FAR *last;    /* have enough input while in < last */
    unsigned char FAR *out;     /* local strm->next_out */
    unsigned char FAR *beg;     /* inflate()'s initial strm->next_out */
    unsigned char FAR *end;     /* while out < end, enough space available */
    unsigned char FAR *limit;   /* safety limit for chunky copies */
#ifdef INFLATE_STRICT
    unsigned dmax;              /* maximum distance from zlib header */
#endif
    unsigned wsize;             /* window size or zero if not using window */
    unsigned whave;             /* valid bytes in the window */
    unsigned wnext;             /* window write index */
    unsigned char FAR *window;  /* allocated sliding window, if wsize != 0 */
    inflate_holder_t hold;      /* local strm->hold */
    unsigned bits;              /* local strm->bits */
    code const FAR *lcode;      /* local strm->lencode */
    code const FAR *dcode;      /* local strm->distcode */
    unsigned lmask;             /* mask for first level of length codes */
    unsigned dmask;             /* mask for first level of distance codes */
    code here;                  /* retrieved table entry */
    unsigned op;                /* code bits, operation, extra bits, or */
                                /*  window position, window bytes to copy */
    unsigned len;               /* match length, unused bytes */
    unsigned dist;              /* match distance */
    unsigned char FAR *from;    /* where to copy match from */

    /* copy state to local variables */
    state = (struct inflate_state FAR *)strm->state;
    in = strm->next_in;
    last = in + (strm->avail_in - (INFLATE_FAST_MIN_INPUT - 1));
    out = strm->next_out;
    beg = out - (start - strm->avail_out);
    end = out + (strm->avail_out - (INFLATE_FAST_MIN_OUTPUT - 1));
    limit = out + strm->avail_out;
#ifdef INFLATE_STRICT
    dmax = state->dmax;
#endif
    wsize = state->wsize;
    whave = state->whave;
    wnext = (state->wnext == 0 && whave >= wsize) ? wsize : state->wnext;
    window = state->window;
    hold = state->hold;
    bits = state->bits;
    lcode = state->lencode;
    dcode = state->distcode;
    lmask = (1U << state->lenbits) - 1;
    dmask = (1U << state->distbits) - 1;

    /* decode literals and length/distances until end-of-block or not enough
       input data or output space */
    do {
        if (bits < 15) {
#ifdef INFLATE_CHUNK_READ_64LE
            hold |= read64le(in) << bits;
            in += 6;
            bits += 48;
#else
            hold += (unsigned long)(*in++) << bits;
            bits += 8;
            hold += (unsigned long)(*in++) << bits;
            bits += 8;
#endif
        }
        here = lcode[hold & lmask];
      dolen:
        op = (unsigned)(here.bits);
        hold >>= op;
        bits -= op;
        op = (unsigned)(here.op);
        if (op == 0) {                          /* literal */
            Tracevv((stderr, here.val >= 0x20 && here.val < 0x7f ?
                    "inflate:         literal '%c'\n" :
                    "inflate:         literal 0x%02x\n", here.val));
            *out++ = (unsigned char)(here.val);
        }
        else if (op & 16) {                     /* length base */
            len = (unsigned)(here.val);
            op &= 15;                           /* number of extra bits */
            if (op) {
                if (bits < op) {
#ifdef INFLATE_CHUNK_READ_64LE
                    hold |= read64le(in) << bits;
                    in += 6;
                    bits += 48;
#else
                    hold += (unsigned long)(*in++) << bits;
                    bits += 8;
#endif
                }
                len += (unsigned)hold & ((1U << op) - 1);
                hold >>= op;
                bits -= op;
            }
            Tracevv((stderr, "inflate:         length %u\n", len));
            if (bits < 15) {
#ifdef INFLATE_CHUNK_READ_64LE
                hold |= read64le(in) << bits;
                in += 6;
                bits += 48;
#else
                hold += (unsigned long)(*in++) << bits;
                bits += 8;
                hold += (unsigned long)(*in++) << bits;
                bits += 8;
#endif
            }
            here = dcode[hold & dmask];
          dodist:
            op = (unsigned)(here.bits);
            hold >>= op;
            bits -= op;
            op = (unsigned)(here.op);
            if (op & 16) {                      /* distance base */
                dist = (unsigned)(here.val);
                op &= 15;                       /* number of extra bits */
                if (bits < op) {
#ifdef INFLATE_CHUNK_READ_64LE
                    hold |= read64le(in) << bits;
                    in += 6;
                    bits += 48;
#else
                    hold += (unsigned long)(*in++) << bits;
                    bits += 8;
                    if (bits < op) {
                        hold += (unsigned long)(*in++) << bits;
                        bits += 8;
                    }
#endif
                }
                dist += (unsigned)hold & ((1U << op) - 1);
#ifdef INFLATE_STRICT
                if (dist > dmax) {
                    strm->msg = (char *)"invalid distance too far back";
                    state->mode = BAD;
                    break;
                }
#endif
                hold >>= op;
                bits -= op;
                Tracevv((stderr, "inflate:         distance %u\n", dist));
                op = (unsigned)(out - beg);     /* max distance in output */
                if (dist > op) {                /* see if copy from window */
                    op = dist - op;             /* distance back in window */
                    if (op > whave) {
                        if (state->sane) {
                            strm->msg =
                                (char *)"invalid distance too far back";
                            state->mode = BAD;
                            break;
                        }
#ifdef INFLATE_ALLOW_INVALID_DISTANCE_TOOFAR_ARRR
                        if (len <= op - whave) {
                            do {
                                *out++ = 0;
                            } while (--len);
                            continue;
                        }
                        len -= op - whave;
                        do {
                            *out++ = 0;
                        } while (--op > whave);
                        if (op == 0) {
                            from = out - dist;
                            do {
                                *out++ = *from++;
                            } while (--len);
                            continue;
                        }
#endif
                    }
                    from = window;
                    if (wnext >= op) {          /* contiguous in window */
                        from += wnext - op;
                    }
                    else {                      /* wrap around window */
                        op -= wnext;
                        from += wsize - op;
                        if (op < len) {         /* some from end of window */
                            len -= op;
                            out = chunkcopy_safe(out, from, op, limit);
                            from = window;      /* more from start of window */
                            op = wnext;
                            /* This (rare) case can create a situation where
                               the first chunkcopy below must be checked.
                             */
                        }
                    }
                    if (op < len) {             /* still need some from output */
                        out = chunkcopy_safe(out, from, op, limit);
                        len -= op;
                        /* When dist is small the amount of data that can be
                           copied from the window is also small, and progress
                           towards the dangerous end of the output buffer is
                           also small.  This means that for trivial memsets and
                           for chunkunroll_relaxed() a safety check is
                           unnecessary.  However, these conditions may not be
                           entered at all, and in that case it's possible that
                           the main copy is near the end.
                          */
                        out = chunkunroll_relaxed(out, &dist, &len);
                        out = chunkcopy_safe(out, out - dist, len, limit);
                    } else {
                        /* from points to window, so there is no risk of
                           overlapping pointers requiring memset-like behaviour
                         */
                        out = chunkcopy_safe(out, from, len, limit);
                    }
                }
                else {
                    /* Whole reference is in range of current output.  No
                       range checks are necessary because we start with room
                       for at least 258 bytes of output, so unroll and roundoff
                       operations can write beyond `out+len` so long as they
                       stay within 258 bytes of `out`.
                     */
                    out = chunkcopy_lapped_relaxed(out, dist, len);
                }
            }
            else if ((op & 64) == 0) {          /* 2nd level distance code */
                here = dcode[here.val + (hold & ((1U << op) - 1))];
                goto dodist;
            }
            else {
                strm->msg = (char *)"invalid distance code";
                state->mode = BAD;
                break;
            }
        }
        else if ((op & 64) == 0) {              /* 2nd level length code */
            here = lcode[here.val + (hold & ((1U << op) - 1))];
            goto dolen;
        }
        else if (op & 32) {                     /* end-of-block */
            Tracevv((stderr, "inflate:         end of block\n"));
            state->mode = TYPE;
            break;
        }
        else {
            strm->msg = (char *)"invalid literal/length code";
            state->mode = BAD;
            break;
        }
    } while (in < last && out < end);

    /* return unused bytes (on entry, bits < 8, so in won't go too far back) */
    len = bits >> 3;
    in -= len;
    bits -= len << 3;
    hold &= (1U << bits) - 1;

    /* update state and return */
    strm->next_in = in;
    strm->next_out = out;
    strm->avail_in = (unsigned)(in < last ?
        (INFLATE_FAST_MIN_INPUT - 1) + (last - in) :
        (INFLATE_FAST_MIN_INPUT - 1) - (in - last));
    strm->avail_out = (unsigned)(out < end ?
        (INFLATE_FAST_MIN_OUTPUT - 1) + (end - out) :
        (INFLATE_FAST_MIN_OUTPUT - 1) - (out - end));
    state->hold = hold;
    state->bits = bits;

    Assert((state->hold >> state->bits) == 0, "invalid input data state");
    return;
}

/*
   inflate_fast() speedups that turned out slower (on a PowerPC G3 750CXe):
   - Using bit fields for code structure
   - Different op definition to avoid & for extra bits (do & for table bits)
   - Three separate decoding do-loops for direct, window, and wnext == 0
   - Special case for distance > 1 copies to do overlapped load and store copy
   - Explicit branch predictions (based on measured branch probabilities)
   - Deferring match copy and interspersed it with decoding subsequent codes
   - Swapping literal/length else
   - Swapping window/direct else
   - Larger unrolled copy loops (three is about right)
   - Moving len -= 3 statement into middle of loop
 */

#endif /* !ASMINF */
