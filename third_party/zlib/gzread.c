/* gzread.c -- zlib functions for reading gzip files
 * Copyright (C) 2004, 2005, 2010 Mark Adler
 * For conditions of distribution and use, see copyright notice in zlib.h
 */

#include "gzguts.h"

/* Local functions */
local int gz_load OF((gz_statep, unsigned char *, unsigned, unsigned *));
local int gz_avail OF((gz_statep));
local int gz_next4 OF((gz_statep, unsigned long *));
local int gz_head OF((gz_statep));
local int gz_decomp OF((gz_statep));
local int gz_make OF((gz_statep));
local int gz_skip OF((gz_statep, z_off64_t));

/* Use read() to load a buffer -- return -1 on error, otherwise 0.  Read from
   state->fd, and update state->eof, state->err, and state->msg as appropriate.
   This function needs to loop on read(), since read() is not guaranteed to
   read the number of bytes requested, depending on the type of descriptor. */
local int gz_load(state, buf, len, have)
    gz_statep state;
    unsigned char *buf;
    unsigned len;
    unsigned *have;
{
    int ret;

    *have = 0;
    do {
        ret = read(state->fd, buf + *have, len - *have);
        if (ret <= 0)
            break;
        *have += ret;
    } while (*have < len);
    if (ret < 0) {
        gz_error(state, Z_ERRNO, zstrerror());
        return -1;
    }
    if (ret == 0)
        state->eof = 1;
    return 0;
}

/* Load up input buffer and set eof flag if last data loaded -- return -1 on
   error, 0 otherwise.  Note that the eof flag is set when the end of the input
   file is reached, even though there may be unused data in the buffer.  Once
   that data has been used, no more attempts will be made to read the file.
   gz_avail() assumes that strm->avail_in == 0. */
local int gz_avail(state)
    gz_statep state;
{
    z_streamp strm = &(state->strm);

    if (state->err != Z_OK)
        return -1;
    if (state->eof == 0) {
        if (gz_load(state, state->in, state->size,
                (unsigned *)&(strm->avail_in)) == -1)
            return -1;
        strm->next_in = state->in;
    }
    return 0;
}

/* Get next byte from input, or -1 if end or error. */
#define NEXT() ((strm->avail_in == 0 && gz_avail(state) == -1) ? -1 : \
                (strm->avail_in == 0 ? -1 : \
                 (strm->avail_in--, *(strm->next_in)++)))

/* Get a four-byte little-endian integer and return 0 on success and the value
   in *ret.  Otherwise -1 is returned and *ret is not modified. */
local int gz_next4(state, ret)
    gz_statep state;
    unsigned long *ret;
{
    int ch;
    unsigned long val;
    z_streamp strm = &(state->strm);

    val = NEXT();
    val += (unsigned)NEXT() << 8;
    val += (unsigned long)NEXT() << 16;
    ch = NEXT();
    if (ch == -1)
        return -1;
    val += (unsigned long)ch << 24;
    *ret = val;
    return 0;
}

/* Look for gzip header, set up for inflate or copy.  state->have must be zero.
   If this is the first time in, allocate required memory.  state->how will be
   left unchanged if there is no more input data available, will be set to COPY
   if there is no gzip header and direct copying will be performed, or it will
   be set to GZIP for decompression, and the gzip header will be skipped so
   that the next available input data is the raw deflate stream.  If direct
   copying, then leftover input data from the input buffer will be copied to
   the output buffer.  In that case, all further file reads will be directly to
   either the output buffer or a user buffer.  If decompressing, the inflate
   state and the check value will be initialized.  gz_head() will return 0 on
   success or -1 on failure.  Failures may include read errors or gzip header
   errors.  */
