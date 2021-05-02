----

2016-04-02:

- other_libs: cro_mipmap, greatest, munit, parg, dr_flac
- stb_image_write: allocate large structures on stack for embedded (Thatcher Ulrich)
- stb_image: allocate large structures on stack for embedded (Thatcher Ulrich)
- stb_image: remove white matting for transparent PSD (stb, Oriol Ferrer Mesia)
- stb_image: fix reported channel count in PNG when req_comp is non-zero
- stb_image: re-enable SSE2 in x64 (except in gcc)
- stb_image: fix harmless typo in name (Matthew Gregan)
- stb_image: support JPEG images coded as RGB
- stb_image: bmp could return wrong channel count (snagar@github)
- stb_image: read 16-bit PNGs as 8-bit (socks-the-fox)
- stb_image_resize: fix handling of subpixel regions
- stb_image_resize: avoid warnings on asserts (Wu Shuang)
- stb_truetype: allow fabs() to be supplied by user (Simon Glass)
- stb_truetype: duplicate typedef
- stb_truetype: don't leak memory if fontsize=0
- stb_vorbis: warnings (Thiago Goulart)
- stb_vorbis: fix multiple memory leaks of setup-memory (manxorist@github)
- stb_vorbis: avoid dropping final frame of audio data
- stb_textedit: better support for keying while holding mouse drag button (ocornut)
- stb_voxel_render: fix type of glModelview matrix (Stephen Olsen)
- stb_leakcheck: typo in comment (Lukas Meller)
- stb.h: fix _WIN32 when defining STB_THREADS
