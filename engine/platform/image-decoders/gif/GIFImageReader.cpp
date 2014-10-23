/* -*- Mode: C; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
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
 * The Original Code is mozilla.org code.
 *
 * The Initial Developer of the Original Code is
 * Netscape Communications Corporation.
 * Portions created by the Initial Developer are Copyright (C) 1998
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *   Chris Saari <saari@netscape.com>
 *   Apple Computer
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

/*
The Graphics Interchange Format(c) is the copyright property of CompuServe
Incorporated. Only CompuServe Incorporated is authorized to define, redefine,
enhance, alter, modify or change in any way the definition of the format.

CompuServe Incorporated hereby grants a limited, non-exclusive, royalty-free
license for the use of the Graphics Interchange Format(sm) in computer
software; computer software utilizing GIF(sm) must acknowledge ownership of the
Graphics Interchange Format and its Service Mark by CompuServe Incorporated, in
User and Technical Documentation. Computer software utilizing GIF, which is
distributed or may be distributed without User or Technical Documentation must
display to the screen or printer a message acknowledging ownership of the
Graphics Interchange Format and the Service Mark by CompuServe Incorporated; in
this case, the acknowledgement may be displayed in an opening screen or leading
banner, or a closing screen or trailing banner. A message such as the following
may be used:

    "The Graphics Interchange Format(c) is the Copyright property of
    CompuServe Incorporated. GIF(sm) is a Service Mark property of
    CompuServe Incorporated."

For further information, please contact :

    CompuServe Incorporated
    Graphics Technology Department
    5000 Arlington Center Boulevard
    Columbus, Ohio  43220
    U. S. A.

CompuServe Incorporated maintains a mailing list with all those individuals and
organizations who wish to receive copies of this document when it is corrected
or revised. This service is offered free of charge; please provide us with your
mailing address.
*/

#include "config.h"
#include "platform/image-decoders/gif/GIFImageReader.h"

#include <string.h>
#include "platform/graphics/ImageSource.h"

