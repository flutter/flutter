/* Copyright 2013 Google Inc. All Rights Reserved.

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

   Transformations on dictionary words.
*/

#ifndef BROTLI_DEC_TRANSFORM_H_
#define BROTLI_DEC_TRANSFORM_H_

#include <stdio.h>
#include <ctype.h>
#include "./types.h"

#if defined(__cplusplus) || defined(c_plusplus)
extern "C" {
#endif

enum WordTransformType {
  kIdentity       = 0,
  kOmitLast1      = 1,
  kOmitLast2      = 2,
  kOmitLast3      = 3,
  kOmitLast4      = 4,
  kOmitLast5      = 5,
  kOmitLast6      = 6,
  kOmitLast7      = 7,
  kOmitLast8      = 8,
  kOmitLast9      = 9,
  kUppercaseFirst = 10,
  kUppercaseAll   = 11,
  kOmitFirst1     = 12,
  kOmitFirst2     = 13,
  kOmitFirst3     = 14,
  kOmitFirst4     = 15,
  kOmitFirst5     = 16,
  kOmitFirst6     = 17,
  kOmitFirst7     = 18,
  kOmitFirst8     = 19,
  kOmitFirst9     = 20
};

typedef struct {
  const char* prefix;
  enum WordTransformType transform;
  const char* suffix;
} Transform;

static const Transform kTransforms[] = {
     {         "", kIdentity,       ""           },
     {         "", kIdentity,       " "          },
     {        " ", kIdentity,       " "          },
     {         "", kOmitFirst1,     ""           },
     {         "", kUppercaseFirst, " "          },
     {         "", kIdentity,       " the "      },
     {        " ", kIdentity,       ""           },
     {       "s ", kIdentity,       " "          },
     {         "", kIdentity,       " of "       },
     {         "", kUppercaseFirst, ""           },
     {         "", kIdentity,       " and "      },
     {         "", kOmitFirst2,     ""           },
     {         "", kOmitLast1,      ""           },
     {       ", ", kIdentity,       " "          },
     {         "", kIdentity,       ", "         },
     {        " ", kUppercaseFirst, " "          },
     {         "", kIdentity,       " in "       },
     {         "", kIdentity,       " to "       },
     {       "e ", kIdentity,       " "          },
     {         "", kIdentity,       "\""         },
     {         "", kIdentity,       "."          },
     {         "", kIdentity,       "\">"        },
     {         "", kIdentity,       "\n"         },
     {         "", kOmitLast3,      ""           },
     {         "", kIdentity,       "]"          },
     {         "", kIdentity,       " for "      },
     {         "", kOmitFirst3,     ""           },
     {         "", kOmitLast2,      ""           },
     {         "", kIdentity,       " a "        },
     {         "", kIdentity,       " that "     },
     {        " ", kUppercaseFirst, ""           },
     {         "", kIdentity,       ". "         },
     {        ".", kIdentity,       ""           },
     {        " ", kIdentity,       ", "         },
     {         "", kOmitFirst4,     ""           },
     {         "", kIdentity,       " with "     },
     {         "", kIdentity,       "'"          },
     {         "", kIdentity,       " from "     },
     {         "", kIdentity,       " by "       },
     {         "", kOmitFirst5,     ""           },
     {         "", kOmitFirst6,     ""           },
     {    " the ", kIdentity,       ""           },
     {         "", kOmitLast4,      ""           },
     {         "", kIdentity,       ". The "     },
     {         "", kUppercaseAll,   ""           },
     {         "", kIdentity,       " on "       },
     {         "", kIdentity,       " as "       },
     {         "", kIdentity,       " is "       },
     {         "", kOmitLast7,      ""           },
     {         "", kOmitLast1,      "ing "       },
     {         "", kIdentity,       "\n\t"       },
     {         "", kIdentity,       ":"          },
     {        " ", kIdentity,       ". "         },
     {         "", kIdentity,       "ed "        },
     {         "", kOmitFirst9,     ""           },
     {         "", kOmitFirst7,     ""           },
     {         "", kOmitLast6,      ""           },
     {         "", kIdentity,       "("          },
     {         "", kUppercaseFirst, ", "         },
     {         "", kOmitLast8,      ""           },
     {         "", kIdentity,       " at "       },
     {         "", kIdentity,       "ly "        },
     {    " the ", kIdentity,       " of "       },
     {         "", kOmitLast5,      ""           },
     {         "", kOmitLast9,      ""           },
     {        " ", kUppercaseFirst, ", "         },
     {         "", kUppercaseFirst, "\""         },
     {        ".", kIdentity,       "("          },
     {         "", kUppercaseAll,   " "          },
     {         "", kUppercaseFirst, "\">"        },
     {         "", kIdentity,       "=\""        },
     {        " ", kIdentity,       "."          },
     {    ".com/", kIdentity,       ""           },
     {    " the ", kIdentity,       " of the "   },
     {         "", kUppercaseFirst, "'"          },
     {         "", kIdentity,       ". This "    },
     {         "", kIdentity,       ","          },
     {        ".", kIdentity,       " "          },
     {         "", kUppercaseFirst, "("          },
     {         "", kUppercaseFirst, "."          },
     {         "", kIdentity,       " not "      },
     {        " ", kIdentity,       "=\""        },
     {         "", kIdentity,       "er "        },
     {        " ", kUppercaseAll,   " "          },
     {         "", kIdentity,       "al "        },
     {        " ", kUppercaseAll,   ""           },
     {         "", kIdentity,       "='"         },
     {         "", kUppercaseAll,   "\""         },
     {         "", kUppercaseFirst, ". "         },
     {        " ", kIdentity,       "("          },
     {         "", kIdentity,       "ful "       },
     {        " ", kUppercaseFirst, ". "         },
     {         "", kIdentity,       "ive "       },
     {         "", kIdentity,       "less "      },
     {         "", kUppercaseAll,   "'"          },
     {         "", kIdentity,       "est "       },
     {        " ", kUppercaseFirst, "."          },
     {         "", kUppercaseAll,   "\">"        },
     {        " ", kIdentity,       "='"         },
     {         "", kUppercaseFirst, ","          },
     {         "", kIdentity,       "ize "       },
     {         "", kUppercaseAll,   "."          },
     { "\xc2\xa0", kIdentity,       ""           },
     {        " ", kIdentity,       ","          },
     {         "", kUppercaseFirst, "=\""        },
     {         "", kUppercaseAll,   "=\""        },
     {         "", kIdentity,       "ous "       },
     {         "", kUppercaseAll,   ", "         },
     {         "", kUppercaseFirst, "='"         },
     {        " ", kUppercaseFirst, ","          },
     {        " ", kUppercaseAll,   "=\""        },
     {        " ", kUppercaseAll,   ", "         },
     {         "", kUppercaseAll,   ","          },
     {         "", kUppercaseAll,   "("          },
     {         "", kUppercaseAll,   ". "         },
     {        " ", kUppercaseAll,   "."          },
     {         "", kUppercaseAll,   "='"         },
     {        " ", kUppercaseAll,   ". "         },
     {        " ", kUppercaseFirst, "=\""        },
     {        " ", kUppercaseAll,   "='"         },
     {        " ", kUppercaseFirst, "='"         },
};

static const int kNumTransforms = sizeof(kTransforms) / sizeof(kTransforms[0]);

static int ToUpperCase(uint8_t *p) {
  if (p[0] < 0xc0) {
    if (p[0] >= 'a' && p[0] <= 'z') {
      p[0] ^= 32;
    }
    return 1;
  }
  /* An overly simplified uppercasing model for utf-8. */
  if (p[0] < 0xe0) {
    p[1] ^= 32;
    return 2;
  }
  /* An arbitrary transform for three byte characters. */
  p[2] ^= 5;
  return 3;
}

static BROTLI_INLINE int TransformDictionaryWord(
    uint8_t* dst, const uint8_t* word, int len, int transform) {
  const char* prefix = kTransforms[transform].prefix;
  const char* suffix = kTransforms[transform].suffix;
  const int t = kTransforms[transform].transform;
  int skip = t < kOmitFirst1 ? 0 : t - (kOmitFirst1 - 1);
  int idx = 0;
  int i = 0;
  uint8_t* uppercase;
  if (skip > len) {
    skip = len;
  }
  while (*prefix) { dst[idx++] = (uint8_t)*prefix++; }
  word += skip;
  len -= skip;
  if (t <= kOmitLast9) {
    len -= t;
  }
  while (i < len) { dst[idx++] = word[i++]; }
  uppercase = &dst[idx - len];
  if (t == kUppercaseFirst) {
    ToUpperCase(uppercase);
  } else if (t == kUppercaseAll) {
    while (len > 0) {
      int step = ToUpperCase(uppercase);
      uppercase += step;
      len -= step;
    }
  }
  while (*suffix) { dst[idx++] = (uint8_t)*suffix++; }
  return idx;
}

#if defined(__cplusplus) || defined(c_plusplus)
}    /* extern "C" */
#endif

#endif  /* BROTLI_DEC_TRANSFORM_H_ */
