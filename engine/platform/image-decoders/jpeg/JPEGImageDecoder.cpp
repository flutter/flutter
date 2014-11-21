/*
 * Copyright (C) 2006 Apple Computer, Inc.
 *
 * Portions are Copyright (C) 2001-6 mozilla.org
 *
 * Other contributors:
 *   Stuart Parmenter <stuart@mozilla.com>
 *
 * Copyright (C) 2007-2009 Torch Mobile, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * Alternatively, the contents of this file may be used under the terms
 * of either the Mozilla Public License Version 1.1, found at
 * http://www.mozilla.org/MPL/ (the "MPL") or the GNU General Public
 * License Version 2.0, found at http://www.fsf.org/copyleft/gpl.html
 * (the "GPL"), in which case the provisions of the MPL or the GPL are
 * applicable instead of those above.  If you wish to allow use of your
 * version of this file only under the terms of one of those two
 * licenses (the MPL or the GPL) and not to allow others to use your
 * version of this file under the LGPL, indicate your decision by
 * deletingthe provisions above and replace them with the notice and
 * other provisions required by the MPL or the GPL, as the case may be.
 * If you do not delete the provisions above, a recipient may use your
 * version of this file under any of the LGPL, the MPL or the GPL.
 */

#include "sky/engine/config.h"
#include "platform/image-decoders/jpeg/JPEGImageDecoder.h"

#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/engine/wtf/dtoa/utils.h"

extern "C" {
#include <stdio.h> // jpeglib.h needs stdio FILE.
#include "jpeglib.h"
#if USE(ICCJPEG)
#include "iccjpeg.h"
#endif
#if USE(QCMSLIB)
#include "qcms.h"
#endif
#include <setjmp.h>
}

#if CPU(BIG_ENDIAN) || CPU(MIDDLE_ENDIAN)
#error Blink assumes a little-endian target.
#endif

#if defined(JCS_ALPHA_EXTENSIONS)
#define TURBO_JPEG_RGB_SWIZZLE
#if SK_B32_SHIFT // Output little-endian RGBA pixels (Android).
inline J_COLOR_SPACE rgbOutputColorSpace() { return JCS_EXT_RGBA; }
#else // Output little-endian BGRA pixels.
inline J_COLOR_SPACE rgbOutputColorSpace() { return JCS_EXT_BGRA; }
#endif
inline bool turboSwizzled(J_COLOR_SPACE colorSpace) { return colorSpace == JCS_EXT_RGBA || colorSpace == JCS_EXT_BGRA; }
inline bool colorSpaceHasAlpha(J_COLOR_SPACE colorSpace) { return turboSwizzled(colorSpace); }
#else
inline J_COLOR_SPACE rgbOutputColorSpace() { return JCS_RGB; }
inline bool colorSpaceHasAlpha(J_COLOR_SPACE) { return false; }
#endif

#if USE(LOW_QUALITY_IMAGE_NO_JPEG_DITHERING)
inline J_DCT_METHOD dctMethod() { return JDCT_IFAST; }
inline J_DITHER_MODE ditherMode() { return JDITHER_NONE; }
#else
inline J_DCT_METHOD dctMethod() { return JDCT_ISLOW; }
inline J_DITHER_MODE ditherMode() { return JDITHER_FS; }
#endif

#if USE(LOW_QUALITY_IMAGE_NO_JPEG_FANCY_UPSAMPLING)
inline bool doFancyUpsampling() { return false; }
#else
inline bool doFancyUpsampling() { return true; }
#endif

namespace {

const int exifMarker = JPEG_APP0 + 1;

// JPEG only supports a denominator of 8.
const unsigned scaleDenominator = 8;

} // namespace

namespace blink {

struct decoder_error_mgr {
    struct jpeg_error_mgr pub; // "public" fields for IJG library
    jmp_buf setjmp_buffer;     // For handling catastropic errors
};

enum jstate {
    JPEG_HEADER,                 // Reading JFIF headers
    JPEG_START_DECOMPRESS,
    JPEG_DECOMPRESS_PROGRESSIVE, // Output progressive pixels
    JPEG_DECOMPRESS_SEQUENTIAL,  // Output sequential pixels
    JPEG_DONE,
    JPEG_ERROR
};

enum yuv_subsampling {
    YUV_UNKNOWN,
    YUV_410,
    YUV_411,
    YUV_420,
    YUV_422,
    YUV_440,
    YUV_444
};

void init_source(j_decompress_ptr jd);
boolean fill_input_buffer(j_decompress_ptr jd);
void skip_input_data(j_decompress_ptr jd, long num_bytes);
void term_source(j_decompress_ptr jd);
void error_exit(j_common_ptr cinfo);

// Implementation of a JPEG src object that understands our state machine
struct decoder_source_mgr {
    // public fields; must be first in this struct!
    struct jpeg_source_mgr pub;

