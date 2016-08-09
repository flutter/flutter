#include <stdio.h>

#define IN_LIBXML
#include "libxml/xmlexports.h"

XMLPUBFUN int hello_world(void);

int hello_world(void)
{
  printf("Success!\n");
  return 0;
}
