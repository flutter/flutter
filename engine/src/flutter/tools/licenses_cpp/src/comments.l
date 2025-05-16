/**
 * Copyright 2013 The Flutter Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file.
 */

%option reentrant
%option noyywrap
%option extra-type="LexerContext*"

%{
#include "flutter/tools/licenses_cpp/src/comments.h"
#pragma clang diagnostic ignored "-Wsign-compare"
#pragma clang diagnostic ignored "-Wunused-function"
typedef void* yyscan_t;

struct LexerContext {
  std::function<void(const char*)> callback;
};
%}

%%
^[ \t]*(\/\/|#)[^\n]*  { yyextra->callback(yytext); }

%%

void lex(const char* buffer, size_t size, std::function<void(const char*)> callback) {
  LexerContext context;
  context.callback = std::move(callback);
  yyscan_t scanner;
  yylex_init_extra(&context, &scanner);
  YY_BUFFER_STATE yybuffer = yy_scan_bytes(buffer, size, scanner);
  yylex(scanner);
  yy_delete_buffer(yybuffer, scanner);
  yylex_destroy(scanner);
}
