// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/tools/compositor_model_bench/render_tree.h"

#include <sstream>
#include <vector>

#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/json/json_reader.h"
#include "base/json/json_writer.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/values.h"

#include "gpu/tools/compositor_model_bench/shaders.h"

using base::JSONReader;
using base::JSONWriter;
using base::ReadFileToString;
using std::string;
using std::vector;

GLenum TextureFormatFromString(std::string format) {
  if (format == "RGBA")
    return GL_RGBA;
  if (format == "RGB")
    return GL_RGB;
  if (format == "LUMINANCE")
    return GL_LUMINANCE;
  return GL_INVALID_ENUM;
}

const char* TextureFormatName(GLenum format) {
  switch (format) {
    case GL_RGBA:
      return "RGBA";
    case GL_RGB:
      return "RGB";
    case GL_LUMINANCE:
      return "LUMINANCE";
    default:
      return "(unknown format)";
  }
}

int FormatBytesPerPixel(GLenum format) {
  switch (format) {
    case GL_RGBA:
      return 4;
    case GL_RGB:
      return 3;
    case GL_LUMINANCE:
      return 1;
    default:
      return 0;
  }
}

RenderNode::RenderNode() {
}

RenderNode::~RenderNode() {
}

void RenderNode::Accept(RenderNodeVisitor* v) {
  v->BeginVisitRenderNode(this);
  v->EndVisitRenderNode(this);
}

ContentLayerNode::ContentLayerNode() {
}

ContentLayerNode::~ContentLayerNode() {
}

void ContentLayerNode::Accept(RenderNodeVisitor* v) {
  v->BeginVisitContentLayerNode(this);
  typedef vector<RenderNode*>::iterator node_itr;
  for (node_itr i = children_.begin(); i != children_.end(); ++i) {
    (*i)->Accept(v);
  }
  v->EndVisitContentLayerNode(this);
}

CCNode::CCNode() {
}

CCNode::~CCNode() {
}

void CCNode::Accept(RenderNodeVisitor* v) {
  v->BeginVisitCCNode(this);
  v->EndVisitCCNode(this);
}

RenderNodeVisitor::~RenderNodeVisitor() {
}

void RenderNodeVisitor::BeginVisitContentLayerNode(ContentLayerNode* v) {
  this->BeginVisitRenderNode(v);
}

void RenderNodeVisitor::BeginVisitCCNode(CCNode* v) {
  this->BeginVisitRenderNode(v);
}

void RenderNodeVisitor::EndVisitRenderNode(RenderNode* v) {
}

void RenderNodeVisitor::EndVisitContentLayerNode(ContentLayerNode* v) {
  this->EndVisitRenderNode(v);
}

void RenderNodeVisitor::EndVisitCCNode(CCNode* v) {
  this->EndVisitRenderNode(v);
}

RenderNode* InterpretNode(base::DictionaryValue* node);

std::string ValueTypeAsString(base::Value::Type type) {
  switch (type) {
    case base::Value::TYPE_NULL:
      return "NULL";
    case base::Value::TYPE_BOOLEAN:
      return "BOOLEAN";
    case base::Value::TYPE_INTEGER:
      return "INTEGER";
    case base::Value::TYPE_DOUBLE:
      return "DOUBLE";
    case base::Value::TYPE_STRING:
      return "STRING";
    case base::Value::TYPE_BINARY:
      return "BINARY";
    case base::Value::TYPE_DICTIONARY:
      return "DICTIONARY";
    case base::Value::TYPE_LIST:
      return "LIST";
    default:
      return "(UNKNOWN TYPE)";
  }
}

// Makes sure that the key exists and has the type we expect.
bool VerifyDictionaryEntry(base::DictionaryValue* node,
                           const std::string& key,
                           base::Value::Type type) {
  if (!node->HasKey(key)) {
    LOG(ERROR) << "Missing value for key: " << key;
    return false;
  }

  base::Value* child;
  node->Get(key, &child);
  if (!child->IsType(type)) {
    LOG(ERROR) << key << " did not have the expected type "
      "(expected " << ValueTypeAsString(type) << ")";
    return false;
  }

  return true;
}

