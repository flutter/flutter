/*
 * Unit tests for "stb.h"
 */

//#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <assert.h>
#include <stdlib.h>

#ifdef _WIN32
#include <crtdbg.h>
#endif

#define STB_STUA
//#define STB_FASTMALLOC
#ifdef _DEBUG
#define STB_MALLOC_WRAPPER_DEBUG
#endif
#define STB_NPTR
#define STB_DEFINE
#include "stb.h"

//#include "stb_file.h"
//#include "stb_pixel32.h"

//#define DEBUG_BLOCK
#ifdef DEBUG_BLOCK
#include <conio.h>
#endif

#ifdef STB_FASTMALLOC
#error "can't use FASTMALLOC with threads"
#endif

int count;
void c(int truth, char *error)
{
   if (!truth) {
      fprintf(stderr, "Test failed: %s\n", error);
      ++count;
   }
}


#if 0
void show(void)
{
   #ifdef _WIN32
   SYSTEM_INFO x;
   GetSystemInfo(&x);
   printf("%d\n", x.dwPageSize);
   #endif
}
#endif

void test_classes(void)
{
   unsigned char size_base[32], size_shift[32];
   int class_to_pages[256];
   int class_to_size[256], cl;
   int lg, size, wasted_pages;
   int kAlignShift = 3;
   int kAlignment = 1 << kAlignShift;
   int kMaxSize = 8 * 4096;
   int kPageShift = 12;
   int kPageSize = (1 << kPageShift);
  int next_class = 1;
  int alignshift = kAlignShift;
  int last_lg = -1;

  for (lg = 0; lg < kAlignShift; lg++) {
    size_base[lg] = 1;
    size_shift[lg] = kAlignShift;
  }

  for (size = kAlignment; size <= kMaxSize; size += (1 << alignshift)) {
    int lg = stb_log2_floor(size);
    if (lg > last_lg) {
      // Increase alignment every so often.
      //
      // Since we double the alignment every time size doubles and
      // size >= 128, this means that space wasted due to alignment is
      // at most 16/128 i.e., 12.5%.  Plus we cap the alignment at 256
      // bytes, so the space wasted as a percentage starts falling for
      // sizes > 2K.
      if ((lg >= 7) && (alignshift < 8)) {
        alignshift++;
      }
      size_base[lg] = next_class - ((size-1) >> alignshift);
      size_shift[lg] = alignshift;
    }

    class_to_size[next_class] = size;
    last_lg = lg;

    next_class++;
  }

  // Initialize the number of pages we should allocate to split into
  // small objects for a given class.
  wasted_pages = 0;
  for (cl = 1; cl < next_class; cl++) {
    // Allocate enough pages so leftover is less than 1/8 of total.
    // This bounds wasted space to at most 12.5%.
    size_t psize = kPageSize;
    const size_t s = class_to_size[cl];
    while ((psize % s) > (psize >> 3)) {
      psize += kPageSize;
    }
    class_to_pages[cl] = psize >> kPageShift;
    wasted_pages += psize;
  }

  printf("TCMalloc can waste as much as %d memory on one-shot allocations\n", wasted_pages);


  return;
}


void test_script(void)
{
   stua_run_script(
      "var g = (2+3)*5 + 3*(2+1) + ((7)); \n"
      "func sprint(x) _print(x) _print(' ') x end;\n"
      "func foo(y) var q = func(x) sprint(x) end; q end;\n "
      "var z=foo(5); z(77);\n"
      "func counter(z) func(x) z=z+1 end end\n"
      "var q=counter(0), p=counter(5);\n"
      "sprint(q()) sprint(p()) sprint(q()) sprint(p()) sprint(q()) sprint(p())\n"
      "var x=2222;\n"
      "if 1 == 2 then 3333 else 4444 end; => x; sprint(x);\n"
      "var x1 = sprint(1.5e3);  \n"
      "var x2 = sprint(.5);  \n"
      "var x3 = sprint(1.);  \n"
      "var x4 = sprint(1.e3);  \n"
      "var x5 = sprint(1e3);  \n"
      "var x6 = sprint(0.5e3);  \n"
      "var x7 = sprint(.5e3);  \n"
      " func sum(x,y) x+y end                                       \n"
      " func sumfunc(a) sum+{x=a} end                               \n"
      " var q = sumfunc(3) \n"
      " var p = sumfunc(20) \n"
      " var d = sprint(q(5)) - sprint(q(8)) \n"
      " var e = sprint(p(5)) - sprint(p(8)) \n"
      " func test3(x)       \n"
      "    sprint(x)         \n"
      "    x = x+3          \n"
      "    sprint(x)         \n"
      "    x+5              \n"
      " end                 \n"
      " var y = test3(4);   \n"
      " func fib(x)         \n"
      "    if x < 3 then    \n"
      "       1             \n"
      "    else             \n"
      "      fib(x-1) + fib(x-2); \n"
      "    end              \n"
      " end                 \n"
      "                     \n"
      " func fib2(x)        \n"
      "    var a=1          \n"
      "    var b=1          \n"
      "    sprint(a)        \n"
      "    sprint(b)        \n"
      "    while x > 2 do   \n"
      "       var c=a+b     \n"
      "       a=b           \n"
      "       b=c           \n"
      "       sprint(b)     \n"
      "       x=x-1         \n"
      "    end              \n"
      "    b                \n"
      " end                 \n"
      "                                                             \n"
      " func assign(z)                                              \n"
      "    var y = { 'this', 'is', 'a', 'lame', 'day', 'to', 'die'} \n"
      "    y[3] = z                                                 \n"
      "    var i = 0                                                \n"
      "    while y[i] != nil do                                     \n"
      "       sprint(y[i])                                          \n"
      "       i = i+1                                               \n"
      "    end                                                      \n"
      " end                                                         \n"
      "                                                             \n"
      " sprint(fib(12)); \n"
      " assign(\"good\"); \n"
      " fib2(20); \n"
      " sprint('ok'); \n"
      " sprint(-5); \n"
      " // final comment with no newline"
   );
}

#ifdef STB_THREADS
extern void __stdcall Sleep(unsigned long);

void * thread_1(void *x)
{
   Sleep(80);
   printf("thread 1\n"); fflush(stdout);
   return (void *) 2;
}

void * thread_2(void *y)
{
   stb_work(thread_1, NULL, y);
   Sleep(50);
   printf("thread 2\n"); fflush(stdout);
   return (void *) 3;
}

stb_semaphore stest;
stb_mutex mutex;
volatile int tc1, tc2;

void *thread_3(void *p)
{
   stb_mutex_begin(mutex);
   ++tc1;
   stb_mutex_end(mutex);
   stb_sem_waitfor(stest);
   stb_mutex_begin(mutex);
   ++tc2;
   stb_mutex_end(mutex);
   return NULL;
}

void test_threads(void)
{
   volatile int a=0,b=0;
   //stb_work_numthreads(2);
   stb_work(thread_2, (void *) &a, (void *) &b);
   while (a==0 || b==0) {
      Sleep(10);
      //printf("a=%d b=%d\n", a, b);
   }
   c(a==2 && b == 3, "stb_thread");
   stb_work_numthreads(4);
   stest = stb_sem_new(8);
   mutex = stb_mutex_new();
   stb_work(thread_3, NULL, NULL);
   stb_work(thread_3, NULL, NULL);
   stb_work(thread_3, NULL, NULL);
   stb_work(thread_3, NULL, NULL);
   stb_work(thread_3, NULL, NULL);
   stb_work(thread_3, NULL, NULL);
   stb_work(thread_3, NULL, NULL);
   stb_work(thread_3, NULL, NULL);
   while (tc1 < 4)
      Sleep(10);
   c(tc1 == 4, "stb_work 1");
   stb_sem_release(stest);
   stb_sem_release(stest);
   stb_sem_release(stest);
   stb_sem_release(stest);
   stb_sem_release(stest);
   stb_sem_release(stest);
   stb_sem_release(stest);
   stb_sem_release(stest);
   Sleep(40);
   while (tc1 != 8 || tc2 != 8)
      Sleep(10);
   c(tc1 == 8 && tc2 == 8, "stb_work 2");
   stb_work_numthreads(2);
   stb_work(thread_3, NULL, NULL);
   stb_work(thread_3, NULL, NULL);
   stb_work(thread_3, NULL, NULL);
   stb_work(thread_3, NULL, NULL);
   while (tc1 < 10)
      Sleep(10);
   c(tc1 == 10, "stb_work 1");
   stb_sem_release(stest);
   stb_sem_release(stest);
   stb_sem_release(stest);
   stb_sem_release(stest);

   Sleep(100);
   stb_sem_delete(stest);
   stb_mutex_delete(mutex);
}
#else
void test_threads(void)
{
}
#endif

void *thread4(void *p)
{
   return NULL;
}

#ifdef STB_THREADS
stb_threadqueue *tq;
stb_sync synch;
stb_mutex msum;

volatile int thread_sum;

void *consume1(void *p)
{
   volatile int *q = (volatile int *) p;
   for(;;) {
      int z;
      stb_threadq_get_block(tq, &z);
      stb_mutex_begin(msum);
      thread_sum += z;
      *q += z;
      stb_mutex_end(msum);
      stb_sync_reach(synch);
   }      
}

void test_threads2(void)
{
   int array[256],i,n=0;
   volatile int which[4];
   synch = stb_sync_new();
   stb_sync_set_target(synch,2);
   stb_work_reach(thread4, NULL, NULL, synch);
   stb_sync_reach_and_wait(synch);
   printf("ok\n");

   tq = stb_threadq_new(4, 1, TRUE,TRUE);
   msum = stb_mutex_new();
   thread_sum = 0;
   stb_sync_set_target(synch, 65);
   for (i=0; i < 4; ++i) {
      which[i] = 0;
      stb_create_thread(consume1, (int *) &which[i]);
   }
   for (i=1; i <= 64; ++i) {
      array[i] = i;
      n += i;
      stb_threadq_add_block(tq, &array[i]);
   }
   stb_sync_reach_and_wait(synch);
   stb_barrier();
   c(thread_sum == n, "stb_threadq 1");
   c(which[0] + which[1] + which[2] + which[3] == n, "stb_threadq 2");
   printf("(Distribution: %d %d %d %d)\n", which[0], which[1], which[2], which[3]);

   stb_sync_delete(synch);
   stb_threadq_delete(tq);
   stb_mutex_delete(msum);
}
#else
void test_threads2(void)
{
}
#endif

char tc[] = "testing compression test quick test voila woohoo what the hell";

char storage1[1 << 23];
int test_compression(char *buffer, int length)
{
   char *storage2;
   int c_len = stb_compress(storage1, buffer, length);
   int dc_len;
   printf("Compressed %d to %d\n", length, c_len);
   dc_len = stb_decompress_length(storage1);
   storage2 = malloc(dc_len);
   dc_len = stb_decompress(storage2, storage1, c_len);
   if (dc_len != length) { free(storage2); return -1; }
   if (memcmp(buffer, storage2, length) != 0) { free(storage2); return -1; }
   free(storage2);
   return c_len;
}

#if 0
int test_en_compression(char *buffer, int length)
{
   int c_len = stb_en_compress(storage1, buffer, length);
   int dc_len;
   printf("Encompressed %d to %d\n", length, c_len);
   dc_len = stb_en_decompress(storage2, storage1, c_len);
   if (dc_len != length) return -1;
   if (memcmp(buffer, storage2, length) != 0) return -1;
   return c_len;
}
#endif

#define STR_x "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
#define STR_y "yyyyyyyyyyyyyyyyyy"

#define STR_xy STR_x STR_y
#define STR_xyyxy STR_xy STR_y STR_xy

#define STR_1 "testing"
#define STR_2 STR_xyyxy STR_xy STR_xyyxy STR_xyyxy STR_xy STR_xyyxy
#define STR_3 "buh"

char buffer[] = STR_1 "\r\n" STR_2 STR_2 STR_2 "\n" STR_3;
char str1[] = STR_1;
char str2[] = STR_2 STR_2 STR_2;
char str3[] = STR_3;

int sum(short *s)
{
   int i,total=0;
   for (i=0; i < stb_arr_len(s); ++i)
      total += s[i];
   return total;
}

stb_uint stb_adler32_old(stb_uint adler32, stb_uchar *buffer, stb_uint buflen)
{
   const stb_uint ADLER_MOD = 65521;
   stb_uint s1 = adler32 & 0xffff;
   stb_uint s2 = adler32 >> 16;

   while (buflen-- > 0) { // NOTE: much faster implementations are possible!
      s1 += *buffer++; if (s1 > ADLER_MOD) s1 -= ADLER_MOD;
      s2 += s1       ; if (s2 > ADLER_MOD) s2 -= ADLER_MOD;
   }
   return (s2 << 16) + s1;
}

static int sample_test[3][5] =
{
   { 1,2,3,4,5 },
   { 6,7,8,9,10, },
   { 11,12,13,14,15 },
};

typedef struct { unsigned short x,y,z; } struct1;
typedef struct { double a; int x,y,z; } struct2;

char *args_raw[] = { "foo", "-dxrf", "bar", "-ts" };
char *args[8];

void do_compressor(int,char**);
void test_sha1(void);

