#define STB_DEFINE
#include "../stb.h"

// create unicode mappings
//
// Two kinds of mappings:
//     map to a number
//     map to a bit
//
// For mapping to a number, we use the following strategy:
//
//   User supplies:
//     1. a table of numbers (for now we use uint16, so full Unicode table is 4MB)
//     2. a "don't care" value
//     3. define a 'fallback' value (typically 0)
//     4. define a fast-path range (typically 0..255 or 0..1023) [@TODO: automate detecting this]
//
//   Code:
//     1. Determine range of *end* of unicode codepoints (U+10FFFF and down) which
//        all have the same value (or don't care). If large enough, emit this as a
//        special case in the code.
//     2. Repeat above, limited to at most U+FFFF.
//     3. Cluster the data into intervals of 8,16,32,64,128,256 numeric values.
//        3a. If all the values in an interval are fallback/dont-care, no further processing
//        3b. Find the "trimmed range" outside which all the values are the fallback or don't care
//        3c. Find the "special trimmed range" outside which all the values are some constant or don't care
//     4. Pack the clusters into continuous memory, and find previous instances of
//        the cluster. Repeat for trimmed & special-trimmed. In the first case, find
//        previous instances of the cluster (allow don't-care to match in either
//        direction), both aligned and mis-aligned; in the latter, starting where
//        things start or mis-aligned. Build an index table specifiying the
//        location of each cluster (and its length). Allow an extra indirection here;
//        the full-sized index can index a smaller table which has the actual offset
//        (and lengths).
//     5. Associate with each packed continuous memory above the amount of memory
//        required to store the data w/ smallest datatype (of uint8, uint16, uint32).
//        Discard the continuous memory. Recurse on each index table, but avoid the
//        smaller packing.
//
// For mapping to a bit, we pack the results for 8 characters into a byte, and then apply
// the above strategy. Note that there may be more optimal approaches with e.g. packing
// 8 different bits into a single structure, though, which we should explore eventually.


// currently we limit *indices* to being 2^16, and we pack them as
//      index + end_trim*2^16 + start_trim*2^24; specials have to go in a separate table
typedef uint32 uval;
#define UVAL_DONT_CARE_DEFAULT 0xffffffff

typedef struct
{
   uval *input;
   uint32 dont_care;
   uint32 fallback;
   int  fastpath;
   int  length;
   int  depth;
   int  has_sign;
   int  splittable;
   int  replace_fallback_with_codepoint;
   size_t input_size;
   size_t inherited_storage;
} table;

typedef struct
{
   int   split_log2;
   table result; // index into not-returned table
   int   storage;
} output;

typedef struct
{
   table t;
   char **output_name;
} info;

typedef struct
{
   size_t path;
   size_t size;
} result;

typedef struct
{
   uint8 trim_end;
   uint8 trim_start;
   uint8 special;
   uint8 aligned;
   uint8 indirect;

   uint16 overhead; // add some forced overhead for each mode to avoid getting complex encoding when it doesn't save much

} mode_info;

mode_info modes[] =
{
   {   0,0,0,0,0,    32, },
   {   0,0,0,0,1,   100, },
   {   0,0,0,1,0,    32, },
   {   0,0,0,1,1,   100, },
   {   0,0,1,0,1,   100, },
   {   0,0,1,1,0,    32, },
   {   0,0,1,1,1,   200, },
   {   1,0,0,0,0,   100, },
   {   1,0,0,0,1,   120, },
   {   1,1,0,0,0,   100, },
   {   1,1,0,0,1,   130, },
   {   1,0,1,0,0,   130, },
   {   1,0,1,0,1,   180, },
   {   1,1,1,0,0,   180, },
   {   1,1,1,0,1,   200, },
};

#define MODECOUNT  (sizeof(modes)/sizeof(modes[0]))
#define CLUSTERSIZECOUNT   6    // 8,16, 32,64,  128,256

size_t size_for_max_number(uint32 number)
{
   if (number == 0) return 0;
   if (number < 256) return 1;
   if (number < 256*256) return 2;
   if (number < 256*256*256) return 3;
   return 4;
}

size_t size_for_max_number_aligned(uint32 number)
{
   size_t n = size_for_max_number(number);
   return n == 3 ? 4 : n;
}

uval get_data(uval *data, int offset, uval *end)
{
   if (data + offset >= end)
      return 0;
   else
      return data[offset];
}

int safe_len(uval *data, int len, uval *end)
{
   if (len > end - data)
      return end - data;
   return len;
}

uval tempdata[256];
int dirty=0;

