/*
 * Summary: Internal Interfaces for saving in libxml2
 * Description: this module describes a few interfaces which were
 *              addded along with the API changes in 2.9.0
 *              those are private routines at this point
 *
 * Copy: See Copyright for the status of this software.
 *
 * Author: Daniel Veillard
 */

#ifndef __XML_SAVE_H__
#define __XML_SAVE_H__

#include <libxml/tree.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifdef LIBXML_OUTPUT_ENABLED
void xmlBufAttrSerializeTxtContent(xmlBufPtr buf, xmlDocPtr doc,
                                   xmlAttrPtr attr, const xmlChar * string);
void xmlBufDumpNotationTable(xmlBufPtr buf, xmlNotationTablePtr table);
void xmlBufDumpElementDecl(xmlBufPtr buf, xmlElementPtr elem);
void xmlBufDumpAttributeDecl(xmlBufPtr buf, xmlAttributePtr attr);
void xmlBufDumpEntityDecl(xmlBufPtr buf, xmlEntityPtr ent);
xmlChar *xmlEncodeAttributeEntities(xmlDocPtr doc, const xmlChar *input);
#endif

#ifdef __cplusplus
}
#endif
#endif /* __XML_SAVE_H__ */