    JPEGImageReader* decoder;
};

static unsigned readUint16(JOCTET* data, bool isBigEndian)
{
    if (isBigEndian)
        return (GETJOCTET(data[0]) << 8) | GETJOCTET(data[1]);
    return (GETJOCTET(data[1]) << 8) | GETJOCTET(data[0]);
}

static unsigned readUint32(JOCTET* data, bool isBigEndian)
{
    if (isBigEndian)
        return (GETJOCTET(data[0]) << 24) | (GETJOCTET(data[1]) << 16) | (GETJOCTET(data[2]) << 8) | GETJOCTET(data[3]);
    return (GETJOCTET(data[3]) << 24) | (GETJOCTET(data[2]) << 16) | (GETJOCTET(data[1]) << 8) | GETJOCTET(data[0]);
}

static bool checkExifHeader(jpeg_saved_marker_ptr marker, bool& isBigEndian, unsigned& ifdOffset)
{
    // For exif data, the APP1 block is followed by 'E', 'x', 'i', 'f', '\0',
    // then a fill byte, and then a tiff file that contains the metadata.
    // A tiff file starts with 'I', 'I' (intel / little endian byte order) or
    // 'M', 'M' (motorola / big endian byte order), followed by (uint16_t)42,
    // followed by an uint32_t with the offset to the tag block, relative to the
    // tiff file start.
    const unsigned exifHeaderSize = 14;
    if (!(marker->marker == exifMarker
        && marker->data_length >= exifHeaderSize
        && marker->data[0] == 'E'
        && marker->data[1] == 'x'
        && marker->data[2] == 'i'
        && marker->data[3] == 'f'
        && marker->data[4] == '\0'
        // data[5] is a fill byte
        && ((marker->data[6] == 'I' && marker->data[7] == 'I')
            || (marker->data[6] == 'M' && marker->data[7] == 'M'))))
        return false;

    isBigEndian = marker->data[6] == 'M';
    if (readUint16(marker->data + 8, isBigEndian) != 42)
        return false;

    ifdOffset = readUint32(marker->data + 10, isBigEndian);
    return true;
}

static ImageOrientation readImageOrientation(jpeg_decompress_struct* info)
{
    // The JPEG decoder looks at EXIF metadata.
    // FIXME: Possibly implement XMP and IPTC support.
    const unsigned orientationTag = 0x112;
    const unsigned shortType = 3;
    for (jpeg_saved_marker_ptr marker = info->marker_list; marker; marker = marker->next) {
        bool isBigEndian;
        unsigned ifdOffset;
        if (!checkExifHeader(marker, isBigEndian, ifdOffset))
            continue;
        const unsigned offsetToTiffData = 6; // Account for 'Exif\0<fill byte>' header.
        if (marker->data_length < offsetToTiffData || ifdOffset >= marker->data_length - offsetToTiffData)
            continue;
        ifdOffset += offsetToTiffData;

        // The jpeg exif container format contains a tiff block for metadata.
        // A tiff image file directory (ifd) consists of a uint16_t describing
        // the number of ifd entries, followed by that many entries.
        // When touching this code, it's useful to look at the tiff spec:
        // http://partners.adobe.com/public/developer/en/tiff/TIFF6.pdf
        JOCTET* ifd = marker->data + ifdOffset;
        JOCTET* end = marker->data + marker->data_length;
        if (end - ifd < 2)
            continue;
        unsigned tagCount = readUint16(ifd, isBigEndian);
        ifd += 2; // Skip over the uint16 that was just read.

        // Every ifd entry is 2 bytes of tag, 2 bytes of contents datatype,
        // 4 bytes of number-of-elements, and 4 bytes of either offset to the
        // tag data, or if the data is small enough, the inlined data itself.
        const int ifdEntrySize = 12;
        for (unsigned i = 0; i < tagCount && end - ifd >= ifdEntrySize; ++i, ifd += ifdEntrySize) {
            unsigned tag = readUint16(ifd, isBigEndian);
            unsigned type = readUint16(ifd + 2, isBigEndian);
            unsigned count = readUint32(ifd + 4, isBigEndian);
            if (tag == orientationTag && type == shortType && count == 1)
                return ImageOrientation::fromEXIFValue(readUint16(ifd + 8, isBigEndian));
        }
    }

    return ImageOrientation();
}

#if USE(QCMSLIB)
static void readColorProfile(jpeg_decompress_struct* info, ColorProfile& colorProfile)
{
#if USE(ICCJPEG)
    JOCTET* profile;
    unsigned profileLength;

    if (!read_icc_profile(info, &profile, &profileLength))
        return;

    // Only accept RGB color profiles from input class devices.
    bool ignoreProfile = false;
    char* profileData = reinterpret_cast<char*>(profile);
    if (profileLength < ImageDecoder::iccColorProfileHeaderLength)
        ignoreProfile = true;
    else if (!ImageDecoder::rgbColorProfile(profileData, profileLength))
        ignoreProfile = true;
    else if (!ImageDecoder::inputDeviceColorProfile(profileData, profileLength))
        ignoreProfile = true;

    ASSERT(colorProfile.isEmpty());
    if (!ignoreProfile)
        colorProfile.append(profileData, profileLength);
    free(profile);
#endif
}
#endif

static IntSize computeUVSize(const jpeg_decompress_struct* info)
{
    int h = info->cur_comp_info[0]->h_samp_factor;
    int v = info->cur_comp_info[0]->v_samp_factor;
    return IntSize((info->output_width + h - 1) / h, (info->output_height + v - 1) / v);
}

static yuv_subsampling yuvSubsampling(const jpeg_decompress_struct& info)
{
    if ((DCTSIZE == 8)
        && (info.num_components == 3)
        && (info.scale_denom <= 8)
        && (info.cur_comp_info[1]->h_samp_factor == 1)
        && (info.cur_comp_info[1]->v_samp_factor == 1)
        && (info.cur_comp_info[2]->h_samp_factor == 1)
        && (info.cur_comp_info[2]->v_samp_factor == 1)) {
        int h = info.cur_comp_info[0]->h_samp_factor;
        int v = info.cur_comp_info[0]->v_samp_factor;
        // 4:4:4 : (h == 1) && (v == 1)
        // 4:4:0 : (h == 1) && (v == 2)
        // 4:2:2 : (h == 2) && (v == 1)
        // 4:2:0 : (h == 2) && (v == 2)
        // 4:1:1 : (h == 4) && (v == 1)
        // 4:1:0 : (h == 4) && (v == 2)
        if (v == 1) {
            switch (h) {
            case 1:
                return YUV_444;
            case 2:
                return YUV_422;
            case 4:
                return YUV_411;
            default:
                break;
            }
        } else if (v == 2) {
            switch (h) {
            case 1:
                return YUV_440;
            case 2:
                return YUV_420;
            case 4:
                return YUV_410;
            default:
                break;
            }
        }
    }

    return YUV_UNKNOWN;
}

class JPEGImageReader {
    WTF_MAKE_FAST_ALLOCATED;
public:
    JPEGImageReader(JPEGImageDecoder* decoder)
        : m_decoder(decoder)
        , m_bufferLength(0)
        , m_bytesToSkip(0)
        , m_state(JPEG_HEADER)
        , m_samples(0)
#if USE(QCMSLIB)
        , m_transform(0)
#endif
    {
        memset(&m_info, 0, sizeof(jpeg_decompress_struct));

        // We set up the normal JPEG error routines, then override error_exit.
        m_info.err = jpeg_std_error(&m_err.pub);
        m_err.pub.error_exit = error_exit;

        // Allocate and initialize JPEG decompression object.
        jpeg_create_decompress(&m_info);

        decoder_source_mgr* src = 0;
        if (!m_info.src) {
            src = (decoder_source_mgr*)fastZeroedMalloc(sizeof(decoder_source_mgr));
            if (!src) {
                m_state = JPEG_ERROR;
                return;
            }
        }

        m_info.src = (jpeg_source_mgr*)src;

        // Set up callback functions.
        src->pub.init_source = init_source;
        src->pub.fill_input_buffer = fill_input_buffer;
        src->pub.skip_input_data = skip_input_data;
        src->pub.resync_to_restart = jpeg_resync_to_restart;
        src->pub.term_source = term_source;
        src->decoder = this;

#if USE(ICCJPEG)
        // Retain ICC color profile markers for color management.
        setup_read_icc_profile(&m_info);
#endif

        // Keep APP1 blocks, for obtaining exif data.
        jpeg_save_markers(&m_info, exifMarker, 0xFFFF);
    }

