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

#include <string>

struct LexerContext {
  std::function<void(const char*)> callback;
  std::string buffer;
};
%}

COMMENT_START (\/\/|#)

%x C_COMMENT
%x BLOCK

%%
^[ \t]*{COMMENT_START}[^\n]* {
  BEGIN(BLOCK);
  yyextra->buffer.append(yytext, yyleng);
}
^[ \t]*\/\* {
  BEGIN(C_COMMENT);
  yyextra->buffer.append(yytext, yyleng);
}

<C_COMMENT>{
  \*\/ {
    BEGIN(INITIAL);
    yyextra->buffer.append(yytext, yyleng);
    yyextra->callback(yyextra->buffer.c_str());
    yyextra->buffer.clear();
  }
  \n|. {
    yyextra->buffer.append(yytext, yyleng);
  }
}

<BLOCK>{
  \n[ \t]*{COMMENT_START}[^\n]* {
    yyextra->buffer.append(yytext, yyleng);
  }
  \n|. {
    BEGIN(INITIAL);
    yyextra->callback(yyextra->buffer.c_str());
    yyextra->buffer.clear();
  }
}

\n|. {}
%%

void lex(const char* buffer,
         size_t size,
         std::function<void(const char*)> callback) {
  LexerContext context;
  context.buffer.reserve(4096);
  context.callback = std::move(callback);
  yyscan_t scanner;
  yylex_init_extra(&context, &scanner);
  YY_BUFFER_STATE yybuffer = yy_scan_bytes(buffer, size, scanner);
  yylex(scanner);
  yy_delete_buffer(yybuffer, scanner);
  yylex_destroy(scanner);
}
