/// The largest SMI value.
///
/// See <https://www.dartlang.org/articles/numeric-computation/#smis-and-mints>
///
/// When compiling to JavaScript, this value is not supported since it is
/// larger than the maximum safe 32bit integer.
const int kMaxUnsignedSMI = 0x3FFFFFFFFFFFFFFF;