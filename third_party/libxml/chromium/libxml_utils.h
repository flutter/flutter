// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef THIRD_PARTY_LIBXML_CHROMIUM_LIBXML_UTILS_H_
#define THIRD_PARTY_LIBXML_CHROMIUM_LIBXML_UTILS_H_
#pragma once

#include <string>

#include "libxml/xmlreader.h"
#include "libxml/xmlwriter.h"

// Converts a libxml xmlChar* into a UTF-8 std::string.
// NULL inputs produce an empty string.
std::string XmlStringToStdString(const xmlChar* xmlstring);

// libxml uses a global error function pointer for reporting errors.
// A ScopedXmlErrorFunc object lets you change the global error pointer
// for the duration of the object's lifetime.
class ScopedXmlErrorFunc {
 public:
  ScopedXmlErrorFunc(void* context, xmlGenericErrorFunc func) {
    old_error_func_ = xmlGenericError;
    old_error_context_ = xmlGenericErrorContext;
    xmlSetGenericErrorFunc(context, func);
  }
  ~ScopedXmlErrorFunc() {
    xmlSetGenericErrorFunc(old_error_context_, old_error_func_);
  }

 private:
  xmlGenericErrorFunc old_error_func_;
  void* old_error_context_;
};

// XmlReader is a wrapper class around libxml's xmlReader,
// providing a simplified C++ API.
class XmlReader {
 public:
  XmlReader();
  ~XmlReader();

  // Load a document into the reader from memory.  |input| must be UTF-8 and
  // exist for the lifetime of this object.  Returns false on error.
  // TODO(evanm): handle encodings other than UTF-8?
  bool Load(const std::string& input);

  // Load a document into the reader from a file.  Returns false on error.
  bool LoadFile(const std::string& file_path);

  // Wrappers around libxml functions -----------------------------------------

  // Read() advances to the next node.  Returns false on EOF or error.
  bool Read() { return xmlTextReaderRead(reader_) == 1; }

  // Next(), when pointing at an opening tag, advances to the node after
  // the matching closing tag.  Returns false on EOF or error.
  bool Next() { return xmlTextReaderNext(reader_) == 1; }

  // Return the depth in the tree of the current node.
  int Depth() { return xmlTextReaderDepth(reader_); }

  // Returns the "local" name of the current node.
  // For a tag like <foo:bar>, this is the string "foo:bar".
  std::string NodeName() {
    return XmlStringToStdString(xmlTextReaderConstLocalName(reader_));
  }

  // When pointing at a tag, retrieves the value of an attribute.
  // Returns false on failure.
  // E.g. for <foo bar:baz="a">, NodeAttribute("bar:baz", &value)
  // returns true and |value| is set to "a".
  bool NodeAttribute(const char* name, std::string* value);

  // Returns true if the node is a closing element (e.g. </foo>).
  bool IsClosingElement();

  // Helper functions not provided by libxml ----------------------------------

  // Return the string content within an element.
  // "<foo>bar</foo>" is a sequence of three nodes:
  // (1) open tag, (2) text, (3) close tag.
  // With the reader currently at (1), this returns the text of (2),
  // and advances past (3).
  // Returns false on error.
  bool ReadElementContent(std::string* content);

  // Skip to the next opening tag, returning false if we reach a closing
  // tag or EOF first.
  // If currently on an opening tag, doesn't advance at all.
  bool SkipToElement();

 private:
  // Returns the libxml node type of the current node.
  int NodeType() { return xmlTextReaderNodeType(reader_); }

  // The underlying libxml xmlTextReader.
  xmlTextReaderPtr reader_;
};

// XmlWriter is a wrapper class around libxml's xmlWriter,
// providing a simplified C++ API.
// StartWriting must be called before other methods, and StopWriting
// must be called before GetWrittenString() will return results.
class XmlWriter {
 public:
  XmlWriter();
  ~XmlWriter();

  // Allocates the xmlTextWriter and an xmlBuffer and starts an XML document.
  // This must be called before any other functions. By default, indenting is
  // set to true.
  void StartWriting();

  // Ends the XML document and frees the xmlTextWriter.
  // This must be called before GetWrittenString() is called.
  void StopWriting();
  // Wrappers around libxml functions -----------------------------------------

  // All following elements will be indented to match their depth.
  void StartIndenting() { xmlTextWriterSetIndent(writer_, 1); }

  // All follow elements will not be indented.
  void StopIndenting() { xmlTextWriterSetIndent(writer_, 0); }

  // Start an element with the given name. All future elements added will be
  // children of this element, until it is ended. Returns false on error.
  bool StartElement(const std::string& element_name) {
    return xmlTextWriterStartElement(writer_,
                                     BAD_CAST element_name.c_str()) >= 0;
  }

  // Ends the current open element. Returns false on error.
  bool EndElement() {
    return xmlTextWriterEndElement(writer_) >= 0;
  }

  // Appends to the content of the current open element.
  bool AppendElementContent(const std::string& content) {
    return xmlTextWriterWriteString(writer_,
                                    BAD_CAST content.c_str()) >= 0;
  }

  // Adds an attribute to the current open element. Returns false on error.
  bool AddAttribute(const std::string& attribute_name,
                    const std::string& attribute_value) {
    return xmlTextWriterWriteAttribute(writer_,
                                       BAD_CAST attribute_name.c_str(),
                                       BAD_CAST attribute_value.c_str()) >= 0;
  }

  // Adds a new element with name |element_name| and content |content|
  // to the buffer. Example: <|element_name|>|content|</|element_name|>
  // Returns false on errors.
  bool WriteElement(const std::string& element_name,
                    const std::string& content) {
    return xmlTextWriterWriteElement(writer_,
                                     BAD_CAST element_name.c_str(),
                                     BAD_CAST content.c_str()) >= 0;
  }

  // Helper functions not provided by xmlTextWriter ---------------------------

  // Returns the string that has been written to the buffer.
  std::string GetWrittenString() {
    if (buffer_ == NULL)
      return "";
    return XmlStringToStdString(buffer_->content);
  }

 private:
  // The underlying libxml xmlTextWriter.
  xmlTextWriterPtr writer_;

  // Stores the output.
  xmlBufferPtr buffer_;
};

#endif  // THIRD_PARTY_LIBXML_CHROMIUM_INCLUDE_LIBXML_LIBXML_UTILS_H_