size_t find_packed(uval **packed, uval *data, int len, int aligned, int fastpath, uval *end, int offset, int replace)
{
   int packlen = stb_arr_len(*packed);
   int i,p;

   if (data+len > end || replace) {
      int safelen = safe_len(data, len, end);
      memset(tempdata, 0, dirty*sizeof(tempdata[0]));
      memcpy(tempdata, data, safelen * sizeof(data[0]));
      data = tempdata;
      dirty = len;
   }
   if (replace) {
      int i;
      int safelen = safe_len(data, len, end);
      for (i=0; i < safelen; ++i)
         if (data[i] == 0)
            data[i] = offset+i;
   }

   if (len <= 0)
      return 0;
   if (!fastpath) {
      if (aligned) {
         for (i=0; i < packlen; i += len)
            if ((*packed)[i] == data[0] && 0==memcmp(&(*packed)[i], data, len * sizeof(uval)))
               return i / len;
      } else {
         for (i=0; i < packlen-len+1; i +=  1 )
            if ((*packed)[i] == data[0] && 0==memcmp(&(*packed)[i], data, len * sizeof(uval)))
               return i;
      }
   }
   p = stb_arr_len(*packed);
   for (i=0; i < len; ++i)
      stb_arr_push(*packed, data[i]);
   return p;
}

void output_table(char *name1, char *name2, uval *data, int length, int sign, char **names)
{
   char temp[20];
   uval maxv = 0;
   int bytes, numlen, at_newline;
   int linelen = 79; // @TODO: make table more readable by choosing a length that's a multiple?
   int i,pos, do_split=0;
   for (i=0; i < length; ++i)
      if (sign)
         maxv = stb_max(maxv, (uval)abs((int)data[i]));
      else
         maxv = stb_max(maxv, data[i]);
   bytes = size_for_max_number_aligned(maxv);
   sprintf(temp, "%d", maxv);
   numlen=strlen(temp);
   if (sign)
      ++numlen;
   
   if (bytes == 0)
      return;

   printf("uint%d %s%s[%d] = {\n", bytes*8, name1, name2, length);
   at_newline = 1;
   for (i=0; i < length; ++i) {
      if (pos + numlen + 2 > linelen) {
         printf("\n");
         at_newline = 1;
         pos = 0;
      }
      if (at_newline) {
         printf("  ");
         pos = 2;
         at_newline = 0;
      } else {
         printf(" ");
         ++pos;
      }
      printf("%*d,", numlen, data[i]);
      pos += numlen+1;
   }
   if (!at_newline) printf("\n");
   printf("};\n");
}

void output_table_with_trims(char *name1, char *name2, uval *data, int length)
{
   uval maxt=0, maxp=0;
   int i,d,s,e, count;
   // split the table into two pieces
   uval *trims = NULL;

   if (length == 0)
      return;

   for (i=0; i < stb_arr_len(data); ++i) {
      stb_arr_push(trims, data[i] >> 16);
      data[i] &= 0xffff;
      maxt = stb_max(maxt, trims[i]);
      maxp = stb_max(maxp, data[i]);
   }

   d=s=e=1;
   if (maxt >= 256) {
      // need to output start & end values
      if (maxp >= 256) {
         // can pack into a single table
         printf("struct { uint16 val; uint8 start, end; } %s%s[%d] = {\n", name1, name2, length);
      } else {
         output_table(name1, name2, data, length, 0, 0);
         d=0;
         printf("struct { uint8 start, end; } %s%s_trim[%d] = {\n", name1, name2, length);
      }
   } else if (maxt > 0) {
      if (maxp >= 256) {
         output_table(name1, name2, data, length, 0, 0);
         output_table(name1, stb_sprintf("%s_end", name2), trims, length, 0, 0);
         return;
      } else {
         printf("struct { uint8 val, end; } %s%s[%d] = {\n", name1, name2, length);
         s=0;
      }
   } else {
      output_table(name1, name2, data, length, 0, 0);
      return;
   }
   // d or s can be zero (but not both), e is always present and last
   count = d + s + e;
   assert(count >= 2 && count <= 3);

   {
      char temp[60];
      uval maxv = 0;
      int numlen, at_newline, len;
      int linelen = 79; // @TODO: make table more readable by choosing a length that's a multiple?
      int i,pos, do_split=0;
      numlen = 0;
      for (i=0; i < length; ++i) {
         if (count == 2)
            sprintf(temp, "{%d,%d}", d ? data[i] : (trims[i]>>8), trims[i]&255);
         else
            sprintf(temp, "{%d,%d,%d}", data[i], trims[i]>>8, trims[i]&255);
         len = strlen(temp);
         numlen = stb_max(len, numlen);
      }
   
      at_newline = 1;
      for (i=0; i < length; ++i) {
         if (pos + numlen + 2 > linelen) {
            printf("\n");
            at_newline = 1;
            pos = 0;
         }
         if (at_newline) {
            printf("  ");
            pos = 2;
            at_newline = 0;
         } else {
            printf(" ");
            ++pos;
         }
         if (count == 2)
            sprintf(temp, "{%d,%d}", d ? data[i] : (trims[i]>>8), trims[i]&255);
         else
            sprintf(temp, "{%d,%d,%d}", data[i], trims[i]>>8, trims[i]&255);
         printf("%*s,", numlen, temp);
         pos += numlen+1;
      }
      if (!at_newline) printf("\n");
      printf("};\n");
   }
}

