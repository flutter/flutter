#define WIN32_MEAN_AND_LEAN
#define WIN32_LEAN_AND_MEAN
//#include <windows.h>
#include <conio.h>
#define STB_STUA
#define STB_DEFINE
#define STB_NPTR
#define STB_ONLY
#include "stb.h"
//#include "stb_file.h"

int count;
void c(int truth, char *error)
{
   if (!truth) {
      fprintf(stderr, "Test failed: %s\n", error);
      ++count;
   }
}

char *expects(stb_matcher *m, char *s, int result, int len, char *str)
{
   int res2,len2=0;
   res2 = stb_lex(m, s, &len2);
   c(result == res2 && len == len2, str);
   return s + len;
}

void test_lex(void)
{
   stb_matcher *m = stb_lex_matcher();
   //         tok_en5 .3 20.1 20. .20 .1
   char *s = "tok_en5.3 20.1 20. .20.1";

   stb_lex_item(m, "[a-zA-Z_][a-zA-Z0-9_]*", 1   );
   stb_lex_item(m, "[0-9]*\\.?[0-9]*"      , 2   );
   stb_lex_item(m, "[\r\n\t ]+"            , 3   );
   stb_lex_item(m, "."                     , -99 );
   s=expects(m,s,1,7, "stb_lex 1");
   s=expects(m,s,2,2, "stb_lex 2");
   s=expects(m,s,3,1, "stb_lex 3");
   s=expects(m,s,2,4, "stb_lex 4");
   s=expects(m,s,3,1, "stb_lex 5");
   s=expects(m,s,2,3, "stb_lex 6");
   s=expects(m,s,3,1, "stb_lex 7");
   s=expects(m,s,2,3, "stb_lex 8");
   s=expects(m,s,2,2, "stb_lex 9");
   s=expects(m,s,0,0, "stb_lex 10");
   stb_matcher_free(m);
}

int main(int argc, char **argv)
{
   char *p;
   p = "abcdefghijklmnopqrstuvwxyz";
   c(stb_ischar('c', p), "stb_ischar 1");
   c(stb_ischar('x', p), "stb_ischar 2");
   c(!stb_ischar('#', p), "stb_ischar 3");
   c(!stb_ischar('X', p), "stb_ischar 4");
   p = "0123456789";
   c(!stb_ischar('c', p), "stb_ischar 5");
   c(!stb_ischar('x', p), "stb_ischar 6");
   c(!stb_ischar('#', p), "stb_ischar 7");
   c(!stb_ischar('X', p), "stb_ischar 8");
   p = "#####";
   c(!stb_ischar('c', p), "stb_ischar a");
   c(!stb_ischar('x', p), "stb_ischar b");
   c(stb_ischar('#', p), "stb_ischar c");
   c(!stb_ischar('X', p), "stb_ischar d");
   p = "xXyY";
   c(!stb_ischar('c', p), "stb_ischar e");
   c(stb_ischar('x', p), "stb_ischar f");
   c(!stb_ischar('#', p), "stb_ischar g");
   c(stb_ischar('X', p), "stb_ischar h");

   test_lex();

   if (count) {
      _getch();
   }
   return 0;
}