local int gz_head(state)
    gz_statep state;
{
    z_streamp strm = &(state->strm);
    int flags;
    unsigned len;

    /* allocate read buffers and inflate memory */
    if (state->size == 0) {
        /* allocate buffers */
        state->in = malloc(state->want);
        state->out = malloc(state->want << 1);
        if (state->in == NULL || state->out == NULL) {
            if (state->out != NULL)
                free(state->out);
            if (state->in != NULL)
                free(state->in);
            gz_error(state, Z_MEM_ERROR, "out of memory");
            return -1;
        }
        state->size = state->want;

        /* allocate inflate memory */
        state->strm.zalloc = Z_NULL;
        state->strm.zfree = Z_NULL;
        state->strm.opaque = Z_NULL;
        state->strm.avail_in = 0;
        state->strm.next_in = Z_NULL;
        if (inflateInit2(&(state->strm), -15) != Z_OK) {    /* raw inflate */
            free(state->out);
            free(state->in);
            state->size = 0;
            gz_error(state, Z_MEM_ERROR, "out of memory");
            return -1;
        }
    }

    /* get some data in the input buffer */
    if (strm->avail_in == 0) {
        if (gz_avail(state) == -1)
            return -1;
        if (strm->avail_in == 0)
            return 0;
    }

    /* look for the gzip magic header bytes 31 and 139 */
    if (strm->next_in[0] == 31) {
        strm->avail_in--;
        strm->next_in++;
        if (strm->avail_in == 0 && gz_avail(state) == -1)
            return -1;
        if (strm->avail_in && strm->next_in[0] == 139) {
            /* we have a gzip header, woo hoo! */
            strm->avail_in--;
            strm->next_in++;

            /* skip rest of header */
            if (NEXT() != 8) {      /* compression method */
                gz_error(state, Z_DATA_ERROR, "unknown compression method");
                return -1;
            }
            flags = NEXT();
            if (flags & 0xe0) {     /* reserved flag bits */
                gz_error(state, Z_DATA_ERROR, "unknown header flags set");
                return -1;
            }
            NEXT();                 /* modification time */
            NEXT();
            NEXT();
            NEXT();
            NEXT();                 /* extra flags */
            NEXT();                 /* operating system */
            if (flags & 4) {        /* extra field */
                len = (unsigned)NEXT();
                len += (unsigned)NEXT() << 8;
                while (len--)
                    if (NEXT() < 0)
                        break;
            }
            if (flags & 8)          /* file name */
                while (NEXT() > 0)
                    ;
            if (flags & 16)         /* comment */
                while (NEXT() > 0)
                    ;
            if (flags & 2) {        /* header crc */
                NEXT();
                NEXT();
            }
            /* an unexpected end of file is not checked for here -- it will be
               noticed on the first request for uncompressed data */

            /* set up for decompression */
            inflateReset(strm);
            strm->adler = crc32(0L, Z_NULL, 0);
            state->how = GZIP;
            state->direct = 0;
            return 0;
        }
        else {
            /* not a gzip file -- save first byte (31) and fall to raw i/o */
            state->out[0] = 31;
            state->have = 1;
        }
    }

    /* doing raw i/o, save start of raw data for seeking, copy any leftover
       input to output -- this assumes that the output buffer is larger than
       the input buffer, which also assures space for gzungetc() */
    state->raw = state->pos;
    state->next = state->out;
    if (strm->avail_in) {
        memcpy(state->next + state->have, strm->next_in, strm->avail_in);
        state->have += strm->avail_in;
        strm->avail_in = 0;
    }
    state->how = COPY;
    state->direct = 1;
    return 0;
}

/* Decompress from input to the provided next_out and avail_out in the state.
   If the end of the compressed data is reached, then verify the gzip trailer
   check value and length (modulo 2^32).  state->have and state->next are set
   to point to the just decompressed data, and the crc is updated.  If the
   trailer is verified, state->how is reset to LOOK to look for the next gzip
   stream or raw data, once state->have is depleted.  Returns 0 on success, -1
   on failure.  Failures may include invalid compressed data or a failed gzip
   trailer verification. */
