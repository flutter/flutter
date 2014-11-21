/* -*- Mode: C; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is Mozilla Communicator client code.
 *
 * The Initial Developer of the Original Code is
 * Netscape Communications Corporation.
 * Portions created by the Initial Developer are Copyright (C) 1998
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

#ifndef SKY_ENGINE_PLATFORM_IMAGE_DECODERS_GIF_GIFIMAGEREADER_H_
#define SKY_ENGINE_PLATFORM_IMAGE_DECODERS_GIF_GIFIMAGEREADER_H_

// Define ourselves as the clientPtr.  Mozilla just hacked their C++ callback class into this old C decoder,
// so we will too.
#include "platform/image-decoders/gif/GIFImageDecoder.h"
#include "sky/engine/platform/SharedBuffer.h"
#include "sky/engine/wtf/Noncopyable.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

#define MAX_DICTIONARY_ENTRY_BITS 12
#define MAX_DICTIONARY_ENTRIES    4096 // 2^MAX_DICTIONARY_ENTRY_BITS
#define MAX_COLORS                256
#define BYTES_PER_COLORMAP_ENTRY  3

const int cLoopCountNotSeen = -2;

// List of possible parsing states.
enum GIFState {
    GIFType,
    GIFGlobalHeader,
    GIFGlobalColormap,
    GIFImageStart,
    GIFImageHeader,
    GIFImageColormap,
    GIFImageBody,
    GIFLZWStart,
    GIFLZW,
    GIFSubBlock,
    GIFExtension,
    GIFControlExtension,
    GIFConsumeBlock,
    GIFSkipBlock,
    GIFDone,
    GIFCommentExtension,
    GIFApplicationExtension,
    GIFNetscapeExtensionBlock,
    GIFConsumeNetscapeExtension,
    GIFConsumeComment
};

struct GIFFrameContext;

// LZW decoder state machine.
class GIFLZWContext {
    WTF_MAKE_FAST_ALLOCATED;
public:
    GIFLZWContext(blink::GIFImageDecoder* client, const GIFFrameContext* frameContext)
        : codesize(0)
        , codemask(0)
        , clearCode(0)
        , avail(0)
        , oldcode(0)
        , firstchar(0)
        , bits(0)
        , datum(0)
        , ipass(0)
        , irow(0)
        , rowsRemaining(0)
        , rowIter(0)
        , m_client(client)
        , m_frameContext(frameContext)
    { }

    bool prepareToDecode();
    bool outputRow(GIFRow::const_iterator rowBegin);
    bool doLZW(const unsigned char* block, size_t bytesInBlock);
    bool hasRemainingRows() { return rowsRemaining; }

private:
    // LZW decoding states and output states.
    int codesize;
    int codemask;
    int clearCode; // Codeword used to trigger dictionary reset.
    int avail; // Index of next available slot in dictionary.
    int oldcode;
    unsigned char firstchar;
    int bits; // Number of unread bits in "datum".
    int datum; // 32-bit input buffer.
    int ipass; // Interlace pass; Ranges 1-4 if interlaced.
    size_t irow; // Current output row, starting at zero.
    size_t rowsRemaining; // Rows remaining to be output.

    unsigned short prefix[MAX_DICTIONARY_ENTRIES];
    unsigned char suffix[MAX_DICTIONARY_ENTRIES];
    unsigned short suffixLength[MAX_DICTIONARY_ENTRIES];
    GIFRow rowBuffer; // Single scanline temporary buffer.
    GIFRow::iterator rowIter;

    // Initialized during construction and read-only.
    blink::GIFImageDecoder* m_client;
    const GIFFrameContext* m_frameContext;
};

// Data structure for one LZW block.
struct GIFLZWBlock {
    WTF_MAKE_FAST_ALLOCATED;
public:
    GIFLZWBlock(size_t position, size_t size)
        : blockPosition(position)
        , blockSize(size)
    {
    }

    size_t blockPosition;
    size_t blockSize;
};

class GIFColorMap {
    WTF_MAKE_FAST_ALLOCATED;
public:
    typedef Vector<blink::ImageFrame::PixelData> Table;

    GIFColorMap()
        : m_isDefined(false)
        , m_position(0)
        , m_colors(0)
    {
    }

    // Set position and number of colors for the RGB table in the data stream.
    void setTablePositionAndSize(size_t position, size_t colors)
    {
        m_position = position;
        m_colors = colors;
    }
    void setDefined() { m_isDefined = true; }
    bool isDefined() const { return m_isDefined; }

    // Build RGBA table using the data stream.
    void buildTable(const unsigned char* data, size_t length);
    const Table& table() const { return m_table; }

private:
    bool m_isDefined;
    size_t m_position;
    size_t m_colors;
    Table m_table;
};

// LocalFrame output state machine.
struct GIFFrameContext {
    WTF_MAKE_FAST_ALLOCATED; WTF_MAKE_NONCOPYABLE(GIFFrameContext);
public:
    GIFFrameContext(int id)
        : m_frameId(id)
        , m_xOffset(0)
        , m_yOffset(0)
        , m_width(0)
        , m_height(0)
        , m_transparentPixel(kNotFound)
        , m_disposalMethod(blink::ImageFrame::DisposeNotSpecified)
        , m_dataSize(0)
        , m_progressiveDisplay(false)
        , m_interlaced(false)
        , m_delayTime(0)
        , m_currentLzwBlock(0)
        , m_isComplete(false)
        , m_isHeaderDefined(false)
        , m_isDataSizeDefined(false)
    {
    }

    ~GIFFrameContext()
    {
    }

    void addLzwBlock(size_t position, size_t size)
    {
        m_lzwBlocks.append(GIFLZWBlock(position, size));
    }

    bool decode(const unsigned char* data, size_t length, blink::GIFImageDecoder* client, bool* frameDecoded);

    int frameId() const { return m_frameId; }
    void setRect(unsigned x, unsigned y, unsigned width, unsigned height)
    {
        m_xOffset = x;
        m_yOffset = y;
        m_width = width;
        m_height = height;
    }
    blink::IntRect frameRect() const { return blink::IntRect(m_xOffset, m_yOffset, m_width, m_height); }
    unsigned xOffset() const { return m_xOffset; }
    unsigned yOffset() const { return m_yOffset; }
    unsigned width() const { return m_width; }
    unsigned height() const { return m_height; }
    size_t transparentPixel() const { return m_transparentPixel; }
    void setTransparentPixel(size_t pixel) { m_transparentPixel = pixel; }
    blink::ImageFrame::DisposalMethod disposalMethod() const { return m_disposalMethod; }
    void setDisposalMethod(blink::ImageFrame::DisposalMethod disposalMethod) { m_disposalMethod = disposalMethod; }
    unsigned delayTime() const { return m_delayTime; }
    void setDelayTime(unsigned delay) { m_delayTime = delay; }
    bool isComplete() const { return m_isComplete; }
    void setComplete() { m_isComplete = true; }
    bool isHeaderDefined() const { return m_isHeaderDefined; }
    void setHeaderDefined() { m_isHeaderDefined = true; }
    bool isDataSizeDefined() const { return m_isDataSizeDefined; }
    int dataSize() const { return m_dataSize; }
    void setDataSize(int size)
    {
        m_dataSize = size;
        m_isDataSizeDefined = true;
    }
    bool progressiveDisplay() const { return m_progressiveDisplay; }
    void setProgressiveDisplay(bool progressiveDisplay) { m_progressiveDisplay = progressiveDisplay; }
    bool interlaced() const { return m_interlaced; }
    void setInterlaced(bool interlaced) { m_interlaced = interlaced; }

    void clearDecodeState() { m_lzwContext.clear(); }
    const GIFColorMap& localColorMap() const { return m_localColorMap; }
    GIFColorMap& localColorMap() { return m_localColorMap; }

private:
    int m_frameId;
    unsigned m_xOffset;
    unsigned m_yOffset; // With respect to "screen" origin.
    unsigned m_width;
    unsigned m_height;
    size_t m_transparentPixel; // Index of transparent pixel. Value is kNotFound if there is no transparent pixel.
    blink::ImageFrame::DisposalMethod m_disposalMethod; // Restore to background, leave in place, etc.
    int m_dataSize;

    bool m_progressiveDisplay; // If true, do Haeberli interlace hack.
    bool m_interlaced; // True, if scanlines arrive interlaced order.

    unsigned m_delayTime; // Display time, in milliseconds, for this image in a multi-image GIF.

    OwnPtr<GIFLZWContext> m_lzwContext;
    Vector<GIFLZWBlock> m_lzwBlocks; // LZW blocks for this frame.
    GIFColorMap m_localColorMap;

    size_t m_currentLzwBlock;
    bool m_isComplete;
    bool m_isHeaderDefined;
    bool m_isDataSizeDefined;
};

class PLATFORM_EXPORT GIFImageReader {
    WTF_MAKE_FAST_ALLOCATED; WTF_MAKE_NONCOPYABLE(GIFImageReader);
public:
    GIFImageReader(blink::GIFImageDecoder* client = 0)
        : m_client(client)
        , m_state(GIFType)
        , m_bytesToConsume(6) // Number of bytes for GIF type, either "GIF87a" or "GIF89a".
        , m_bytesRead(0)
        , m_version(0)
        , m_screenWidth(0)
        , m_screenHeight(0)
        , m_loopCount(cLoopCountNotSeen)
        , m_parseCompleted(false)
    {
    }

    ~GIFImageReader()
    {
    }

    void setData(PassRefPtr<blink::SharedBuffer> data) { m_data = data; }
    bool parse(blink::GIFImageDecoder::GIFParseQuery);
    bool decode(size_t frameIndex);

    size_t imagesCount() const
    {
        if (m_frames.isEmpty())
            return 0;

        // This avoids counting an empty frame when the file is truncated right after
        // GIFControlExtension but before GIFImageHeader.
        // FIXME: This extra complexity is not necessary and we should just report m_frames.size().
        return m_frames.last()->isHeaderDefined() ? m_frames.size() : m_frames.size() - 1;
    }
    int loopCount() const { return m_loopCount; }

    const GIFColorMap& globalColorMap() const
    {
        return m_globalColorMap;
    }

    const GIFFrameContext* frameContext(size_t index) const
    {
        return index < m_frames.size() ? m_frames[index].get() : 0;
    }

    bool parseCompleted() const { return m_parseCompleted; }

    void clearDecodeState(size_t index) { m_frames[index]->clearDecodeState(); }

private:
    bool parseData(size_t dataPosition, size_t len, blink::GIFImageDecoder::GIFParseQuery);
    void setRemainingBytes(size_t);

    const unsigned char* data(size_t dataPosition) const
    {
        return reinterpret_cast<const unsigned char*>(m_data->data()) + dataPosition;
    }

    void addFrameIfNecessary();
    bool currentFrameIsFirstFrame() const
    {
        return m_frames.isEmpty() || (m_frames.size() == 1u && !m_frames[0]->isComplete());
    }

    blink::GIFImageDecoder* m_client;

    // Parsing state machine.
    GIFState m_state; // Current decoder master state.
    size_t m_bytesToConsume; // Number of bytes to consume for next stage of parsing.
    size_t m_bytesRead; // Number of bytes processed.

    // Global (multi-image) state.
    int m_version; // Either 89 for GIF89 or 87 for GIF87.
    unsigned m_screenWidth; // Logical screen width & height.
    unsigned m_screenHeight;
    GIFColorMap m_globalColorMap;
    int m_loopCount; // Netscape specific extension block to control the number of animation loops a GIF renders.

    Vector<OwnPtr<GIFFrameContext> > m_frames;

    RefPtr<blink::SharedBuffer> m_data;
    bool m_parseCompleted;
};

} // namespace blink

#endif  // SKY_ENGINE_PLATFORM_IMAGE_DECODERS_GIF_GIFIMAGEREADER_H_
