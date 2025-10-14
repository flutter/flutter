/**
 * Copyright 2013 The Flutter Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file.
 */
/**
 * To regenerate comments.cc run:
 * flex -o comments.cc comments.l
 */
%option reentrant
%option noyywrap
%option extra-type="LexerContext*"

%top{
// No linting because it's generated code.
// FLUTTER_NOLINT: https://github.com/flutter/flutter/issues/167141
}

%{
#include "flutter/tools/licenses_cpp/src/comments.h"
#include "flutter/tools/licenses_cpp/src/comments_util.h"
#pragma clang diagnostic ignored "-Wsign-compare"
#pragma clang diagnostic ignored "-Wunused-function"
#pragma clang diagnostic ignored "-Wunused-function"
typedef void* yyscan_t;

#include <string>

struct LexerContext {
  std::function<void(std::string_view)> callback;
  std::string buffer;
};
%}

COMMENT_START (\/\/|#)

%x C_COMMENT
%x BLOCK

%%
^[ \t]*{COMMENT_START}[^\n]* {
  BEGIN(BLOCK);
  CommentsUtil::AddTrimLine(&yyextra->buffer, yytext, yyleng);
}
^[ \t]*\/\*[\*]*[\n]? {
  BEGIN(C_COMMENT);
  if (!yyextra->buffer.empty()) {
    // If we go from a block to a c comment, add a newline between them.
    yyextra->buffer.append("\n");
  }
}

<C_COMMENT>{
  .*\*\/.*\n {
    BEGIN(INITIAL);
    CommentsUtil::AddCEndTrimLine(&yyextra->buffer, yytext, yyleng - 2);
  }
  .*\n {
    CommentsUtil::AddCTrimLine(&yyextra->buffer, yytext, yyleng);
  }
}

<BLOCK>{
  \n[ \t]*{COMMENT_START}[^\n]* {
    yyextra->buffer.append("\n", 1);
    CommentsUtil::AddTrimLine(&yyextra->buffer, yytext + 1, yyleng - 1);
  }
  \n|. {
    BEGIN(INITIAL);
  }
}

\n|. {
  if (!yyextra->buffer.empty()) {
    yyextra->callback(yyextra->buffer);
    yyextra->buffer.clear();
  }
}
%%

void IterateComments(const char* buffer,
                     size_t size,
                     std::function<void(std::string_view)> callback) {
  LexerContext context;
  context.buffer.reserve(4096);
  context.callback = std::move(callback);
  yyscan_t scanner;
  yylex_init_extra(&context, &scanner);
  YY_BUFFER_STATE yybuffer = yy_scan_bytes(buffer, size, scanner);
  yylex(scanner);
  if (!context.buffer.empty()) {
    context.callback(context.buffer);
  }
  yy_delete_buffer(yybuffer, scanner);
  yylex_destroy(scanner);
}
