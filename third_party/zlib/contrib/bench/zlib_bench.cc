/*
 * Copyright 2018 The Chromium Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the Chromium source repository LICENSE file.
 *
 * A benchmark test harness for measuring decoding performance of gzip or zlib
 * (deflate) encoded compressed data. Given a file containing any data, encode
 * (compress) it into gzip or zlib format and then decode (uncompress). Output
 * the median and maximum encoding and decoding rates in MB/s.
 *
 * Raw deflate (no gzip or zlib stream wrapper) mode is also supported. Select
 * it with the [raw] argument. Use the [gzip] [zlib] arguments to select those
 * stream wrappers.
 *
 * Note this code can be compiled outside of the Chromium build system against
 * the system zlib (-lz) with g++ or clang++ as follows:
 *
 *   g++|clang++ -O3 -Wall -std=c++11 -lstdc++ -lz zlib_bench.cc
 */

#include <algorithm>
#include <chrono>
#include <fstream>
#include <memory>
#include <string>
#include <vector>

#include <memory.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "zlib.h"

void error_exit(const char* error, int code) {
  fprintf(stderr, "%s (%d)\n", error, code);
  exit(code);
}

inline char* string_data(std::string* s) {
  return s->empty() ? nullptr : &*s->begin();
}

struct Data {
  Data(size_t s) { data.reset(new (std::nothrow) char[size = s]); }
  std::unique_ptr<char[]> data;
  size_t size;
};

Data read_file_data_or_exit(const char* name) {
  std::ifstream file(name, std::ios::in | std::ios::binary);
  if (!file) {
    perror(name);
    exit(1);
  }

  file.seekg(0, std::ios::end);
  Data data(file.tellg());
  file.seekg(0, std::ios::beg);

  if (file && data.data)
    file.read(data.data.get(), data.size);

  if (!file || !data.data || !data.size) {
    perror((std::string("failed: reading ") + name).c_str());
    exit(1);
  }

  return data;
}

size_t zlib_estimate_compressed_size(size_t input_size) {
  return compressBound(input_size);
}

enum zlib_wrapper {
  kWrapperNONE,
  kWrapperZLIB,
  kWrapperGZIP,
  kWrapperZRAW,
};

inline int zlib_stream_wrapper_type(zlib_wrapper type) {
  if (type == kWrapperZLIB) // zlib DEFLATE stream wrapper
    return MAX_WBITS;
  if (type == kWrapperGZIP) // gzip DEFLATE stream wrapper
    return MAX_WBITS + 16;
  if (type == kWrapperZRAW) // no wrapper, use raw DEFLATE
    return -MAX_WBITS;
  error_exit("bad wrapper type", int(type));
  return 0;
}

const char* zlib_wrapper_name(zlib_wrapper type) {
  if (type == kWrapperZLIB)
    return "ZLIB";
  if (type == kWrapperGZIP)
    return "GZIP";
  if (type == kWrapperZRAW)
    return "RAW";
  error_exit("bad wrapper type", int(type));
  return nullptr;
}

static int zlib_strategy = Z_DEFAULT_STRATEGY;

const char* zlib_level_strategy_name(int compression_level) {
  if (compression_level == 0)
    return "";  // strategy is meaningless at level 0
  if (zlib_strategy == Z_HUFFMAN_ONLY)
    return "huffman ";
  if (zlib_strategy == Z_RLE)
    return "rle ";
  if (zlib_strategy == Z_DEFAULT_STRATEGY)
    return "";
  error_exit("bad strategy", zlib_strategy);
  return nullptr;
}

static int zlib_compression_level = Z_DEFAULT_COMPRESSION;

void zlib_compress(
    const zlib_wrapper type,
    const char* input,
    const size_t input_size,
    std::string* output,
    bool resize_output = false)
{
  if (resize_output)
    output->resize(zlib_estimate_compressed_size(input_size));
  size_t output_size = output->size();

  z_stream stream;
  memset(&stream, 0, sizeof(stream));

  int result = deflateInit2(&stream, zlib_compression_level, Z_DEFLATED,
      zlib_stream_wrapper_type(type), MAX_MEM_LEVEL, zlib_strategy);
  if (result != Z_OK)
    error_exit("deflateInit2 failed", result);

  stream.next_out = (Bytef*)string_data(output);
  stream.avail_out = (uInt)output_size;
  stream.next_in = (z_const Bytef*)input;
  stream.avail_in = (uInt)input_size;

  result = deflate(&stream, Z_FINISH);
  if (result == Z_STREAM_END)
    output_size = stream.total_out;
  result |= deflateEnd(&stream);
  if (result != Z_STREAM_END)
    error_exit("compress failed", result);

  if (resize_output)
    output->resize(output_size);
}

void zlib_uncompress(
    const zlib_wrapper type,
    const std::string& input,
    const size_t output_size,
    std::string* output)
{
  z_stream stream;
  memset(&stream, 0, sizeof(stream));

  int result = inflateInit2(&stream, zlib_stream_wrapper_type(type));
  if (result != Z_OK)
    error_exit("inflateInit2 failed", result);

  stream.next_out = (Bytef*)string_data(output);
  stream.avail_out = (uInt)output->size();
  stream.next_in = (z_const Bytef*)input.data();
  stream.avail_in = (uInt)input.size();

  result = inflate(&stream, Z_FINISH);
  if (stream.total_out != output_size)
    result = Z_DATA_ERROR;
  result |= inflateEnd(&stream);
  if (result == Z_STREAM_END)
    return;

  std::string error("uncompress failed: ");
  if (stream.msg)
    error.append(stream.msg);
  error_exit(error.c_str(), result);
}