local int gz_decomp(state)
    gz_statep state;
{
    int ret;
    unsigned had;
    unsigned long crc, len;
    z_streamp strm = &(state->strm);

    /* fill output buffer up to end of deflate stream */
    had = strm->avail_out;
    do {
        /* get more input for inflate() */
        if (strm->avail_in == 0 && gz_avail(state) == -1)
            return -1;
        if (strm->avail_in == 0) {
            gz_error(state, Z_DATA_ERROR, "unexpected end of file");
            return -1;
        }

        /* decompress and handle errors */
        ret = inflate(strm, Z_NO_FLUSH);
        if (ret == Z_STREAM_ERROR || ret == Z_NEED_DICT) {
            gz_error(state, Z_STREAM_ERROR,
                      "internal error: inflate stream corrupt");
            return -1;
        }
        if (ret == Z_MEM_ERROR) {
            gz_error(state, Z_MEM_ERROR, "out of memory");
            return -1;
        }
        if (ret == Z_DATA_ERROR) {              /* deflate stream invalid */
            gz_error(state, Z_DATA_ERROR,
                      strm->msg == NULL ? "compressed data error" : strm->msg);
            return -1;
        }
    } while (strm->avail_out && ret != Z_STREAM_END);

    /* update available output and crc check value */
    state->have = had - strm->avail_out;
    state->next = strm->next_out - state->have;
    strm->adler = crc32(strm->adler, state->next, state->have);

    /* check gzip trailer if at end of deflate stream */
    if (ret == Z_STREAM_END) {
        if (gz_next4(state, &crc) == -1 || gz_next4(state, &len) == -1) {
            gz_error(state, Z_DATA_ERROR, "unexpected end of file");
            return -1;
        }
        if (crc != strm->adler) {
            gz_error(state, Z_DATA_ERROR, "incorrect data check");
            return -1;
        }
        if (len != (strm->total_out & 0xffffffffL)) {
            gz_error(state, Z_DATA_ERROR, "incorrect length check");
            return -1;
        }
        state->how = LOOK;      /* ready for next stream, once have is 0 (leave
                                   state->direct unchanged to remember how) */
    }

    /* good decompression */
    return 0;
}

/* Make data and put in the output buffer.  Assumes that state->have == 0.
   Data is either copied from the input file or decompressed from the input
   file depending on state->how.  If state->how is LOOK, then a gzip header is
   looked for (and skipped if found) to determine wither to copy or decompress.
   Returns -1 on error, otherwise 0.  gz_make() will leave state->have as COPY
   or GZIP unless the end of the input file has been reached and all data has
   been processed.  */
local int gz_make(state)
    gz_statep state;
{
    z_streamp strm = &(state->strm);

    if (state->how == LOOK) {           /* look for gzip header */
        if (gz_head(state) == -1)
            return -1;
        if (state->have)                /* got some data from gz_head() */
            return 0;
    }
    if (state->how == COPY) {           /* straight copy */
        if (gz_load(state, state->out, state->size << 1, &(state->have)) == -1)
            return -1;
        state->next = state->out;
    }
    else if (state->how == GZIP) {      /* decompress */
        strm->avail_out = state->size << 1;
        strm->next_out = state->out;
        if (gz_decomp(state) == -1)
            return -1;
    }
    return 0;
}

/* Skip len uncompressed bytes of output.  Return -1 on error, 0 on success. */
local int gz_skip(state, len)
    gz_statep state;
    z_off64_t len;
{
    unsigned n;

    /* skip over len bytes or reach end-of-file, whichever comes first */
    while (len)
        /* skip over whatever is in output buffer */
        if (state->have) {
            n = GT_OFF(state->have) || (z_off64_t)state->have > len ?
                (unsigned)len : state->have;
            state->have -= n;
            state->next += n;
            state->pos += n;
            len -= n;
        }

        /* output buffer empty -- return if we're at the end of the input */
        else if (state->eof && state->strm.avail_in == 0)
            break;

        /* need more data to skip -- load up output buffer */
        else {
            /* get more output, looking for header if required */
            if (gz_make(state) == -1)
                return -1;
        }
    return 0;
}