int weight=1;

table pack_for_mode(table *t, int mode, char *table_name)
{
   size_t extra_size;
   int i;
   uval maxv;
   mode_info mi = modes[mode % MODECOUNT];
   int size = 8 << (mode / MODECOUNT);
   table newtab;
   uval *packed = NULL;
   uval *index = NULL;
   uval *indirect = NULL;
   uval *specials = NULL;
   newtab.dont_care = UVAL_DONT_CARE_DEFAULT;
   if (table_name)
      printf("// clusters of %d\n", size);
   for (i=0; i < t->length; i += size) {
      uval newval;
      int fastpath = (i < t->fastpath);
      if (mi.special) {
         int end_trim = size-1;
         int start_trim = 0;
         uval special;
         // @TODO: pick special from start or end instead of only end depending on which is longer
         for(;;) {
            special = t->input[i + end_trim];
            if (special != t->dont_care || end_trim == 0)
               break;
            --end_trim;
         }
         // at this point, special==inp[end_trim], and end_trim >= 0
         if (special == t->dont_care && !fastpath) {
            // entire block is don't care, so OUTPUT don't care
            stb_arr_push(index, newtab.dont_care);
            continue;
         } else {
            uval pos, trim;
            if (mi.trim_end && !fastpath) {
               while (end_trim >= 0) {
                  if (t->input[i + end_trim] == special || t->input[i + end_trim] == t->dont_care)
                     --end_trim;
                  else
                     break;
               }
            }

            if (mi.trim_start && !fastpath) {
               while (start_trim < end_trim) {
                  if (t->input[i + start_trim] == special || t->input[i + start_trim] == t->dont_care)
                     ++start_trim;
                  else
                     break;
               }
            }

            // end_trim points to the last character we have to output

            // find the first match, or add it
            pos = find_packed(&packed, &t->input[i+start_trim], end_trim-start_trim+1, mi.aligned, fastpath, &t->input[t->length], i+start_trim, t->replace_fallback_with_codepoint);

            // encode as a uval
            if (!mi.trim_end) {
               if (end_trim == 0)
                  pos = special;
               else
                  pos = pos | 0x80000000;
            } else {
               assert(end_trim < size && end_trim >= -1);
               if (!fastpath) assert(end_trim < size-1); // special always matches last one
               assert(end_trim < size && end_trim+1 >= 0);
               if (!fastpath) assert(end_trim+1 < size);

               if (mi.trim_start)
                  trim = start_trim*256 + (end_trim+1);
               else
                  trim = end_trim+1;

               assert(pos < 65536); // @TODO: if this triggers, just bail on this search path
               pos = pos + (trim << 16);
            }

            newval = pos;

            stb_arr_push(specials, special);
         }
      } else if (mi.trim_end) {
         int end_trim = size-1;
         int start_trim = 0;
         uval pos, trim;

         while (end_trim >= 0 && !fastpath)
            if (t->input[i + end_trim] == t->fallback || t->input[i + end_trim] == t->dont_care)
               --end_trim;
            else
               break;

         if (mi.trim_start && !fastpath) {
            while (start_trim < end_trim) {
               if (t->input[i + start_trim] == t->fallback || t->input[i + start_trim] == t->dont_care)
                  ++start_trim;
               else
                  break;
            }
         }

         // end_trim points to the last character we have to output, and can be -1
         ++end_trim; // make exclusive at end

         if (end_trim == 0 && size == 256)
            start_trim = end_trim = 1;  // we can't make encode a length from 0..256 in 8 bits, so restrict end_trim to 1..256

         // find the first match, or add it
         pos = find_packed(&packed, &t->input[i+start_trim], end_trim - start_trim, mi.aligned, fastpath, &t->input[t->length], i+start_trim, t->replace_fallback_with_codepoint);

         assert(end_trim <= size && end_trim >= 0);
         if (size == 256)
            assert(end_trim-1 < 256 && end_trim-1 >= 0);
         else
            assert(end_trim < 256 && end_trim >= 0);
         if (size == 256)
            --end_trim;

         if (mi.trim_start)
            trim = start_trim*256 + end_trim;
         else
            trim = end_trim;

         assert(pos < 65536); // @TODO: if this triggers, just bail on this search path
         pos = pos + (trim << 16);

         newval = pos;
      } else {
         newval = find_packed(&packed, &t->input[i], size, mi.aligned, fastpath, &t->input[t->length], i, t->replace_fallback_with_codepoint);
      }

      if (mi.indirect) {
         int j;
         for (j=0; j < stb_arr_len(indirect); ++j)
            if (indirect[j] == newval)
               break;
         if (j == stb_arr_len(indirect))
            stb_arr_push(indirect, newval);
         stb_arr_push(index, j);
      } else {
         stb_arr_push(index, newval);
      }
   }

   // total up the new size for everything but the index table
   extra_size = mi.overhead * weight; // not the actual overhead cost; a penalty to avoid excessive complexity
   extra_size += 150; // per indirection
   if (table_name)
      extra_size = 0;
   
   if (t->has_sign) {
      // 'packed' contains two values, which should be packed positive & negative for size
      uval maxv2;
      for (i=0; i < stb_arr_len(packed); ++i)
         if (packed[i] & 0x80000000)
            maxv2 = stb_max(maxv2, packed[i]);
         else
            maxv  = stb_max(maxv, packed[i]);
      maxv = stb_max(maxv, maxv2) << 1;
   } else {
      maxv = 0;
      for (i=0; i < stb_arr_len(packed); ++i)
         if (packed[i] > maxv && packed[i] != t->dont_care)
            maxv = packed[i];
   }
   extra_size += stb_arr_len(packed) * (t->splittable ? size_for_max_number(maxv) : size_for_max_number_aligned(maxv));
   if (table_name) {
      if (t->splittable)
         output_table_with_trims(table_name, "", packed, stb_arr_len(packed));
      else
         output_table(table_name, "", packed, stb_arr_len(packed), t->has_sign, NULL);
   }

   maxv = 0;
   for (i=0; i < stb_arr_len(specials); ++i)
      if (specials[i] > maxv)
         maxv = specials[i];
   extra_size += stb_arr_len(specials) * size_for_max_number_aligned(maxv);
   if (table_name)
      output_table(table_name, "_default", specials, stb_arr_len(specials), 0, NULL);

   maxv = 0;
   for (i=0; i < stb_arr_len(indirect); ++i)
      if (indirect[i] > maxv)
         maxv = indirect[i];
   extra_size += stb_arr_len(indirect) * size_for_max_number(maxv);

   if (table_name && stb_arr_len(indirect)) {
      if (mi.trim_end)
         output_table_with_trims(table_name, "_index", indirect, stb_arr_len(indirect));
      else {
         assert(0); // this case should only trigger in very extreme circumstances
         output_table(table_name, "_index", indirect, stb_arr_len(indirect), 0, NULL);
      }
      mi.trim_end = mi.special = 0;
   }

   if (table_name)
      printf("// above tables should be %d bytes\n", extra_size);

   maxv = 0;
   for (i=0; i < stb_arr_len(index); ++i)
      if (index[i] > maxv && index[i] != t->dont_care)
         maxv = index[i];
   newtab.splittable = mi.trim_end;
   newtab.input_size = newtab.splittable ? size_for_max_number(maxv) : size_for_max_number_aligned(maxv);
   newtab.input = index;
   newtab.length = stb_arr_len(index);
   newtab.inherited_storage = t->inherited_storage + extra_size;
   newtab.fastpath = 0;
   newtab.depth = t->depth+1;
   stb_arr_free(indirect);
   stb_arr_free(packed);
   stb_arr_free(specials);

   return newtab;
}

