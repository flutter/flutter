/*
 * Summary: Internal Interfaces for encoding in libxml2
 * Description: this module describes a few interfaces which were
 *              addded along with the API changes in 2.9.0
 *              those are private routines at this point
 *
 * Copy: See Copyright for the status of this software.
 *
 * Author: Daniel Veillard
 */

#ifndef __XML_ENC_H__
#define __XML_ENC_H__

#include <libxml/tree.h>

#ifdef __cplusplus
extern "C" {
#endif

int xmlCharEncFirstLineInt(xmlCharEncodingHandler *handler, xmlBufferPtr out,
                           xmlBufferPtr in, int len);
int xmlCharEncFirstLineInput(xmlParserInputBufferPtr input, int len);
int xmlCharEncInput(xmlParserInputBufferPtr input, int flush);
int xmlCharEncOutput(xmlOutputBufferPtr output, int init);

#ifdef __cplusplus
}
#endif
#endif /* __XML_ENC_H__ */