/* -- see zlib.h -- */
int ZEXPORT gzread(file, buf, len)
    gzFile file;
    voidp buf;
    unsigned len;
{
    unsigned got, n;
    gz_statep state;
    z_streamp strm;

    /* get internal structure */
    if (file == NULL)
        return -1;
    state = (gz_statep)file;
    strm = &(state->strm);

    /* check that we're reading and that there's no error */
    if (state->mode != GZ_READ || state->err != Z_OK)
        return -1;

    /* since an int is returned, make sure len fits in one, otherwise return
       with an error (this avoids the flaw in the interface) */
    if ((int)len < 0) {
        gz_error(state, Z_BUF_ERROR, "requested length does not fit in int");
        return -1;
    }

    /* if len is zero, avoid unnecessary operations */
    if (len == 0)
        return 0;

    /* process a skip request */
    if (state->seek) {
        state->seek = 0;
        if (gz_skip(state, state->skip) == -1)
            return -1;
    }

    /* get len bytes to buf, or less than len if at the end */
    got = 0;
    do {
        /* first just try copying data from the output buffer */
        if (state->have) {
            n = state->have > len ? len : state->have;
            memcpy(buf, state->next, n);
            state->next += n;
            state->have -= n;
        }

        /* output buffer empty -- return if we're at the end of the input */
        else if (state->eof && strm->avail_in == 0)
            break;

        /* need output data -- for small len or new stream load up our output
           buffer */
        else if (state->how == LOOK || len < (state->size << 1)) {
            /* get more output, looking for header if required */
            if (gz_make(state) == -1)
                return -1;
            continue;       /* no progress yet -- go back to memcpy() above */
            /* the copy above assures that we will leave with space in the
               output buffer, allowing at least one gzungetc() to succeed */
        }

        /* large len -- read directly into user buffer */
        else if (state->how == COPY) {      /* read directly */
            if (gz_load(state, buf, len, &n) == -1)
                return -1;
        }

        /* large len -- decompress directly into user buffer */
        else {  /* state->how == GZIP */
            strm->avail_out = len;
            strm->next_out = buf;
            if (gz_decomp(state) == -1)
                return -1;
            n = state->have;
            state->have = 0;
        }

        /* update progress */
        len -= n;
        buf = (char *)buf + n;
        got += n;
        state->pos += n;
    } while (len);

    /* return number of bytes read into user buffer (will fit in int) */
    return (int)got;
}

/* -- see zlib.h -- */
int ZEXPORT gzgetc(file)
    gzFile file;
{
    int ret;
    unsigned char buf[1];
    gz_statep state;

    /* get internal structure */
    if (file == NULL)
        return -1;
    state = (gz_statep)file;

    /* check that we're reading and that there's no error */
    if (state->mode != GZ_READ || state->err != Z_OK)
        return -1;

    /* try output buffer (no need to check for skip request) */
    if (state->have) {
        state->have--;
        state->pos++;
        return *(state->next)++;
    }

    /* nothing there -- try gzread() */
    ret = gzread(file, buf, 1);
    return ret < 1 ? -1 : buf[0];
}

