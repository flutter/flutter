/*
  Additional tools for Minizip
  Code: Xavier Roche '2004
  License: Same as ZLIB (www.gzip.org)
*/

/* Code */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "third_party/zlib/zlib.h"
#include "unzip.h"

#define READ_8(adr)  ((unsigned char)*(adr))
#define READ_16(adr) ( READ_8(adr) | (READ_8(adr+1) << 8) )
#define READ_32(adr) ( READ_16(adr) | (READ_16((adr)+2) << 16) )

#define WRITE_8(buff, n) do { \
  *((unsigned char*)(buff)) = (unsigned char) ((n) & 0xff); \
} while(0)
#define WRITE_16(buff, n) do { \
  WRITE_8((unsigned char*)(buff), n); \
  WRITE_8(((unsigned char*)(buff)) + 1, (n) >> 8); \
} while(0)
#define WRITE_32(buff, n) do { \
  WRITE_16((unsigned char*)(buff), (n) & 0xffff); \
  WRITE_16((unsigned char*)(buff) + 2, (n) >> 16); \
} while(0)

extern int ZEXPORT unzRepair(file, fileOut, fileOutTmp, nRecovered, bytesRecovered)
const char* file;
const char* fileOut;
const char* fileOutTmp;
uLong* nRecovered;
uLong* bytesRecovered;
{
  int err = Z_OK;
  FILE* fpZip = fopen(file, "rb");
  FILE* fpOut = fopen(fileOut, "wb");
  FILE* fpOutCD = fopen(fileOutTmp, "wb");
  if (fpZip != NULL &&  fpOut != NULL) {
    int entries = 0;
    uLong totalBytes = 0;
    char header[30];
    char filename[1024];
    char extra[1024];
    int offset = 0;
    int offsetCD = 0;
    while ( fread(header, 1, 30, fpZip) == 30 ) {
      int currentOffset = offset;

      /* File entry */
      if (READ_32(header) == 0x04034b50) {
        unsigned int version = READ_16(header + 4);
        unsigned int gpflag = READ_16(header + 6);
        unsigned int method = READ_16(header + 8);
        unsigned int filetime = READ_16(header + 10);
        unsigned int filedate = READ_16(header + 12);
        unsigned int crc = READ_32(header + 14); /* crc */
        unsigned int cpsize = READ_32(header + 18); /* compressed size */
        unsigned int uncpsize = READ_32(header + 22); /* uncompressed sz */
        unsigned int fnsize = READ_16(header + 26); /* file name length */
        unsigned int extsize = READ_16(header + 28); /* extra field length */
        filename[0] = extra[0] = '\0';

        /* Header */
        if (fwrite(header, 1, 30, fpOut) == 30) {
          offset += 30;
        } else {
          err = Z_ERRNO;
          break;
        }

        /* Filename */
        if (fnsize > 0) {
          if (fnsize < sizeof(filename)) {
            if (fread(filename, 1, fnsize, fpZip) == fnsize) {
                if (fwrite(filename, 1, fnsize, fpOut) == fnsize) {
                offset += fnsize;
              } else {
                err = Z_ERRNO;
                break;
              }
            } else {
              err = Z_ERRNO;
              break;
            }
          } else {
            err = Z_ERRNO;
            break;
          }
        } else {
          err = Z_STREAM_ERROR;
          break;
        }

        /* Extra field */
        if (extsize > 0) {
          if (extsize < sizeof(extra)) {
            if (fread(extra, 1, extsize, fpZip) == extsize) {
              if (fwrite(extra, 1, extsize, fpOut) == extsize) {
                offset += extsize;
                } else {
                err = Z_ERRNO;
                break;
              }
            } else {
              err = Z_ERRNO;
              break;
            }
          } else {
            err = Z_ERRNO;
            break;
          }
        }

        /* Data */
        {
          int dataSize = cpsize;
          if (dataSize == 0) {
            dataSize = uncpsize;
          }
          if (dataSize > 0) {
            char* data = malloc(dataSize);
            if (data != NULL) {
              if ((int)fread(data, 1, dataSize, fpZip) == dataSize) {
                if ((int)fwrite(data, 1, dataSize, fpOut) == dataSize) {
                  offset += dataSize;
                  totalBytes += dataSize;
                } else {
                  err = Z_ERRNO;
                }
              } else {
                err = Z_ERRNO;
              }
              free(data);
              if (err != Z_OK) {
                break;
              }
            } else {
              err = Z_MEM_ERROR;
              break;
            }
          }
        }

        /* Central directory entry */
        {
          char header[46];
          char* comment = "";
          int comsize = (int) strlen(comment);
          WRITE_32(header, 0x02014b50);
          WRITE_16(header + 4, version);
          WRITE_16(header + 6, version);
          WRITE_16(header + 8, gpflag);
          WRITE_16(header + 10, method);
          WRITE_16(header + 12, filetime);
          WRITE_16(header + 14, filedate);
          WRITE_32(header + 16, crc);
          WRITE_32(header + 20, cpsize);
          WRITE_32(header + 24, uncpsize);
          WRITE_16(header + 28, fnsize);
          WRITE_16(header + 30, extsize);
          WRITE_16(header + 32, comsize);
          WRITE_16(header + 34, 0);     /* disk # */
          WRITE_16(header + 36, 0);     /* int attrb */
          WRITE_32(header + 38, 0);     /* ext attrb */
          WRITE_32(header + 42, currentOffset);
          /* Header */
          if (fwrite(header, 1, 46, fpOutCD) == 46) {
            offsetCD += 46;

            /* Filename */
            if (fnsize > 0) {
              if (fwrite(filename, 1, fnsize, fpOutCD) == fnsize) {
                offsetCD += fnsize;
              } else {
                err = Z_ERRNO;
                break;
              }
            } else {
              err = Z_STREAM_ERROR;
              break;
            }

            /* Extra field */
            if (extsize > 0) {
              if (fwrite(extra, 1, extsize, fpOutCD) == extsize) {
                offsetCD += extsize;
              } else {
                err = Z_ERRNO;
                break;
              }
            }

            /* Comment field */
            if (comsize > 0) {
              if ((int)fwrite(comment, 1, comsize, fpOutCD) == comsize) {
                offsetCD += comsize;
              } else {
                err = Z_ERRNO;
                break;
              }
            }


          } else {
            err = Z_ERRNO;
            break;
          }
        }

        /* Success */
        entries++;

      } else {
        break;
      }
    }

    /* Final central directory  */
    {
      int entriesZip = entries;
      char header[22];
      char* comment = ""; // "ZIP File recovered by zlib/minizip/mztools";
      int comsize = (int) strlen(comment);
      if (entriesZip > 0xffff) {
        entriesZip = 0xffff;
      }
      WRITE_32(header, 0x06054b50);
      WRITE_16(header + 4, 0);    /* disk # */
      WRITE_16(header + 6, 0);    /* disk # */
      WRITE_16(header + 8, entriesZip);   /* hack */
      WRITE_16(header + 10, entriesZip);  /* hack */
      WRITE_32(header + 12, offsetCD);    /* size of CD */
      WRITE_32(header + 16, offset);      /* offset to CD */
      WRITE_16(header + 20, comsize);     /* comment */

      /* Header */
      if (fwrite(header, 1, 22, fpOutCD) == 22) {

        /* Comment field */
        if (comsize > 0) {
          if ((int)fwrite(comment, 1, comsize, fpOutCD) != comsize) {
            err = Z_ERRNO;
          }
        }

      } else {
        err = Z_ERRNO;
      }
    }

    /* Final merge (file + central directory) */
    fclose(fpOutCD);
    if (err == Z_OK) {
      fpOutCD = fopen(fileOutTmp, "rb");
      if (fpOutCD != NULL) {
        int nRead;
        char buffer[8192];
        while ( (nRead = (int)fread(buffer, 1, sizeof(buffer), fpOutCD)) > 0) {
          if ((int)fwrite(buffer, 1, nRead, fpOut) != nRead) {
            err = Z_ERRNO;
            break;
          }
        }
        fclose(fpOutCD);
      }
    }

    /* Close */
    fclose(fpZip);
    fclose(fpOut);

    /* Wipe temporary file */
    (void)remove(fileOutTmp);

    /* Number of recovered entries */
    if (err == Z_OK) {
      if (nRecovered != NULL) {
        *nRecovered = entries;
      }
      if (bytesRecovered != NULL) {
        *bytesRecovered = totalBytes;
      }
    }
  } else {
    err = Z_STREAM_ERROR;
  }
  return err;
}