namespace blink {

using blink::GIFImageDecoder;

// GETN(n, s) requests at least 'n' bytes available from 'q', at start of state 's'.
//
// Note, the hold will never need to be bigger than 256 bytes to gather up in the hold,
// as each GIF block (except colormaps) can never be bigger than 256 bytes.
// Colormaps are directly copied in the resp. global_colormap or dynamically allocated local_colormap.
// So a fixed buffer in GIFImageReader is good enough.
// This buffer is only needed to copy left-over data from one GifWrite call to the next
#define GETN(n, s) \
    do { \
        m_bytesToConsume = (n); \
        m_state = (s); \
    } while (0)

// Get a 16-bit value stored in little-endian format.
#define GETINT16(p)   ((p)[1]<<8|(p)[0])

// Send the data to the display front-end.
bool GIFLZWContext::outputRow(GIFRow::const_iterator rowBegin)
{
    int drowStart = irow;
    int drowEnd = irow;

    // Haeberli-inspired hack for interlaced GIFs: Replicate lines while
    // displaying to diminish the "venetian-blind" effect as the image is
    // loaded. Adjust pixel vertical positions to avoid the appearance of the
    // image crawling up the screen as successive passes are drawn.
    if (m_frameContext->progressiveDisplay() && m_frameContext->interlaced() && ipass < 4) {
        unsigned rowDup = 0;
        unsigned rowShift = 0;

        switch (ipass) {
        case 1:
            rowDup = 7;
            rowShift = 3;
            break;
        case 2:
            rowDup = 3;
            rowShift = 1;
            break;
        case 3:
            rowDup = 1;
            rowShift = 0;
            break;
        default:
            break;
        }

        drowStart -= rowShift;
        drowEnd = drowStart + rowDup;

        // Extend if bottom edge isn't covered because of the shift upward.
        if (((m_frameContext->height() - 1) - drowEnd) <= rowShift)
            drowEnd = m_frameContext->height() - 1;

        // Clamp first and last rows to upper and lower edge of image.
        if (drowStart < 0)
            drowStart = 0;

        if ((unsigned)drowEnd >= m_frameContext->height())
            drowEnd = m_frameContext->height() - 1;
    }

    // Protect against too much image data.
    if ((unsigned)drowStart >= m_frameContext->height())
        return true;

    // CALLBACK: Let the client know we have decoded a row.
    if (!m_client->haveDecodedRow(m_frameContext->frameId(), rowBegin, m_frameContext->width(),
        drowStart, drowEnd - drowStart + 1, m_frameContext->progressiveDisplay() && m_frameContext->interlaced() && ipass > 1))
        return false;

    if (!m_frameContext->interlaced())
        irow++;
    else {
        do {
            switch (ipass) {
            case 1:
                irow += 8;
                if (irow >= m_frameContext->height()) {
                    ipass++;
                    irow = 4;
                }
                break;

            case 2:
                irow += 8;
                if (irow >= m_frameContext->height()) {
                    ipass++;
                    irow = 2;
                }
                break;

            case 3:
                irow += 4;
                if (irow >= m_frameContext->height()) {
                    ipass++;
                    irow = 1;
                }
                break;

            case 4:
                irow += 2;
                if (irow >= m_frameContext->height()) {
                    ipass++;
                    irow = 0;
                }
                break;

            default:
                break;
            }
        } while (irow > (m_frameContext->height() - 1));
    }
    return true;
}

// Perform Lempel-Ziv-Welch decoding.
// Returns true if decoding was successful. In this case the block will have been completely consumed and/or rowsRemaining will be 0.
// Otherwise, decoding failed; returns false in this case, which will always cause the GIFImageReader to set the "decode failed" flag.
bool GIFLZWContext::doLZW(const unsigned char* block, size_t bytesInBlock)
{
    const size_t width = m_frameContext->width();

    if (rowIter == rowBuffer.end())
        return true;

    for (const unsigned char* ch = block; bytesInBlock-- > 0; ch++) {
        // Feed the next byte into the decoder's 32-bit input buffer.
        datum += ((int) *ch) << bits;
        bits += 8;

        // Check for underflow of decoder's 32-bit input buffer.
        while (bits >= codesize) {
            // Get the leading variable-length symbol from the data stream.
            int code = datum & codemask;
            datum >>= codesize;
            bits -= codesize;

            // Reset the dictionary to its original state, if requested.
            if (code == clearCode) {
                codesize = m_frameContext->dataSize() + 1;
                codemask = (1 << codesize) - 1;
                avail = clearCode + 2;
                oldcode = -1;
                continue;
            }

            // Check for explicit end-of-stream code.
            if (code == (clearCode + 1)) {
                // end-of-stream should only appear after all image data.
                if (!rowsRemaining)
                    return true;
                return false;
            }

            const int tempCode = code;
            unsigned short codeLength = 0;
            if (code < avail) {
                // This is a pre-existing code, so we already know what it
                // encodes.
                codeLength = suffixLength[code];
                rowIter += codeLength;
            } else if (code == avail && oldcode != -1) {
                // This is a new code just being added to the dictionary.
                // It must encode the contents of the previous code, plus
                // the first character of the previous code again.
                codeLength = suffixLength[oldcode] + 1;
                rowIter += codeLength;
                *--rowIter = firstchar;
                code = oldcode;
            } else {
                // This is an invalid code. The dictionary is just initialized
                // and the code is incomplete. We don't know how to handle
                // this case.
                return false;
            }

            while (code >= clearCode) {
                *--rowIter = suffix[code];
                code = prefix[code];
            }

            *--rowIter = firstchar = suffix[code];

            // Define a new codeword in the dictionary as long as we've read
            // more than one value from the stream.
            if (avail < MAX_DICTIONARY_ENTRIES && oldcode != -1) {
                prefix[avail] = oldcode;
                suffix[avail] = firstchar;
                suffixLength[avail] = suffixLength[oldcode] + 1;
                ++avail;

                // If we've used up all the codewords of a given length
                // increase the length of codewords by one bit, but don't
                // exceed the specified maximum codeword size.
                if (!(avail & codemask) && avail < MAX_DICTIONARY_ENTRIES) {
                    ++codesize;
                    codemask += avail;
                }
            }
            oldcode = tempCode;
            rowIter += codeLength;

            // Output as many rows as possible.
            GIFRow::iterator rowBegin = rowBuffer.begin();
            for (; rowBegin + width <= rowIter; rowBegin += width) {
                if (!outputRow(rowBegin))
                    return false;
                rowsRemaining--;
                if (!rowsRemaining)
                    return true;
            }

            if (rowBegin != rowBuffer.begin()) {
                // Move the remaining bytes to the beginning of the buffer.
                const size_t bytesToCopy = rowIter - rowBegin;
                memcpy(rowBuffer.begin(), rowBegin, bytesToCopy);
                rowIter = rowBuffer.begin() + bytesToCopy;
            }
        }
    }
    return true;
}

void GIFColorMap::buildTable(const unsigned char* data, size_t length)
{
    if (!m_isDefined || !m_table.isEmpty())
        return;

    RELEASE_ASSERT(m_position + m_colors * BYTES_PER_COLORMAP_ENTRY <= length);
    const unsigned char* srcColormap = data + m_position;
    m_table.resize(m_colors);
    for (Table::iterator iter = m_table.begin(); iter != m_table.end(); ++iter) {
        *iter = SkPackARGB32NoCheck(255, srcColormap[0], srcColormap[1], srcColormap[2]);
        srcColormap += BYTES_PER_COLORMAP_ENTRY;
    }
}

// Perform decoding for this frame. frameDecoded will be true if the entire frame is decoded.
// Returns false if a decoding error occurred. This is a fatal error and causes the GIFImageReader to set the "decode failed" flag.
// Otherwise, either not enough data is available to decode further than before, or the new data has been decoded successfully; returns true in this case.
bool GIFFrameContext::decode(const unsigned char* data, size_t length, GIFImageDecoder* client, bool* frameDecoded)
{
    m_localColorMap.buildTable(data, length);

    *frameDecoded = false;
    if (!m_lzwContext) {
        // Wait for more data to properly initialize GIFLZWContext.
        if (!isDataSizeDefined() || !isHeaderDefined())
            return true;

        m_lzwContext = adoptPtr(new GIFLZWContext(client, this));
        if (!m_lzwContext->prepareToDecode()) {
            m_lzwContext.clear();
            return false;
        }

        m_currentLzwBlock = 0;
    }

    // Some bad GIFs have extra blocks beyond the last row, which we don't want to decode.
    while (m_currentLzwBlock < m_lzwBlocks.size() && m_lzwContext->hasRemainingRows()) {
        size_t blockPosition = m_lzwBlocks[m_currentLzwBlock].blockPosition;
        size_t blockSize = m_lzwBlocks[m_currentLzwBlock].blockSize;
        if (blockPosition + blockSize > length)
            return false;
        if (!m_lzwContext->doLZW(data + blockPosition, blockSize))
            return false;
        ++m_currentLzwBlock;
    }

    // If this frame is data complete then the previous loop must have completely decoded all LZW blocks.
    // There will be no more decoding for this frame so it's time to cleanup.
    if (isComplete()) {
        *frameDecoded = true;
        m_lzwContext.clear();
    }
    return true;
}

// Decode a frame.
// This method uses GIFFrameContext:decode() to decode the frame; decoding error is reported to client as a critical failure.
// Return true if decoding has progressed. Return false if an error has occurred.
bool GIFImageReader::decode(size_t frameIndex)
{
    m_globalColorMap.buildTable(data(0), m_data->size());

    bool frameDecoded = false;
    GIFFrameContext* currentFrame = m_frames[frameIndex].get();

    return currentFrame->decode(data(0), m_data->size(), m_client, &frameDecoded)
        && (!frameDecoded || m_client->frameComplete(frameIndex));
}

bool GIFImageReader::parse(GIFImageDecoder::GIFParseQuery query)
{
    ASSERT(m_bytesRead <= m_data->size());

    return parseData(m_bytesRead, m_data->size() - m_bytesRead, query);
}

// Parse incoming GIF data stream into internal data structures.
// Return true if parsing has progressed or there is not enough data.
// Return false if a fatal error is encountered.
bool GIFImageReader::parseData(size_t dataPosition, size_t len, GIFImageDecoder::GIFParseQuery query)
{
    if (!len) {
        // No new data has come in since the last call, just ignore this call.
        return true;
    }

    if (len < m_bytesToConsume)
        return true;

    // This loop reads as many components from |m_data| as possible.
    // At the beginning of each iteration, dataPosition will be advanced by m_bytesToConsume to
    // point to the next component. len will be decremented accordingly.
    while (len >= m_bytesToConsume) {
        const size_t currentComponentPosition = dataPosition;
        const unsigned char* currentComponent = data(dataPosition);

        // Mark the current component as consumed. Note that currentComponent will remain pointed at this
        // component until the next loop iteration.
        dataPosition += m_bytesToConsume;
        len -= m_bytesToConsume;

        switch (m_state) {
        case GIFLZW:
            ASSERT(!m_frames.isEmpty());
            // m_bytesToConsume is the current component size because it hasn't been updated.
            m_frames.last()->addLzwBlock(currentComponentPosition, m_bytesToConsume);
            GETN(1, GIFSubBlock);
            break;

        case GIFLZWStart: {
            ASSERT(!m_frames.isEmpty());
            m_frames.last()->setDataSize(*currentComponent);
            GETN(1, GIFSubBlock);
            break;
        }

        case GIFType: {
            // All GIF files begin with "GIF87a" or "GIF89a".
            if (!strncmp((char*)currentComponent, "GIF89a", 6))
                m_version = 89;
            else if (!strncmp((char*)currentComponent, "GIF87a", 6))
                m_version = 87;
            else
                return false;
            GETN(7, GIFGlobalHeader);
            break;
        }

        case GIFGlobalHeader: {
            // This is the height and width of the "screen" or frame into which images are rendered. The
            // individual images can be smaller than the screen size and located with an origin anywhere
            // within the screen.
            m_screenWidth = GETINT16(currentComponent);
            m_screenHeight = GETINT16(currentComponent + 2);

            // CALLBACK: Inform the decoderplugin of our size.
            // Note: A subsequent frame might have dimensions larger than the "screen" dimensions.
            if (m_client && !m_client->setSize(m_screenWidth, m_screenHeight))
                return false;

            const size_t globalColorMapColors = 2 << (currentComponent[4] & 0x07);

            if ((currentComponent[4] & 0x80) && globalColorMapColors > 0) { /* global map */
                m_globalColorMap.setTablePositionAndSize(dataPosition, globalColorMapColors);
                GETN(BYTES_PER_COLORMAP_ENTRY * globalColorMapColors, GIFGlobalColormap);
                break;
            }

            GETN(1, GIFImageStart);
            break;
        }

        case GIFGlobalColormap: {
            m_globalColorMap.setDefined();
            GETN(1, GIFImageStart);
            break;
        }

        case GIFImageStart: {
            if (*currentComponent == '!') { // extension.
                GETN(2, GIFExtension);
                break;
            }

            if (*currentComponent == ',') { // image separator.
                GETN(9, GIFImageHeader);
                break;
            }

            // If we get anything other than ',' (image separator), '!'
            // (extension), or ';' (trailer), there is extraneous data
            // between blocks. The GIF87a spec tells us to keep reading
            // until we find an image separator, but GIF89a says such
            // a file is corrupt. We follow Mozilla's implementation and
            // proceed as if the file were correctly terminated, so the
            // GIF will display.
            GETN(0, GIFDone);
            break;
        }

        case GIFExtension: {
            size_t bytesInBlock = currentComponent[1];
            GIFState exceptionState = GIFSkipBlock;

            switch (*currentComponent) {
            case 0xf9:
                exceptionState = GIFControlExtension;
                // The GIF spec mandates that the GIFControlExtension header block length is 4 bytes,
                // and the parser for this block reads 4 bytes, so we must enforce that the buffer
                // contains at least this many bytes. If the GIF specifies a different length, we
                // allow that, so long as it's larger; the additional data will simply be ignored.
                bytesInBlock = std::max(bytesInBlock, static_cast<size_t>(4));
                break;

            // The GIF spec also specifies the lengths of the following two extensions' headers
            // (as 12 and 11 bytes, respectively). Because we ignore the plain text extension entirely
            // and sanity-check the actual length of the application extension header before reading it,
            // we allow GIFs to deviate from these values in either direction. This is important for
            // real-world compatibility, as GIFs in the wild exist with application extension headers
            // that are both shorter and longer than 11 bytes.
            case 0x01:
                // ignoring plain text extension
                break;

            case 0xff:
                exceptionState = GIFApplicationExtension;
                break;

            case 0xfe:
                exceptionState = GIFConsumeComment;
                break;
            }

            if (bytesInBlock)
                GETN(bytesInBlock, exceptionState);
            else
                GETN(1, GIFImageStart);
            break;
        }

        case GIFConsumeBlock: {
            if (!*currentComponent)
                GETN(1, GIFImageStart);
            else
                GETN(*currentComponent, GIFSkipBlock);
            break;
        }

        case GIFSkipBlock: {
            GETN(1, GIFConsumeBlock);
            break;
        }

        case GIFControlExtension: {
            addFrameIfNecessary();
            GIFFrameContext* currentFrame = m_frames.last().get();
            if (*currentComponent & 0x1)
                currentFrame->setTransparentPixel(currentComponent[3]);

            // We ignore the "user input" bit.

            // NOTE: This relies on the values in the FrameDisposalMethod enum
            // matching those in the GIF spec!
            int disposalMethod = ((*currentComponent) >> 2) & 0x7;
            if (disposalMethod < 4) {
                currentFrame->setDisposalMethod(static_cast<ImageFrame::DisposalMethod>(disposalMethod));
            } else if (disposalMethod == 4) {
                // Some specs say that disposal method 3 is "overwrite previous", others that setting
                // the third bit of the field (i.e. method 4) is. We map both to the same value.
                currentFrame->setDisposalMethod(ImageFrame::DisposeOverwritePrevious);
            }
            currentFrame->setDelayTime(GETINT16(currentComponent + 1) * 10);
            GETN(1, GIFConsumeBlock);
            break;
        }

        case GIFCommentExtension: {
            if (*currentComponent)
                GETN(*currentComponent, GIFConsumeComment);
            else
                GETN(1, GIFImageStart);
            break;
        }

        case GIFConsumeComment: {
            GETN(1, GIFCommentExtension);
            break;
        }

        case GIFApplicationExtension: {
            // Check for netscape application extension.
            if (m_bytesToConsume == 11
                && (!strncmp((char*)currentComponent, "NETSCAPE2.0", 11) || !strncmp((char*)currentComponent, "ANIMEXTS1.0", 11)))
                GETN(1, GIFNetscapeExtensionBlock);
            else
                GETN(1, GIFConsumeBlock);
            break;
        }

        // Netscape-specific GIF extension: animation looping.
        case GIFNetscapeExtensionBlock: {
            // GIFConsumeNetscapeExtension always reads 3 bytes from the stream; we should at least wait for this amount.
            if (*currentComponent)
                GETN(std::max(3, static_cast<int>(*currentComponent)), GIFConsumeNetscapeExtension);
            else
                GETN(1, GIFImageStart);
            break;
        }

        // Parse netscape-specific application extensions
        case GIFConsumeNetscapeExtension: {
            int netscapeExtension = currentComponent[0] & 7;

            // Loop entire animation specified # of times. Only read the loop count during the first iteration.
            if (netscapeExtension == 1) {
                m_loopCount = GETINT16(currentComponent + 1);

                // Zero loop count is infinite animation loop request.
                if (!m_loopCount)
                    m_loopCount = cAnimationLoopInfinite;

                GETN(1, GIFNetscapeExtensionBlock);
            } else if (netscapeExtension == 2) {
                // Wait for specified # of bytes to enter buffer.

                // Don't do this, this extension doesn't exist (isn't used at all)
                // and doesn't do anything, as our streaming/buffering takes care of it all...
                // See: http://semmix.pl/color/exgraf/eeg24.htm
                GETN(1, GIFNetscapeExtensionBlock);
            } else {
                // 0,3-7 are yet to be defined netscape extension codes
                return false;
            }
            break;
        }

        case GIFImageHeader: {
            unsigned height, width, xOffset, yOffset;

            /* Get image offsets, with respect to the screen origin */
            xOffset = GETINT16(currentComponent);
            yOffset = GETINT16(currentComponent + 2);

            /* Get image width and height. */
            width  = GETINT16(currentComponent + 4);
            height = GETINT16(currentComponent + 6);

            /* Work around broken GIF files where the logical screen
             * size has weird width or height.  We assume that GIF87a
             * files don't contain animations.
             */
            if (currentFrameIsFirstFrame()
                && ((m_screenHeight < height) || (m_screenWidth < width) || (m_version == 87))) {
                m_screenHeight = height;
                m_screenWidth = width;
                xOffset = 0;
                yOffset = 0;

                // CALLBACK: Inform the decoderplugin of our size.
                if (m_client && !m_client->setSize(m_screenWidth, m_screenHeight))
                    return false;
            }

            // Work around more broken GIF files that have zero image width or height
            if (!height || !width) {
                height = m_screenHeight;
                width = m_screenWidth;
                if (!height || !width)
                    return false;
            }

            if (query == GIFImageDecoder::GIFSizeQuery) {
                // The decoder needs to stop. Hand back the number of bytes we consumed from
                // buffer minus 9 (the amount we consumed to read the header).
                setRemainingBytes(len + 9);
                GETN(9, GIFImageHeader);
                return true;
            }

            addFrameIfNecessary();
            GIFFrameContext* currentFrame = m_frames.last().get();

            currentFrame->setHeaderDefined();
            currentFrame->setRect(xOffset, yOffset, width, height);
            m_screenWidth = std::max(m_screenWidth, width);
            m_screenHeight = std::max(m_screenHeight, height);
            currentFrame->setInterlaced(currentComponent[8] & 0x40);

            // Overlaying interlaced, transparent GIFs over
            // existing image data using the Haeberli display hack
            // requires saving the underlying image in order to
            // avoid jaggies at the transparency edges. We are
            // unprepared to deal with that, so don't display such
            // images progressively. Which means only the first
            // frame can be progressively displayed.
            // FIXME: It is possible that a non-transparent frame
            // can be interlaced and progressively displayed.
            currentFrame->setProgressiveDisplay(currentFrameIsFirstFrame());

            const bool isLocalColormapDefined = currentComponent[8] & 0x80;
            if (isLocalColormapDefined) {
                // The three low-order bits of currentComponent[8] specify the bits per pixel.
                const size_t numColors = 2 << (currentComponent[8] & 0x7);
                currentFrame->localColorMap().setTablePositionAndSize(dataPosition, numColors);
                GETN(BYTES_PER_COLORMAP_ENTRY * numColors, GIFImageColormap);
                break;
            }

            GETN(1, GIFLZWStart);
            break;
        }

        case GIFImageColormap: {
            ASSERT(!m_frames.isEmpty());
            m_frames.last()->localColorMap().setDefined();
            GETN(1, GIFLZWStart);
            break;
        }

        case GIFSubBlock: {
            const size_t bytesInBlock = *currentComponent;
            if (bytesInBlock)
                GETN(bytesInBlock, GIFLZW);
            else {
                // Finished parsing one frame; Process next frame.
                ASSERT(!m_frames.isEmpty());
                // Note that some broken GIF files do not have enough LZW blocks to fully
                // decode all rows but we treat it as frame complete.
                m_frames.last()->setComplete();
                GETN(1, GIFImageStart);
            }
            break;
        }

        case GIFDone: {
            m_parseCompleted = true;
            return true;
        }

        default:
            // We shouldn't ever get here.
            return false;
            break;
        }
    }

    setRemainingBytes(len);
    return true;
}

void GIFImageReader::setRemainingBytes(size_t remainingBytes)
{
    ASSERT(remainingBytes <= m_data->size());
    m_bytesRead = m_data->size() - remainingBytes;
}

void GIFImageReader::addFrameIfNecessary()
{
    if (m_frames.isEmpty() || m_frames.last()->isComplete())
        m_frames.append(adoptPtr(new GIFFrameContext(m_frames.size())));
}

// FIXME: Move this method to close to doLZW().
bool GIFLZWContext::prepareToDecode()
{
    ASSERT(m_frameContext->isDataSizeDefined() && m_frameContext->isHeaderDefined());

    // Since we use a codesize of 1 more than the datasize, we need to ensure
    // that our datasize is strictly less than the MAX_DICTIONARY_ENTRY_BITS.
    if (m_frameContext->dataSize() >= MAX_DICTIONARY_ENTRY_BITS)
        return false;
    clearCode = 1 << m_frameContext->dataSize();
    avail = clearCode + 2;
    oldcode = -1;
    codesize = m_frameContext->dataSize() + 1;
    codemask = (1 << codesize) - 1;
    datum = bits = 0;
    ipass = m_frameContext->interlaced() ? 1 : 0;
    irow = 0;

    // We want to know the longest sequence encodable by a dictionary with
    // MAX_DICTIONARY_ENTRIES entries. If we ignore the need to encode the base
    // values themselves at the beginning of the dictionary, as well as the need
    // for a clear code or a termination code, we could use every entry to
    // encode a series of multiple values. If the input value stream looked
    // like "AAAAA..." (a long string of just one value), the first dictionary
    // entry would encode AA, the next AAA, the next AAAA, and so forth. Thus
    // the longest sequence would be MAX_DICTIONARY_ENTRIES + 1 values.
    //
    // However, we have to account for reserved entries. The first |datasize|
    // bits are reserved for the base values, and the next two entries are
    // reserved for the clear code and termination code. In theory a GIF can
    // set the datasize to 0, meaning we have just two reserved entries, making
    // the longest sequence (MAX_DICTIONARY_ENTIRES + 1) - 2 values long. Since
    // each value is a byte, this is also the number of bytes in the longest
    // encodable sequence.
    const size_t maxBytes = MAX_DICTIONARY_ENTRIES - 1;

    // Now allocate the output buffer. We decode directly into this buffer
    // until we have at least one row worth of data, then call outputRow().
    // This means worst case we may have (row width - 1) bytes in the buffer
    // and then decode a sequence |maxBytes| long to append.
    rowBuffer.resize(m_frameContext->width() - 1 + maxBytes);
    rowIter = rowBuffer.begin();
    rowsRemaining = m_frameContext->height();

    // Clearing the whole suffix table lets us be more tolerant of bad data.
    for (int i = 0; i < clearCode; ++i) {
        suffix[i] = i;
        suffixLength[i] = 1;
    }
    return true;
}

} // namespace blink