// Makes sure that the list entry has the type we expect.
bool VerifyListEntry(base::ListValue* l,
                     int idx,
                     base::Value::Type type,
                     const char* listName = 0) {
  // Assume the idx is valid (since we'll be able to generate a better
  // error message for this elsewhere.)
  base::Value* el;
  l->Get(idx, &el);
  if (!el->IsType(type)) {
    LOG(ERROR) << (listName ? listName : "List") << "element " << idx <<
      " did not have the expected type (expected " <<
      ValueTypeAsString(type) << ")\n";
    return false;
  }

  return true;
}

bool InterpretCommonContents(base::DictionaryValue* node, RenderNode* c) {
  if (!VerifyDictionaryEntry(node, "layerID", base::Value::TYPE_INTEGER) ||
      !VerifyDictionaryEntry(node, "width", base::Value::TYPE_INTEGER) ||
      !VerifyDictionaryEntry(node, "height", base::Value::TYPE_INTEGER) ||
      !VerifyDictionaryEntry(node, "drawsContent", base::Value::TYPE_BOOLEAN) ||
      !VerifyDictionaryEntry(node, "targetSurfaceID",
                             base::Value::TYPE_INTEGER) ||
      !VerifyDictionaryEntry(node, "transform", base::Value::TYPE_LIST)
    ) {
    return false;
  }

  int layerID;
  node->GetInteger("layerID", &layerID);
  c->set_layerID(layerID);
  int width;
  node->GetInteger("width", &width);
  c->set_width(width);
  int height;
  node->GetInteger("height", &height);
  c->set_height(height);
  bool drawsContent;
  node->GetBoolean("drawsContent", &drawsContent);
  c->set_drawsContent(drawsContent);
  int targetSurface;
  node->GetInteger("targetSurfaceID", &targetSurface);
  c->set_targetSurface(targetSurface);

  base::ListValue* transform;
  node->GetList("transform", &transform);
  if (transform->GetSize() != 16) {
    LOG(ERROR) << "4x4 transform matrix did not have 16 elements";
    return false;
  }
  float transform_mat[16];
  for (int i = 0; i < 16; ++i) {
    if (!VerifyListEntry(transform, i, base::Value::TYPE_DOUBLE, "Transform"))
      return false;
    double el;
    transform->GetDouble(i, &el);
    transform_mat[i] = el;
  }
  c->set_transform(transform_mat);

  if (node->HasKey("tiles")) {
    if (!VerifyDictionaryEntry(node, "tiles", base::Value::TYPE_DICTIONARY))
      return false;
    base::DictionaryValue* tiles_dict;
    node->GetDictionary("tiles", &tiles_dict);
    if (!VerifyDictionaryEntry(tiles_dict, "dim", base::Value::TYPE_LIST))
      return false;
    base::ListValue* dim;
    tiles_dict->GetList("dim", &dim);
    if (!VerifyListEntry(dim, 0, base::Value::TYPE_INTEGER, "Tile dimension") ||
        !VerifyListEntry(dim, 1, base::Value::TYPE_INTEGER, "Tile dimension")) {
      return false;
    }
    int tile_width;
    dim->GetInteger(0, &tile_width);
    c->set_tile_width(tile_width);
    int tile_height;
    dim->GetInteger(1, &tile_height);
    c->set_tile_height(tile_height);

    if (!VerifyDictionaryEntry(tiles_dict, "info", base::Value::TYPE_LIST))
      return false;
    base::ListValue* tiles;
    tiles_dict->GetList("info", &tiles);
    for (unsigned int i = 0; i < tiles->GetSize(); ++i) {
      if (!VerifyListEntry(tiles, i, base::Value::TYPE_DICTIONARY, "Tile info"))
        return false;
      base::DictionaryValue* tdict;
      tiles->GetDictionary(i, &tdict);

      if (!VerifyDictionaryEntry(tdict, "x", base::Value::TYPE_INTEGER) ||
          !VerifyDictionaryEntry(tdict, "y", base::Value::TYPE_INTEGER)) {
        return false;
      }
      Tile t;
      tdict->GetInteger("x", &t.x);
      tdict->GetInteger("y", &t.y);
      if (tdict->HasKey("texID")) {
        if (!VerifyDictionaryEntry(tdict, "texID", base::Value::TYPE_INTEGER))
          return false;
        tdict->GetInteger("texID", &t.texID);
      } else {
        t.texID = -1;
      }
      c->add_tile(t);
    }
  }
  return true;
}

