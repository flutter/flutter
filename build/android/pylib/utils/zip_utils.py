# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import logging
import os
import zipfile


def WriteToZipFile(zip_file, path, arc_path):
  """Recursively write |path| to |zip_file| as |arc_path|.

  zip_file: An open instance of zipfile.ZipFile.
  path: An absolute path to the file or directory to be zipped.
  arc_path: A relative path within the zip file to which the file or directory
    located at |path| should be written.
  """
  if os.path.isdir(path):
    for dir_path, _, file_names in os.walk(path):
      dir_arc_path = os.path.join(arc_path, os.path.relpath(dir_path, path))
      logging.debug('dir:  %s -> %s', dir_path, dir_arc_path)
      zip_file.write(dir_path, dir_arc_path, zipfile.ZIP_STORED)
      for f in file_names:
        file_path = os.path.join(dir_path, f)
        file_arc_path = os.path.join(dir_arc_path, f)
        logging.debug('file: %s -> %s', file_path, file_arc_path)
        zip_file.write(file_path, file_arc_path, zipfile.ZIP_DEFLATED)
  else:
    logging.debug('file: %s -> %s', path, arc_path)
    zip_file.write(path, arc_path, zipfile.ZIP_DEFLATED)

