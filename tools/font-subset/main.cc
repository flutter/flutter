// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <hb-subset.h>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <limits>
#include <set>
#include <string>

#include "hb_wrappers.h"

hb_codepoint_t ParseCodepoint(const std::string& arg) {
  uint64_t value = 0;
  // Check for \u123, u123, otherwise let strtoul work it out.
  if (arg[0] == 'u') {
    value = strtoul(arg.c_str() + 1, nullptr, 16);
  } else if (arg[0] == '\\' && arg[1] == 'u') {
    value = strtoul(arg.c_str() + 2, nullptr, 16);
  } else {
    value = strtoul(arg.c_str(), nullptr, 0);
  }
  if (value == 0 || value > std::numeric_limits<hb_codepoint_t>::max()) {
    std::cerr << "The value '" << arg << "' (" << value
              << ") could not be parsed as a valid unicode codepoint; aborting."
              << std::endl;
    exit(-1);
  }
  return value;
}

void Usage() {
  std::cout << "Usage:" << std::endl;
  std::cout << "font-subset <output.ttf> <input.ttf>" << std::endl;
  std::cout << std::endl;
  std::cout << "The output.ttf file will be overwritten if it exists already "
               "and the subsetting operation succeeds."
            << std::endl;
  std::cout << "Codepoints should be specified on stdin, separated by spaces, "
               "and must be input as decimal numbers (123), hexidecimal "
               "numbers (0x7B), or unicode hexidecimal characters (\\u7B)."
            << std::endl;
  std::cout << "Input terminates with a newline." << std::endl;
  std::cout
      << "This program will de-duplicate codepoints if the same codepoint is "
         "specified multiple times, e.g. '123 123' will be treated as '123'."
      << std::endl;
}

int main(int argc, char** argv) {
  if (argc != 3) {
    Usage();
    return -1;
  }
  std::string output_file_path(argv[1]);
  std::string input_file_path(argv[2]);
  std::cout << "Using output file: " << output_file_path << std::endl;
  std::cout << "Using source file: " << input_file_path << std::endl;

  HarfbuzzWrappers::HbBlobPtr font_blob(
      hb_blob_create_from_file(input_file_path.c_str()));
  if (!hb_blob_get_length(font_blob.get())) {
    std::cerr << "Failed to load input font " << input_file_path
              << "; aborting. This error indicates that the font is invalid or "
                 "the current version of Harfbuzz is unable to process it."
              << std::endl;
    return -1;
  }

  HarfbuzzWrappers::HbFacePtr font_face(hb_face_create(font_blob.get(), 0));
  if (font_face.get() == hb_face_get_empty()) {
    std::cerr << "Failed to load input font face " << input_file_path
              << "; aborting. This error indicates that the font is invalid or "
                 "the current version of Harfbuzz is unable to process it."
              << std::endl;
    return -1;
  }

  HarfbuzzWrappers::HbSubsetInputPtr input(hb_subset_input_create_or_fail());
  {
    hb_set_t* desired_codepoints = hb_subset_input_unicode_set(input.get());
    HarfbuzzWrappers::HbSetPtr actual_codepoints(hb_set_create());
    hb_face_collect_unicodes(font_face.get(), actual_codepoints.get());
    std::string raw_codepoint;
    while (std::cin >> raw_codepoint) {
      auto codepoint = ParseCodepoint(raw_codepoint);
      if (!codepoint) {
        std::cerr << "Invalid codepoint for " << raw_codepoint << "; exiting."
                  << std::endl;
        return -1;
      }
      if (!hb_set_has(actual_codepoints.get(), codepoint)) {
        std::cerr << "Codepoint " << raw_codepoint
                  << " not found in font, aborting." << std::endl;
        return -1;
      }
      hb_set_add(desired_codepoints, codepoint);
    }
    if (hb_set_is_empty(desired_codepoints)) {
      std::cerr << "No codepoints specified, exiting." << std::endl;
      return -1;
    }
  }

  HarfbuzzWrappers::HbFacePtr new_face(hb_subset(font_face.get(), input.get()));

  if (new_face.get() == hb_face_get_empty()) {
    std::cerr
        << "Failed to subset font; aborting. This error normally indicates "
           "the current version of Harfbuzz is unable to process it."
        << std::endl;
    return -1;
  }

  HarfbuzzWrappers::HbBlobPtr result(hb_face_reference_blob(new_face.get()));
  if (!hb_blob_get_length(result.get())) {
    std::cerr << "Failed get new font bytes; aborting. This error may indicate "
                 "low availability of memory or a bug in Harfbuzz."
              << std::endl;
    return -1;
  }

  unsigned int data_length;
  const char* data = hb_blob_get_data(result.get(), &data_length);

  std::ofstream output_font_file;
  output_font_file.open(output_file_path,
                        std::ios::out | std::ios::trunc | std::ios::binary);
  if (!output_font_file.is_open()) {
    std::cerr << "Failed to open output file '" << output_file_path
              << "'. The parent directory may not exist, or the user does not "
                 "have permission to create this file."
              << std::endl;
    return -1;
  }
  output_font_file.write(data, data_length);
  output_font_file.flush();
  output_font_file.close();

  std::cout << "Wrote " << data_length << " bytes to " << output_file_path
            << std::endl;
  return 0;
}