bool InterpretCCData(base::DictionaryValue* node, CCNode* c) {
  if (!VerifyDictionaryEntry(node, "vertex_shader", base::Value::TYPE_STRING) ||
      !VerifyDictionaryEntry(node, "fragment_shader",
                             base::Value::TYPE_STRING) ||
      !VerifyDictionaryEntry(node, "textures", base::Value::TYPE_LIST)) {
    return false;
  }
  string vertex_shader_name, fragment_shader_name;
  node->GetString("vertex_shader", &vertex_shader_name);
  node->GetString("fragment_shader", &fragment_shader_name);

  c->set_vertex_shader(ShaderIDFromString(vertex_shader_name));
  c->set_fragment_shader(ShaderIDFromString(fragment_shader_name));
  base::ListValue* textures;
  node->GetList("textures", &textures);
  for (unsigned int i = 0; i < textures->GetSize(); ++i) {
    if (!VerifyListEntry(textures, i, base::Value::TYPE_DICTIONARY, "Tex list"))
      return false;
    base::DictionaryValue* tex;
    textures->GetDictionary(i, &tex);

    if (!VerifyDictionaryEntry(tex, "texID", base::Value::TYPE_INTEGER) ||
        !VerifyDictionaryEntry(tex, "height", base::Value::TYPE_INTEGER) ||
        !VerifyDictionaryEntry(tex, "width", base::Value::TYPE_INTEGER) ||
        !VerifyDictionaryEntry(tex, "format", base::Value::TYPE_STRING)) {
      return false;
    }
    Texture t;
    tex->GetInteger("texID", &t.texID);
    tex->GetInteger("height", &t.height);
    tex->GetInteger("width", &t.width);

    string formatName;
    tex->GetString("format", &formatName);
    t.format = TextureFormatFromString(formatName);
    if (t.format == GL_INVALID_ENUM) {
      LOG(ERROR) << "Unrecognized texture format in layer " << c->layerID() <<
        " (format: " << formatName << ")\n"
        "The layer had " << textures->GetSize() << " children.";
      return false;
    }

    c->add_texture(t);
  }

  if (c->vertex_shader() == SHADER_UNRECOGNIZED) {
    LOG(ERROR) << "Unrecognized vertex shader name, layer " << c->layerID() <<
      " (shader: " << vertex_shader_name << ")";
    return false;
  }

  if (c->fragment_shader() == SHADER_UNRECOGNIZED) {
    LOG(ERROR) << "Unrecognized fragment shader name, layer " << c->layerID() <<
      " (shader: " << fragment_shader_name << ")";
    return false;
  }

  return true;
}