    ~JPEGImageReader()
    {
        close();
    }

    void close()
    {
        decoder_source_mgr* src = (decoder_source_mgr*)m_info.src;
        if (src)
            fastFree(src);
        m_info.src = 0;

#if USE(QCMSLIB)
        clearColorTransform();
#endif
        jpeg_destroy_decompress(&m_info);
    }

    void skipBytes(long numBytes)
    {
        decoder_source_mgr* src = (decoder_source_mgr*)m_info.src;
        long bytesToSkip = std::min(numBytes, (long)src->pub.bytes_in_buffer);
        src->pub.bytes_in_buffer -= (size_t)bytesToSkip;
        src->pub.next_input_byte += bytesToSkip;

        m_bytesToSkip = std::max(numBytes - bytesToSkip, static_cast<long>(0));
    }

    bool decode(const SharedBuffer& data, bool onlySize)
    {
        unsigned newByteCount = data.size() - m_bufferLength;
        unsigned readOffset = m_bufferLength - m_info.src->bytes_in_buffer;

        m_info.src->bytes_in_buffer += newByteCount;
        m_info.src->next_input_byte = (JOCTET*)(data.data()) + readOffset;

        // If we still have bytes to skip, try to skip those now.
        if (m_bytesToSkip)
            skipBytes(m_bytesToSkip);

        m_bufferLength = data.size();

        // We need to do the setjmp here. Otherwise bad things will happen
        if (setjmp(m_err.setjmp_buffer))
            return m_decoder->setFailed();

        J_COLOR_SPACE overrideColorSpace = JCS_UNKNOWN;
        switch (m_state) {
        case JPEG_HEADER:
            // Read file parameters with jpeg_read_header().
            if (jpeg_read_header(&m_info, true) == JPEG_SUSPENDED)
                return false; // I/O suspension.

            switch (m_info.jpeg_color_space) {
            case JCS_YCbCr:
                // libjpeg can convert YCbCr image pixels to RGB.
                m_info.out_color_space = rgbOutputColorSpace();
                if (m_decoder->hasImagePlanes() && (yuvSubsampling(m_info) != YUV_UNKNOWN))
                    overrideColorSpace = JCS_YCbCr;
                break;
            case JCS_GRAYSCALE:
            case JCS_RGB:
                // libjpeg can convert GRAYSCALE image pixels to RGB.
                m_info.out_color_space = rgbOutputColorSpace();
#if defined(TURBO_JPEG_RGB_SWIZZLE)
                if (m_info.saw_JFIF_marker)
                    break;
                // FIXME: Swizzle decoding does not support Adobe transform=0
                // images (yet), so revert to using JSC_RGB in that case.
                if (m_info.saw_Adobe_marker && !m_info.Adobe_transform)
                    m_info.out_color_space = JCS_RGB;
#endif
                break;
            case JCS_CMYK:
            case JCS_YCCK:
                // libjpeg can convert YCCK to CMYK, but neither to RGB, so we
                // manually convert CMKY to RGB.
                m_info.out_color_space = JCS_CMYK;
                break;
            default:
                return m_decoder->setFailed();
            }

            m_state = JPEG_START_DECOMPRESS;

            // We can fill in the size now that the header is available.
            if (!m_decoder->setSize(m_info.image_width, m_info.image_height))
                return false;

            // Calculate and set decoded size.
            m_info.scale_num = m_decoder->desiredScaleNumerator();
            m_info.scale_denom = scaleDenominator;
            jpeg_calc_output_dimensions(&m_info);
            m_decoder->setDecodedSize(m_info.output_width, m_info.output_height);

            m_decoder->setOrientation(readImageOrientation(info()));

#if USE(QCMSLIB)
            // Allow color management of the decoded RGBA pixels if possible.
            if (!m_decoder->ignoresGammaAndColorProfile()) {
                ColorProfile colorProfile;
                readColorProfile(info(), colorProfile);
                createColorTransform(colorProfile, colorSpaceHasAlpha(m_info.out_color_space));
                if (m_transform) {
                    overrideColorSpace = JCS_UNKNOWN;
#if defined(TURBO_JPEG_RGB_SWIZZLE)
                    // Input RGBA data to qcms. Note: restored to BGRA on output.
                    if (m_info.out_color_space == JCS_EXT_BGRA)
                        m_info.out_color_space = JCS_EXT_RGBA;
#endif
                }
                m_decoder->setHasColorProfile(!!m_transform);
            }
#endif
            if (overrideColorSpace == JCS_YCbCr) {
                m_info.out_color_space = JCS_YCbCr;
                m_info.raw_data_out = TRUE;
            }

            // Don't allocate a giant and superfluous memory buffer when the
            // image is a sequential JPEG.
            m_info.buffered_image = jpeg_has_multiple_scans(&m_info);

            if (onlySize) {
                // We can stop here. Reduce our buffer length and available data.
                m_bufferLength -= m_info.src->bytes_in_buffer;
                m_info.src->bytes_in_buffer = 0;
                return true;
            }
        // FALL THROUGH

        case JPEG_START_DECOMPRESS:
            // Set parameters for decompression.
            // FIXME -- Should reset dct_method and dither mode for final pass
            // of progressive JPEG.
            m_info.dct_method = dctMethod();
            m_info.dither_mode = ditherMode();
            m_info.do_fancy_upsampling = doFancyUpsampling();
            m_info.enable_2pass_quant = false;
            m_info.do_block_smoothing = true;

            // Make a one-row-high sample array that will go away when done with
            // image. Always make it big enough to hold an RGB row. Since this
            // uses the IJG memory manager, it must be allocated before the call
            // to jpeg_start_compress().
            // FIXME: note that some output color spaces do not need the samples
            // buffer. Remove this allocation for those color spaces.
            m_samples = (*m_info.mem->alloc_sarray)(reinterpret_cast<j_common_ptr>(&m_info), JPOOL_IMAGE, m_info.output_width * 4, m_info.out_color_space == JCS_YCbCr ? 2 : 1);

            // Start decompressor.
            if (!jpeg_start_decompress(&m_info))
                return false; // I/O suspension.

            // If this is a progressive JPEG ...
            m_state = (m_info.buffered_image) ? JPEG_DECOMPRESS_PROGRESSIVE : JPEG_DECOMPRESS_SEQUENTIAL;
        // FALL THROUGH

        case JPEG_DECOMPRESS_SEQUENTIAL:
            if (m_state == JPEG_DECOMPRESS_SEQUENTIAL) {

                if (!m_decoder->outputScanlines())
                    return false; // I/O suspension.

                // If we've completed image output...
                ASSERT(m_info.output_scanline == m_info.output_height);
                m_state = JPEG_DONE;
            }
        // FALL THROUGH

        case JPEG_DECOMPRESS_PROGRESSIVE:
            if (m_state == JPEG_DECOMPRESS_PROGRESSIVE) {
                int status;
                do {
                    status = jpeg_consume_input(&m_info);
                } while ((status != JPEG_SUSPENDED) && (status != JPEG_REACHED_EOI));

                for (;;) {
                    if (!m_info.output_scanline) {
                        int scan = m_info.input_scan_number;

                        // If we haven't displayed anything yet
                        // (output_scan_number == 0) and we have enough data for
                        // a complete scan, force output of the last full scan.
                        if (!m_info.output_scan_number && (scan > 1) && (status != JPEG_REACHED_EOI))
                            --scan;

                        if (!jpeg_start_output(&m_info, scan))
                            return false; // I/O suspension.
                    }

                    if (m_info.output_scanline == 0xffffff)
                        m_info.output_scanline = 0;

                    // If outputScanlines() fails, it deletes |this|. Therefore,
                    // copy the decoder pointer and use it to check for failure
                    // to avoid member access in the failure case.
                    JPEGImageDecoder* decoder = m_decoder;
                    if (!decoder->outputScanlines()) {
                        if (decoder->failed()) // Careful; |this| is deleted.
                            return false;
                        if (!m_info.output_scanline)
                            // Didn't manage to read any lines - flag so we
                            // don't call jpeg_start_output() multiple times for
                            // the same scan.
                            m_info.output_scanline = 0xffffff;
                        return false; // I/O suspension.
                    }

                    if (m_info.output_scanline == m_info.output_height) {
                        if (!jpeg_finish_output(&m_info))
                            return false; // I/O suspension.

                        if (jpeg_input_complete(&m_info) && (m_info.input_scan_number == m_info.output_scan_number))
                            break;

                        m_info.output_scanline = 0;
                    }
                }

                m_state = JPEG_DONE;
            }
        // FALL THROUGH

        case JPEG_DONE:
            // Finish decompression.
            return jpeg_finish_decompress(&m_info);

        case JPEG_ERROR:
            // We can get here if the constructor failed.
            return m_decoder->setFailed();
        }

        return true;
    }