result pack_table(table *t, size_t path, int min_storage)
{
   int i;
   result best;
   best.size = t->inherited_storage + t->input_size * t->length;
   best.path = path;

   if ((int) t->inherited_storage > min_storage) {
      best.size = stb_max(best.size, t->inherited_storage);
      return best;
   }

   if (t->length <= 256 || t->depth >= 4) {
      //printf("%08x: %7d\n", best.path, best.size);
      return best;
   }

   path <<= 7;
   for (i=0; i < MODECOUNT * CLUSTERSIZECOUNT; ++i) {
      table newtab;
      result r;
      newtab = pack_for_mode(t, i, 0);
      r = pack_table(&newtab, path+i+1, min_storage);
      if (r.size < best.size)
         best = r;
      stb_arr_free(newtab.input);
      //printf("Size: %6d + %6d\n", newtab.inherited_storage, newtab.input_size * newtab.length);
   }
   return best;
}

int pack_table_by_modes(table *t, int *modes)
{
   table s = *t;
   while (*modes > -1) {
      table newtab;
      newtab = pack_for_mode(&s, *modes, 0);
      if (s.input != t->input)
         stb_arr_free(s.input);
      s = newtab;
      ++modes;
   }
   return s.inherited_storage + s.input_size * s.length;
}

int strip_table(table *t, int exceptions)
{
   uval terminal_value;
   int p = t->length-1;
   while (t->input[p] == t->dont_care)
      --p;
   terminal_value = t->input[p];

   while (p >= 0x10000) {
      if (t->input[p] != terminal_value && t->input[p] != t->dont_care) {
         if (exceptions)
            --exceptions;
         else
            break;
      }
      --p;
   }
   return p+1; // p is a character we must output
}

