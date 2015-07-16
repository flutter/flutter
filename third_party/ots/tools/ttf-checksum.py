import struct
import sys

def readU32(contents, offset):
  wordBytes = contents[offset:offset + 4]
  return struct.unpack('>I', wordBytes)[0]

def readU16(contents, offset):
  wordBytes = contents[offset:offset + 2]
  return struct.unpack('>H', wordBytes)[0]

def checkChecksum(infile):
  contents = infile.read()
  if len(contents) % 4:
    print 'File length is not a multiple of 4'

  sum = 0
  for offset in range(0, len(contents), 4):
    sum += readU32(contents, offset)
    while sum >= 2**32:
      sum -= 2**32
  print 'Sum of whole file: %x' % sum

  numTables = readU16(contents, 4)

  for offset in range(12, 12 + numTables * 16, 16):
    tag = contents[offset:offset + 4]
    chksum = readU32(contents, offset + 4)
    toffset = readU32(contents, offset + 8)
    tlength = readU32(contents, offset + 12)

    sum = 0
    for offset2 in range(toffset, toffset + tlength, 4):
      sum += readU32(contents, offset2)
      while sum >= 2**32:
        sum -= 2**32
    if sum != chksum:
      print 'Bad chksum: %s' % tag

if __name__ == '__main__':
  if len(sys.argv) != 2:
    print 'Usage: %s <ttf filename>' % sys.argv[0]
  else:
    checkChecksum(file(sys.argv[1], 'r'))