    jpeg_decompress_struct* info() { return &m_info; }
    JSAMPARRAY samples() const { return m_samples; }
    JPEGImageDecoder* decoder() { return m_decoder; }
#if USE(QCMSLIB)
    qcms_transform* colorTransform() const { return m_transform; }

    void clearColorTransform()
    {
        if (m_transform)
            qcms_transform_release(m_transform);
        m_transform = 0;
    }

    void createColorTransform(const ColorProfile& colorProfile, bool hasAlpha)
    {
        clearColorTransform();

        if (colorProfile.isEmpty())
            return;
        qcms_profile* deviceProfile = ImageDecoder::qcmsOutputDeviceProfile();
        if (!deviceProfile)
            return;
        qcms_profile* inputProfile = qcms_profile_from_memory(colorProfile.data(), colorProfile.size());
        if (!inputProfile)
            return;
        // We currently only support color profiles for RGB profiled images.
        ASSERT(icSigRgbData == qcms_profile_get_color_space(inputProfile));
        qcms_data_type dataFormat = hasAlpha ? QCMS_DATA_RGBA_8 : QCMS_DATA_RGB_8;
        // FIXME: Don't force perceptual intent if the image profile contains an intent.
        m_transform = qcms_transform_create(inputProfile, dataFormat, deviceProfile, dataFormat, QCMS_INTENT_PERCEPTUAL);
        qcms_profile_release(inputProfile);
    }
#endif

private:
    JPEGImageDecoder* m_decoder;
    unsigned m_bufferLength;
    int m_bytesToSkip;