RenderNode* InterpretContentLayer(base::DictionaryValue* node) {
  ContentLayerNode* n = new ContentLayerNode;
  if (!InterpretCommonContents(node, n))
    return NULL;

  if (!VerifyDictionaryEntry(node, "type", base::Value::TYPE_STRING) ||
      !VerifyDictionaryEntry(node, "skipsDraw", base::Value::TYPE_BOOLEAN) ||
      !VerifyDictionaryEntry(node, "children", base::Value::TYPE_LIST)) {
    return NULL;
  }

  string type;
  node->GetString("type", &type);
  DCHECK_EQ(type, "ContentLayer");
  bool skipsDraw;
  node->GetBoolean("skipsDraw", &skipsDraw);
  n->set_skipsDraw(skipsDraw);

  base::ListValue* children;
  node->GetList("children", &children);
  for (unsigned int i = 0; i < children->GetSize(); ++i) {
    base::DictionaryValue* childNode;
    children->GetDictionary(i, &childNode);
    RenderNode* child = InterpretNode(childNode);
    if (child)
      n->add_child(child);
  }

  return n;
}

RenderNode* InterpretCanvasLayer(base::DictionaryValue* node) {
  CCNode* n = new CCNode;
  if (!InterpretCommonContents(node, n))
    return NULL;

  if (!VerifyDictionaryEntry(node, "type", base::Value::TYPE_STRING)) {
    return NULL;
  }

  string type;
  node->GetString("type", &type);
  assert(type == "CanvasLayer");

  if (!InterpretCCData(node, n))
    return NULL;

  return n;
}

RenderNode* InterpretVideoLayer(base::DictionaryValue* node) {
  CCNode* n = new CCNode;
  if (!InterpretCommonContents(node, n))
    return NULL;

  if (!VerifyDictionaryEntry(node, "type", base::Value::TYPE_STRING)) {
    return NULL;
  }

  string type;
  node->GetString("type", &type);
  assert(type == "VideoLayer");

  if (!InterpretCCData(node, n))
    return NULL;

  return n;
}

RenderNode* InterpretImageLayer(base::DictionaryValue* node) {
  CCNode* n = new CCNode;
  if (!InterpretCommonContents(node, n))
    return NULL;

  if (!VerifyDictionaryEntry(node, "type", base::Value::TYPE_STRING)) {
    return NULL;
  }

  string type;
  node->GetString("type", &type);
  assert(type == "ImageLayer");

  if (!InterpretCCData(node, n))
    return NULL;

  return n;
}

RenderNode* InterpretNode(base::DictionaryValue* node) {
  if (!VerifyDictionaryEntry(node, "type", base::Value::TYPE_STRING)) {
    return NULL;
  }

  string type;
  node->GetString("type", &type);
  if (type == "ContentLayer")
    return InterpretContentLayer(node);
  if (type == "CanvasLayer")
    return InterpretCanvasLayer(node);
  if (type == "VideoLayer")
    return InterpretVideoLayer(node);
  if (type == "ImageLayer")
    return InterpretImageLayer(node);


  string outjson;
  JSONWriter::WriteWithOptions(node, base::JSONWriter::OPTIONS_PRETTY_PRINT,
                               &outjson);
  LOG(ERROR) << "Unrecognized node type! JSON:\n\n"
      "-----------------------\n" <<
      outjson <<
      "-----------------------";

  return NULL;
}

RenderNode* BuildRenderTreeFromFile(const base::FilePath& path) {
  LOG(INFO) << "Reading " << path.LossyDisplayName();
  string contents;
  if (!ReadFileToString(path, &contents))
    return NULL;

  scoped_ptr<base::Value> root;
  int error_code = 0;
  string error_message;
  root.reset(JSONReader::ReadAndReturnError(contents,
            base::JSON_ALLOW_TRAILING_COMMAS,
            &error_code,
            &error_message));
  if (!root.get()) {
    LOG(ERROR) << "Failed to parse JSON file " << path.LossyDisplayName() <<
        "\n(" << error_message << ")";
    return NULL;
  }

  if (root->IsType(base::Value::TYPE_DICTIONARY)) {
    base::DictionaryValue* v = static_cast<base::DictionaryValue*>(root.get());
    RenderNode* tree = InterpretContentLayer(v);
    return tree;
  } else {
    LOG(ERROR) << path.LossyDisplayName() <<
        " doesn not encode a JSON dictionary.";
    return NULL;
  }
}

