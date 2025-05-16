/**
 * Copyright 2013 The Flutter Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file.
 */

%option reentrant
%option noyywrap

%{
#include <string>
#pragma clang diagnostic ignored "-Wsign-compare"
#pragma clang diagnostic ignored "-Wunused-function"
int num_lines = 0, num_chars = 0;
static std::string buf;
typedef void* yyscan_t;
%}

%%
^[ \t]*(\/\/|#)[^\n]*  { buf = yytext; }
\n  { ++num_lines; ++num_chars; }
.   { ++num_chars; }

%%

void lex(const char* buffer, size_t size) {
  yyscan_t scanner;
  yylex_init(&scanner);
  YY_BUFFER_STATE yybuffer = yy_scan_bytes(buffer, size, scanner);
  yylex(scanner);
  yy_delete_buffer(yybuffer, scanner);
  yylex_destroy(scanner);
}