    jpeg_decompress_struct m_info;
    decoder_error_mgr m_err;
    jstate m_state;

    JSAMPARRAY m_samples;

#if USE(QCMSLIB)
    qcms_transform* m_transform;
#endif
};

// Override the standard error method in the IJG JPEG decoder code.
void error_exit(j_common_ptr cinfo)
{
    // Return control to the setjmp point.
    decoder_error_mgr *err = reinterpret_cast_ptr<decoder_error_mgr *>(cinfo->err);
    longjmp(err->setjmp_buffer, -1);
}

void init_source(j_decompress_ptr)
{
}

void skip_input_data(j_decompress_ptr jd, long num_bytes)
{
    decoder_source_mgr *src = (decoder_source_mgr *)jd->src;
    src->decoder->skipBytes(num_bytes);
}

boolean fill_input_buffer(j_decompress_ptr)
{
    // Our decode step always sets things up properly, so if this method is ever
    // called, then we have hit the end of the buffer.  A return value of false
    // indicates that we have no data to supply yet.
    return false;
}

void term_source(j_decompress_ptr jd)
{
    decoder_source_mgr *src = (decoder_source_mgr *)jd->src;
    src->decoder->decoder()->jpegComplete();
}

JPEGImageDecoder::JPEGImageDecoder(ImageSource::AlphaOption alphaOption,
    ImageSource::GammaAndColorProfileOption gammaAndColorProfileOption,
    size_t maxDecodedBytes)
    : ImageDecoder(alphaOption, gammaAndColorProfileOption, maxDecodedBytes)
    , m_hasColorProfile(false)
{
}

JPEGImageDecoder::~JPEGImageDecoder()
{
}

bool JPEGImageDecoder::isSizeAvailable()
{
    if (!ImageDecoder::isSizeAvailable())
         decode(true);

    return ImageDecoder::isSizeAvailable();
}

bool JPEGImageDecoder::setSize(unsigned width, unsigned height)
{
    if (!ImageDecoder::setSize(width, height))
        return false;

    if (!desiredScaleNumerator())
        return setFailed();

    setDecodedSize(width, height);
    return true;
}

void JPEGImageDecoder::setDecodedSize(unsigned width, unsigned height)
{
    m_decodedSize = IntSize(width, height);
}

IntSize JPEGImageDecoder::decodedYUVSize(int component) const
{
    if (((component == 1) || (component == 2)) && m_reader.get()) { // Asking for U or V
        const jpeg_decompress_struct* info = m_reader->info();
        if (info && (info->out_color_space == JCS_YCbCr)) {
            return computeUVSize(info);
        }
    }

    return m_decodedSize;
}

unsigned JPEGImageDecoder::desiredScaleNumerator() const
{
    size_t originalBytes = size().width() * size().height() * 4;
    if (originalBytes <= m_maxDecodedBytes) {
        return scaleDenominator;
    }

    // Downsample according to the maximum decoded size.
    unsigned scaleNumerator = static_cast<unsigned>(floor(sqrt(
        // MSVC needs explicit parameter type for sqrt().
        static_cast<float>(m_maxDecodedBytes * scaleDenominator * scaleDenominator / originalBytes))));

    return scaleNumerator;
}

bool JPEGImageDecoder::canDecodeToYUV() const
{
    ASSERT(const_cast<JPEGImageDecoder*>(this)->isSizeAvailable() && m_reader);

    return m_reader->info()->out_color_space == JCS_YCbCr;
}

bool JPEGImageDecoder::decodeToYUV()
{
    if (!hasImagePlanes())
        return false;
    decode(false);
    return !failed();
}

ImageFrame* JPEGImageDecoder::frameBufferAtIndex(size_t index)
{
    if (index)
        return 0;

    if (m_frameBufferCache.isEmpty()) {
        m_frameBufferCache.resize(1);
        m_frameBufferCache[0].setPremultiplyAlpha(m_premultiplyAlpha);
    }

    ImageFrame& frame = m_frameBufferCache[0];
    if (frame.status() != ImageFrame::FrameComplete) {
        decode(false);
    }

    frame.notifyBitmapIfPixelsChanged();
    return &frame;
}

bool JPEGImageDecoder::setFailed()
{
    m_reader.clear();
    return ImageDecoder::setFailed();
}

void JPEGImageDecoder::setImagePlanes(PassOwnPtr<ImagePlanes> imagePlanes)
{
    m_imagePlanes = imagePlanes;
}

template <J_COLOR_SPACE colorSpace> void setPixel(ImageFrame& buffer, ImageFrame::PixelData* pixel, JSAMPARRAY samples, int column)
{
    ASSERT_NOT_REACHED();
}

template <> void setPixel<JCS_RGB>(ImageFrame& buffer, ImageFrame::PixelData* pixel, JSAMPARRAY samples, int column)
{
    JSAMPLE* jsample = *samples + column * 3;
    buffer.setRGBARaw(pixel, jsample[0], jsample[1], jsample[2], 255);
}

template <> void setPixel<JCS_CMYK>(ImageFrame& buffer, ImageFrame::PixelData* pixel, JSAMPARRAY samples, int column)
{
    JSAMPLE* jsample = *samples + column * 4;

    // Source is 'Inverted CMYK', output is RGB.
    // See: http://www.easyrgb.com/math.php?MATH=M12#text12
    // Or: http://www.ilkeratalay.com/colorspacesfaq.php#rgb
    // From CMYK to CMY:
    // X =   X    * (1 -   K   ) +   K  [for X = C, M, or Y]
    // Thus, from Inverted CMYK to CMY is:
    // X = (1-iX) * (1 - (1-iK)) + (1-iK) => 1 - iX*iK
    // From CMY (0..1) to RGB (0..1):
    // R = 1 - C => 1 - (1 - iC*iK) => iC*iK  [G and B similar]
    unsigned k = jsample[3];
    buffer.setRGBARaw(pixel, jsample[0] * k / 255, jsample[1] * k / 255, jsample[2] * k / 255, 255);
}

template <J_COLOR_SPACE colorSpace> bool outputRows(JPEGImageReader* reader, ImageFrame& buffer)
{
    JSAMPARRAY samples = reader->samples();
    jpeg_decompress_struct* info = reader->info();
    int width = info->output_width;

    while (info->output_scanline < info->output_height) {
        // jpeg_read_scanlines will increase the scanline counter, so we
        // save the scanline before calling it.
        int y = info->output_scanline;
        // Request one scanline: returns 0 or 1 scanlines.
        if (jpeg_read_scanlines(info, samples, 1) != 1)
            return false;
#if USE(QCMSLIB)
        if (reader->colorTransform() && colorSpace == JCS_RGB)
            qcms_transform_data(reader->colorTransform(), *samples, *samples, width);
#endif
        ImageFrame::PixelData* pixel = buffer.getAddr(0, y);
        for (int x = 0; x < width; ++pixel, ++x)
            setPixel<colorSpace>(buffer, pixel, samples, x);
    }

    buffer.setPixelsChanged(true);
    return true;
}

static bool outputRawData(JPEGImageReader* reader, ImagePlanes* imagePlanes)
{
    JSAMPARRAY samples = reader->samples();
    jpeg_decompress_struct* info = reader->info();
    JSAMPARRAY bufferraw[3];
    JSAMPROW bufferraw2[32];
    bufferraw[0] = &bufferraw2[0]; // Y channel rows (8 or 16)
    bufferraw[1] = &bufferraw2[16]; // U channel rows (8)
    bufferraw[2] = &bufferraw2[24]; // V channel rows (8)
    int yWidth = info->output_width;
    int yHeight = info->output_height;
    int yMaxH = yHeight - 1;
    int v = info->cur_comp_info[0]->v_samp_factor;
    IntSize uvSize = computeUVSize(info);
    int uvMaxH = uvSize.height() - 1;
    JSAMPROW outputY = static_cast<JSAMPROW>(imagePlanes->plane(0));
    JSAMPROW outputU = static_cast<JSAMPROW>(imagePlanes->plane(1));
    JSAMPROW outputV = static_cast<JSAMPROW>(imagePlanes->plane(2));
    size_t rowBytesY = imagePlanes->rowBytes(0);
    size_t rowBytesU = imagePlanes->rowBytes(1);
    size_t rowBytesV = imagePlanes->rowBytes(2);

    int yScanlinesToRead = DCTSIZE * v;
    JSAMPROW yLastRow = *samples;
    JSAMPROW uLastRow = yLastRow + 2 * yWidth;
    JSAMPROW vLastRow = uLastRow + 2 * yWidth;
    JSAMPROW dummyRow = vLastRow + 2 * yWidth;

    while (info->output_scanline < info->output_height) {
        // Request 8 or 16 scanlines: returns 0 or more scanlines.
        bool hasYLastRow(false), hasUVLastRow(false);
        // Assign 8 or 16 rows of memory to read the Y channel.
        for (int i = 0; i < yScanlinesToRead; ++i) {
            int scanline = (info->output_scanline + i);
            if (scanline < yMaxH) {
                bufferraw2[i] = &outputY[scanline * rowBytesY];
            } else if (scanline == yMaxH) {
                bufferraw2[i] = yLastRow;
                hasYLastRow = true;
            } else {
                bufferraw2[i] = dummyRow;
            }
        }
        int scaledScanline = info->output_scanline / v;
        // Assign 8 rows of memory to read the U and V channels.
        for (int i = 0; i < 8; ++i) {
            int scanline = (scaledScanline + i);
            if (scanline < uvMaxH) {
                bufferraw2[16 + i] = &outputU[scanline * rowBytesU];
                bufferraw2[24 + i] = &outputV[scanline * rowBytesV];
            } else if (scanline == uvMaxH) {
                bufferraw2[16 + i] = uLastRow;
                bufferraw2[24 + i] = vLastRow;
                hasUVLastRow = true;
            } else {
                bufferraw2[16 + i] = dummyRow;
                bufferraw2[24 + i] = dummyRow;
            }
        }
        JDIMENSION scanlinesRead = jpeg_read_raw_data(info, bufferraw, yScanlinesToRead);

        if (scanlinesRead == 0)
            return false;

        if (hasYLastRow) {
            memcpy(&outputY[yMaxH * rowBytesY], yLastRow, yWidth);
        }
        if (hasUVLastRow) {
            memcpy(&outputU[uvMaxH * rowBytesU], uLastRow, uvSize.width());
            memcpy(&outputV[uvMaxH * rowBytesV], vLastRow, uvSize.width());
        }
    }

    info->output_scanline = std::min(info->output_scanline, info->output_height);

    return true;
}

bool JPEGImageDecoder::outputScanlines()
{
    if (hasImagePlanes()) {
        return outputRawData(m_reader.get(), m_imagePlanes.get());
    }

    if (m_frameBufferCache.isEmpty())
        return false;

    jpeg_decompress_struct* info = m_reader->info();

    // Initialize the framebuffer if needed.
    ImageFrame& buffer = m_frameBufferCache[0];
    if (buffer.status() == ImageFrame::FrameEmpty) {
        ASSERT(info->output_width == static_cast<JDIMENSION>(m_decodedSize.width()));
        ASSERT(info->output_height == static_cast<JDIMENSION>(m_decodedSize.height()));

        if (!buffer.setSize(info->output_width, info->output_height))
            return setFailed();
        buffer.setStatus(ImageFrame::FramePartial);
        // The buffer is transparent outside the decoded area while the image is
        // loading. The completed image will be marked fully opaque in jpegComplete().
        buffer.setHasAlpha(true);

        // For JPEGs, the frame always fills the entire image.
        buffer.setOriginalFrameRect(IntRect(IntPoint(), size()));
    }

#if defined(TURBO_JPEG_RGB_SWIZZLE)
    if (turboSwizzled(info->out_color_space)) {
        while (info->output_scanline < info->output_height) {
            unsigned char* row = reinterpret_cast<unsigned char*>(buffer.getAddr(0, info->output_scanline));
            if (jpeg_read_scanlines(info, &row, 1) != 1)
                return false;
#if USE(QCMSLIB)
            if (qcms_transform* transform = m_reader->colorTransform())
                qcms_transform_data_type(transform, row, row, info->output_width, rgbOutputColorSpace() == JCS_EXT_BGRA ? QCMS_OUTPUT_BGRX : QCMS_OUTPUT_RGBX);
#endif
        }
        buffer.setPixelsChanged(true);
        return true;
    }
#endif

    switch (info->out_color_space) {
    case JCS_RGB:
        return outputRows<JCS_RGB>(m_reader.get(), buffer);
    case JCS_CMYK:
        return outputRows<JCS_CMYK>(m_reader.get(), buffer);
    default:
        ASSERT_NOT_REACHED();
    }

    return setFailed();
}

void JPEGImageDecoder::jpegComplete()
{
    if (m_frameBufferCache.isEmpty())
        return;

    // Hand back an appropriately sized buffer, even if the image ended up being
    // empty.
    ImageFrame& buffer = m_frameBufferCache[0];
    buffer.setHasAlpha(false);
    buffer.setStatus(ImageFrame::FrameComplete);
}

void JPEGImageDecoder::decode(bool onlySize)
{
    if (failed())
        return;

    if (!m_reader) {
        m_reader = adoptPtr(new JPEGImageReader(this));
    }

    // If we couldn't decode the image but we've received all the data, decoding
    // has failed.
    if (!m_reader->decode(*m_data, onlySize) && isAllDataReceived())
        setFailed();
    // If we're done decoding the image, we don't need the JPEGImageReader
    // anymore.  (If we failed, |m_reader| has already been cleared.)
    else if ((!m_frameBufferCache.isEmpty() && (m_frameBufferCache[0].status() == ImageFrame::FrameComplete)) || (hasImagePlanes() && !onlySize))
        m_reader.clear();
}

}