/* -- see zlib.h -- */
int ZEXPORT gzungetc(c, file)
    int c;
    gzFile file;
{
    gz_statep state;

    /* get internal structure */
    if (file == NULL)
        return -1;
    state = (gz_statep)file;

    /* check that we're reading and that there's no error */
    if (state->mode != GZ_READ || state->err != Z_OK)
        return -1;

    /* process a skip request */
    if (state->seek) {
        state->seek = 0;
        if (gz_skip(state, state->skip) == -1)
            return -1;
    }

    /* can't push EOF */
    if (c < 0)
        return -1;

    /* if output buffer empty, put byte at end (allows more pushing) */
    if (state->have == 0) {
        state->have = 1;
        state->next = state->out + (state->size << 1) - 1;
        state->next[0] = c;
        state->pos--;
        return c;
    }

    /* if no room, give up (must have already done a gzungetc()) */
    if (state->have == (state->size << 1)) {
        gz_error(state, Z_BUF_ERROR, "out of room to push characters");
        return -1;
    }

    /* slide output data if needed and insert byte before existing data */
    if (state->next == state->out) {
        unsigned char *src = state->out + state->have;
        unsigned char *dest = state->out + (state->size << 1);
        while (src > state->out)
            *--dest = *--src;
        state->next = dest;
    }
    state->have++;
    state->next--;
    state->next[0] = c;
    state->pos--;
    return c;
}

/* -- see zlib.h -- */
char * ZEXPORT gzgets(file, buf, len)
    gzFile file;
    char *buf;
    int len;
{
    unsigned left, n;
    char *str;
    unsigned char *eol;
    gz_statep state;

    /* check parameters and get internal structure */
    if (file == NULL || buf == NULL || len < 1)
        return NULL;
    state = (gz_statep)file;

    /* check that we're reading and that there's no error */
    if (state->mode != GZ_READ || state->err != Z_OK)
        return NULL;

    /* process a skip request */
    if (state->seek) {
        state->seek = 0;
        if (gz_skip(state, state->skip) == -1)
            return NULL;
    }

    /* copy output bytes up to new line or len - 1, whichever comes first --
       append a terminating zero to the string (we don't check for a zero in
       the contents, let the user worry about that) */
    str = buf;
    left = (unsigned)len - 1;
    if (left) do {
        /* assure that something is in the output buffer */
        if (state->have == 0) {
            if (gz_make(state) == -1)
                return NULL;            /* error */
            if (state->have == 0) {     /* end of file */
                if (buf == str)         /* got bupkus */
                    return NULL;
                break;                  /* got something -- return it */
            }
        }

        /* look for end-of-line in current output buffer */
        n = state->have > left ? left : state->have;
        eol = memchr(state->next, '\n', n);
        if (eol != NULL)
            n = (unsigned)(eol - state->next) + 1;

        /* copy through end-of-line, or remainder if not found */
        memcpy(buf, state->next, n);
        state->have -= n;
        state->next += n;
        state->pos += n;
        left -= n;
        buf += n;
    } while (left && eol == NULL);

    /* found end-of-line or out of space -- terminate string and return it */
    buf[0] = 0;
    return str;
}

/* -- see zlib.h -- */
int ZEXPORT gzdirect(file)
    gzFile file;
{
    gz_statep state;

    /* get internal structure */
    if (file == NULL)
        return 0;
    state = (gz_statep)file;

    /* check that we're reading */
    if (state->mode != GZ_READ)
        return 0;

    /* if the state is not known, but we can find out, then do so (this is
       mainly for right after a gzopen() or gzdopen()) */
    if (state->how == LOOK && state->have == 0)
        (void)gz_head(state);

    /* return 1 if reading direct, 0 if decompressing a gzip stream */
    return state->direct;
}

/* -- see zlib.h -- */
int ZEXPORT gzclose_r(file)
    gzFile file;
{
    int ret;
    gz_statep state;

    /* get internal structure */
    if (file == NULL)
        return Z_STREAM_ERROR;
    state = (gz_statep)file;

    /* check that we're reading */
    if (state->mode != GZ_READ)
        return Z_STREAM_ERROR;

    /* free memory and close file */
    if (state->size) {
        inflateEnd(&(state->strm));
        free(state->out);
        free(state->in);
    }
    gz_error(state, Z_OK, NULL);
    free(state->path);
    ret = close(state->fd);
    free(state);
    return ret ? Z_ERRNO : Z_OK;
}