int alloc_num, alloc_size;
void dumpfunc(void *ptr, int sz, char *file, int line)
{
   printf("%p (%6d)  -- %3d:%s\n", ptr, sz, line, file);
   alloc_size += sz;
   alloc_num  += 1;
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

typedef struct Btest
{
   struct Btest stb_bst_fields(btest_);
   int v;
} Btest;

stb_bst(Btest, btest_, BT2,bt2,v, int, a - b)

void bst_test(void)
{
   Btest *root = NULL, *t;
   int items[500], sorted[500];
   int i,j,z;
   for (z=0; z < 10; ++z) {
      for (i=0; i < 500; ++i)
         items[i] = stb_rand() & 0xfffffff;

      // check for collisions, and retrry if so
      memcpy(sorted, items, sizeof(sorted));
      qsort(sorted, 500, sizeof(sorted[0]), stb_intcmp(0));
      for (i=1; i < 500; ++i)
         if (sorted[i-1] == sorted[i])
            break;
      if (i != 500) { --z; break; }

      for (i=0; i < 500; ++i)  {
         t = malloc(sizeof(*t));
         t->v = items[i];
         root = btest_insert(root, t);
         #ifdef STB_DEBUG
         btest__validate(root,1);
         #endif
         for (j=0; j <= i; ++j)
            c(btest_find(root, items[j]) != NULL, "stb_bst 1");
         for (   ; j < 500; ++j)
            c(btest_find(root, items[j]) == NULL, "stb_bst 2");
      }

      t = btest_first(root);
      for (i=0; i < 500; ++i)
         t = btest_next(root,t);
      c(t == NULL, "stb_bst 5");
      t = btest_last(root);
      for (i=0; i < 500; ++i)
         t = btest_prev(root,t);
      c(t == NULL, "stb_bst 6");

      memcpy(sorted, items, sizeof(sorted));
      qsort(sorted, 500, sizeof(sorted[0]), stb_intcmp(0));
      t = btest_first(root);
      for (i=0; i < 500; ++i) {
         assert(t->v == sorted[i]);
         t = btest_next(root, t);
      }
      assert(t == NULL);

      if (z==1)
         stb_reverse(items, 500, sizeof(items[0]));
      else if (z)
         stb_shuffle(items, 500, sizeof(items[0]), stb_rand());

      for (i=0; i < 500; ++i)  {
         t = btest_find(root, items[i]);
         assert(t != NULL);
         root = btest_remove(root, t);
         c(btest_find(root, items[i]) == NULL, "stb_bst 5");
         #ifdef STB_DEBUG
         btest__validate(root, 1);
         #endif
         for (j=0; j <= i; ++j)
            c(btest_find(root, items[j]) == NULL, "stb_bst 3");
         for (   ; j < 500; ++j)
            c(btest_find(root, items[j]) != NULL, "stb_bst 4");
         free(t);
      }
   }
}

extern void stu_uninit(void);

stb_define_sort(sort_int, int, *a < *b)

stb_rand_define(prime_rand, 1)
void test_packed_floats(void);
void test_parser_generator(void);

void rec_print(stb_dirtree2 *d, int depth)
{
   int i;
   for (i=0; i < depth; ++i) printf("  ");
   printf("%s (%d)\n", d->relpath, stb_arr_len(d->files));
   for (i=0; i < stb_arr_len(d->subdirs); ++i)
      rec_print(d->subdirs[i], depth+1);
   d->weight = (float) stb_arr_len(d->files);
}

#ifdef MAIN_TEST
int main(int argc, char **argv)
{
   char *z;
   stb__wchar buffer7[1024],buffer9[1024];
   char buffer8[4096];
   FILE *f;
   char *p1 = "foo/bar\\baz/test.xyz";
   char *p2 = "foo/.bar";
   char *p3 = "foo.bar";
   char *p4 = "foo/bar";
   char *wildcards[] = { "*foo*", "*bar", "baz", "*1*2*3*", "*/CVS/repository", "*oof*" };
   char **s;
   char buf[256], *p;
   int n,len2,*q,i;
   stb_matcher *mt=NULL;

   if (argc > 1) {
      do_compressor(argc,argv);
      return 0;
   }
   test_classes();
   //show();

   //stb_malloc_check_counter(2,2);
   //_CrtSetBreakAlloc(10398);

   stbprint("Checking {!if} the {$fancy} print function {#works}?  - should\n");
   stbprint("                                                      - align\n");
   stbprint("But {#3this}} {one}}                                  - shouldn't\n");

   #if 0
   {
      int i;
      char **s = stb_readdir_recursive("/sean", NULL);
      stb_dirtree *d = stb_dirtree_from_files_relative("", s, stb_arr_len(s));
      stb_dirtree **e;
      rec_print(d, 0);
      e = stb_summarize_tree(d,12,4);
      for (i=0; i < stb_arr_len(e); ++i) {
         printf("%s\n", e[i]->fullpath);
      }
      stb_arr_free(e);

      stb_fatal("foo");
   }
   #endif

   stb_("Started stb.c");
   test_threads2();
   test_threads();

   for (i=0; i < 1023 && 5+77*i < 0xd800; ++i)
      buffer7[i] = 5+77*i;
   buffer7[i++] = 0xd801;
   buffer7[i++] = 0xdc02;
   buffer7[i++] = 0xdbff;
   buffer7[i++] = 0xdfff;
   buffer7[i] = 0;
   p = stb_to_utf8(buffer8, buffer7, sizeof(buffer8));
   c(p != NULL, "stb_to_utf8");
   if (p != NULL) {
      stb_from_utf8(buffer9, buffer8, sizeof(buffer9)/2);
      c(!memcmp(buffer7, buffer9, i*2), "stb_from_utf8");
   }

   z = "foo.*[bd]ak?r";
   c( stb_regex(z, "muggle man food is barfy") == 1, "stb_regex 1");
   c( stb_regex("foo.*bar", "muggle man food is farfy") == 0, "stb_regex 2");
   c( stb_regex("[^a-zA-Z]foo[^a-zA-Z]", "dfoobar xfood") == 0, "stb_regex 3");
   c( stb_regex(z, "muman foob is bakrfy") == 1, "stb_regex 4");
   z = "foo.*[bd]bk?r";
   c( stb_regex(z, "muman foob is bakrfy") == 0, "stb_regex 5");
   c( stb_regex(z, "muman foob is bbkrfy") == 1, "stb_regex 6");

   stb_regex(NULL,NULL);

   #if 0
   test_parser_generator();
   stb_wrapper_listall(dumpfunc);
   if (alloc_num) 
      printf("Memory still in use: %d allocations of %d bytes.\n", alloc_num, alloc_size);
   #endif

   test_script();
   p = stb_file("sieve.stua", NULL);
   if (p) {
      stua_run_script(p);      
      free(p);
   }
   stua_uninit();

   //stb_wrapper_listall(dumpfunc);
   printf("Memory still in use: %d allocations of %d bytes.\n", alloc_num, alloc_size);

   c(stb_alloc_count_alloc == stb_alloc_count_free, "stb_alloc 0");

   bst_test();

   c(stb_alloc_count_alloc == stb_alloc_count_free, "stb_alloc 0");

#if 0
   // stb_block
   {
      int inuse=0, freespace=0;
      int *x = malloc(10000*sizeof(*x));
      stb_block *b = stb_block_new(1, 10000);
      #define BLOCK_COUNT  1000
      int *p = malloc(sizeof(*p) * BLOCK_COUNT);
      int *l = malloc(sizeof(*l) * BLOCK_COUNT);
      int i, n, k = 0;

      memset(x, 0, 10000 * sizeof(*x));

      n = 0;
      while (n < BLOCK_COUNT && k < 1000) {
         l[n] = 16 + (rand() & 31);
         p[n] = stb_block_alloc(b, l[n], 0);
         if (p[n] == 0)
            break;
         inuse += l[n];

         freespace = 0;
         for (i=0; i < b->len; ++i)
            freespace += b->freelist[i].len;
         assert(freespace + inuse == 9999);

         for (i=0; i < l[n]; ++i)
            x[ p[n]+i ] = p[n];
         ++n;

         if (k > 20) {
            int sz;
            i = (stb_rand() % n);
            sz = l[i];
            stb_block_free(b, p[i], sz);
            inuse -= sz;
            p[i] = p[n-1];
            l[i] = l[n-1];
            --n;

            freespace = 0;
            for (i=0; i < b->len; ++i)
               freespace += b->freelist[i].len;
            assert(freespace + inuse == 9999);
         }


         ++k;

         // validate
         if ((k % 50) == 0) {
            int j;
            for (j=0; j < n; ++j) {
               for (i=0; i < l[j]; ++i)
                  assert(x[ p[j]+i ] == p[j]);
            }
         }

         if ((k % 200) == 0) {
            stb_block_compact_freelist(b);
         }
      }

      for (i=0; i < n; ++i)
         stb_block_free(b, p[i], l[i]);

      stb_block_destroy(b);
      free(p);
      free(l);
      free(x);
   }

   blockfile_test();
#endif

   mt = stb_lex_matcher();
   for (i=0; i < 5; ++i)
      stb_lex_item_wild(mt, wildcards[i], i+1);

   c(1==stb_lex(mt, "this is a foo in the middle",NULL), "stb_matcher_match 1");
   c(0==stb_lex(mt, "this is a bar in the middle",NULL), "stb_matcher_match 2");
   c(0==stb_lex(mt, "this is a baz in the middle",NULL), "stb_matcher_match 3");
   c(2==stb_lex(mt, "this is a bar",NULL), "stb_matcher_match 4");
   c(0==stb_lex(mt, "this is a baz",NULL), "stb_matcher_match 5");
   c(3==stb_lex(mt, "baz",NULL), "stb_matcher_match 6");
   c(4==stb_lex(mt, "1_2_3_4",NULL), "stb_matcher_match 7");
   c(0==stb_lex(mt, "1  3  3 3 3  2 ",NULL), "stb_matcher_match 8");
   c(4==stb_lex(mt, "1  3  3 3 2  3 ",NULL), "stb_matcher_match 9");
   c(5==stb_lex(mt, "C:/sean/prj/old/gdmag/mipmap/hqp/adol-c/CVS/Repository",NULL), "stb_matcher_match 10");
   stb_matcher_free(mt);

   {
      #define SSIZE  500000
      static int arr[SSIZE],arr2[SSIZE];
      int i,good;
      for (i=0; i < SSIZE; ++i)
         arr2[i] = stb_rand();
      memcpy(arr,arr2,sizeof(arr));
      printf("stb_define_sort:\n");
      sort_int(arr, SSIZE);
      good = 1;
      for (i=0; i+1 < SSIZE; ++i)
         if (arr[i] > arr[i+1])
            good = 0;
      c(good, "stb_define_sort");
      printf("qsort:\n");
      qsort(arr2, SSIZE, sizeof(arr2[0]), stb_intcmp(0));
      printf("done\n");
      // check for bugs
      memset(arr, 0, sizeof(arr[0]) * 1000);
      sort_int(arr, 1000);
   }


   c(stb_alloc_count_alloc == stb_alloc_count_free, "stb_alloc -2");

   c( stb_is_prime( 2), "stb_is_prime 1");
   c( stb_is_prime( 3), "stb_is_prime 2");
   c( stb_is_prime( 5), "stb_is_prime 3");
   c( stb_is_prime( 7), "stb_is_prime 4");
   c(!stb_is_prime( 9), "stb_is_prime 5");
   c( stb_is_prime(11), "stb_is_prime 6");
   c(!stb_is_prime(25), "stb_is_prime 7");
   c(!stb_is_prime(27), "stb_is_prime 8");
   c( stb_is_prime(29), "stb_is_prime 9");
   c( stb_is_prime(31), "stb_is_prime a");
   c(!stb_is_prime(33), "stb_is_prime b");
   c(!stb_is_prime(35), "stb_is_prime c");
   c(!stb_is_prime(36), "stb_is_prime d");

   for (n=7; n < 64; n += 3) {
      int i;
      stb_perfect s;
      unsigned int *p = malloc(n * sizeof(*p));
      for (i=0; i < n; ++i)
         p[i] = i*i;
      c(stb_perfect_create(&s, p, n), "stb_perfect_hash 1");
      stb_perfect_destroy(&s);
      for (i=0; i < n; ++i)
         p[i] = stb_rand();
      c(stb_perfect_create(&s, p, n), "stb_perfect_hash 2");
      stb_perfect_destroy(&s);
      for (i=0; i < n; ++i)
         p[i] = (0x80000000 >> stb_log2_ceil(n>>1)) * i;
      c(stb_perfect_create(&s, p, n), "stb_perfect_hash 2");
      stb_perfect_destroy(&s);
      for (i=0; i < n; ++i)
         p[i] = (int) malloc(1024);
      c(stb_perfect_create(&s, p, n), "stb_perfect_hash 3");
      stb_perfect_destroy(&s);
      for (i=0; i < n; ++i)
         free((void *) p[i]);
      free(p);
   }
   printf("Maximum attempts required to find perfect hash: %d\n",
         stb_perfect_hash_max_failures);

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

   c(stb_alloc_count_alloc == stb_alloc_count_free, "stb_alloc 1");

   q = stb_wordwrapalloc(15, "How now brown cow. Testinglishously. Okey dokey");
   // How now brown
   // cow. Testinglis
   // hously. Okey
   // dokey
   c(stb_arr_len(q) ==  8, "stb_wordwrap 8");
   c(q[2] == 14 && q[3] == 15, "stb_wordwrap 9");
   c(q[4] == 29 && q[5] == 12, "stb_wordwrap 10");
   stb_arr_free(q);

   q = stb_wordwrapalloc(20, "How now brown cow. Testinglishously. Okey dokey");
   // How now brown cow.
   // Testinglishously.
   // Okey dokey
   c(stb_arr_len(q) ==  6, "stb_wordwrap 1");
   c(q[0] ==  0 && q[1] == 18, "stb_wordwrap 2");
   c(q[2] == 19 && q[3] == 17, "stb_wordwrap 3");
   c(q[4] == 37 && q[5] == 10, "stb_wordwrap 4");
   stb_arr_free(q);

   q = stb_wordwrapalloc(12, "How now brown cow. Testinglishously. Okey dokey");
   // How now
   // brown cow.
   // Testinglisho
   // usly. Okey
   // dokey
   c(stb_arr_len(q) ==  10, "stb_wordwrap 5");
   c(q[4] == 19 && q[5] == 12, "stb_wordwrap 6");
   c(q[6] == 31 && q[3] == 10, "stb_wordwrap 7");
   stb_arr_free(q);

   //test_script();

   //test_packed_floats();

   c(stb_alloc_count_alloc == stb_alloc_count_free, "stb_alloc 0");
   if (stb_alloc_count_alloc != stb_alloc_count_free) {
      printf("%d allocs, %d frees\n", stb_alloc_count_alloc, stb_alloc_count_free);
   }
   test_lex();

   mt = stb_regex_matcher(".*foo.*bar.*");
   c(stb_matcher_match(mt, "foobarx")                == 1, "stb_matcher_match 1");
   c(stb_matcher_match(mt, "foobar")                 == 1, "stb_matcher_match 2");
   c(stb_matcher_match(mt, "foo bar")                == 1, "stb_matcher_match 3");
   c(stb_matcher_match(mt, "fo foo ba ba bar ba")    == 1, "stb_matcher_match 4");
   c(stb_matcher_match(mt, "fo oo oo ba ba bar foo") == 0, "stb_matcher_match 5");
   stb_free(mt);

   mt = stb_regex_matcher(".*foo.?bar.*");
   c(stb_matcher_match(mt, "abfoobarx")                == 1, "stb_matcher_match 6");
   c(stb_matcher_match(mt, "abfoobar")                 == 1, "stb_matcher_match 7");
   c(stb_matcher_match(mt, "abfoo bar")                == 1, "stb_matcher_match 8");
   c(stb_matcher_match(mt, "abfoo  bar")               == 0, "stb_matcher_match 9");
   c(stb_matcher_match(mt, "abfo foo ba ba bar ba")    == 0, "stb_matcher_match 10");
   c(stb_matcher_match(mt, "abfo oo oo ba ba bar foo") == 0, "stb_matcher_match 11");
   stb_free(mt);

   mt = stb_regex_matcher(".*m((foo|bar)*baz)m.*");
   c(stb_matcher_match(mt, "abfoobarx")                == 0, "stb_matcher_match 12");
   c(stb_matcher_match(mt, "a mfoofoofoobazm d")       == 1, "stb_matcher_match 13");
   c(stb_matcher_match(mt, "a mfoobarbazfoom d")       == 0, "stb_matcher_match 14");
   c(stb_matcher_match(mt, "a mbarbarfoobarbazm d")    == 1, "stb_matcher_match 15");
   c(stb_matcher_match(mt, "a mfoobarfoo bazm d")      == 0, "stb_matcher_match 16");
   c(stb_matcher_match(mt, "a mm foobarfoobarfoobar ") == 0, "stb_matcher_match 17");
   stb_free(mt);

   mt = stb_regex_matcher("f*|z");
   c(stb_matcher_match(mt, "fz")       == 0, "stb_matcher_match 0a");
   c(stb_matcher_match(mt, "ff")       == 1, "stb_matcher_match 0b");
   c(stb_matcher_match(mt, "z")        == 1, "stb_matcher_match 0c");
   stb_free(mt);

   mt = stb_regex_matcher("m(f|z*)n");
   c(stb_matcher_match(mt, "mfzn")     == 0, "stb_matcher_match 0d");
   c(stb_matcher_match(mt, "mffn")     == 0, "stb_matcher_match 0e");
   c(stb_matcher_match(mt, "mzn")      == 1, "stb_matcher_match 0f");
   c(stb_matcher_match(mt, "mn")       == 1, "stb_matcher_match 0g");
   c(stb_matcher_match(mt, "mzfn")     == 0, "stb_matcher_match 0f");

   c(stb_matcher_find(mt, "manmanmannnnnnnmmmmmmmmm       ") == 0, "stb_matcher_find 1");
   c(stb_matcher_find(mt, "manmanmannnnnnnmmmmmmmmm       ") == 0, "stb_matcher_find 2");
   c(stb_matcher_find(mt, "manmanmannnnnnnmmmmmmmmmffzzz  ") == 0, "stb_matcher_find 3");
   c(stb_matcher_find(mt, "manmanmannnnnnnmmmmmmmmmnfzzz  ") == 1, "stb_matcher_find 4");
   c(stb_matcher_find(mt, "mmmfn aanmannnnnnnmmmmmm fzzz  ") == 1, "stb_matcher_find 5");
   c(stb_matcher_find(mt, "mmmzzn anmannnnnnnmmmmmm fzzz  ") == 1, "stb_matcher_find 6");
   c(stb_matcher_find(mt, "mm anmannnnnnnmmmmmm fzmzznzz  ") == 1, "stb_matcher_find 7");
   c(stb_matcher_find(mt, "mm anmannnnnnnmmmmmm fzmzzfnzz ") == 0, "stb_matcher_find 8");
   c(stb_matcher_find(mt, "manmfnmannnnnnnmmmmmmmmmffzzz  ") == 1, "stb_matcher_find 9");
   stb_free(mt);

   mt = stb_regex_matcher(".*m((foo|bar)*|baz)m.*");
   c(stb_matcher_match(mt, "abfoobarx")                == 0, "stb_matcher_match 18");
   c(stb_matcher_match(mt, "a mfoofoofoobazm d")       == 0, "stb_matcher_match 19");
   c(stb_matcher_match(mt, "a mfoobarbazfoom d")       == 0, "stb_matcher_match 20");
   c(stb_matcher_match(mt, "a mbazm d")                == 1, "stb_matcher_match 21");
   c(stb_matcher_match(mt, "a mfoobarfoom d")          == 1, "stb_matcher_match 22");
   c(stb_matcher_match(mt, "a mm foobarfoobarfoobar ") == 1, "stb_matcher_match 23");
   stb_free(mt);

   mt = stb_regex_matcher("[a-fA-F]..[^]a-zA-Z]");
   c(stb_matcher_match(mt, "Axx1")                     == 1, "stb_matcher_match 24");
   c(stb_matcher_match(mt, "Fxx1")                     == 1, "stb_matcher_match 25");
   c(stb_matcher_match(mt, "Bxx]")                     == 0, "stb_matcher_match 26");
   c(stb_matcher_match(mt, "Cxxz")                     == 0, "stb_matcher_match 27");
   c(stb_matcher_match(mt, "gxx[")                     == 0, "stb_matcher_match 28");
   c(stb_matcher_match(mt, "-xx0")                     == 0, "stb_matcher_match 29");
   stb_free(mt);

   c(stb_wildmatch("foo*bar", "foobarx")    == 0, "stb_wildmatch 0a");
   c(stb_wildmatch("foo*bar", "foobar")     == 1, "stb_wildmatch 1a");
   c(stb_wildmatch("foo*bar", "foo bar")    == 1, "stb_wildmatch 2a");
   c(stb_wildmatch("foo*bar", "fo foo ba ba bar ba") == 0, "stb_wildmatch 3a");
   c(stb_wildmatch("foo*bar", "fo oo oo ba ba ar foo") == 0, "stb_wildmatch 4a");

   c(stb_wildmatch("*foo*bar*", "foobar")     == 1, "stb_wildmatch 1b");
   c(stb_wildmatch("*foo*bar*", "foo bar")    == 1, "stb_wildmatch 2b");
   c(stb_wildmatch("*foo*bar*", "fo foo ba ba bar ba") == 1, "stb_wildmatch 3b");
   c(stb_wildmatch("*foo*bar*", "fo oo oo ba ba ar foo") == 0, "stb_wildmatch 4b");

   c(stb_wildmatch("foo*bar*", "foobarx")     == 1, "stb_wildmatch 1c");
   c(stb_wildmatch("foo*bar*", "foobabar")    == 1, "stb_wildmatch 2c");
   c(stb_wildmatch("foo*bar*", "fo foo ba ba bar ba") == 0, "stb_wildmatch 3c");
   c(stb_wildmatch("foo*bar*", "fo oo oo ba ba ar foo") == 0, "stb_wildmatch 4c");

   c(stb_wildmatch("*foo*bar", "foobar")     == 1, "stb_wildmatch 1d");
   c(stb_wildmatch("*foo*bar", "foo bar")    == 1, "stb_wildmatch 2d");
   c(stb_wildmatch("*foo*bar", "fo foo ba ba bar ba") == 0, "stb_wildmatch 3d");
   c(stb_wildmatch("*foo*bar", "fo oo oo ba ba ar foo") == 0, "stb_wildmatch 4d");

   c(stb_wildfind("foo*bar", "xyfoobarx")    == 2, "stb_wildfind 0a");
   c(stb_wildfind("foo*bar", "aaafoobar")    == 3, "stb_wildfind 1a");
   c(stb_wildfind("foo*bar", "foo bar")      == 0, "stb_wildfind 2a");
   c(stb_wildfind("foo*bar", "fo foo ba ba bar ba") == 3, "stb_wildfind 3a");
   c(stb_wildfind("foo*bar", "fo oo oo ba ba ar foo") == -1, "stb_wildfind 4a");

   c(stb_wildmatch("*foo*;*bar*", "foobar")  == 1, "stb_wildmatch 1e");
   c(stb_wildmatch("*foo*;*bar*", "afooa")  == 1, "stb_wildmatch 2e");
   c(stb_wildmatch("*foo*;*bar*", "abara")  == 1, "stb_wildmatch 3e");
   c(stb_wildmatch("*foo*;*bar*", "abaza")  == 0, "stb_wildmatch 4e");
   c(stb_wildmatch("*foo*;*bar*", "foboar")  == 0, "stb_wildmatch 5e");

   test_sha1();

   n = sizeof(args_raw)/sizeof(args_raw[0]);
   memcpy(args, args_raw, sizeof(args_raw));
   s = stb_getopt(&n, args);
   c(n >= 1 && !strcmp(args[1], "bar" ), "stb_getopt 1");
   c(stb_arr_len(s) >= 2 && !strcmp(s[2]   , "r"   ), "stb_getopt 2");
   stb_getopt_free(s);

   n = sizeof(args_raw)/sizeof(args_raw[0]);
   memcpy(args, args_raw, sizeof(args_raw));
   s = stb_getopt_param(&n, args, "f");
   c(stb_arr_len(s) >= 3 && !strcmp(s[3]   , "fbar"), "stb_getopt 3");
   stb_getopt_free(s);

   n = sizeof(args_raw)/sizeof(args_raw[0]);
   memcpy(args, args_raw, sizeof(args_raw));
   s = stb_getopt_param(&n, args, "x");
   c(stb_arr_len(s) >= 2 && !strcmp(s[1]   , "xrf" ), "stb_getopt 4");
   stb_getopt_free(s);

   n = sizeof(args_raw)/sizeof(args_raw[0]);
   memcpy(args, args_raw, sizeof(args_raw));
   s = stb_getopt_param(&n, args, "s");
   c(s == NULL && n == 0     , "stb_getopt 5");
   stb_getopt_free(s);

#if 0
   c(*stb_csample_int(sample_test[0], 1, 5, 5, 3, -1, -1) ==  1, "stb_csample_int 1");
   c(*stb_csample_int(sample_test[0], 1, 5, 5, 3,  1, -3) ==  2, "stb_csample_int 2");
   c(*stb_csample_int(sample_test[0], 1, 5, 5, 3, 12, -2) ==  5, "stb_csample_int 3");
   c(*stb_csample_int(sample_test[0], 1, 5, 5, 3, 15,  1) == 10, "stb_csample_int 4");
   c(*stb_csample_int(sample_test[0], 1, 5, 5, 3,  5,  4) == 15, "stb_csample_int 5");
   c(*stb_csample_int(sample_test[0], 1, 5, 5, 3,  3,  3) == 14, "stb_csample_int 6");
   c(*stb_csample_int(sample_test[0], 1, 5, 5, 3, -2,  5) == 11, "stb_csample_int 7");
   c(*stb_csample_int(sample_test[0], 1, 5, 5, 3, -7,  0) ==  1, "stb_csample_int 8");
   c(*stb_csample_int(sample_test[0], 1, 5, 5, 3,  2,  1) ==  8, "stb_csample_int 9");
#endif

   c(!strcmp(stb_splitpath(buf, p1, STB_PATH      ), "foo/bar\\baz/"), "stb_splitpath 1");
   c(!strcmp(stb_splitpath(buf, p1, STB_FILE      ), "test"), "stb_splitpath 2");
   c(!strcmp(stb_splitpath(buf, p1, STB_EXT       ), ".xyz"), "stb_splitpath 3");
   c(!strcmp(stb_splitpath(buf, p1, STB_PATH_FILE ), "foo/bar\\baz/test"), "stb_splitpath 4");
   c(!strcmp(stb_splitpath(buf, p1, STB_FILE_EXT  ), "test.xyz"), "stb_splitpath 5");

   c(!strcmp(stb_splitpath(buf, p2, STB_PATH      ), "foo/"), "stb_splitpath 6");
   c(!strcmp(stb_splitpath(buf, p2, STB_FILE      ), ""), "stb_splitpath 7");
   c(!strcmp(stb_splitpath(buf, p2, STB_EXT       ), ".bar"), "stb_splitpath 8");
   c(!strcmp(stb_splitpath(buf, p2, STB_PATH_FILE ), "foo/"), "stb_splitpath 9");
   c(!strcmp(stb_splitpath(buf, p2, STB_FILE_EXT  ), ".bar"), "stb_splitpath 10");

   c(!strcmp(stb_splitpath(buf, p3, STB_PATH      ), "./"), "stb_splitpath 11");
   c(!strcmp(stb_splitpath(buf, p3, STB_FILE      ), "foo"), "stb_splitpath 12");
   c(!strcmp(stb_splitpath(buf, p3, STB_EXT       ), ".bar"), "stb_splitpath 13");
   c(!strcmp(stb_splitpath(buf, p3, STB_PATH_FILE ), "foo"), "stb_splitpath 14");

   c(!strcmp(stb_splitpath(buf, p4, STB_PATH      ), "foo/"), "stb_splitpath 16");
   c(!strcmp(stb_splitpath(buf, p4, STB_FILE      ), "bar"), "stb_splitpath 17");
   c(!strcmp(stb_splitpath(buf, p4, STB_EXT       ), ""), "stb_splitpath 18");
   c(!strcmp(stb_splitpath(buf, p4, STB_PATH_FILE ), "foo/bar"), "stb_splitpath 19");
   c(!strcmp(stb_splitpath(buf, p4, STB_FILE_EXT  ), "bar"), "stb_splitpath 20");

   c(!strcmp(p=stb_dupreplace("testfootffooo foo fox", "foo", "brap"), "testbraptfbrapo brap fox"), "stb_dupreplace 1"); free(p);
   c(!strcmp(p=stb_dupreplace("testfootffooo foo fox", "foo", ""    ), "testtfo  fox"            ), "stb_dupreplace 2"); free(p);
   c(!strcmp(p=stb_dupreplace("abacab", "a", "aba"),                   "abababacabab"            ), "stb_dupreplace 3"); free(p);


#if 0
   m = stb_mml_parse("<a><b><c>x</c><d>y</d></b><e>&lt;&amp;f&gt;</e></a>");
   c(m != NULL, "stb_mml_parse 1");
   if (m) {
      c(!strcmp(m->child[0]->child[0]->child[1]->tag, "d"), "stb_mml_parse 2");
      c(!strcmp(m->child[0]->child[1]->leaf_data, "<&f>"), "stb_mml_parse 3");
   }
   if (m)
      stb_mml_free(m);
   c(stb_alloc_count_alloc == stb_alloc_count_free, "stb_alloc 1");
   if (stb_alloc_count_alloc != stb_alloc_count_free) {
      printf("%d allocs, %d frees\n", stb_alloc_count_alloc, stb_alloc_count_free);
   }
#endif

   c(stb_linear_remap(3.0f,0,8,1,2) == 1.375, "stb_linear_remap()");

   c(stb_bitreverse(0x1248fec8) == 0x137f1248, "stb_bitreverse() 1");
   c(stb_bitreverse8(0x4e) == 0x72, "stb_bitreverse8() 1");
   c(stb_bitreverse8(0x31) == 0x8c, "stb_bitreverse8() 2");
   for (n=1; n < 255; ++n) {
      unsigned int m = stb_bitreverse8((uint8) n);
      c(stb_bitreverse8((uint8) m) == (unsigned int) n, "stb_bitreverse8() 3");
   }

   for (n=2; n <= 31; ++n) {
      c(stb_is_pow2   ((1 << n)  ) == 1  , "stb_is_pow2() 1");
      c(stb_is_pow2   ((1 << n)+1) == 0  , "stb_is_pow2() 2");
      c(stb_is_pow2   ((1 << n)-1) == 0  , "stb_is_pow2() 3");

      c(stb_log2_floor((1 << n)  ) == n  , "stb_log2_floor() 1");
      c(stb_log2_floor((1 << n)+1) == n  , "stb_log2_floor() 2");
      c(stb_log2_floor((1 << n)-1) == n-1, "stb_log2_floor() 3");

      c(stb_log2_ceil ((1 << n)  ) == n  , "stb_log2_ceil() 1");
      c(stb_log2_ceil ((1 << n)+1) == n+1, "stb_log2_ceil() 2");
      c(stb_log2_ceil ((1 << n)-1) == n  , "stb_log2_ceil() 3");

      c(stb_bitreverse(1 << n) == 1U << (31-n), "stb_bitreverse() 2");
   }

   c(stb_log2_floor(0) == -1, "stb_log2_floor() 4");
   c(stb_log2_ceil (0) == -1, "stb_log2_ceil () 4");

   c(stb_log2_floor(-1) == 31, "stb_log2_floor() 5");
   c(stb_log2_ceil (-1) == 32, "stb_log2_ceil () 5");

   c(stb_bitcount(0xffffffff) == 32, "stb_bitcount() 1");
   c(stb_bitcount(0xaaaaaaaa) == 16, "stb_bitcount() 2");
   c(stb_bitcount(0x55555555) == 16, "stb_bitcount() 3");
   c(stb_bitcount(0x00000000) ==  0, "stb_bitcount() 4");

   c(stb_lowbit8(0xf0) == 4, "stb_lowbit8 1");
   c(stb_lowbit8(0x10) == 4, "stb_lowbit8 2");
   c(stb_lowbit8(0xf3) == 0, "stb_lowbit8 3");
   c(stb_lowbit8(0xf8) == 3, "stb_lowbit8 4");
   c(stb_lowbit8(0x60) == 5, "stb_lowbit8 5");

   for (n=0; n < sizeof(buf); ++n)
      buf[n] = 0;

   for (n = 0; n < 200000; ++n) {
      unsigned int k = stb_rand();
      int i,z=0;
      for (i=0; i < 32; ++i)
         if (k & (1 << i)) ++z;
      c(stb_bitcount(k) == z, "stb_bitcount() 5");

      buf[k >> 24] = 1;

      if (k != 0) {
         if (stb_is_pow2(k)) {
            c(stb_log2_floor(k) == stb_log2_ceil(k), "stb_is_pow2() 1");
            c(k == 1U << stb_log2_floor(k), "stb_is_pow2() 2");
         } else {
            c(stb_log2_floor(k) == stb_log2_ceil(k)-1, "stb_is_pow2() 3");
         }
      }

      c(stb_bitreverse(stb_bitreverse(n)) == (uint32) n, "stb_bitreverse() 3");
   }

   // make sure reasonable coverage from stb_rand()
   for (n=0; n < sizeof(buf); ++n)
      c(buf[n] != 0, "stb_rand()");

   for (n=0; n < sizeof(buf); ++n)
      buf[n] = 0;

   for (n=0; n < 60000; ++n) {
      float z = (float) stb_frand();
      int n = (int) (z * sizeof(buf));
      c(z >= 0 && z < 1, "stb_frand() 1");
      c(n >= 0 && n < sizeof(buf), "stb_frand() 2");
      buf[n] = 1;
   }

   // make sure reasonable coverage from stb_frand(),
   // e.g. that the range remap isn't incorrect
   for (n=0; n < sizeof(buf); ++n)
      c(buf[n] != 0, "stb_frand()");
         

   // stb_arr
   {
      short *s = NULL;

      c(sum(s) == 0, "stb_arr 1");

      stb_arr_add(s); s[0] = 3;
      stb_arr_push(s,7);

      c( stb_arr_valid(s,1), "stb_arr 2");
      c(!stb_arr_valid(s,2), "stb_arr 3");

      // force a realloc
      stb_arr_push(s,0);
      stb_arr_push(s,0);
      stb_arr_push(s,0);
      stb_arr_push(s,0);

      c(sum(s) == 10, "stb_arr 4");
      stb_arr_push(s,0);
      s[0] = 1; s[1] = 5; s[2] = 20;
      c(sum(s) == 26, "stb_arr 5");
      stb_arr_setlen(s,2);
      c(sum(s) == 6, "stb_arr 6");
      stb_arr_setlen(s,1);
      c(sum(s) == 1, "stb_arr 7");
      stb_arr_setlen(s,0);
      c(sum(s) == 0, "stb_arr 8");

      stb_arr_push(s,3);
      stb_arr_push(s,4);
      stb_arr_push(s,5);
      stb_arr_push(s,6);
      stb_arr_push(s,7);
      stb_arr_deleten(s,1,3);
      c(stb_arr_len(s)==2 && sum(s) == 10, "stb_arr_9");

      stb_arr_push(s,2);
      // 3 7 2
      stb_arr_insertn(s,2,2);
      // 3 7 x x 2
      s[2] = 5;
      s[3] = 6;
      c(s[0]==3 && s[1] == 7 && s[2] == 5 && s[3] == 6 && s[4] == 2, "stb_arr 10");
      stb_arr_free(s);
   }

   #if 1
   f= stb_fopen("data/stb.test", "wb");
   fwrite(buffer, 1, sizeof(buffer)-1, f);
   stb_fclose(f, stb_keep_yes);
   #ifndef WIN32
   sleep(1);  // andLinux has some synchronization problem here
   #endif
   #else
   f= fopen("data/stb.test", "wb");
   fwrite(buffer, 1, sizeof(buffer)-1, f);
   fclose(f);
   #endif
   if (!stb_fexists("data/stb.test")) {
      fprintf(stderr, "Error: couldn't open file just written, or stb_fexists() is broken.\n");
   }

   f = fopen("data/stb.test", "rb");
   // f = NULL; // test stb_fatal()
   if (!f) { stb_fatal("Error: couldn't open file just written\n"); }
   else {
      char temp[4];
      int len1 = stb_filelen(f), len2;
      int n1,n2;
      if (fread(temp,1,4,f) == 0) {
         int n = ferror(f);
         if (n) { stb_fatal("Error reading from stream: %d", n); }
         if (feof(f)) stb_fatal("Weird, read 0 bytes and hit eof");
         stb_fatal("Read 0, but neither feof nor ferror is true");
      }
      fclose(f);
      p = stb_file("data/stb.test", &len2);
      if (p == NULL) stb_fatal("Error: stb_file() failed");
      c(len1 == sizeof(buffer)-1, "stb_filelen()");
      c(len2 == sizeof(buffer)-1, "stb_file():n");
      c(memcmp(p, buffer, sizeof(buffer)-1) == 0, "stb_file()");
      c(strcmp(p, buffer)==0, "stb_file() terminated");
      free(p);

      s = stb_stringfile("data/stb.test", &n1);
      c(n1 == 3, "stb_stringfile():n");
      n2 = 0;
      while (s[n2]) ++n2;
      c(n1 == n2, "stb_stringfile():n length matches the non-NULL strings");
      if (n2 == 3) {
         c(strcmp(s[0],str1)==0, "stb_stringfile()[0]");
         c(strcmp(s[1],str2)==0, "stb_stringfile()[1]");
         c(strcmp(s[2],str3)==0, "stb_stringfile()[2] (no terminating newlines)");
      }
      free(s);

      f = fopen("data/stb.test", "rb");
      stb_fgets(buf, sizeof(buf), f);
      //c(strcmp(buf, str1)==0, "stb_fgets()");
      p = stb_fgets_malloc(f);
      n1 = strlen(p);
      n2 = strlen(str2);
      c(strcmp(p, str2)==0, "stb_fgets_malloc()");
      free(p);
      stb_fgets(buf, sizeof(buf), f);
      c(strcmp(buf, str3)==0, "stb_fgets()3");
   }

   c( stb_prefix("foobar", "foo"), "stb_prefix() 1");
   c(!stb_prefix("foo", "foobar"), "stb_prefix() 2");
   c( stb_prefix("foob", "foob" ), "stb_prefix() 3");

   stb_strncpy(buf, "foobar", 6);  c(strcmp(buf,"fooba" )==0, "stb_strncpy() 1");
   stb_strncpy(buf, "foobar", 8);  c(strcmp(buf,"foobar")==0, "stb_strncpy() 2");

   c(!strcmp(p=stb_duplower("FooBar"), "foobar"), "stb_duplower()"); free(p);
   strcpy(buf, "FooBar");
   stb_tolower(buf);
   c(!strcmp(buf, "foobar"), "stb_tolower()");

   p = stb_strtok(buf, "foo=ba*r", "#=*");
   c(!strcmp(buf, "foo" ), "stb_strtok() 1");
   c(!strcmp(p  , "ba*r"), "stb_strtok() 2");
   p = stb_strtok(buf, "foobar", "#=*");
   c(*p == 0, "stb_strtok() 3");

   c(!strcmp(stb_skipwhite(" \t\n foo"), "foo"), "stb_skipwhite()");

   s = stb_tokens("foo == ba*r", "#=*", NULL);
   c(!strcmp(s[0], "foo "), "stb_tokens() 1");
   c(!strcmp(s[1], " ba"),  "stb_tokens() 2");
   c(!strcmp(s[2], "r"),    "stb_tokens() 3");
   c(s[3] == 0,             "stb_tokens() 4");
   free(s);

   s = stb_tokens_allowempty("foo == ba*r", "#=*", NULL);
   c(!strcmp(s[0], "foo "), "stb_tokens_allowempty() 1");
   c(!strcmp(s[1], ""    ), "stb_tokens_allowempty() 2");
   c(!strcmp(s[2], " ba"),  "stb_tokens_allowempty() 3");
   c(!strcmp(s[3], "r"),    "stb_tokens_allowempty() 4");
   c(s[4] == 0,             "stb_tokens_allowempty() 5");
   free(s);

   s = stb_tokens_stripwhite("foo == ba*r", "#=*", NULL);
   c(!strcmp(s[0], "foo"),  "stb_tokens_stripwhite() 1");
   c(!strcmp(s[1], ""   ),  "stb_tokens_stripwhite() 2");
   c(!strcmp(s[2], "ba"),   "stb_tokens_stripwhite() 3");
   c(!strcmp(s[3], "r"),    "stb_tokens_stripwhite() 4");
   c(s[4] == 0,             "stb_tokens_stripwhite() 5");
   free(s);

   s = stb_tokens_quoted("foo =\"=\" ba*\"\"r \" foo\" bah    ", "#=*", NULL);
   c(!strcmp(s[0], "foo"),  "stb_tokens_quoted() 1");
   c(!strcmp(s[1], "= ba"), "stb_tokens_quoted() 2");
   c(!strcmp(s[2], "\"r  foo bah"),  "stb_tokens_quoted() 3");
   c(s[3] == 0,             "stb_tokens_quoted() 4");
   free(s);


   p = stb_file("stb.h", &len2);
   if (p) {
      uint32 z = stb_adler32_old(1, p, len2);
      uint32 x = stb_adler32    (1, p, len2);
      c(z == x, "stb_adler32() 1");
      memset(p,0xff,len2);
      z = stb_adler32_old((65520<<16) + 65520, p, len2);
      x = stb_adler32    ((65520<<16) + 65520, p, len2);
      c(z == x, "stb_adler32() 2");
      free(p);
   }

   //   stb_hheap
   {
      #define HHEAP_COUNT  100000
      void **p = malloc(sizeof(*p) * HHEAP_COUNT);
      int i, j;
      #if 0
      stb_hheap *h2, *h = stb_newhheap(sizeof(struct1),0);

      for (i=0; i < HHEAP_COUNT; ++i)
         p[i] = stb_halloc(h);
      stb_shuffle(p, HHEAP_COUNT, sizeof(*p), stb_rand());
      for (i=0; i < HHEAP_COUNT; ++i)
         stb_hfree(p[i]);

      c(h->num_alloc == 0, "stb_hheap 1");
      stb_delhheap(h);

      h = stb_newhheap(sizeof(struct1),0);
      h2 = stb_newhheap(sizeof(struct2),8);

      for (i=0; i < HHEAP_COUNT; ++i) {
         if (i & 1)
            p[i] = stb_halloc(h);
         else {
            p[i] = stb_halloc(h2);
            c((((int) p[i]) & 4) == 0, "stb_hheap 2");
         }
      }

      stb_shuffle(p, HHEAP_COUNT, sizeof(*p), stb_rand());
      for (i=0; i < HHEAP_COUNT; ++i)
         stb_hfree(p[i]);

      c(h->num_alloc == 0, "stb_hheap 3");
      c(h2->num_alloc == 0, "stb_hheap 4");

      stb_delhheap(h);
      stb_delhheap(h2);
      #else
      for (i=0; i < HHEAP_COUNT; ++i)
         p[i] = malloc(32);
      stb_shuffle(p, HHEAP_COUNT, sizeof(*p), stb_rand());
      for (i=0; i < HHEAP_COUNT; ++i)
         free(p[i]);
      #endif

      // now use the same array of pointers to do pointer set operations
      for (j=100; j < HHEAP_COUNT; j += 25000) {
         stb_ps *ps = NULL;
         for (i=0; i < j; ++i)
            ps = stb_ps_add(ps, p[i]);

         for (i=0; i < HHEAP_COUNT; ++i)
            c(stb_ps_find(ps, p[i]) == (i < j), "stb_ps 1");
         c(stb_ps_count(ps) == j, "stb_ps 1b");

         for (i=j; i < HHEAP_COUNT; ++i)
            ps = stb_ps_add(ps, p[i]);

         for (i=0; i < j; ++i)
            ps = stb_ps_remove(ps, p[i]);

         for (i=0; i < HHEAP_COUNT; ++i)
            c(stb_ps_find(ps, p[i]) == !(i < j), "stb_ps 2");

         stb_ps_delete(ps);
      }

      #define HHEAP_COUNT2   100
      // now use the same array of pointers to do pointer set operations
      for (j=1; j < 40; ++j) {
         stb_ps *ps = NULL;
         for (i=0; i < j; ++i)
            ps = stb_ps_add(ps, p[i]);

         for (i=0; i < HHEAP_COUNT2; ++i)
            c(stb_ps_find(ps, p[i]) == (i < j), "stb_ps 3");
         c(stb_ps_count(ps) == j, "stb_ps 3b");

         for (i=j; i < HHEAP_COUNT2; ++i)
            ps = stb_ps_add(ps, p[i]);

         for (i=0; i < j; ++i)
            ps = stb_ps_remove(ps, p[i]);

         for (i=0; i < HHEAP_COUNT2; ++i)
            c(stb_ps_find(ps, p[i]) == !(i < j), "stb_ps 4");

         stb_ps_delete(ps);
      }

      free(p);
   }


   n = test_compression(tc, sizeof(tc));
   c(n >= 0, "stb_compress()/stb_decompress() 1");

   p = stb_file("stb.h", &len2);
   if (p) {
      FILE *f = fopen("data/stb_h.z", "wb");
      if (stb_compress_stream_start(f)) {
         int i;
         void *q;
         int len3;

         for (i=0; i < len2; ) {
            int n = stb_rand() % 10;
            if (n <= 6) n = 1 + stb_rand()%16;
            else if (n <= 8) n = 20 + stb_rand() % 1000;
            else n = 15000;
            if (i + n > len2) n = len2 - i;
            stb_write(p + i, n);
            i += n;
         }
         stb_compress_stream_end(1);

         q = stb_decompress_fromfile("data/stb_h.z", &len3);
         c(len3 == len2, "stb_compress_stream 2");
         if (len2 == len3)
            c(!memcmp(p,q,len2), "stb_compress_stream 3");
         if (q) free(q);
      } else {
         c(0, "stb_compress_stream 1");
      }

      free(p);
      stb_compress_window(65536*4);
   }

   p = stb_file("stb.h", &len2);
   if (p) {
      n = test_compression(p, len2);
      c(n >= 0, "stb_compress()/stb_decompress() 2");
      #if 0
      n = test_en_compression(p, len2);
      c(n >= 0, "stb_en_compress()/stb_en_decompress() 2");
      #endif
      free(p);
   } else {
      fprintf(stderr, "No stb.h to compression test.\n");
   }

   p = stb_file("data/test.bmp", &len2);
   if (p) {
      n = test_compression(p, len2);
      c(n == 106141, "stb_compress()/stb_decompress() 4");
      #if 0
      n = test_en_compression(p, len2);
      c(n >= 0, "stb_en_compress()/stb_en_decompress() 4");
      #endif
      free(p);
   }

   // the hardcoded compressed lengths being verified _could_
   // change if you changed the compresser parameters; but pure
   // performance optimizations shouldn't change them
   p = stb_file("data/cantrbry.zip", &len2);
   if (p) {
      n = test_compression(p, len2);
      c(n == 642787, "stb_compress()/stb_decompress() 3");
      #if 0
      n = test_en_compression(p, len2);
      c(n >= 0, "stb_en_compress()/stb_en_decompress() 3");
      #endif
      free(p);
   }

   p = stb_file("data/bible.txt", &len2);
   if (p) {
      n = test_compression(p, len2);
      c(n == 2022520, "stb_compress()/stb_decompress() 4");
      #if 0
      n = test_en_compression(p, len2);
      c(n >= 0, "stb_en_compress()/stb_en_decompress() 4");
      #endif
      free(p);
   }

   {
      int len = 1 << 25, o=0; // 32MB
      char *buffer = malloc(len);
      int i;
      for (i=0; i < 8192; ++i)
         buffer[o++] = (char) stb_rand();
      for (i=0; i < (1 << 15); ++i)
         buffer[o++] = 1;
      for (i=0; i < 64; ++i)
         buffer[o++] = buffer[i];
      for (i=0; i < (1 << 21); ++i)
         buffer[o++] = 2;
      for (i=0; i < 64; ++i)
         buffer[o++] = buffer[i];
      for (i=0; i < (1 << 21); ++i)
         buffer[o++] = 3;
      for (i=0; i < 8192; ++i)
         buffer[o++] = buffer[i];
      for (i=0; i < (1 << 21); ++i)
         buffer[o++] = 4;
      assert(o < len);
      stb_compress_window(1 << 24);
      i = test_compression(buffer, len);
      c(n >= 0, "stb_compress() 6");
      free(buffer);
   }

   #ifdef STB_THREADS
   stb_thread_cleanup();
   #endif
   stb_ischar(0,NULL);
   stb_wrapper_listall(dumpfunc);
   printf("Memory still in use: %d allocations of %d bytes.\n", alloc_num, alloc_size);

   // force some memory checking
   for (n=1; n < 20; ++n)
      malloc(1 << n);

   printf("Finished stb.c with %d errors.\n", count);

   #ifdef _MSC_VER
   if (count)
      __asm int 3;
   #endif

   return 0;
}

#endif





// NIST test vectors

struct
{
   int length;
   char *message;
   char *digest;
} sha1_tests[] =
{
   24,
"616263",
"a9993e364706816aba3e25717850c26c9cd0d89d",

   1304,
"ec29561244ede706b6eb30a1c371d74450a105c3f9735f7fa9fe38cf67f304a5736a106e"
"92e17139a6813b1c81a4f3d3fb9546ab4296fa9f722826c066869edacd73b25480351858"
"13e22634a9da44000d95a281ff9f264ecce0a931222162d021cca28db5f3c2aa24945ab1"
"e31cb413ae29810fd794cad5dfaf29ec43cb38d198fe4ae1da2359780221405bd6712a53"
"05da4b1b737fce7cd21c0eb7728d08235a9011",
"970111c4e77bcc88cc20459c02b69b4aa8f58217",

   2096,
"5fc2c3f6a7e79dc94be526e5166a238899d54927ce470018fbfd668fd9dd97cbf64e2c91"
"584d01da63be3cc9fdff8adfefc3ac728e1e335b9cdc87f069172e323d094b47fa1e652a"
"fe4d6aa147a9f46fda33cacb65f3aa12234746b9007a8c85fe982afed7815221e43dba55"
"3d8fe8a022cdac1b99eeeea359e5a9d2e72e382dffa6d19f359f4f27dc3434cd27daeeda"
"8e38594873398678065fbb23665aba9309d946135da0e4a4afdadff14db18e85e71dd93c"
"3bf9faf7f25c8194c4269b1ee3d9934097ab990025d9c3aaf63d5109f52335dd3959d38a"
"e485050e4bbb6235574fc0102be8f7a306d6e8de6ba6becf80f37415b57f9898a5824e77"
"414197422be3d36a6080",
   "0423dc76a8791107d14e13f5265b343f24cc0f19",

   2888,
"0f865f46a8f3aed2da18482aa09a8f390dc9da07d51d1bd10fe0bf5f3928d5927d08733d"
"32075535a6d1c8ac1b2dc6ba0f2f633dc1af68e3f0fa3d85e6c60cb7b56c239dc1519a00"
"7ea536a07b518ecca02a6c31b46b76f021620ef3fc6976804018380e5ab9c558ebfc5cb1"
"c9ed2d974722bf8ab6398f1f2b82fa5083f85c16a5767a3a07271d67743f00850ce8ec42"
"8c7f22f1cf01f99895c0c844845b06a06cecb0c6cf83eb55a1d4ebc44c2c13f6f7aa5e0e"
"08abfd84e7864279057abc471ee4a45dbbb5774afa24e51791a0eada11093b88681fe30b"
"aa3b2e94113dc63342c51ca5d1a6096d0897b626e42cb91761058008f746f35465465540"
"ad8c6b8b60f7e1461b3ce9e6529625984cb8c7d46f07f735be067588a0117f23e34ff578"
"00e2bbe9a1605fde6087fb15d22c5d3ac47566b8c448b0cee40373e5ba6eaa21abee7136"
"6afbb27dbbd300477d70c371e7b8963812f5ed4fb784fb2f3bd1d3afe883cdd47ef32bea"
"ea",
   "6692a71d73e00f27df976bc56df4970650d90e45",

   3680,
"4893f1c763625f2c6ce53aacf28026f14b3cd8687e1a1d3b60a81e80fcd1e2b038f9145a"
"b64a0718f948f7c3c9ac92e3d86fb669a5257da1a18c776291653688338210a3242120f1"
"01788e8acc9110db9258b1554bf3d26602516ea93606a25a7f566c0c758fb39ecd9d876b"
"c5d8abc1c3205095382c2474cb1f8bbdb45c2c0e659cb0fc703ec607a5de6bcc7a28687d"
"b1ee1c8f34797bb2441d5706d210df8c2d7d65dbded36414d063c117b52a51f7a4eb9cac"
"0782e008b47459ed5acac0bc1f20121087f992ad985511b33c866d18e63f585478ee5a5e"
"654b19d81231d98683ae3f0533565aba43dce408d7e3c4c6be11d8f05165f29c9dcb2030"
"c4ee31d3a04e7421aa92c3231a1fc07e50e95fea7389a5e65891afaba51cf55e36a9d089"
"bf293accb356d5d06547307d6e41456d4ed146a056179971c56521c83109bf922866186e"
"184a99a96c7bb96df8937e35970e438412a2b8d744cf2ad87cb605d4232e976f9f151697"
"76e4e5b6b786132c966b25fc56d815c56c819af5e159aa39f8a93d38115f5580cda93bc0"
"73c30b39920e726fe861b72483a3f886269ab7a8eefe952f35d25c4eb7f443f4f3f26e43"
"d51fb54591e6a6dad25fcdf5142033084e5624bdd51435e77dea86b8",
   "dc5859dd5163c4354d5d577b855fa98e37f04384",

   4472,
"cf494c18a4e17bf03910631471bca5ba7edea8b9a63381e3463517961749848eb03abefd"
"4ce676dece3740860255f57c261a558aa9c7f11432f549a9e4ce31d8e17c79450ce2ccfc"
"148ad904aedfb138219d7052088520495355dadd90f72e6f69f9c6176d3d45f113f275b7"
"fbc2a295784d41384cd7d629b23d1459a22e45fd5097ec9bf65fa965d3555ec77367903c"
"32141065fc24da5c56963d46a2da3c279e4035fb2fb1c0025d9dda5b9e3443d457d92401"
"a0d3f58b48469ecb1862dc975cdbe75ca099526db8b0329b03928206f084c633c04eef5e"
"8e377f118d30edf592504be9d2802651ec78aeb02aea167a03fc3e23e5fc907c324f283f"
"89ab37e84687a9c74ccf055402db95c29ba2c8d79b2bd4fa96459f8e3b78e07e923b8119"
"8267492196ecb71e01c331f8df245ec5bdf8d0e05c91e63bb299f0f6324895304dda721d"
"39410458f117c87b7dd6a0ee734b79fcbe482b2c9e9aa0cef03a39d4b0c86de3bc34b4aa"
"dabfa373fd2258f7c40c187744d237080762382f547a36adb117839ca72f8ebbc5a20a07"
"e86f4c8bb923f5787698d278f6db0040e76e54645bb0f97083995b34b9aa445fc4244550"
"58795828dd00c32471ec402a307f5aa1b37b1a86d6dae3bcbfbe9ba41cab0beeabf489af"
"0073d4b3837d3f14b815120bc3602d072b5aeefcdec655fe756b660eba7dcf34675acbce"
"317746270599424b9248791a0780449c1eabbb9459cc1e588bfd74df9b1b711c85c09d8a"
"a171b309281947e8f4b6ac438753158f4f36fa",
   "4c17926feb6e87f5bca7890d8a5cde744f231dab",

   5264,
"8236153781bd2f1b81ffe0def1beb46f5a70191142926651503f1b3bb1016acdb9e7f7ac"
"ced8dd168226f118ff664a01a8800116fd023587bfba52a2558393476f5fc69ce9c65001"
"f23e70476d2cc81c97ea19caeb194e224339bcb23f77a83feac5096f9b3090c51a6ee6d2"
"04b735aa71d7e996d380b80822e4dfd43683af9c7442498cacbea64842dfda238cb09992"
"7c6efae07fdf7b23a4e4456e0152b24853fe0d5de4179974b2b9d4a1cdbefcbc01d8d311"
"b5dda059136176ea698ab82acf20dd490be47130b1235cb48f8a6710473cfc923e222d94"
"b582f9ae36d4ca2a32d141b8e8cc36638845fbc499bce17698c3fecae2572dbbd4705524"
"30d7ef30c238c2124478f1f780483839b4fb73d63a9460206824a5b6b65315b21e3c2f24"
"c97ee7c0e78faad3df549c7ca8ef241876d9aafe9a309f6da352bec2caaa92ee8dca3928"
"99ba67dfed90aef33d41fc2494b765cb3e2422c8e595dabbfaca217757453fb322a13203"
"f425f6073a9903e2dc5818ee1da737afc345f0057744e3a56e1681c949eb12273a3bfc20"
"699e423b96e44bd1ff62e50a848a890809bfe1611c6787d3d741103308f849a790f9c015"
"098286dbacfc34c1718b2c2b77e32194a75dda37954a320fa68764027852855a7e5b5274"
"eb1e2cbcd27161d98b59ad245822015f48af82a45c0ed59be94f9af03d9736048570d6e3"
"ef63b1770bc98dfb77de84b1bb1708d872b625d9ab9b06c18e5dbbf34399391f0f8aa26e"
"c0dac7ff4cb8ec97b52bcb942fa6db2385dcd1b3b9d567aaeb425d567b0ebe267235651a"
"1ed9bf78fd93d3c1dd077fe340bb04b00529c58f45124b717c168d07e9826e33376988bc"
"5cf62845c2009980a4dfa69fbc7e5a0b1bb20a5958ca967aec68eb31dd8fccca9afcd30a"
"26bab26279f1bf6724ff",
   "11863b483809ef88413ca9b0084ac4a5390640af",

   6056,
"31ec3c3636618c7141441294fde7e72366a407fa7ec6a64a41a7c8dfda150ca417fac868"
"1b3c5be253e3bff3ab7a5e2c01b72790d95ee09b5362be835b4d33bd20e307c3c702aa15"
"60cdc97d190a1f98b1c78e9230446e31d60d25155167f73e33ed20cea27b2010514b57ba"
"b05ed16f601e6388ea41f714b0f0241d2429022e37623c11156f66dd0fa59131d8401dba"
"f502cffb6f1d234dcb53e4243b5cf9951688821586a524848123a06afa76ab8058bcfa72"
"27a09ce30d7e8cb100c8877bb7a81b615ee6010b8e0daced7cc922c971940b757a9107de"
"60b8454dda3452e902092e7e06faa57c20aadc43c8012b9d28d12a8cd0ba0f47ab4b377f"
"316902e6dff5e4f2e4a9b9de1e4359f344e66d0565bd814091e15a25d67d89cf6e30407b"
"36b2654762bbe53a6f204b855a3f9108109e351825cf9080c89764c5f74fb4afef89d804"
"e7f7d097fd89d98171d63eaf11bd719df44c5a606be0efea358e058af2c265b2da2623fd"
"afc62b70f0711d0150625b55672060cea6a253c590b7db1427a536d8a51085756d1e6ada"
"41d9d506b5d51bcae41249d16123b7df7190e056777a70feaf7d9f051fdbbe45cbd60fc6"
"295dda84d4ebbd7284ad44be3ee3ba57c8883ead603519b8ad434e3bf630734a9243c00a"
"a07366b8f88621ec6176111f0418c66b20ff9a93009f43432aaea899dad0f4e3ae72e9ab"
"a3f678f140118eb7117230c357a5caa0fe36c4e6cf1957bbe7499f9a68b0f1536e476e53"
"457ed826d9dea53a6ded52e69052faaa4d3927b9a3f9e8b435f424b941bf2d9cd6849874"
"42a44d5acaa0da6d9f390d1a0dd6c19af427f8bb7c082ae405a8dd535dea76aa360b4faa"
"d786093e113424bb75b8cc66c41af637a7b2acdca048a501417919cf9c5cd3b2fa668860"
"d08b6717eea6f125fa1b0bae1dbb52aafce8ae2deaf92aeb5be003fb9c09fedbc286ffb5"
"e16ad8e07e725faa46ebc35500cf205fc03250075ddc050c263814b8d16d141db4ca289f"
"386719b28a09a8e5934722202beb3429899b016dfeb972fee487cdd8d18f8a681042624f"
"51",
   "f43937922444421042f76756fbed0338b354516f",

   6848,
"21b9a9686ec200456c414f2e6963e2d59e8b57e654eced3d4b57fe565b51c9045c697566"
"44c953178f0a64a6e44d1b46f58763c6a71ce4c373b0821c0b3927a64159c32125ec916b"
"6edd9bf41c3d80725b9675d6a97c8a7e3b662fac9dbcf6379a319a805b5341a8d360fe00"
"5a5c9ac1976094fea43566d66d220aee5901bd1f2d98036b2d27eb36843e94b2e5d1f09c"
"738ec826de6e0034cf8b1dca873104c5c33704cae290177d491d65f307c50a69b5c81936"
"a050e1fe2b4a6f296e73549323b6a885c3b54ee5eca67aa90660719126b590163203909e"
"470608f157f033f017bcf48518bf17d63380dabe2bc9ac7d8efe34aedcae957aeb68f10c"
"8ad02c4465f1f2b029d5fbb8e8538d18be294394b54b0ee6e67a79fce11731604f3ac4f8"
"d6ffa9ef3d2081f3d1c99ca107a7bf3d624324a7978ec38af0bcd0d7ee568572328b212b"
"9dc831efb7880e3f4d6ca7e25f8e80d73913fb8edfffd758ae4df61b4140634a92f49314"
"6138ebdcdaa083ea72d52a601230aa6f77874dcad9479f5bcac3763662cc30cb99823c5f"
"f469dcbd64c028286b0e579580fd3a17b56b099b97bf62d555798f7a250e08b0e4f238c3"
"fcf684198bd48a68c208a6268be2bb416eda3011b523388bce8357b7f26122640420461a"
"bcabcb5004519adfa2d43db718bce7d0c8f1b4645c89315c65df1f0842e5741244bba3b5"
"10801d2a446818635d0e8ffcd80c8a6f97ca9f878793b91780ee18eb6c2b99ffac3c38ef"
"b7c6d3af0478317c2b9c421247eba8209ea677f984e2398c7c243696a12df2164417f602"
"d7a1d33809c865b73397550ff33fe116166ae0ddbccd00e2b6fc538733830ac39c328018"
"bcb87ac52474ad3cce8780d6002e14c6734f814cb551632bcc31965c1cd23d048b9509a4"
"e22ab88f76a6dba209d5dd2febd1413a64d32be8574a22341f2a14e4bd879abb35627ef1"
"35c37be0f80843006a7cc7158d2bb2a71bf536b36de20ca09bb5b674e5c408485106e6fa"
"966e4f2139779b46f6010051615b5b41cda12d206d48e436b9f75d7e1398a656abb0087a"
"a0eb453368fc1ecc71a31846080f804d7b67ad6a7aa48579c3a1435eff7577f4e6004d46"
"aac4130293f6f62ae6d50c0d0c3b9876f0728923a94843785966a27555dd3ce68602e7d9"
"0f7c7c552f9bda4969ec2dc3e30a70620db6300e822a93e633ab9a7a",
   "5d4d18b24b877092188a44be4f2e80ab1d41e795",

   7640,
"1c87f48f4409c3682e2cf34c63286dd52701b6c14e08669851a6dc8fa15530ad3bef692c"
"7d2bf02238644561069df19bdec3bccae5311fce877afc58c7628d08d32d9bd2dc1df0a6"
"24360e505944219d211f33bff62e9ff2342ac86070240a420ccaf14908e6a93c1b27b6e2"
"0324e522199e83692805cc4c7f3ea66f45a490a50d4dd558aa8e052c45c1a5dfad452674"
"edc7149024c09024913f004ceee90577ff3eaec96a1eebbdc98b440ffeb0cad9c6224efc"
"9267d2c192b53dc012fb53010926e362ef9d4238d00df9399f6cbb9acc389a7418007a6c"
"a926c59359e3608b548bdeece213f4e581d02d273781dffe26905ec161956f6dfe1c008d"
"6da8165d08f8062eea88e80c055b499f6ff8204ffdb303ab132d9b0cba1e5675f3525bbe"
"4cf2c3f2b00506f58336b36aefd865d37827f2fad7d1e59105b52f1596ea19f848037dfe"
"dc9136e824ead5505e2995d4c0769276548835430667f333fc77375125b29c1b1535602c"
"10fe161864f49a98fc274ae7335a736be6bf0a98cd019d120b87881103f86c0a6efadd8c"
"aa405b6855c384141b4f8751cc42dc0cb2913382210baaa84fe242ca66679472d815c08b"
"f3d1a7c6b5705a3de17ad157522de1eb90c568a8a1fbcbb422cca293967bb14bfdd91bc5"
"a9c4d2774dee524057e08f937f3e2bd8a04ced0fc7b16fb78a7b16ee9c6447d99e53d846"
"3726c59066af25c317fc5c01f5dc9125809e63a55f1cd7bdf7f995ca3c2655f4c7ab940f"
"2aa48bc3808961eb48b3a03c731ce627bb67dd0037206c5f2c442fc72704258548c6a9db"
"e16da45e40da009dc8b2600347620eff8361346116b550087cb9e2ba6b1d6753622e8b22"
"85589b90a8e93902aa17530104455699a1829efef153327639b2ae722d5680fec035575c"
"3b48d9ec8c8e9550e15338cc76b203f3ab597c805a8c6482676deabc997a1e4ba857a889"
"97ceba32431443c53d4d662dd5532aa177b373c93bf93122b72ed7a3189e0fa171dfabf0"
"520edf4b9d5caef595c9a3a13830c190cf84bcf9c3596aadb2a674fbc2c951d135cb7525"
"3ee6c59313444f48440a381e4b95f5086403beb19ff640603394931f15d36b1cc9f3924f"
"794c965d4449bfbdd8b543194335bdf70616dc986b49582019ac2bf8e68cfd71ec67e0aa"
"dff63db39e6a0ef207f74ec6108fae6b13f08a1e6ae01b813cb7ee40961f95f5be189c49"
"c43fbf5c594f5968e4e820a1d38f105f2ff7a57e747e4d059ffb1d0788b7c3c772b9bc1f"
"e147c723aca999015230d22c917730b935e902092f83e0a8e6db9a75d2626e0346e67e40"
"8d5b815439dab8ccb8ea23f828fff6916c4047",
   "32e0f5d40ceec1fbe45ddd151c76c0b3fef1c938",

   8432,
"084f04f8d44b333dca539ad2f45f1d94065fbb1d86d2ccf32f9486fe98f7c64011160ec0"
"cd66c9c7478ed74fde7945b9c2a95cbe14cedea849978cc2d0c8eb0df48d4834030dfac2"
"b043e793b6094a88be76b37f836a4f833467693f1aa331b97a5bbc3dbd694d96ce19d385"
"c439b26bc16fc64919d0a5eab7ad255fbdb01fac6b2872c142a24aac69b9a20c4f2f07c9"
"923c9f0220256b479c11c90903193d4e8f9e70a9dbdf796a49ca5c12a113d00afa844694"
"de942601a93a5c2532031308ad63c0ded048633935f50a7e000e9695c1efc1e59c426080"
"a7d1e69a93982a408f1f6a4769078f82f6e2b238b548e0d4af271adfa15aa02c5d7d7052"
"6e00095ffb7b74cbee4185ab54385f2707e8362e8bd1596937026f6d95e700340b6338ce"
"ba1ee854a621ce1e17a016354016200b1f98846aa46254ab15b7a128b1e840f494b2cdc9"
"daccf14107c1e149a7fc27d33121a5cc31a4d74ea6945816a9b7a83850dc2c11d26d767e"
"ec44c74b83bfd2ef8a17c37626ed80be10262fe63cf9f804b8460c16d62ae63c8dd0d124"
"1d8aaac5f220e750cb68d8631b162d80afd6b9bf929875bf2e2bc8e2b30e05babd8336be"
"31e41842673a66a68f0c5acd4d7572d0a77970f42199a4da26a56df6aad2fe420e0d5e34"
"448eb2ed33afbfb35dffaba1bf92039df89c038bae3e11c02ea08aba5240c10ea88a45a1"
"d0a8631b269bec99a28b39a3fc5b6b5d1381f7018f15638cc5274ab8dc56a62b2e9e4fee"
"f172be20170b17ec72ff67b81c15299f165810222f6a001a281b5df1153a891206aca89e"
"e7baa761a5af7c0493a3af840b9219e358b1ec1dd301f35d4d241b71ad70337bda42f0ea"
"dc9434a93ed28f96b6ea073608a314a7272fefd69d030cf22ee6e520b848fa705ed6160f"
"e54bd3bf5e89608506e882a16aced9c3cf80657cd03749f34977ced9749caa9f52b683e6"
"4d96af371b293ef4e5053a8ea9422df9dd8be45d5574730f660e79bf4cbaa5f3c93a79b4"
"0f0e4e86e0fd999ef4f26c509b0940c7a3eaf1f87c560ad89aff43cd1b9d4863aa3ebc41"
"a3dd7e5b77372b6953dae497fc7f517efe99e553052e645e8be6a3aeb362900c75ce712d"
"fcba712c4c25583728db9a883302939655ef118d603e13fcf421d0cea0f8fb7c49224681"
"d013250defa7d4fd64b69b0b52e95142e4cc1fb6332486716a82a3b02818b25025ccd283"
"198b07c7d9e08519c3c52c655db94f423912b9dc1c95f2315e44be819477e7ff6d2e3ccd"
"daa6da27722aaadf142c2b09ce9472f7fd586f68b64d71fc653decebb4397bf7af30219f"
"25c1d496514e3c73b952b8aa57f4a2bbf7dcd4a9e0456aaeb653ca2d9fa7e2e8a532b173"
"5c4609e9c4f393dd70901393e898ed704db8e9b03b253357f333a66aba24495e7c3d1ad1"
"b5200b7892554b59532ac63af3bdef590b57bd5df4fbf38d2b3fa540fa5bf89455802963"
"036bd173fe3967ed1b7d",
   "ee976e4ad3cad933b283649eff9ffdb41fcccb18",

   9224,
"bd8320703d0cac96a96aeefa3abf0f757456bf42b3e56f62070fc03e412d3b8f4e4e427b"
"c47c4600bb423b96de6b4910c20bc5c476c45feb5b429d4b35088813836fa5060ceb26db"
"bb9162e4acd683ef879a7e6a0d6549caf0f0482de8e7083d03ed2f583de1b3ef505f4b2c"
"cd8a23d86c09d47ba05093c56f21a82c815223d777d0cabb7ee4550423b5deb6690f9394"
"1862ae41590ea7a580dda79229d141a786215d75f77e74e1db9a03c9a7eb39eb35adf302"
"5e26eb31ca2d2ca507edca77d9e7cfcfd136784f2117a2afafa87fa468f08d07d720c933"
"f61820af442d260d172a0a113494ca169d33a3aeaacdcc895b356398ed85a871aba769f6"
"071abd31e9f2f5834721d0fef6f6ee0fc0e38760b6835dfcc7dbefb592e1f0c3793af7ad"
"f748786d3364f3cfd5686b1a18711af220e3637d8fad08c553ce9d5dc1183d48e8337b16"
"1fe69b50e1920316dbffec07425b5d616a805a699576590e0939f5c965bce6c7342d314a"
"c37b9c4d30166567c4f633f182de4d6b00e20a1c762789f915eaa1c89ac31b85222b1f05"
"403dedd94db9ce75ff4e49923d1999d032695fa0a1c595617830c3c9a7ab758732fcec26"
"85ae14350959b6a5f423ef726587e186b055a8daf6fa8fdefa02841b2fdbca1616dcee78"
"c685fc6dcc09f24a36097572eba3c37a3eabe98bc23836085f63ef71a54b4488615d83b2"
"6ed28c9fce78852df9b6cf8a75ca3899a7567298e91bc4ffdd04ffab0066b43b8286a4bb"
"555c78808496b252c6e0e4d153631f11f68baf88630e052acc2af5d2af2e22e4f23bb630"
"314c561a577455f86b6727bcad3c19d3e271404dec30af3d9dd0ed63cd9fa708aadfa12a"
"500ef2d99a6b71e137b56ba90036975b88004b45f577ef800f0fb3cf97577dc9da37253b"
"8675e5c8bb7e0bd26564f19eca232fb25f280f82e014424c9fbdd1411d7556e5d7906bb8"
"62206316ba03385cd820c54c82ed35b36735bc486b1885d84053eba036c1ebfb5422d93d"
"a71c53deda7f74db07cd4959cdfa898ba37080d76b564d344b124dd7b80cd70ed3b52a6c"
"f9c9a32695d134bd39eb11ddeecdac86c808e469bd8a7995b667c452e7d9a54d5c85bcf6"
"d5ffdc27d491bc06f438f02c7cf018073431587c78ba08d18a8daccb2d3b26136f612ade"
"c673f3cd5eb83412b29652d55a10d0d6238d0b5365db272c917349450aff062c36191cfc"
"d45660819083f89cd42ecae9e26934a020cafeb9b2b68d544edf59574c0ca159fd195dbf"
"3e3e74244d942fffdbd4ed7f626219bab88b5a07e50b09a832d3e8ad82091114e54f2c35"
"6b48e55e36589ebad3ac6077cb7b1827748b00670df65bbf0a2e65caad3f8a97d654d64e"
"1c7dad171cafbc37110d2f7ca66524dc08fe60593e914128bd95f41137bfe819b5ca835f"
"e5741344b5c907ce20a35f4f48726141c6398e753ed9d46d3692050628c78859d5014fe4"
"dd3708e58d4d9807f8dac540492e32fa579491717ad4145c9efc24cf95605660b2e09b89"
"9369b74d3ebff41e707917ff314d93e6ac8dfd643ef2c087cd9912005b4b2681da01a369"
"42a756a3e22123cbf38c429373c6a8663130c24b24b2690b000013960b1c46a32d1d5397"
"47",
   "2df09b10933afedfcd3f2532dfd29e7cb6213859",

   10016,
"7a94978bec7f5034b12c96b86498068db28cd2726b676f54d81d8d7350804cc106bead8a"
"252b465a1f413b1c41e5697f8cece49ec0dea4dfb9fa7b1bfe7a4a00981875b420d094bb"
"1ce86c1b8c2e1dbebf819c176b926409fdec69042e324e71d7a8d75006f5a11f512811fe"
"6af88a12f450e327950b18994dfc3f740631beda6c78bca5fe23d54e6509120e05cd1842"
"d3639f1466cf26585030e5b4aefe0404fe900afc31e1980f0193579085342f1803c1ba27"
"0568f80eaf92440c4f2186b736f6ab9dc7b7522ccdcfc8cf12b6375a2d721aa89b5ef482"
"112a42c31123aebabcb485d0e72d6b6b70c44e12d2da98d1f87fa9df4f37847e1ffec823"
"1b8be3d737d282ddb9cc4b95937acfa0f028ba450def4d134a7d0fc88119bf7296e18cd4"
"4f56890b661b5b72ddfa34c29228067e13caf08eb3b7fd29de800df9a9ae137aad4a81a4"
"16a301c9f74b66c0e163e243b3187996b36eb569de3d9c007d78df91f9b554eef0eaa663"
"88754ce20460b75d95e2d0747229a1502a5652cf39ca58e1daa0e9321d7ab3093981cd70"
"23a7ee956030dd70177028a66ad619ad0629e631f91228b7c5db8e81b276d3b168c1edb1"
"bc0888d1cbcbb23245c2d8e40c1ff14bfe13f9c70e93a1939a5c45eef9351e795374b9e1"
"b5c3a7bd642477ba7233e1f590ab44a8232c53099a3c0a6ffe8be8b7ca7b58e6fedf700f"
"6f03dd7861ee1ef857e3f1a32a2e0baa591d0c7ca04cb231cc254d29cda873f00d68f465"
"00d6101cfdc2e8004c1f333d8007325d06ffe6b0ff7b80f24ba51928e65aa3cb78752028"
"27511207b089328bb60264595a2cebfc0b84d9899f5eca7ea3e1d2f0f053b4e67f975500"
"7ff3705ca4178ab9c15b29dd99494135f35befbcec05691d91f6361cad9c9a32e0e65577"
"f14d8dc66515081b51d09e3f6c25eea868cf519a83e80c935968cae6fce949a646ad53c5"
"6ee1f07dda23daef3443310bc04670afedb1a0132a04cb64fa84b4af4b3dc501044849cd"
"dd4adb8d733d1eac9c73afa4f7d75864c87787f4033ffe5ba707cbc14dd17bd1014b8b61"
"509c1f55a25cf6c0cbe49e4ddcc9e4de3fa38f7203134e4c7404ee52ef30d0b3f4e69bcc"
"7d0b2e4d8e60d9970e02cc69d537cfbc066734eb9f690a174e0194ca87a6fadad3883d91"
"6bd1700a052b26deee832701590d67e6f78938eac7c4beef3061a3474dd90dd588c1cd6e"
"6a4cda85b110fd08a30dcd85a3ebde910283366a17a100db920885600db7578be46bcfa6"
"4765ba9a8d6d5010cb1766d5a645e48365ed785e4b1d8c7c233c76291c92ef89d70bc77f"
"bf37d7ce9996367e5b13b08242ce73971f1e0c6ff2d7920fb9c821768a888a7fe0734908"
"33efb854cbf482aed5cb594fb715ec82a110130664164db488666d6198279006c1aa521f"
"9cf04250476c934eba0914fd586f62d6c5825b8cf82cd7ef915d93106c506ea6760fd8b0"
"bf39875cd1036b28417de54783173446026330ef701c3a6e5b6873b2025a2c1666bb9e41"
"a40adb4a81c1052047dabe2ad092df2ae06d6d67b87ac90be7d826ca647940c4da264cad"
"43c32a2bb8d5e27f87414e6887561444a80ed879ce91af13e0fbd6af1b5fa497ad0cbd2e"
"7f0f898f52f9e4710de2174e55ad07c45f8ead3b02cac6c811becc51e72324f2439099a0"
"5740090c1b165ecae7dec0b341d60a88f46d7ad8624aac231a90c93fad61fcfbbea12503"
"59fcd203862a6b0f1d71ac43db6c58a6b60c2c546edc12dd658998e8",
   "f32e70862a16e3e8b199e9d81a9949d66f812cad",

   10808,
"88dd7f273acbe799219c23184782ac0b07bade2bc46b4f8adbd25ed3d59c0fd3e2931638"
"837d31998641bbb7374c7f03d533ca60439ac4290054ff7659cc519bdda3dff2129a7bdb"
"66b3300068931ade382b7b813c970c8e15469187d25cb04b635403dc50ea6c65ab38a97c"
"431f28a41ae81c16192bd0c103f03b8fa815d6ea5bf0aa7fa534ad413b194eb12eb74f5d"
"62b3d3a7411eb8c8b09a261542bf6880acbdfb617a42e577009e482992253712f8d4c8bd"
"1c386bad068c7aa10a22111640041f0c35dabd0de00ebf6cd82f89cbc49325df12419278"
"ec0d5ebb670577b2fe0c3e0840c5dd0dc5b3da00669eed8ead380f968b00d42f4967faec"
"c131425fce1f7edb01cbec7e96d3c26fa6390a659e0ab069ef3edadc07e077bb816f1b22"
"98830a0fe2b393693bb79f41feca89577c5230e0a6c34b860dc1fdb10d85aa054481082c"
"494779d59ba798fcd817116c3059b7831857d0364352b354ce3b960fbb61a1b8a04d47ca"
"a0ead52a9bea4bada2646cdbaec211f391dac22f2c5b8748e36bfc3d4e8ea45131ca7f52"
"af09df21babe776fcecbb5c5dfa352c790ab27b9a5e74242bbd23970368dbefd7c3c74d1"
"61ae01c7e13c65b415f38aa660f51b69ea1c9a504fe1ad31987cb9b26a4db2c37d7b326c"
"50dbc8c91b13925306ff0e6098532dee7282a99c3ddf99f9e1024301f76e31e58271870b"
"d94b9356e892a6a798d422a48c7fd5b80efe855a4925cc93b8cf27badec5498338e2b538"
"70758b45d3e7a2fa059ed88df320a65e0a7cf87fa7e63b74cea1b7371e221f8004726642"
"30d4d57945a85b23d58f248c8cd06ccfabfa969ab8cb78317451fab60e4fdfa796e2e2a8"
"b46405839a91266d37e8d38bae545fb4060c357923b86d62f5d59d7bef5af20fbb9c7fb4"
"2c6fd487748ed3b9973dbf4b1f2c9615129fa10d21cc49c622842c37c01670be71715765"
"a98814634efbdee66bf3420f284dbd3efafc8a9117a8b9a72d9b81aa53ded78c409f3f90"
"bad6e30d5229e26f4f0cea7ee82c09e3b60ec0e768f35a7fb9007b869f9bfc49c518f648"
"3c951d3b6e22505453266ec4e7fe6a80dbe6a2458a1d6cd93044f2955607412091009c7d"
"6cd81648a3b0603c92bfdff9ec3c0104b07ed2105962ca7c56ede91cb932073c337665e2"
"409387549f9a46da05bc21c5126bd4b084bc2c06ab1019c51df30581aa4464ab92978c13"
"f6d7c7ac8d30a78f982b9a43181bbe3c3eb9f7a1230b3e53b98a3c2a028317827fbe8cf6"
"ec5e3e6b2a084d517d472b25f72fab3a34415bba488f14e7f621cfa72396ba40890e8c60"
"b04815601a0819c9bebc5e18b95e04be3f9c156bd7375d8cc8a97c13ce0a3976123419fa"
"592631317ca638c1182be06886f9663d0e8e6839573df8f52219eeb5381482a6a1681a64"
"173660bfbb6d98bf06ee31e601ee99b4b99b5671ed0253260b3077ed5b977c6a79b4ff9a"
"08efd3cba5c39bec1a1e9807d40bbf0c988e0fd071cf2155ed7b014c88683cd869783a95"
"4cbfced9c0e80c3a92d45b508985cbbc533ba868c0dc4f112e99400345cf7524e42bf234"
"5a129e53da4051c429af2ef09aba33ae3c820ec1529132a203bd2b81534f2e865265f55c"
"9395caf0e0d3e1762c95eaaec935e765dc963b3e0d0a04b28373ab560fa9ba5ca71ced5d"
"17bb8b56f314f6f0d0bc8104b3f1835eca7eaac15adf912cf9a6945cfd1de392342dd596"
"d67e7ffcb7e086a6c1ea318aa2e0c2b5c2da079078232c637de0d317a1f26640bc1dac5b"
"e8699b53edc86e4bfdfaf797a2ae350bf4ea29790face675c4d2e85b8f37a694c91f6a14"
"1fd561274392ee6ee1a14424d5c134a69bcb4333079400f03615952fc4c99bf03f5733a8"
"dc71524269fc5c648371f5f3098314d9d10258",
   "08632c75676571a5db5971f5d99cb8de6bf1792a",

   11600,
"85d43615942fcaa449329fd1fe9efb17545eb252cac752228f1e9d90955a3cf4e72cb116"
"3c3d8e93ccb7e4826206ff58b3e05009ee82ab70943db3f18a32925d6d5aed1525c91673"
"bd33846571af815b09bb236466807d935b5816a8be8e9becbe65d05d765bcc0bc3ae66c2"
"5320ebe9fff712aa5b4931548b76b0fd58f6be6b83554435587b1725873172e130e1a3ca"
"3d9d0425f4632d79cca0683780f266a0633230e4f3b25f87b0c390092f7b13c66ab5e31b"
"5a58dbcac8dd26a0600bf85507057bb36e870dfae76da8847875a1a52e4596d5b4b0a211"
"2435d27e1dc8dd5016d60feaf2838746d436a2983457b72e3357059b2bf1e9148bb0551a"
"e2b27d5a39abd3d1a62c36331e26668e8baabc2a1ef218b5e7a51a9ca35795bcd54f403a"
"188eafafb30d82896e45ddaea4f418629a1fb76a0f539c7114317bac1e2a8fba5a868bce"
"40abd40f6b9ced3fa8c0329b4de5ca03cc84d75b8746ef31e6c8d0a0a79b4f747690928e"
"be327f8bbe9374a0df4c39c845bf3322a49fda9455b36db5a9d6e4ea7d4326cf0e0f7cd8"
"0ff74538f95cec01a38c188d1243221e9272ccc1053e30787c4cf697043cca6fc3730d2a"
"431ecbf60d73ee667a3ab114c68d578c66dc1c659b346cb148c053980190353f6499bfef"
"acfd1d73838d6dc1188c74dd72b690fb0481eee481a3fd9af1d4233f05d5ae33a7b10d7d"
"d643406cb1f88d7dd1d77580dcbee6f757eeb2bfbcc940f2cddb820b2718264b1a64115c"
"b85909352c44b13d4e70bbb374a8594d8af7f41f65b221bf54b8d1a7f8f9c7da563550cb"
"2b062e7a7f21d5e07dd9da8d82e5a89074627597551c745718094c2eb316ca077526d27f"
"9a589c461d891dc7cd1bc20ba3f464da53c97924219c87a0f683dfb3b3ac8793c59e78ac"
"fac109439221ac599a6fd8d2754946d6bcba60784805f7958c9e34ff287ad1dbbc888848"
"fa80cc4200dbb8c5e4224535906cbffdd0237a77a906c10ced740f9c0ce7821f2dbf8c8d"
"7d41ecfcc7dfdc0846b98c78b765d01fb1eb15ff39149ab592e5dd1152665304bba85bbf"
"4705751985aaaf31245361554d561a2337e3daeef58a826492fd886d5f18ef568c1e772e"
"f6461170407695e3254eb7bf0c683811ddde5960140d959114998f08bdb24a104095987d"
"3255d590e0dbd41ae32b1ae4f4ea4a4f011de1388034231e034756870c9f2d9f23788723"
"27055a7de2b5e931dfb53e7780b6d4294bf094e08567025b026db9203b681565a1d52f30"
"318d0ebe49471b22ba5fd62e1ed6c8966c99b853c9062246a1ace51ef7523c7bf93bef53"
"d8a9cb96d6a04f0da1eca888df66e0380a72525a7ecc6115d08569a66248f6ba34e2341b"
"fd01a78f7b3c1cfe0754e0d26cba2fa3f951ef14d5749ff8933b8aba06fa40fb570b467c"
"54ce0d3f0bed21e998e5a36b3bc2f9e1ae29c4bab59c121af6fad67c0b45959cd6a86194"
"14b90b4535fb95f86ca7e64502acc135eff4f8a3abe9dde84238fab7a7d402454a3f07ad"
"ec05ec94b2891e0879037fae6acaa31dcecf3f85236ade946f5ad69ad4077beb65099285"
"38ee09f2bc38e5704da67b5006b5e39cd765aafcd740c7dadb99d0c547126e1324610fcb"
"7353dac2c110e803fca2b17485b1c4b78690bc4f867e6f043b2568889f67985a465a48eb"
"ee915200589e915756d4968d26529c3ffe3dbe70e84c682ad08a0c68db571634fbb0210d"
"c1b16b8b725886465c8c51f36a5e27d0f78e5643e051d3bddd512ce511f6bdf3dfe42759"
"00c5fea9d248c2b3f36911ed0ff41a19f6445521f251724657ea8f795b3ead0928a1657f"
"308dd7c7c1e7e490d9849df43becfa5cc25ed09ef614fd69ddc7e5e3147623901d647876"
"fb60077ffc48c51ed7d02b35f6802e3715fc708a0c88b82fe9cba0a442d38d09ca5ae483"
"21487bdef1794e7636bf7457dd2b51a391880c34d229438347e5fec8555fe263f08ba87b"
"b16dcde529248a477628067d13d0cb3bf51776f4d39fb3fbc5f669e91019323e40360e4b"
"78b6584f077bf9e03b66",
   "ab7213f6becb980d40dc89fbda0ca39f225a2d33",

   12392,
"7ae3ca60b3a96be914d24980fb5652eb68451fed5fa47abe8e771db8301fbd5331e64753"
"93d96a4010d6551701e5c23f7ecb33bec7dd7bade21381e9865d410c383a139cb4863082"
"8e9372bd197c5b5788b6599853e8487bddfd395e537772fdd706b6a1de59c695d63427da"
"0dc3261bce2e1ae3cd6de90ec45ecd7e5f14580f5672b6ccd8f9336330dffcd6a3612a74"
"975afc08fb136450e25dc6b071ddfc28fca89d846c107fd2e4bd7a19a4ff6f482d62896d"
"a583c3277e23ab5e537a653112cdf2306043b3cc39f5280bd744fe81d66f497b95650e7d"
"dfd704efcb929b13e00c3e3a7d3cd53878af8f1506d9de05dba9c39a92604b394ea25acb"
"a2cda7b4ae8b08098ba3f0fdea15359df76517be84377f33631c844313ac335aa0d590fe"
"c472d805521f0905d44ca40d7391b292184105acd142c083761c1a038c4f5ed869ea3696"
"99592a37817f64cb4205b66be1f1de6fa47a08e1bf1a94312fe61a29e71bab242af95a7b"
"38d4fb412c682b30256d91e2a46b634535d02b495240cbdb842cbe17cba6a2b94073f3d5"
"f9621ac92ddda66f98bed997216466b4bb0579d58945f8d7450808d9e285d4f1709d8a1d"
"416aa57d4a1a72bfcbfecdda33de2cff3e90e0cc60c897c4663224fc5bbe8316a83c1773"
"802837a57bc7e9238173ed41ea32fe5fe38e546014a16d5e80700d9bac7a84bb03902f31"
"79e641f86f6bc383d656daf69801499633fb367ea7593195934c72bc9bf9624c0c845ebf"
"c36eb7ad4b22fdfb45ca7d4f0d6708c69a21f6eaa6db6bde0f0bd9dc7ec9c6e24626d0a7"
"8fbeeed4b391f871e80e6a9d207165832d4ff689296f9bca15dc03c7c0381659ea5335eb"
"aafdc3e50d18e46b00f1844870d09c25afcdb0ff1ae69dd8f94f91aca6095ba6f2b6e594"
"c4acfe9903485d21b684e31a6acc2162d40e1a7bb8114a860a07e76f5265666555f2418d"
"f11ef8f7499656d12215f5da8d7d041ac72648d15d7661ad93b24f3f071334b0921d5bb0"
"6f2c7ab09f5034518b5ae21cec379373e87d51c77d44a70c2337606aadeb9036716fd920"
"a824e7ae18ce3de9f0ec3456f3454027d8c476b3f1854b240c309f6f9786fa8a073915d9"
"7a019ce99aec3260c5f6b6346cd9c41cb9267f4475958e45289965548238c6b9f91a8784"
"b4e0957ba8b73956012c9a2fc3428434b1c1679f6ed2a3e8e2c90238df428622046f668e"
"e2b053f55e64ffd45600e05a885e3264af573bacee93d23d72a0222b5442ac80bc0a8b79"
"4c2afcf3bc881d20c111f57e3450b50a703f3db1fc5de2076a006f3b7eed694b93269874"
"3b03c2ed2684bad445e69a692e744c7ac3a04f1e0e52b7a6708076d1fbffdb3f1c995828"
"7d5f884e29407030f2db06811092efd80ae08da9daec39744c5ecd3ca771663b8f4968d4"
"2a88c2c9821c73ae2a5a4d9e2551f82c03583b9c4dea775423b4748d24eb604e8ee3159b"
"a6de9bea5b22eed6264e011734ed02b2c74ce06dda890b8604ed7ba49e7bf30e28c9871b"
"e90f5cead67eaf52b5d3181c822b10701219b28ef6f6bebfa278e38acf863e2a1d4b1e40"
"fd8a0ac6ce31054446301046148bf10dc3ae3385e2026e7762bdc8003ffebc4263191a59"
"c72f4f90db03e7d52808506b33bfe1dfa53f1a3daa152e83974fbe56cfd4e8f4e7f7806a"
"084b9d0795b858100eced0b5355a72446f37779d6c67ade60a627b8077ae1f3996b03bc3"
"a5c290651c8609f0d879fbf578cbab35086e1159dd6ddbe3bf7fb5654edcc8f09e4f80d0"
"258c9376d7c53fb68f78d333b18b70170d9a11070790c956f5744c78c986b1baf08b7631"
"7a65c5f07ae6f57eb0e65488659324d29709e3735623d0426e90aa8c4629bb080881150c"
"02be1c004da84414ac001c2eb6138c26388f5a36d594f3acef0e69e2cb43b870efa84da0"
"cff9c923a9880202aed64ad76260f53c45bb1584b3e388a909d13586094b924680006a1d"
"25d4dd36c579a8ec9d3fa63c082d977a5a5021440b5314b51850f2daa6e6af6ae88cb5b1"
"44242bceb1d4771e641101f8abfc3a9b19f2de64e35e76458ad22072ba57925d73015de5"
"66c66fcaa28fdc656f90de967ad51afd331e246d74ed469d63dd7d219935c59984bd9629"
"09d1af296eb3121d782650e7d038063bab5fa854aac77de5ffebeb53d263f521e3fc02ac"
"70",
   "b0e15d39025f5263e3efa255c1868d4a37041382",

   13184,
"fa922061131282d91217a9ff07463843ae34ff7f8c28b6d93b23f1ea031d5020aa92f660"
"8c3d3df0ee24a8958fd41af880ee454e36e26438defb2de8f09c018607c967d2f0e8b80a"
"00c91c0eabe5b4c253e319b45e6106ff8bf0516f866020e5ba3f59fd669c5aeff310ebb3"
"85007069d01c64f72d2b02f4ec0b45c5ecf313056afcb52b17e08b666d01fecc42adb5b4"
"9ea00c60cacac2e0a953f1324bdd44aec00964a22a3cb33916a33da10d74ec6c6577fb37"
"5dc6ac8a6ad13e00cba419a8636d4daac8383a2e98fe90790cde7b59cfaa17c410a52abc"
"d68b127593d2fcbafd30578d195d890e981ae09e6772cb4382404a4e09f1a33c958b57db"
"ccee54ae335b6c91443206a0c100135647b844f226417a1f70317fd350d9f3789d81894a"
"aff4730072401aaeb8b713ead4394e2e64b6917d6eee2549af7bd0952f12035719065320"
"ca0d2dfe2847c6a2357c52bee4a676b12bafff66597bd479aa29299c1896f63a7523a85a"
"b7b916c5930ab66b4d191103cefc74f2f7e0e96e354f65e355ae43959a0af1880d14ea9d"
"1569e4fd47174aba7f5decb430b3f6baf80a1ef27855227b62487250d3602970e423423c"
"7ca90920685bcf75adfbe2a61ce5bd9228947b32f567927cb1a5bd8727c03aef91d6367b"
"ae7d86fd15c0977ac965a88b0d7236037aefb8d24eec8d2a07c633e031a7b9147c4c7714"
"110bfc7e261448a5d0f73c3619664e1c533c81a0acbf95d502227a33f84f0b8249e3f9fa"
"5c7905a8192b7313fc56bb20679e81333d32c797ac5162204a0eaa0e64507635921c485b"
"8f17c4e2484667a733197529e2a833eed83c57229b11bd820b5a5b78f1867787dbc217ea"
"28bfba785fb545cbc5a840a12eea428213e1aaa4e50a900ba13efcf4a5345574c2481c5d"
"927ada610bba567a55630c89d905db3d9b67fe36c9cc3d6a947664c83e69f51c74711a33"
"df66dd3ff6af9b7c1605b614d4798b4192b9a4b1508f2e2ec5aaad7eaea1ee8867353db9"
"b8d7d9a6f16aa5f339492073238c979082879aee7f94ac4be8133eaacbaedfb044e2ad4e"
"93ba0fa071dea615a5cd80d1d2678f4f93ae5a4bc9cdf3df345a29ec41d8febb23805ce4"
"2541036f3f05c63ae736f79a29802045fad9f370cabf843458c1b636ca41f387fd7821c9"
"1abbd1946afcb9186b936403233f28a5b467595131a6bc07b0873e51a08de66b5d7709a6"
"02c1bd0e7f6e8f4beb0579c51bda0e0c738ef876fcd9a40ab7873c9c31c1d63a588eebc7"
"8d9a0ae6fa35cd1a269e0d2bc68252cbd7c08d79e96f0aa6be22a016136a2b8abe9d3c9c"
"f9d60eeafe3dbc76d489b24d68c36167df4c38cf2b21cf03dc5e659e39018c3490f1237e"
"ca3f85b742ab0045d86a899c4126ad60a147cbc95b71814c274d6478668df41eb32acfb4"
"bbf024fb4e3d6be0b60653a0471afc3037ab67dcb00a2b2e24b26911e1880136e56106b7"
"f3c570fbe6f311d94624cb001914ff96fbbf481f71686aa17be0850568058fc1ee8900b4"
"7af5cf51c5ed9e00a8b532c131f42513f6b8df14a9bbc2e9ede5a560681184d41a147552"
"edfbdef98d95e6a7793229d25ba9b0b395a020aa1c0731de89e662246d59ec22e5d8f4b4"
"6fbc048efcffbc234744c5c66417070f9c751c81788f04691ccb1a09d60c46f6f73375bf"
"e2e646cf6290069541a8dfe216374c925e94d06ece72e851e81d3e8acd011f82526c2f9f"
"55955c6752dc10e93153ab58627e30fa2c573e4042954337982eec1f741be058c85bad86"
"bf3a02ed96d3201dadd48bd4de8105200dfcbcc400c3c3dd717abfc562ebe338b14b1eb5"
"ecbe9227661e49c58bf8233770d813faafc78b05711135adcc4ce4c65095ca0bdc1debc0"
"b6e5d195dbc582ce94b3afa14a422edf9b69abd7ae869a78c3a26fb50ef7122ec5af8d0c"
"78ef082ca114f8817c3d93b31809870caea2eb9533fa767c2954efb9ba07e4f1077e9f9b"
"be845661eabea2c91079321477a7c167c7234528d63d6aabbe723e0e337b2e61138a310a"
"3fd04368aa4215b7af9d0334a8a74681bcb86b4af87a0329a1ed9dc7c9aef14521785eda"
"0eeb97bdff8c9945fd0ee04e84d0dae091a69c0bfcdcd4150878fed839c0db6565fc1fed"
"0e7d6ae2efde7a59d58a9fb3b07e6f7cea51ba93f771c18b2eafa252d7fe171085776052"
"a6a17e6858f0a20b7e8be54413523989bf20a028a84d9ce98b78e6ee0b8362df49de5344"
"b409cc322354672a21ea383e870d047551a3af71aaf2f44f49a859cf001e61b592dd036f"
"c6625bf7b91ea0fb78c1563cceb8c4345bf4a9fbe6ee2b6bf5e81083",
   "8b6d59106f04300cb57c7c961945cd77f3536b0a",

   13976,
"162cca41155de90f6e4b76a34261be6666ef65bdb92b5831b47604ce42e0c6c8d2eda265"
"ab9a3716809bf2e745e7831a41768d0f6349a268d9ac6e6adfb832a5d51b75d7951cf60e"
"03d9e40de6d351f1f6ade5143531cf32839401ca6dfb9dc7473daa607aeb0c3d1e8eb3db"
"cc2f1231ad1dd394d7eac9d8dab726b895b1ee774fdcabc8031063ecfa41c71a9f03ad23"
"904cc056f17c76a1059c43faffe30dfd157fdfd7d792e162bf7a889109550a0fc4c41523"
"2af0c0d72dcbc2595299e1a1c2aeae549f7970e994c15e0ab02f113d740d38c32a4d8ec0"
"79cd099d37d954ab7ef2800902cdf7c7a19fb14b3c98aaf4c6ad93fe9a9bc7a61229828e"
"55ad4d6270d1bdbca9975d450f9be91e5699bd7ee22e8c9c22e355cf1f6793f3551cb510"
"c1d5cd363bdf8cab063e6e49a6383221f1188d64692c1f84c910a696de2e72fb9886193f"
"61ab6b41ad0ea894d37ff1261bf1fd1f187e0d0c38ab223d99ec6d6b1e6b079fc305e24e"
"2d9500c98676e2d587434495d6e107b193c06fb12d5d8eaa7b0c001d08f4d91cae5bdcae"
"6624ee755e95ca8e4c5ef5b903d7f5ba438abeffd6f16d82d88138f157e7a50d1c91fb50"
"c770f6d222fcbf6daf791b1f8379e3b157a3b496ddb2e71650c1c4ac4fc5f2aceb5b3228"
"ffc44e15c02d4baa9434e60928a93f21bc91cfd3c2719f53a8c9bcd2f2dee65a8bbc88f9"
"5d7ced211fc3b04f6e8b74eb2026d66fd57fa0cccea43f0a0381782e6fee5660afed674d"
"cb2c28cb54d2bdbbaf78e534b0742ede6b5e659b46cd516d5362a194dd0822f6417935c4"
"ff05815b118fe5687cd8b050240015cfe449d9dfde1f4fdb105586e429b2c1849aac2791"
"ef73bc54603190eba39037ec057e784bb92d497e705dfcde2addb3514b4f1926f12d5440"
"850935779019b23bd0f2977a8c9478c424a7eaaeec04f3743a77bee2bec3937412e707bc"
"92a070046e2f9c35fe5cc3f755bbb91a182e683591ab7e8cff40633730546e81522f588f"
"07bdf142b78e115d2a22d2eb5664fcdb7574c1ee5ba9abd307d7d29078cd5223c222fc69"
"60324c40cc639be84dad96b01059efce7b08538ebef89bafab834609c7e82774a14e5be6"
"62067edba6111efa8ae270f5066442b17e3f31a793581c8a3f96d92921ec26981594e28a"
"08987d020b97ad2ba5c662836e35fd3fd954bcec52b579528913959d0d942fbf1c4b9910"
"ba010c3700359a4eb7616541257f0f7727cc71b580cc903f718ecc408a315b6bbfa7f6e3"
"beb9d258804bd2731ee2fb75e763281baf1effc4690a23d5f952ab5d4311d4f5885af2eb"
"f27cad9f6d84692cb903064bbd11ca751f919b4811b7722c6ec80c360521e34d357b5c8b"
"ba6d42e5c632730f53add99ab8aa9c607b6796216753086ede158bc670d04900aca66ce8"
"357bd72d19fb147b5fde8ee4df6a0184573a2e65ba3fd3a0cb04dac5eb36d17d2f639a6e"
"b602645f3ab4da9de4c9999d6506e8e242a5a3216f9e79a4202558ecdc74249ad3caaf90"
"71b4e653338b48b3ba3e9daf1e51e49384268d63f37ce87c6335de79175cdf542d661bcd"
"74b8f5107d6ab492f54b7c3c31257ecb0b426b77ed2e2ed22bbfdaf49653e1d54e5988fa"
"d71397546f9955659f22b3a4117fc823a1e87d6fb6fb8ab7d302a1316975e8baf0c0adbd"
"35455655f6a596b6ac3be7c9a8ea34166119d5e70dfbc1aa6e14ff98eff95e94ef576656"
"5d368ec8857fb0b029bcb990d420a5ca6bc7ab08053eb4dbfc4612a345d56faefc5e03a4"
"43520b224de776a5b618e1aa16edc513d5fcefcd413031b0ddc958a6fca45d108fbde065"
"3cf2d11cb00a71cd35f57993875598b4e33e2384623a0986859105d511c717c21d6534bf"
"69fd3d7cf1682e4fc25298d90df951e77a316996beac61bb7078988118c906548af92cfe"
"72cd4b102ffad584e5e721a0cdb5621ed07dda8955d84bea57a5afa4ba06289ddfac3a9e"
"765538fd9392fc7904cedb65e38cd90967f01845ff819777a22d199f608e62c13e6ba98b"
"40824b38c784bdb41d62c4014fc7e8d93be52695e975e54d1ff92b412f451177143d74a6"
"bde0ee53a986043ab465a1ef315ac4c538e775ef4178fde5f2ea560a364de18b8fe9578a"
"ad80027c3fd32dcf0967d9d03789b1cdf19040762f626289cf3af8afe5a8e0a152d9258e"
"981872c1ec95cd7f8d65812e55cb5cbd8db61b3f068a23d9652372dfbf18d43a663c5a0d"
"026b0898e383ce5c95b0ba7fb5ed6b7304c7c9d3ba64f38d1dc579465148ccfa7271f2e3"
"e0e97e9ddac7c0874f0f396cf07851638a734df393687b7b0343afd1652ff32a2da17b3a"
"4c99d79c02256c73f32625527e5666594a8a42a12135eddb022e743371b3ab7b12ad6785"
"7635eed03558ac673d17280769b2368056276d5d72f5dbc75525f8a7558bd90b544aa6cb"
"dd964e6c70be79441969bfdf471f17a2dc0c92",
   "6144c4786145852e2a01b20604c369d1b9721019",

   14768,
"c9bed88d93806b89c2d028866842e6542ab88c895228c96c1f9f05125f8697c7402538b0"
"6465b7ae33daef847500f73d20c598c86e4804e633e1c4466e61f3ed1e9baadc5723bbed"
"9455a2ff4f99b852cfe6aa3442852ade0b18e4995ddab4250928165a9441de108d4a293d"
"1d95935de022aa17f366a31d4f4c4c54557a4235a9d56473444787ddc5c06c87087aef24"
"fa8280b7ac74d76ba685e4be7dc705e5a8a97c6c8fbd201ee5bf522438d23371c60c155d"
"93352f8fb8cc9421fe4b66ffabad46909c2c1099944fc55ed424c90aecca4f50d0331153"
"2e2844c3ff8ecb495de7ab26941cbf177b79ad7b05f918b713c417da8cf6e67db0a2dcee"
"a9179d8d636191759e13955f4244f0c4f2d88842e3015641ef0417d6e54144e8246e4591"
"6823e2c6e39bfa3b90b97781c44981710689f2ce20e70a26760d65f9971b291e12338461"
"8b3b56710dde2afaa2d46b0e2164d5c9482729350a0e256b2aa6b3fb099b618ebd7c11ca"
"62bdf176b502aedfdf9be57a8e4adbca4a4d6d8407984af2f6635f95a1e4930e375eb53f"
"245ab2ade5340c281bda87afded1268e537955c9819168bd60fd440533c75c9b1865e03f"
"de3a301d165f97aa6da236cf39cf3e49512f6350224f8d76ff02d0d3b9a99e5f70b23b9f"
"a85f72849fc98790df246c3a0f4437940e60d42b4317f72e2eb055d343a614f7f9648005"
"1e4dff186dff476462d9ced24dbb82eaa60cbbf6a0026e64001da36d30f529f48f3688b1"
"0ce9378ef3f50f5106e5007cd0eb037136254fda4f20d048769bd51a9d8d09a1e469a482"
"6aa0e25b6267b5a96abcb6e919a362fdd7b683d2f2dcec40ee5969311c07f6066ee22f36"
"89ca08381c85bea470040e9541e7a451cd43d62c2aa292a9dc4b95e3a7c4de2ba29663f3"
"8d5002eb64ceba6934bb1b0e2e55fba7fa706b514ebeeae1be4dd882d6512da066246a05"
"1d8bd042593bd0513e9cc47806ccdc7097e75bc75b8603834c85cd084e0ade3cc2c2b7e8"
"586eac62249f9769f5bdcd50e24e515f257548762db9adf3ee0846d67cfcd723d85d9588"
"09e6dd406f4c2637557c356fc52490a2a0763429ee298a1c72c098bb810e740c15faffc6"
"1e80cf6e18f86dc0e29bc150ce43ca71f5729356cd966277fd8b32366f6263c3a761b13d"
"544a631a25e1c4c8dea8d794abed47ccb4069d20f1dcb54e40a673ffb5f7b2eb31fb7d44"
"36fd8252f92dc35bb9a18fc55099b17e0807e79caf4f9641ee4bbbc2d6922508bcfae236"
"475bf78bc796548bc8d60659e816af68e5e43352fa64b5086c97c22c60ddcbbbefb9d9ef"
"7cd57c64454604793910f4f90aedb4fb824a86061a93bb79c9b0272a1ad0d24e8165f099"
"ef6f14a6a4fea09845f280022e061804090d7ab79f7bddcbef264b6f7d4e9971eddb9ca7"
"d0e79a8dbe7cff2fa59f514a608d66ae8c44d5e69745aa1b19995e366812064567d3ca20"
"9e12994c901d1b1f489be7253615f7c339b5581afd4d262e879ab8480ecb18990d3db61f"
"96895dcde9c065e645f52baafefcbe34d072dba373fd1c786fd56c3f3284be7260eaff9a"
"6a8348b762ed59e20ea443313b1164db53c3989c32fcae5b366f190b9548e8cff46df961"
"350369b490354ed8e530a91f5072967eff45c63540862fb2deab02b3ae05deac65414368"
"ac3549f277da92b692947de47cba9c1579526931e31c3490c1d3605f9bafcf468c2e9b47"
"981407ea40b0b59754621943095a2d4f4ba266ac545fe7447e54f69555a7ac9ff1e8f001"
"834fa65f2d4523061726e4d3bf4680519032dc21b7389e9f3229e4c2295d354482f8b803"
"b06ca3a8cb3ff786e60f6bc59dd3a5bfed63b0aa493bab78e97bbefb6633534d84de826f"
"4e2ccc3069050d50a2caace6c9de15ffc2656988d94b736e5688df0351a3a6a4c875cd99"
"ef304f3cc7a0585df2b0b3e6c62f86bba0d43de47b80c4eec1c4f98e60a36188219919cf"
"36dc10ee11e174a67d226ad9e71f02a7fca26ad67a4862773f3defc6a747545314063e5f"
"ce7a3f890ec57daa5532acfd027739832437c8a58dcbe11c2842e60e8ca64979d081fbd5"
"a1a028f59317212fb5869abc689a156171d69e4f4c93b949c3459904c00192d3603cd184"
"48d64b843c57f34aee7830f313e58e2abc41b44be46a96c845ffebcb7120e21d1d751046"
"c072adf65dd901a39c8019742054be5e159ea88d0885ee05fcd4c189bafe5abb68603186"
"5dc570b9342fa7f41fd5c1c87e68371ab19a83c82ae1d890c678102d5da8e6c29845657c"
"027ba07362cba4d24950ab38e747925e22ce8df9eaec1ae2c6d23374b360c8352feb6cb9"
"913e4fc49bde6caf5293030d0d234a8ecd616023cc668262591f812de208738e5336a9e6"
"9f9be2479b86be1e1369761518dfc93797ed3a55308878a944581eba50bc9c7f7a0e75c7"
"6a28acd95b277857726f3f684eefc215e0a696f47d65d30431d710d957c08ef96682b385"
"0ee5ba1c8417aafc1af2846a127ec155b4b7fb369e90eb3a5c3793a3389bbc6b532ca32b"
"f5e1f03c2280e71c6e1ae21312d4ff163eee16ebb1fdee8e887bb0d453829b4e6ed5fa70"
"8f2053f29b81e277be46",
   "a757ead499a6ec3d8ab9814f839117354ae563c8"
};

void test_sha1(void)
{
   unsigned char buffer[4000];
   int i;
   for (i=0; i < sizeof(sha1_tests) / sizeof(sha1_tests[0]); ++i) {
      stb_uint len = sha1_tests[i].length / 8;
      unsigned char digest[20], fdig[20];
      unsigned int h;
      assert(len <= sizeof(buffer));
      assert(strlen(sha1_tests[i].message) == len*2);
      assert(strlen(sha1_tests[i].digest) == 20 * 2);
      for (h=0; h < len; ++h) {
         char v[3];
         v[0] = sha1_tests[i].message[h*2];
         v[1] = sha1_tests[i].message[h*2+1];
         v[2] = 0;
         buffer[h] = (unsigned char) strtol(v, NULL, 16);
      }
      stb_sha1(digest, buffer, len);
      for (h=0; h < 20; ++h) {
         char v[3];
         int res;
         v[0] = sha1_tests[i].digest[h*2];
         v[1] = sha1_tests[i].digest[h*2+1];
         v[2] = 0;
         res = digest[h] == strtol(v, NULL, 16);
         c(res, sha1_tests[i].digest);
         if (!res)
            break;
      }
      {
         int z;
         FILE *f = fopen("data/test.bin", "wb");
         if (!f) stb_fatal("Couldn't write to test.bin");
         fwrite(buffer, len, 1, f);
         fclose(f);
         #ifdef _WIN32
         z = stb_sha1_file(fdig, "data/test.bin");
         if (!z) stb_fatal("Couldn't digest test.bin");
         c(memcmp(digest, fdig, 20)==0, "stb_sh1_file");
         #endif
      }
   }
}


#if 0

stb__obj zero, one;

void test_packed_floats(void)
{
   stb__obj *p;
   float x,y,*q;
   clock_t a,b,c;
   int i;
   stb_float_init();
   for (i=-10; i < 10; ++i) {
      float f = (float) pow(10,i);
      float g = f * 10;
      float delta = (g - f) / 10000;
      while (f < g) {
         stb__obj z = stb_float(f);
         float k = stb_getfloat(z);
         float p = stb_getfloat_table(z);
         assert((z & 1) == 1);
         assert(f == k);
         assert(k == p);
         f += delta;
      }
   }

   zero = stb_float(0);
   one  = stb_float(1);

   p = malloc(8192 * 4);
   for (i=0; i < 8192; ++i)
      p[i] = stb_rand();
   for (i=0; i < 8192; ++i)
      if ((stb_rand() & 31) < 28)
         p[i] = zero;

   q = malloc(4 * 1024);
      
   a = clock();

   x = y = 0;
   for (i=0; i < 200000000; ++i)
      q[i&1023] = stb_getfloat_table(p[i&8191]);
   b = clock();
   for (i=0; i < 200000000; ++i)
      q[i&1023] = stb_getfloat_table2(p[i&8191]);
   c = clock();
   free(p);

   free(q);

   printf("Table: %d\nIFs: %d\n", b-a, c-b);
}
#endif


void do_compressor(int argc,char**argv)
{
   char *p;
   int len;

   int window;
   if (argc == 2) {
      p = stb_file(argv[1], &len);
      if (p) {
         int dlen, clen = stb_compress_tofile("data/dummy.bin", p, len);
         char *q = stb_decompress_fromfile("data/dummy.bin", &dlen);

         if (len != dlen) {
            printf("FAILED %d -> %d\n", len, clen);
         } else {
            int z = memcmp(q,p,dlen);
            if (z != 0) 
               printf("FAILED %d -> %d\n", len, clen);
            else
               printf("%d -> %d\n", len, clen);
         }
      }
      return;
   }

   window = atoi(argv[1]);
   if (window && argc == 4) {
      p = stb_file(argv[3], &len);
      if (p) {
         stb_compress_hashsize(window);
         stb_compress_tofile(argv[2], p, len);
      }
   } else if (argc == 3) {
      p = stb_decompress_fromfile(argv[2], &len);
      if (p) {
         FILE *f = fopen(argv[1], "wb");
         fwrite(p,1,len,f);
         fclose(f);
      } else {
         fprintf(stderr, "FAILED.\n");
      }
   } else {
      fprintf(stderr, "Usage: stb <hashsize> <output> <filetocompress>\n"
                      "   or  stb            <output> <filetodecompress>\n");
   }
}

#if 0
// naive backtracking implementation
int wildmatch(char *expr, char *candidate)
{
   while(*expr) {
      if (*expr == '?') {
         if (!*candidate) return 0;
         ++candidate;
         ++expr;
      } else if (*expr == '*') {
         ++expr;
         while (*expr == '*' || *expr =='?') ++expr;
         // '*' at end of expression matches anything
         if (!*expr) return 1;
         // now scan candidate 'til first match
         while (*candidate) {
            if (*candidate == *expr) {
               // check this candidate
               if (stb_wildmatch(expr+1, candidate+1))
                  return 1;
               // if not, then backtrack
            }
            ++candidate;
         }
      } else {
         if (*expr != *candidate)
            return 0;
         ++expr, ++candidate;
      }
   }
   return *candidate != 0;
}

int stb_matcher_find_slow(stb_matcher *m, char *str)
{
   int result = 1;
   int i,j,y,z;
   uint16 *previous = NULL;
   uint16 *current = NULL;
   uint16 *temp;

   stb_arr_setsize(previous, 4);
   stb_arr_setsize(current, 4);

   previous = stb__add_if_inactive(m, previous, m->start_node);
   previous = stb__eps_closure(m,previous);
   if (stb__clear_goalcheck(m, previous))
      goto done;

   while (*str) {
      y = stb_arr_len(previous);
      for (i=0; i < y; ++i) {
         stb_nfa_node *n = &m->nodes[previous[i]];
         z = stb_arr_len(n->out);
         for (j=0; j < z; ++j) {
            if (n->out[j].match == *str)
               current = stb__add_if_inactive(m, current, n->out[j].node);
            else if (n->out[j].match == -1) {
               if (*str != '\n')
                  current = stb__add_if_inactive(m, current, n->out[j].node);
            } else if (n->out[j].match < -1) {
               int z = -n->out[j].match - 2;
               if (m->charset[(uint8) *str] & (1 << z))
                  current = stb__add_if_inactive(m, current, n->out[j].node);
            }
         }
      }
      ++str;
      stb_arr_setlen(previous, 0);

      temp = previous;
      previous = current;
      current = temp;

      if (!m->match_start)
         previous = stb__add_if_inactive(m, previous, m->start_node);
      previous = stb__eps_closure(m,previous);
      if (stb__clear_goalcheck(m, previous))
         goto done;
   }

   result=0;

done:
   stb_arr_free(previous);
   stb_arr_free(current);

   return result;
}
#endif






//////////////////////////////////////////////////////////////////////////
//
//   stb_parser
//
//   Generates an LR(1) parser from a grammar, and can parse with it



// Symbol representations
//
// Client:     Internal:
//    -           c=0     e aka epsilon
//    -           c=1     $ aka end of string
//   > 0        2<=c<M    terminals (note these are remapped from a sparse layout)
//   < 0        M<=c<N    non-terminals

#define END 1
#define EPS 0

short encode_term[4096];  // @TODO: malloc these
short encode_nonterm[4096];
int first_nonterm, num_symbols, symset;
#define encode_term(x)     encode_term[x]
#define encode_nonterm(x)  encode_nonterm[~(x)]
#define encode_symbol(x)   ((x) >= 0 ? encode_term(x) : encode_nonterm(x))

stb_bitset **compute_first(short ** productions)
{
   int i, changed;
   stb_bitset **first = malloc(sizeof(*first) * num_symbols);

   assert(symset);
   for (i=0; i < num_symbols; ++i)
      first[i] = stb_bitset_new(0, symset);

   for (i=END; i < first_nonterm; ++i)
      stb_bitset_setbit(first[i], i);

   for (i=0; i < stb_arr_len(productions); ++i) {
      if (productions[i][2] == 0) {
         int nt = encode_nonterm(productions[i][0]);
         stb_bitset_setbit(first[nt], EPS);
      }
   }

   do {
      changed = 0;
      for (i=0; i < stb_arr_len(productions); ++i) {
         int j, nt = encode_nonterm(productions[i][0]);
         for (j=2; productions[i][j]; ++j) {
            int z = encode_symbol(productions[i][j]);
            changed |= stb_bitset_unioneq_changed(first[nt], first[z], symset);
            if (!stb_bitset_testbit(first[z], EPS))
               break;
         }
         if (!productions[i][j] && !stb_bitset_testbit(first[nt], EPS)) {
            stb_bitset_setbit(first[nt], EPS);
            changed = 1;
         }
      }
   } while (changed);
   return first;
}

stb_bitset **compute_follow(short ** productions, stb_bitset **first, int start)
{
   int i,j,changed;
   stb_bitset **follow = malloc(sizeof(*follow) * num_symbols);

   assert(symset);
   for (i=0; i < num_symbols; ++i)
      follow[i] = (i >= first_nonterm ? stb_bitset_new(0, symset) : NULL);

   stb_bitset_setbit(follow[start], END);
   do {
      changed = 0;
      for (i=0; i < stb_arr_len(productions); ++i) {
         int nt = encode_nonterm(productions[i][0]);
         for (j=2; productions[i][j]; ++j) {
            if (productions[i][j] < 0) {
               int k,z = encode_nonterm(productions[i][j]);
               for (k=j+1; productions[i][k]; ++k) {
                  int q = encode_symbol(productions[i][k]);
                  changed |= stb_bitset_unioneq_changed(follow[z], first[q], symset);
                  if (!stb_bitset_testbit(first[q], EPS))
                     break;
               }
               if (!productions[i][k] == 0)
                  changed |= stb_bitset_unioneq_changed(follow[z], follow[nt], symset);
            }
         }
      }
   } while (changed);

   for (i=first_nonterm; i < num_symbols; ++i)
      stb_bitset_clearbit(follow[i], EPS);

   return follow;
}

void first_for_prod_plus_sym(stb_bitset **first, stb_bitset *out, short *prod, int symbol)
{
   stb_bitset_clearall(out, symset);
   for(;*prod;++prod) {
      int z = encode_symbol(*prod);
      stb_bitset_unioneq_changed(out, first[z], symset);
      if (!stb_bitset_testbit(first[z], EPS))
         return;
   }
   stb_bitset_unioneq_changed(out, first[symbol], symset);
}

#define Item(p,c,t)       ((void *) (((t) << 18) + ((c) << 12) + ((p) << 2)))
#define ItemProd(i)       ((((uint32) (i)) >> 2) & 1023)
#define ItemCursor(i)     ((((uint32) (i)) >> 12) & 63)
#define ItemLookahead(i)  (((uint32) (i)) >> 18)

static void pc(stb_ps *p)
{
}

typedef struct
{
   short *prod;
   int prod_num;
} ProdRef;

typedef struct
{
   stb_bitset **first;
   stb_bitset **follow;
   short **   prod;
   ProdRef ** prod_by_nt;
} Grammar;

stb_ps *itemset_closure(Grammar g, stb_ps *set)
{
   stb_bitset *lookahead;
   int changed,i,j,k, list_len;
   if (set == NULL) return set;
   lookahead = stb_bitset_new(0, symset);
   do {
      void **list = stb_ps_getlist(set, &list_len);
      changed = 0;
      for (i=0; i < list_len; ++i) {
         ProdRef *prod;
         int nt, *looklist;
         int p = ItemProd(list[i]), c = ItemCursor(list[i]), t = ItemLookahead(list[i]);
         if (g.prod[p][c] >= 0) continue;
         nt = encode_nonterm(g.prod[p][c]);
         first_for_prod_plus_sym(g.first, lookahead, g.prod[p]+c+1, t);
         looklist = stb_bitset_getlist(lookahead, 1, first_nonterm);
               
         prod = g.prod_by_nt[nt];
         for (j=0; j < stb_arr_len(prod); ++j) {
            assert(prod[j].prod[0] == g.prod[p][c]);
            // matched production; now iterate terminals
            for (k=0; k < stb_arr_len(looklist); ++k) {
               void *item = Item(prod[j].prod_num,2,looklist[k]);
               if (!stb_ps_find(set, item)) {
                  changed = 1;
                  set = stb_ps_add(set, item);
                  pc(set);
               }
            }
         }
         stb_arr_free(looklist);
      }
      free(list);
   } while (changed);
   free(lookahead);
   return set;
}

stb_ps *itemset_goto(Grammar g, stb_ps *set, int sym)
{
   int i, listlen;
   void **list = stb_ps_fastlist(set, &listlen);
   stb_ps *out = NULL;
   for (i=0; i < listlen; ++i) {
      int p,c;
      if (!stb_ps_fastlist_valid(list[i])) continue;
      p = ItemProd(list[i]), c = ItemCursor(list[i]);
      if (encode_symbol(g.prod[p][c]) == sym) {
         void *z = Item(p,c+1,ItemLookahead(list[i]));
         if (!stb_ps_find(out, z))
            out = stb_ps_add(out, z);
         pc(out);
      }
   }
   return itemset_closure(g, out);
}

void itemset_all_nextsym(Grammar g, stb_bitset *out, stb_ps *set)
{
   int i, listlen;
   void **list = stb_ps_fastlist(set, &listlen);
   stb_bitset_clearall(out, symset);
   pc(set);
   for (i=0; i < listlen; ++i) {
      if (stb_ps_fastlist_valid(list[i])) {
         int p = ItemProd(list[i]);
         int c = ItemCursor(list[i]);
         if (g.prod[p][c])
            stb_bitset_setbit(out, encode_symbol(g.prod[p][c]));
      }
   }
}

stb_ps ** generate_items(Grammar g, int start_prod)
{
   stb_ps ** all=NULL;
   int i,j,k;
   stb_bitset *try = stb_bitset_new(0,symset);
   stb_ps *set = NULL;
   void *item = Item(start_prod, 2, END);
   set = stb_ps_add(set, item);
   pc(set);
   set = itemset_closure(g, set);
   pc(set);
   stb_arr_push(all, set);
   for (i = 0; i < stb_arr_len(all); ++i) {
      // only try symbols that appear in all[i]... there's a smarter way to do this,
      // which is to take all[i], and divide it up by symbol
      pc(all[i]);
      itemset_all_nextsym(g, try, all[i]);
      for (j = 1; j < num_symbols; ++j) {
         if (stb_bitset_testbit(try, j)) {
            stb_ps *out;
            if (stb_arr_len(all) > 4) pc(all[4]);
            if (i == 1 && j == 29) {
               if (stb_arr_len(all) > 4) pc(all[4]);
               out = itemset_goto(g, all[i], j);
               if (stb_arr_len(all) > 4) pc(all[4]);
            } else
               out = itemset_goto(g, all[i], j);
            pc(out);
            if (stb_arr_len(all) > 4) pc(all[4]);
            if (out != NULL) {
               // add it to the array if it's not already there
               for (k=0; k < stb_arr_len(all); ++k)
                  if (stb_ps_eq(all[k], out))
                     break;
               if (k == stb_arr_len(all)) {
                  stb_arr_push(all, out);
                  pc(out);
                  if (stb_arr_len(all) > 4) pc(all[4]);
               } else
                  stb_ps_delete(out);
            }
         }
      }
   }
   free(try);
   return all;
}

typedef struct
{
   int num_stack;
   int function;
} Reduction;

typedef struct
{
   short *encode_term;
   Reduction *reductions;
   short **action_goto; // terminals are action, nonterminals are goto
   int start;
   int end_term;
} Parser;

enum
{
   A_error, A_accept, A_shift, A_reduce, A_conflict
};

typedef struct
{
   uint8 type;
   uint8 cursor;
   short prod;
   short value;
} Action;

Parser *parser_create(short **productions, int num_prod, int start_nt, int end_term)
{
   short *mini_rule = malloc(4 * sizeof(mini_rule[0]));
   Action *actions;
   Grammar g;
   stb_ps ** sets;
   Parser *p = malloc(sizeof(*p));
   int i,j,n;
   stb_bitset *mapped;
   int min_s=0, max_s=0, termset, ntset, num_states, num_reductions, init_prod;

   int synth_start;

   // remap sparse terminals and nonterminals

   for (i=0; i < num_prod; ++i) {
      for (j=2; productions[i][j]; ++j) {
         if (productions[i][j] < min_s) min_s = productions[i][j];
         if (productions[i][j] > max_s) max_s = productions[i][j];
      }
   }
   synth_start = --min_s;

   termset = (max_s + 32) >> 5;
   ntset = (~min_s + 32) >> 5;
   memset(encode_term, 0, sizeof(encode_term));
   memset(encode_nonterm, 0, sizeof(encode_nonterm));

   mapped = stb_bitset_new(0, termset);
   n = 2;
   for (i=0; i < num_prod; ++i)
      for (j=2; productions[i][j]; ++j)
         if (productions[i][j] > 0)
            if (!stb_bitset_testbit(mapped, productions[i][j])) {
               stb_bitset_setbit(mapped, productions[i][j]);
               encode_term[productions[i][j]] = n++;
            }
   free(mapped);

   first_nonterm = n;

   mapped = stb_bitset_new(0, ntset);
   for (i=0; i < num_prod; ++i)
      for (j=2; productions[i][j]; ++j)
         if (productions[i][j] < 0)
            if (!stb_bitset_testbit(mapped, ~productions[i][j])) {
               stb_bitset_setbit(mapped, ~productions[i][j]);
               encode_nonterm[~productions[i][j]] = n++;
            }
   free(mapped);

   // add a special start state for internal processing
   p->start = n++;
   encode_nonterm[synth_start] = p->start;
   mini_rule[0] = synth_start;
   mini_rule[1] = -32768;
   mini_rule[2] = start_nt;
   mini_rule[3] = 0;

   p->end_term = end_term;

   num_symbols = n;
   
   // create tables
   g.prod = NULL;
   g.prod_by_nt = malloc(num_symbols * sizeof(g.prod_by_nt[0]));
   for (i=0; i < num_symbols; ++i)
      g.prod_by_nt[i] = NULL;

   for (i=0; i < num_prod; ++i) {
      stb_arr_push(g.prod, productions[i]);
   }
   init_prod = stb_arr_len(g.prod);
   stb_arr_push(g.prod, mini_rule);

   num_reductions = stb_arr_len(g.prod);
   p->reductions = malloc(num_reductions * sizeof(*p->reductions));

   symset = (num_symbols + 31) >> 5;
   g.first = compute_first(g.prod);
   g.follow = compute_follow(g.prod, g.first, p->start);

   for (i=0; i < stb_arr_len(g.prod); ++i) {
      ProdRef pr = { g.prod[i], i };
      stb_arr_push(g.prod_by_nt[encode_nonterm(g.prod[i][0])], pr);
   }

   sets = generate_items(g, init_prod);

   num_states = stb_arr_len(sets);
   // now generate tables

   actions = malloc(sizeof(*actions) * first_nonterm);
   p->action_goto = (short **) stb_array_block_alloc(num_states, sizeof(short) * num_symbols);
   for (i=0; i < num_states; ++i) {
      int j,n;
      void **list = stb_ps_getlist(sets[i], &n);
      memset(actions, 0, sizeof(*actions) * first_nonterm);
      for (j=0; j < n; ++j) {
         int p = ItemProd(list[j]), c = ItemCursor(list[j]), t = ItemLookahead(list[j]);
         if (g.prod[p][c] == 0) {
            if (p == init_prod) {
               // @TODO: check for conflicts
               assert(actions[t].type == A_error || actions[t].type == A_accept);
               actions[t].type = A_accept;
            } else {
               // reduce production p
               if (actions[t].type == A_reduce) {
                  // is it the same reduction we already have?
                  if (actions[t].prod != p) {
                     // no, it's a reduce-reduce conflict!
                     printf("Reduce-reduce conflict for rule %d and %d, lookahead %d\n", p, actions[t].prod, t);
                     // @TODO: use precedence
                     actions[t].type = A_conflict;
                  }
               } else if (actions[t].type == A_shift) {
                  printf("Shift-reduce conflict for rule %d and %d, lookahead %d\n", actions[t].prod, p, t);
                  actions[t].type = A_conflict;
               } else if (actions[t].type == A_accept) {
                  assert(0);
               } else if (actions[t].type == A_error) {
                  actions[t].type = A_reduce;
                  actions[t].prod = p;
               }
            }
         } else if (g.prod[p][c] > 0) {
            int a = encode_symbol(g.prod[p][c]), k;
            stb_ps *out = itemset_goto(g, sets[i], a);
            for (k=0; k < stb_arr_len(sets); ++k)
               if (stb_ps_eq(sets[k], out))
                  break;
            assert(k < stb_arr_len(sets));
            // shift k
            if (actions[a].type == A_shift) {
               if (actions[a].value != k) {
                  printf("Shift-shift conflict! Rule %d and %d with lookahead %d/%d\n", actions[a].prod, p, a,t);
                  actions[a].type = A_conflict;
               }
            } else if (actions[a].type == A_reduce) {
               printf("Shift-reduce conflict for rule %d and %d, lookahead %d/%d\n", p, actions[a].prod, a,t);
               actions[a].type = A_conflict;
            } else if (actions[a].type == A_accept) {
               assert(0);
            } else if (actions[a].type == A_error) {
               actions[a].type = A_shift;
               actions[a].prod = p;
               actions[a].cursor = c;
               actions[a].value  = k;
            }
         }
      }
      // @TODO: recompile actions into p->action_goto
   }

   free(mini_rule);
   stb_pointer_array_free(g.first , num_symbols); free(g.first );
   stb_pointer_array_free(g.follow, num_symbols); free(g.follow);
   stb_arr_free(g.prod);
   for (i=0; i < num_symbols; ++i)
      stb_arr_free(g.prod_by_nt[i]);
   free(g.prod_by_nt);
   for (i=0; i < stb_arr_len(sets); ++i)
      stb_ps_delete(sets[i]);
   stb_arr_free(sets);

   return p;
}

void parser_destroy(Parser *p)
{
   free(p);
}

#if 0
enum nonterm
{
   N_globals = -50,
   N_global, N_vardef, N_varinitlist, N_varinit, N_funcdef, N_optid, N_optparamlist,
   N_paramlist, N_param, N_optinit, N_optcomma, N_statements, N_statement,
   N_optexpr, N_assign, N_if, N_ifcore, N_else, N_dictdef, N_dictdef2,
   N_dictdefitem, N_expr,
   N__last
};

short grammar[][10] =
{
   { N_globals    ,  0, N_globals, N_global                                 },
   { N_globals    ,  0                                                      },
   { N_global     ,  0, N_vardef                                            },
   { N_global     ,  0, N_funcdef                                           },
   { N_vardef     ,  0, ST_var, N_varinitlist,                               },
   { N_varinitlist,  0, N_varinitlist, ',', N_varinit                       },
   { N_varinitlist,  0, N_varinit,                                          },
   { N_varinit    ,  0, ST_id, N_optinit,                                    },
   { N_funcdef    ,  0, ST_func, N_optid, '(', N_optparamlist, ')', N_statements, ST_end },
   { N_optid      ,  0, ST_id                                                },
   { N_optid      ,  0,                                                     },
   { N_optparamlist, 0,                                                     },
   { N_optparamlist, 0, N_paramlist, N_optcomma                             },
   { N_paramlist  ,  0, N_paramlist, ',', N_param                           },
   { N_paramlist  ,  0, N_param                                             },
   { N_param      ,  0, ST_id, N_optinit                                     },
   { N_optinit    ,  0, '=', N_expr                                         },
   { N_optinit    ,  0,                                                     },
   { N_optcomma   ,  0, ','                                                 },
   { N_optcomma   ,  0,                                                     },
   { N_statements ,  0, N_statements, N_statement                           },
   { N_statement  ,  0, N_statement, ';'                                    },
   { N_statement  ,  0, N_varinit                                           },
   { N_statement  ,  0, ST_return, N_expr                                    },
   { N_statement  ,  0, ST_break , N_optexpr                                 },
   { N_optexpr    ,  0, N_expr                                              },
   { N_optexpr    ,  0,                                                     },
   { N_statement  ,  0, ST_continue                                          },
   { N_statement  ,  0, N_assign                                            },
   { N_assign     ,  0, N_expr, '=', N_assign                               },
   //{ N_assign     ,  0, N_expr                                              },
   { N_statement  ,  0, ST_while, N_expr, N_statements, ST_end                },
   { N_statement  ,  0, ST_if, N_if,                                         },
   { N_if         ,  0, N_ifcore, ST_end,                                    },
   { N_ifcore     ,  0, N_expr, ST_then, N_statements, N_else, ST_end         },
   { N_else       ,  0, ST_elseif, N_ifcore                                  },
   { N_else       ,  0, ST_else, N_statements                                },
   { N_else       ,  0,                                                     },
   { N_dictdef    ,  0, N_dictdef2, N_optcomma                              },
   { N_dictdef2   ,  0, N_dictdef2, ',', N_dictdefitem                      },
   { N_dictdef2   ,  0, N_dictdefitem                                       },
   { N_dictdefitem,  0, ST_id, '=', N_expr                                   },
   { N_dictdefitem,  0, N_expr                                              },
   { N_expr       ,  0, ST_number                                            },
   { N_expr       ,  0, ST_string                                            },
   { N_expr       ,  0, ST_id                                                },
   { N_expr       ,  0, N_funcdef                                           },
   { N_expr       ,  0, '-', N_expr                                         },
   { N_expr       ,  0, '{', N_dictdef, '}'                                 },
   { N_expr       ,  0, '(', N_expr, ')'                                    },
   { N_expr       ,  0, N_expr, '.', ST_id                                   },
   { N_expr       ,  0, N_expr, '[', N_expr, ']'                            },
   { N_expr       ,  0, N_expr, '(', N_dictdef, ')'                         },
#if 0
#define BINOP(op)  { N_expr, 0, N_expr, op, N_expr }
   BINOP(ST_and), BINOP(ST_or), BINOP(ST_eq), BINOP(ST_ne),
   BINOP(ST_le),  BINOP(ST_ge), BINOP('>') , BINOP('<' ),
   BINOP('&'), BINOP('|'), BINOP('^'), BINOP('+'), BINOP('-'),
   BINOP('*'), BINOP('/'), BINOP('%'),
#undef BINOP
#endif
};

short *grammar_list[stb_arrcount(grammar)];

void test_parser_generator(void)
{
   Parser *p;
   int i;
   assert(N__last <= 0);
   for (i=0; i < stb_arrcount(grammar); ++i)
      grammar_list[i] = grammar[i];
   p = parser_create(grammar_list, stb_arrcount(grammar), N_globals, 0);
   parser_destroy(p);
}
#endif


#if 0
// stb_threadtest.c


#include <windows.h>
#define STB_DEFINE
//#define STB_THREAD_TEST
#include "../stb.h"

#define NUM_WORK 100

void *work_consumer(void *p)
{
   stb__thread_sleep(20);
   return NULL;
}

int pass;
stb_threadqueue *tq1, *tq2, *tq3, *tq4;
volatile float t1,t2;

//    with windows.h
// Worked correctly with 100,000,000 enqueue/dequeue WAITLESS
// (770 passes, 170000 per pass)
// Worked correctly with   2,500,000 enqueue/dequeue !WAITLESS
// (15 passes, 170000 per pass)
// Worked correctly with   1,500,000 enqueue/dequeue WAITLESS && STB_THREAD_TEST
// (9 passes, 170000 per pass)
//    without windows.h
// Worked correctly with   1,000,000 enqueue/dequeue WAITLESS && STB_THREAD_TEST
// (6 passes, 170000 per pass)
// Worked correctly with     500,000 enqueue/dequeue !WAITLESS && STB_THREAD_TEST
// (3 passes, 170000 per pass)
// Worked correctly with   1,000,000 enqueue/dequeue WAITLESS
// (15 passes, 170000 per pass)
#define WAITLESS

volatile int table[1000*1000*10];

void wait(int n)
{
#ifndef WAITLESS
   int j;
   float y;
   for (j=0; j < n; ++j)
      y += 1 / (t1+j);
   t2 = y;
#endif
}

void *tq1_consumer(void *p)
{
   for(;;) {
      int z;
      float y = 0;
      stb_threadq_get_block(tq1, &z);
      wait(5000);
      table[z] = pass;
   }
}

void *tq2_consumer(void *p)
{
   for(;;) {
      int z;
      if (stb_threadq_get(tq2, &z))
         table[z] = pass;
      wait(1000);
   }
}

void *tq3_consumer(void *p)
{
   for(;;) {
      int z;
      stb_threadq_get_block(tq3, &z);
      table[z] = pass;
      wait(500);
   }
}

void *tq4_consumer(void *p)
{
   for (;;) {
      int z;
      stb_threadq_get_block(tq4, &z);
      table[z] = pass;
      wait(500);
   }
}

typedef struct
{
   int start, end;
   stb_threadqueue *tq;
   int delay;
} write_data;

void *writer(void *q)
{
   int i;
   write_data *p = (write_data *) q;
   for (i=p->start; i < p->end; ++i) {
      stb_threadq_add_block(p->tq, &i);
      #ifndef WAITLESS
      if (p->delay) stb__thread_sleep(p->delay);
      else {
         int j;
         float z = 0;
         for (j=0; j <= 20; ++j)
            z += 1 / (t1+j);
         t2 = z;
      }
      #endif
   }
   return NULL;
}

write_data info[256];
int pos;

void start_writer(int z, int count, stb_threadqueue *tq, int delay)
{
   info[z].start = pos;
   info[z].end = pos+count;
   info[z].tq = tq;
   info[z].delay = delay;
   stb_create_thread(writer, &info[z]);
   pos += count;
}

int main(int argc, char **argv)
{
   int i;
   stb_sync s = stb_sync_new();
   stb_sync_set_target(s, NUM_WORK+1);
   stb_work_numthreads(2);
   for (i=0; i < NUM_WORK; ++i) {
      stb_work_reach(work_consumer, NULL, NULL, s);
   }
   printf("Started stb_work test.\n");

   t1 = 1;

   // create the queues
   tq1 = stb_threadq_new(4, 4, TRUE , TRUE);
   tq2 = stb_threadq_new(4, 4, TRUE , FALSE);
   tq3 = stb_threadq_new(4, 4, FALSE, TRUE);
   tq4 = stb_threadq_new(4, 4, FALSE, FALSE);

   // start the consumers
   stb_create_thread(tq1_consumer, NULL);
   stb_create_thread(tq1_consumer, NULL);
   stb_create_thread(tq1_consumer, NULL);

   stb_create_thread(tq2_consumer, NULL);

   stb_create_thread(tq3_consumer, NULL);
   stb_create_thread(tq3_consumer, NULL);
   stb_create_thread(tq3_consumer, NULL);
   stb_create_thread(tq3_consumer, NULL);
   stb_create_thread(tq3_consumer, NULL);
   stb_create_thread(tq3_consumer, NULL);
   stb_create_thread(tq3_consumer, NULL);

   stb_create_thread(tq4_consumer, NULL);

   for (pass=1; pass <= 5000; ++pass) {
      int z = 0;
      int last_n = -1;
      int identical = 0;
      pos = 0;
      start_writer(z++, 50000, tq1, 0);
      start_writer(z++, 50000, tq1, 0);
      start_writer(z++, 50000, tq1, 0);

      start_writer(z++, 5000, tq2, 1);
      start_writer(z++, 3000, tq2, 3);
      start_writer(z++, 2000, tq2, 5);

      start_writer(z++, 5000, tq3, 3);

      start_writer(z++, 5000, tq4, 3);
      #ifndef WAITLESS
      stb__thread_sleep(8000);
      #endif
      for(;;) {
         int n =0;
         for (i=0; i < pos; ++i) {
            if (table[i] == pass)
               ++n;
         }
         if (n == pos) break;
         if (n == last_n) {
            ++identical;
            if (identical == 3) {
               printf("Problem slots:\n");
               for (i=0; i < pos; ++i) {
                  if (table[i] != pass) printf("%d ", i);
               }
               printf("\n");
            } else {
               if (identical < 3)
                  printf("Processed %d of %d\n", n, pos);
               else
                  printf(".");
            }
         } else {
            identical = 0;
            printf("Processed %d of %d\n", n, pos);
         }
         last_n = n;
         #ifdef WAITLESS
         stb__thread_sleep(750);
         #else
         stb__thread_sleep(3000);
         #endif
      }
      printf("Finished pass %d\n", pass);
   }

   stb_sync_reach_and_wait(s);
   printf("stb_work test completed ok.\n");
   return 0;
}
#endif


#if 0
//////////////////////////////////////////////////////////////////////////////
//
//   collapse tree leaves up to parents until we only have N nodes
//   useful for cmirror summaries

typedef struct stb_summary_tree
{
   struct stb_summary_tree **children;
   int num_children;
   float weight;
} stb_summary_tree;

STB_EXTERN void *stb_summarize_tree(void *tree, int limit, float reweight);

#ifdef STB_DEFINE

typedef struct stb_summary_tree2
{
   STB__ARR(struct stb_summary_tree2 *) children;
   int num_children;
   float weight;
   float weight_with_all_children;
   float makes_target_weight;
   float weight_at_target;
   stb_summary_tree *original;
   struct stb_summary_tree2 *target;
   STB__ARR(struct stb_summary_tree2 *) targeters;
} stb_summary_tree2;

static stb_summary_tree2 *stb__summarize_clone(stb_summary_tree *t)
{
   int i;
   stb_summary_tree2 *s;
   s = (stb_summary_tree2 *) malloc(sizeof(*s));
   s->original = t;
   s->weight = t->weight;
   s->weight_with_all_children = 0;
   s->weight_at_target = 0;
   s->target = NULL;
   s->targeters = NULL;
   s->num_children = t->num_children;
   s->children = NULL;
   for (i=0; i < s->num_children; ++i)
      stb_arr_push(s->children, stb__summarize_clone(t->children[i]));
   return s;
}

static float stb__summarize_compute_targets(stb_summary_tree2 *parent, stb_summary_tree2 *node, float reweight, float weight)
{
   float total = 0;
   if (node->weight == 0 && node->num_children == 1 && parent) {
      node->target = parent;
      return stb__summarize_compute_targets(parent, node->children[0], reweight, weight*reweight);
   } else {
      float total=0;
      int i;
      for (i=0; i < node->num_children; ++i)
         total += stb__summarize_compute_targets(node, node->children[i], reweight, reweight);
      node->weight_with_all_children = total + node->weight;
      if (parent && node->weight_with_all_children) {
         node->target = parent;
         node->weight_at_target = node->weight_with_all_children * weight;
         node->makes_target_weight = node->weight_at_target + parent->weight;
         stb_arr_push(parent->targeters, node);
      } else {
         node->target = NULL;
         node->weight_at_target = node->weight;
         node->makes_target_weight = 0;
      }
      return node->weight_with_all_children * weight;
   }      
}

static stb_summary_tree2 ** stb__summarize_make_array(STB__ARR(stb_summary_tree2 *) all, stb_summary_tree2 *tree)
{
   int i;
   stb_arr_push(all, tree);
   for (i=0; i < tree->num_children; ++i)
      all = stb__summarize_make_array(all, tree->children[i]);
   return all;
}

typedef stb_summary_tree2 * stb__stree2;
stb_define_sort(stb__summarysort, stb__stree2, (*a)->makes_target_weight < (*b)->makes_target_weight)

void *stb_summarize_tree(void *tree, int limit, float reweight)
{
   int i,j,k;
   STB__ARR(stb_summary_tree *) ret=NULL;
   STB__ARR(stb_summary_tree2 *) all=NULL;

   // first clone the tree so we can manipulate it
   stb_summary_tree2 *t = stb__summarize_clone((stb_summary_tree *) tree);
   if (reweight < 1) reweight = 1;

   // now compute how far up the tree each node would get pushed
   // there's no value in pushing a node up to an empty node with
   // only one child, so we keep pushing it up
   stb__summarize_compute_targets(NULL, t, reweight, 1);

   all = stb__summarize_make_array(all, t);

   // now we want to iteratively find the smallest 'makes_target_weight',
   // update that, and then fix all the others (which will be all descendents)
   // to do this efficiently, we need a heap or a sorted binary tree
   // what we have is an array. maybe we can insertion sort the array?
   stb__summarysort(all, stb_arr_len(all));

   for (i=0; i < stb_arr_len(all) - limit; ++i) {
      stb_summary_tree2 *src, *dest;
      src = all[i];
      dest = all[i]->target;
      if (src->makes_target_weight == 0) continue;
      assert(dest != NULL);

      for (k=0; k < stb_arr_len(all); ++k)
         if (all[k] == dest)
            break;
      assert(k != stb_arr_len(all));
      assert(i < k);

      // move weight from all[i] to target
      src->weight = dest->makes_target_weight;
      src->weight = 0;
      src->makes_target_weight = 0;
      // recompute effect of other descendents
      for (j=0; j < stb_arr_len(dest->targeters); ++j) {
         if (dest->targeters[j]->weight) {
            dest->targeters[j]->makes_target_weight = dest->weight + dest->targeters[j]->weight_at_target;
            assert(dest->targeters[j]->makes_target_weight <= dest->weight_with_all_children);
         }
      }
      STB_(stb__summarysort,_ins_sort)(all+i, stb_arr_len(all)-i);
   }
   // now the elements in [ i..stb_arr_len(all) ) are the relevant ones
   for (; i < stb_arr_len(all); ++i)
      stb_arr_push(ret, all[i]->original);

   // now free all our temp data
   for (i=0; i < stb_arr_len(all); ++i) {
      stb_arr_free(all[i]->children);
      free(all[i]);
   }
   stb_arr_free(all);
   return ret;
}
#endif

#endif