void optimize_table(table *t, char *table_name)
{
   int modelist[3] = { 85, -1 };
   int modes[8];
   int num_modes = 0;
   int decent_size;
   result r;
   size_t path;
   table s;

   // strip tail end of table
   int orig_length = t->length;
   int threshhold = 0xffff;
   int p = strip_table(t, 2);
   int len_saved = t->length - p;
   if (len_saved >= threshhold) {
      t->length = p;
      while (p > 0x10000) {
         p = strip_table(t, 0);
         len_saved = t->length - p;
         if (len_saved < 0x10000)
            break;
         len_saved = orig_length - p;
         if (len_saved < threshhold)
            break;
         threshhold *= 2;
      }
   }

   t->depth = 1;


   // find size of table if we use path 86
   decent_size = pack_table_by_modes(t, modelist);


   #if 1
   // find best packing of remainder of table by exploring tree of packings
   r = pack_table(t, 0, decent_size);
   // use the computed 'path' to evaluate and output tree
   path = r.path;
   #else
   path = 86;//90;//132097;
   #endif

   while (path) {
      modes[num_modes++] = (path & 127) - 1;
      path >>= 7;
   }

   printf("// modes: %d\n", r.path);
   s = *t;
   while (num_modes > 0) {
      char name[256];
      sprintf(name, "%s_%d", table_name, num_modes+1);
      --num_modes;
      s = pack_for_mode(&s, modes[num_modes], name);
   }
   // output the final table as-is
   if (s.splittable)
      output_table_with_trims(table_name, "_1", s.input, s.length);
   else
      output_table(table_name, "_1", s.input, s.length, 0, NULL);
}

uval unicode_table[0x110000];

typedef struct
{
   uval lo,hi;
} char_range;

char_range get_range(char *str)
{
   char_range cr;
   char *p;
   cr.lo = strtol(str, &p, 16);
   p = stb_skipwhite(p);
   if (*p == '.')
      cr.hi = strtol(p+2, NULL, 16);
   else
      cr.hi = cr.lo;
   return cr;
}

char *skip_semi(char *s, int count)
{
   while (count) {
      s = strchr(s, ';');
      assert(s != NULL);
      ++s;
      --count;
   }
   return s;
}

int main(int argc, char **argv)
{
   table t;
   uval maxv=0;
   int i,n=0;
   char **s = stb_stringfile("../../data/UnicodeData.txt", &n);
   assert(s);
   for (i=0; i < n; ++i) {
      if (s[i][0] == '#' || s[i][0] == '\n' || s[i][0] == 0)
         ;
      else {
         char_range cr = get_range(s[i]);
         char *t = skip_semi(s[i], 13);
         uval j, v;
         if (*t == ';' || *t == '\n' || *t == 0)
            v = 0;
         else {
            v = strtol(t, NULL, 16);
            if (v < 65536) {
               maxv = stb_max(v, maxv);
               for (j=cr.lo; j <= cr.hi; ++j) {
                  unicode_table[j] = v;
                  //printf("%06x => %06x\n", j, v);
               }
            }
         }
      }
   }

   t.depth = 0;
   t.dont_care = UVAL_DONT_CARE_DEFAULT;
   t.fallback = 0;
   t.fastpath = 256;
   t.inherited_storage = 0;
   t.has_sign = 0;
   t.splittable = 0;
   t.input = unicode_table;
   t.input_size = size_for_max_number(maxv);
   t.length = 0x110000;
   t.replace_fallback_with_codepoint = 1;

   optimize_table(&t, "stbu_upppercase");
   return 0;
}