void verify_equal(const char* input, size_t size, std::string* output) {
  const char* data = string_data(output);
  if (output->size() == size && !memcmp(data, input, size))
    return;
  fprintf(stderr, "uncompressed data does not match the input data\n");
  exit(3);
}

void zlib_file(const char* name, const zlib_wrapper type) {
  /*
   * Read the file data.
   */
  const auto file = read_file_data_or_exit(name);
  const int length = static_cast<int>(file.size);
  const char* data = file.data.get();

  /*
   * Report compression strategy and file name.
   */
  const char* strategy = zlib_level_strategy_name(zlib_compression_level);
  printf("%s%-40s :\n", strategy, name);

  /*
   * Chop the data into blocks.
   */
  const int block_size = 1 << 20;
  const int blocks = (length + block_size - 1) / block_size;

  std::vector<const char*> input(blocks);
  std::vector<size_t> input_length(blocks);
  std::vector<std::string> compressed(blocks);
  std::vector<std::string> output(blocks);

  for (int b = 0; b < blocks; ++b) {
    int input_start = b * block_size;
    int input_limit = std::min<int>((b + 1) * block_size, length);
    input[b] = data + input_start;
    input_length[b] = input_limit - input_start;
  }

  /*
   * Run the zlib compress/uncompress loop a few times with |repeats| to
   * process about 10MB of data if the length is small relative to 10MB.
   * If length is large relative to 10MB, process the data once.
   */
  const int mega_byte = 1024 * 1024;
  const int repeats = (10 * mega_byte + length) / (length + 1);
  const int runs = 5;
  double ctime[runs];
  double utime[runs];

  for (int run = 0; run < runs; ++run) {
    const auto now = [] { return std::chrono::steady_clock::now(); };

    // Pre-grow the output buffer so we don't measure string resize time.
    for (int b = 0; b < blocks; ++b)
      compressed[b].resize(zlib_estimate_compressed_size(block_size));

    auto start = now();
    for (int b = 0; b < blocks; ++b)
      for (int r = 0; r < repeats; ++r)
        zlib_compress(type, input[b], input_length[b], &compressed[b]);
    ctime[run] = std::chrono::duration<double>(now() - start).count();

    // Compress again, resizing compressed, so we don't leave junk at the
    // end of the compressed string that could confuse zlib_uncompress().
    for (int b = 0; b < blocks; ++b)
      zlib_compress(type, input[b], input_length[b], &compressed[b], true);

    for (int b = 0; b < blocks; ++b)
      output[b].resize(input_length[b]);

    start = now();
    for (int r = 0; r < repeats; ++r)
      for (int b = 0; b < blocks; ++b)
        zlib_uncompress(type, compressed[b], input_length[b], &output[b]);
    utime[run] = std::chrono::duration<double>(now() - start).count();

    for (int b = 0; b < blocks; ++b)
      verify_equal(input[b], input_length[b], &output[b]);
  }

  /*
   * Output the median/maximum compress/uncompress rates in MB/s.
   */
  size_t output_length = 0;
  for (size_t i = 0; i < compressed.size(); ++i)
    output_length += compressed[i].size();

  std::sort(ctime, ctime + runs);
  std::sort(utime, utime + runs);

  double deflate_rate_med = length * repeats / mega_byte / ctime[runs / 2];
  double inflate_rate_med = length * repeats / mega_byte / utime[runs / 2];
  double deflate_rate_max = length * repeats / mega_byte / ctime[0];
  double inflate_rate_max = length * repeats / mega_byte / utime[0];

  // type, block size, compression ratio, etc
  printf("%s: [b %dM] bytes %6d -> %6u %4.1f%%",
    zlib_wrapper_name(type), block_size / (1 << 20), length,
    static_cast<unsigned>(output_length), output_length * 100.0 / length);

  // compress / uncompress median (max) rates
  printf(" comp %5.1f (%5.1f) MB/s uncomp %5.1f (%5.1f) MB/s\n",
    deflate_rate_med, deflate_rate_max, inflate_rate_med, inflate_rate_max);
}

static int argn = 1;

char* get_option(int argc, char* argv[], const char* option) {
  if (argn < argc)
    return !strcmp(argv[argn], option) ? argv[argn++] : nullptr;
  return nullptr;
}

bool get_compression(int argc, char* argv[], int* value) {
  if (argn < argc)
    *value = isdigit(argv[argn][0]) ? atoi(argv[argn++]) : -1;
  return *value >= 0 && *value <= 9;
}

void usage_exit(const char* program) {
  printf(
      "usage: %s gzip|zlib|raw [--compression 0:9] [--huffman|--rle] "
      "files...\n",
      program);
  exit(1);
}

int main(int argc, char* argv[]) {
  zlib_wrapper type;
  if (get_option(argc, argv, "zlib"))
    type = kWrapperZLIB;
  else if (get_option(argc, argv, "gzip"))
    type = kWrapperGZIP;
  else if (get_option(argc, argv, "raw"))
    type = kWrapperZRAW;
  else
    usage_exit(argv[0]);

  while (argn < argc && argv[argn][0] == '-') {
    if (get_option(argc, argv, "--compression")) {
      if (!get_compression(argc, argv, &zlib_compression_level))
        usage_exit(argv[0]);
    } else if (get_option(argc, argv, "--huffman")) {
      zlib_strategy = Z_HUFFMAN_ONLY;
    } else if (get_option(argc, argv, "--rle")) {
      zlib_strategy = Z_RLE;
    } else {
      usage_exit(argv[0]);
    }
  }

  if (argn >= argc)
    usage_exit(argv[0]);
  while (argn < argc)
    zlib_file(argv[argn++], type);

  return 0;
}
