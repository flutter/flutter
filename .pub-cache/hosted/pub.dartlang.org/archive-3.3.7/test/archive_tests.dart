library test.archive;

import 'tests/adler32_test.dart' as adler32_test;
import 'tests/bzip2_test.dart' as bzip2_test;
import 'tests/commands_test.dart' as commands_test;
import 'tests/crc32_test.dart' as crc32_test;
import 'tests/deflate_test.dart' as deflate_test;
import 'tests/gzip_test.dart' as gzip_test;
import 'tests/inflate_test.dart' as inflate_test;
import 'tests/input_stream_test.dart' as input_stream_test;
import 'tests/io_test.dart' as io_test;
import 'tests/output_stream_test.dart' as output_stream_test;
import 'tests/tar_test.dart' as tar_test;
import 'tests/zip_test.dart' as zip_test;
import 'tests/zlib_test.dart' as zlib_test;
import 'tests/xz_test.dart' as xz_test;

void main() {
  adler32_test.main();
  bzip2_test.main();
  commands_test.main();
  crc32_test.main();
  deflate_test.main();
  gzip_test.main();
  inflate_test.main();
  input_stream_test.main();
  io_test.main();
  output_stream_test.main();
  tar_test.main();
  zip_test.main();
  zlib_test.main();
  xz_test.main();
}
