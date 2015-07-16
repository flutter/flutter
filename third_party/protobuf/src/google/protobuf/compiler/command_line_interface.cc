// Protocol Buffers - Google's data interchange format
// Copyright 2008 Google Inc.  All rights reserved.
// http://code.google.com/p/protobuf/
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// Author: kenton@google.com (Kenton Varda)
//  Based on original Protocol Buffers design by
//  Sanjay Ghemawat, Jeff Dean, and others.

#include <google/protobuf/compiler/command_line_interface.h>

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#ifdef _MSC_VER
#include <io.h>
#include <direct.h>
#else
#include <unistd.h>
#endif
#include <errno.h>
#include <iostream>
#include <ctype.h>

#include <google/protobuf/stubs/hash.h>

#include <google/protobuf/stubs/common.h>
#include <google/protobuf/compiler/importer.h>
#include <google/protobuf/compiler/code_generator.h>
#include <google/protobuf/compiler/plugin.pb.h>
#include <google/protobuf/compiler/subprocess.h>
#include <google/protobuf/compiler/zip_writer.h>
#include <google/protobuf/descriptor.h>
#include <google/protobuf/text_format.h>
#include <google/protobuf/dynamic_message.h>
#include <google/protobuf/io/coded_stream.h>
#include <google/protobuf/io/zero_copy_stream_impl.h>
#include <google/protobuf/io/printer.h>
#include <google/protobuf/stubs/strutil.h>
#include <google/protobuf/stubs/substitute.h>
#include <google/protobuf/stubs/map-util.h>
#include <google/protobuf/stubs/stl_util.h>


namespace google {
namespace protobuf {
namespace compiler {

#if defined(_WIN32)
#define mkdir(name, mode) mkdir(name)
#ifndef W_OK
#define W_OK 02  // not defined by MSVC for whatever reason
#endif
#ifndef F_OK
#define F_OK 00  // not defined by MSVC for whatever reason
#endif
#ifndef STDIN_FILENO
#define STDIN_FILENO 0
#endif
#ifndef STDOUT_FILENO
#define STDOUT_FILENO 1
#endif
#endif

#ifndef O_BINARY
#ifdef _O_BINARY
#define O_BINARY _O_BINARY
#else
#define O_BINARY 0     // If this isn't defined, the platform doesn't need it.
#endif
#endif

namespace {
#if defined(_WIN32) && !defined(__CYGWIN__)
static const char* kPathSeparator = ";";
#else
static const char* kPathSeparator = ":";
#endif

// Returns true if the text looks like a Windows-style absolute path, starting
// with a drive letter.  Example:  "C:\foo".  TODO(kenton):  Share this with
// copy in importer.cc?
static bool IsWindowsAbsolutePath(const string& text) {
#if defined(_WIN32) || defined(__CYGWIN__)
  return text.size() >= 3 && text[1] == ':' &&
         isalpha(text[0]) &&
         (text[2] == '/' || text[2] == '\\') &&
         text.find_last_of(':') == 1;
#else
  return false;
#endif
}

void SetFdToTextMode(int fd) {
#ifdef _WIN32
  if (_setmode(fd, _O_TEXT) == -1) {
    // This should never happen, I think.
    GOOGLE_LOG(WARNING) << "_setmode(" << fd << ", _O_TEXT): " << strerror(errno);
  }
#endif
  // (Text and binary are the same on non-Windows platforms.)
}

void SetFdToBinaryMode(int fd) {
#ifdef _WIN32
  if (_setmode(fd, _O_BINARY) == -1) {
    // This should never happen, I think.
    GOOGLE_LOG(WARNING) << "_setmode(" << fd << ", _O_BINARY): " << strerror(errno);
  }
#endif
  // (Text and binary are the same on non-Windows platforms.)
}

void AddTrailingSlash(string* path) {
  if (!path->empty() && path->at(path->size() - 1) != '/') {
    path->push_back('/');
  }
}

bool VerifyDirectoryExists(const string& path) {
  if (path.empty()) return true;

  if (access(path.c_str(), F_OK) == -1) {
    cerr << path << ": " << strerror(errno) << endl;
    return false;
  } else {
    return true;
  }
}

// Try to create the parent directory of the given file, creating the parent's
// parent if necessary, and so on.  The full file name is actually
// (prefix + filename), but we assume |prefix| already exists and only create
// directories listed in |filename|.
bool TryCreateParentDirectory(const string& prefix, const string& filename) {
  // Recursively create parent directories to the output file.
  vector<string> parts;
  SplitStringUsing(filename, "/", &parts);
  string path_so_far = prefix;
  for (int i = 0; i < parts.size() - 1; i++) {
    path_so_far += parts[i];
    if (mkdir(path_so_far.c_str(), 0777) != 0) {
      if (errno != EEXIST) {
        cerr << filename << ": while trying to create directory "
             << path_so_far << ": " << strerror(errno) << endl;
        return false;
      }
    }
    path_so_far += '/';
  }

  return true;
}

}  // namespace

// A MultiFileErrorCollector that prints errors to stderr.
class CommandLineInterface::ErrorPrinter : public MultiFileErrorCollector,
                                           public io::ErrorCollector {
 public:
  ErrorPrinter(ErrorFormat format, DiskSourceTree *tree = NULL)
    : format_(format), tree_(tree) {}
  ~ErrorPrinter() {}

  // implements MultiFileErrorCollector ------------------------------
  void AddError(const string& filename, int line, int column,
                const string& message) {

    // Print full path when running under MSVS
    string dfile;
    if (format_ == CommandLineInterface::ERROR_FORMAT_MSVS &&
        tree_ != NULL &&
        tree_->VirtualFileToDiskFile(filename, &dfile)) {
      cerr << dfile;
    } else {
      cerr << filename;
    }

    // Users typically expect 1-based line/column numbers, so we add 1
    // to each here.
    if (line != -1) {
      // Allow for both GCC- and Visual-Studio-compatible output.
      switch (format_) {
        case CommandLineInterface::ERROR_FORMAT_GCC:
          cerr << ":" << (line + 1) << ":" << (column + 1);
          break;
        case CommandLineInterface::ERROR_FORMAT_MSVS:
          cerr << "(" << (line + 1) << ") : error in column=" << (column + 1);
          break;
      }
    }

    cerr << ": " << message << endl;
  }

  // implements io::ErrorCollector -----------------------------------
  void AddError(int line, int column, const string& message) {
    AddError("input", line, column, message);
  }

 private:
  const ErrorFormat format_;
  DiskSourceTree *tree_;
};

// -------------------------------------------------------------------

// A GeneratorContext implementation that buffers files in memory, then dumps
// them all to disk on demand.
class CommandLineInterface::GeneratorContextImpl : public GeneratorContext {
 public:
  GeneratorContextImpl(const vector<const FileDescriptor*>& parsed_files);
  ~GeneratorContextImpl();

  // Write all files in the directory to disk at the given output location,
  // which must end in a '/'.
  bool WriteAllToDisk(const string& prefix);

  // Write the contents of this directory to a ZIP-format archive with the
  // given name.
  bool WriteAllToZip(const string& filename);

  // Add a boilerplate META-INF/MANIFEST.MF file as required by the Java JAR
  // format, unless one has already been written.
  void AddJarManifest();

  // implements GeneratorContext --------------------------------------
  io::ZeroCopyOutputStream* Open(const string& filename);
  io::ZeroCopyOutputStream* OpenForInsert(
      const string& filename, const string& insertion_point);
  void ListParsedFiles(vector<const FileDescriptor*>* output) {
    *output = parsed_files_;
  }

 private:
  friend class MemoryOutputStream;

  // map instead of hash_map so that files are written in order (good when
  // writing zips).
  map<string, string*> files_;
  const vector<const FileDescriptor*>& parsed_files_;
  bool had_error_;
};

class CommandLineInterface::MemoryOutputStream
    : public io::ZeroCopyOutputStream {
 public:
  MemoryOutputStream(GeneratorContextImpl* directory, const string& filename);
  MemoryOutputStream(GeneratorContextImpl* directory, const string& filename,
                     const string& insertion_point);
  virtual ~MemoryOutputStream();

  // implements ZeroCopyOutputStream ---------------------------------
  virtual bool Next(void** data, int* size) { return inner_->Next(data, size); }
  virtual void BackUp(int count)            {        inner_->BackUp(count);    }
  virtual int64 ByteCount() const           { return inner_->ByteCount();      }

 private:
  // Where to insert the string when it's done.
  GeneratorContextImpl* directory_;
  string filename_;
  string insertion_point_;

  // The string we're building.
  string data_;

  // StringOutputStream writing to data_.
  scoped_ptr<io::StringOutputStream> inner_;
};

// -------------------------------------------------------------------

CommandLineInterface::GeneratorContextImpl::GeneratorContextImpl(
    const vector<const FileDescriptor*>& parsed_files)
    : parsed_files_(parsed_files),
      had_error_(false) {
}

CommandLineInterface::GeneratorContextImpl::~GeneratorContextImpl() {
  STLDeleteValues(&files_);
}

bool CommandLineInterface::GeneratorContextImpl::WriteAllToDisk(
    const string& prefix) {
  if (had_error_) {
    return false;
  }

  if (!VerifyDirectoryExists(prefix)) {
    return false;
  }

  for (map<string, string*>::const_iterator iter = files_.begin();
       iter != files_.end(); ++iter) {
    const string& relative_filename = iter->first;
    const char* data = iter->second->data();
    int size = iter->second->size();

    if (!TryCreateParentDirectory(prefix, relative_filename)) {
      return false;
    }
    string filename = prefix + relative_filename;

    // Create the output file.
    int file_descriptor;
    do {
      file_descriptor =
        open(filename.c_str(), O_WRONLY | O_CREAT | O_TRUNC | O_BINARY, 0666);
    } while (file_descriptor < 0 && errno == EINTR);

    if (file_descriptor < 0) {
      int error = errno;
      cerr << filename << ": " << strerror(error);
      return false;
    }

    // Write the file.
    while (size > 0) {
      int write_result;
      do {
        write_result = write(file_descriptor, data, size);
      } while (write_result < 0 && errno == EINTR);

      if (write_result <= 0) {
        // Write error.

        // FIXME(kenton):  According to the man page, if write() returns zero,
        //   there was no error; write() simply did not write anything.  It's
        //   unclear under what circumstances this might happen, but presumably
        //   errno won't be set in this case.  I am confused as to how such an
        //   event should be handled.  For now I'm treating it as an error,
        //   since retrying seems like it could lead to an infinite loop.  I
        //   suspect this never actually happens anyway.

        if (write_result < 0) {
          int error = errno;
          cerr << filename << ": write: " << strerror(error);
        } else {
          cerr << filename << ": write() returned zero?" << endl;
        }
        return false;
      }

      data += write_result;
      size -= write_result;
    }

    if (close(file_descriptor) != 0) {
      int error = errno;
      cerr << filename << ": close: " << strerror(error);
      return false;
    }
  }

  return true;
}

bool CommandLineInterface::GeneratorContextImpl::WriteAllToZip(
    const string& filename) {
  if (had_error_) {
    return false;
  }

  // Create the output file.
  int file_descriptor;
  do {
    file_descriptor =
      open(filename.c_str(), O_WRONLY | O_CREAT | O_TRUNC | O_BINARY, 0666);
  } while (file_descriptor < 0 && errno == EINTR);

  if (file_descriptor < 0) {
    int error = errno;
    cerr << filename << ": " << strerror(error);
    return false;
  }

  // Create the ZipWriter
  io::FileOutputStream stream(file_descriptor);
  ZipWriter zip_writer(&stream);

  for (map<string, string*>::const_iterator iter = files_.begin();
       iter != files_.end(); ++iter) {
    zip_writer.Write(iter->first, *iter->second);
  }

  zip_writer.WriteDirectory();

  if (stream.GetErrno() != 0) {
    cerr << filename << ": " << strerror(stream.GetErrno()) << endl;
  }

  if (!stream.Close()) {
    cerr << filename << ": " << strerror(stream.GetErrno()) << endl;
  }

  return true;
}

void CommandLineInterface::GeneratorContextImpl::AddJarManifest() {
  string** map_slot = &files_["META-INF/MANIFEST.MF"];
  if (*map_slot == NULL) {
    *map_slot = new string(
        "Manifest-Version: 1.0\n"
        "Created-By: 1.6.0 (protoc)\n"
        "\n");
  }
}

io::ZeroCopyOutputStream* CommandLineInterface::GeneratorContextImpl::Open(
    const string& filename) {
  return new MemoryOutputStream(this, filename);
}

io::ZeroCopyOutputStream*
CommandLineInterface::GeneratorContextImpl::OpenForInsert(
    const string& filename, const string& insertion_point) {
  return new MemoryOutputStream(this, filename, insertion_point);
}

// -------------------------------------------------------------------

CommandLineInterface::MemoryOutputStream::MemoryOutputStream(
    GeneratorContextImpl* directory, const string& filename)
    : directory_(directory),
      filename_(filename),
      inner_(new io::StringOutputStream(&data_)) {
}

CommandLineInterface::MemoryOutputStream::MemoryOutputStream(
    GeneratorContextImpl* directory, const string& filename,
    const string& insertion_point)
    : directory_(directory),
      filename_(filename),
      insertion_point_(insertion_point),
      inner_(new io::StringOutputStream(&data_)) {
}

CommandLineInterface::MemoryOutputStream::~MemoryOutputStream() {
  // Make sure all data has been written.
  inner_.reset();

  // Insert into the directory.
  string** map_slot = &directory_->files_[filename_];

  if (insertion_point_.empty()) {
    // This was just a regular Open().
    if (*map_slot != NULL) {
      cerr << filename_ << ": Tried to write the same file twice." << endl;
      directory_->had_error_ = true;
      return;
    }

    *map_slot = new string;
    (*map_slot)->swap(data_);
  } else {
    // This was an OpenForInsert().

    // If the data doens't end with a clean line break, add one.
    if (!data_.empty() && data_[data_.size() - 1] != '\n') {
      data_.push_back('\n');
    }

    // Find the file we are going to insert into.
    if (*map_slot == NULL) {
      cerr << filename_ << ": Tried to insert into file that doesn't exist."
           << endl;
      directory_->had_error_ = true;
      return;
    }
    string* target = *map_slot;

    // Find the insertion point.
    string magic_string = strings::Substitute(
        "@@protoc_insertion_point($0)", insertion_point_);
    string::size_type pos = target->find(magic_string);

    if (pos == string::npos) {
      cerr << filename_ << ": insertion point \"" << insertion_point_
           << "\" not found." << endl;
      directory_->had_error_ = true;
      return;
    }

    // Seek backwards to the beginning of the line, which is where we will
    // insert the data.  Note that this has the effect of pushing the insertion
    // point down, so the data is inserted before it.  This is intentional
    // because it means that multiple insertions at the same point will end
    // up in the expected order in the final output.
    pos = target->find_last_of('\n', pos);
    if (pos == string::npos) {
      // Insertion point is on the first line.
      pos = 0;
    } else {
      // Advance to character after '\n'.
      ++pos;
    }

    // Extract indent.
    string indent_(*target, pos, target->find_first_not_of(" \t", pos) - pos);

    if (indent_.empty()) {
      // No indent.  This makes things easier.
      target->insert(pos, data_);
    } else {
      // Calculate how much space we need.
      int indent_size = 0;
      for (int i = 0; i < data_.size(); i++) {
        if (data_[i] == '\n') indent_size += indent_.size();
      }

      // Make a hole for it.
      target->insert(pos, data_.size() + indent_size, '\0');

      // Now copy in the data.
      string::size_type data_pos = 0;
      char* target_ptr = string_as_array(target) + pos;
      while (data_pos < data_.size()) {
        // Copy indent.
        memcpy(target_ptr, indent_.data(), indent_.size());
        target_ptr += indent_.size();

        // Copy line from data_.
        // We already guaranteed that data_ ends with a newline (above), so this
        // search can't fail.
        string::size_type line_length =
            data_.find_first_of('\n', data_pos) + 1 - data_pos;
        memcpy(target_ptr, data_.data() + data_pos, line_length);
        target_ptr += line_length;
        data_pos += line_length;
      }

      GOOGLE_CHECK_EQ(target_ptr,
          string_as_array(target) + pos + data_.size() + indent_size);
    }
  }
}

// ===================================================================

CommandLineInterface::CommandLineInterface()
  : mode_(MODE_COMPILE),
    error_format_(ERROR_FORMAT_GCC),
    imports_in_descriptor_set_(false),
    source_info_in_descriptor_set_(false),
    disallow_services_(false),
    inputs_are_proto_path_relative_(false) {}
CommandLineInterface::~CommandLineInterface() {}

void CommandLineInterface::RegisterGenerator(const string& flag_name,
                                             CodeGenerator* generator,
                                             const string& help_text) {
  GeneratorInfo info;
  info.flag_name = flag_name;
  info.generator = generator;
  info.help_text = help_text;
  generators_by_flag_name_[flag_name] = info;
}

void CommandLineInterface::RegisterGenerator(const string& flag_name,
                                             const string& option_flag_name,
                                             CodeGenerator* generator,
                                             const string& help_text) {
  GeneratorInfo info;
  info.flag_name = flag_name;
  info.option_flag_name = option_flag_name;
  info.generator = generator;
  info.help_text = help_text;
  generators_by_flag_name_[flag_name] = info;
  generators_by_option_name_[option_flag_name] = info;
}

void CommandLineInterface::AllowPlugins(const string& exe_name_prefix) {
  plugin_prefix_ = exe_name_prefix;
}

int CommandLineInterface::Run(int argc, const char* const argv[]) {
  Clear();
  switch (ParseArguments(argc, argv)) {
    case PARSE_ARGUMENT_DONE_AND_EXIT:
      return 0;
    case PARSE_ARGUMENT_FAIL:
      return 1;
    case PARSE_ARGUMENT_DONE_AND_CONTINUE:
      break;
  }

  // Set up the source tree.
  DiskSourceTree source_tree;
  for (int i = 0; i < proto_path_.size(); i++) {
    source_tree.MapPath(proto_path_[i].first, proto_path_[i].second);
  }

  // Map input files to virtual paths if necessary.
  if (!inputs_are_proto_path_relative_) {
    if (!MakeInputsBeProtoPathRelative(&source_tree)) {
      return 1;
    }
  }

  // Allocate the Importer.
  ErrorPrinter error_collector(error_format_, &source_tree);
  Importer importer(&source_tree, &error_collector);

  vector<const FileDescriptor*> parsed_files;

  // Parse each file.
  for (int i = 0; i < input_files_.size(); i++) {
    // Import the file.
    const FileDescriptor* parsed_file = importer.Import(input_files_[i]);
    if (parsed_file == NULL) return 1;
    parsed_files.push_back(parsed_file);

    // Enforce --disallow_services.
    if (disallow_services_ && parsed_file->service_count() > 0) {
      cerr << parsed_file->name() << ": This file contains services, but "
              "--disallow_services was used." << endl;
      return 1;
    }
  }

  // We construct a separate GeneratorContext for each output location.  Note
  // that two code generators may output to the same location, in which case
  // they should share a single GeneratorContext so that OpenForInsert() works.
  typedef hash_map<string, GeneratorContextImpl*> GeneratorContextMap;
  GeneratorContextMap output_directories;

  // Generate output.
  if (mode_ == MODE_COMPILE) {
    for (int i = 0; i < output_directives_.size(); i++) {
      string output_location = output_directives_[i].output_location;
      if (!HasSuffixString(output_location, ".zip") &&
          !HasSuffixString(output_location, ".jar")) {
        AddTrailingSlash(&output_location);
      }
      GeneratorContextImpl** map_slot = &output_directories[output_location];

      if (*map_slot == NULL) {
        // First time we've seen this output location.
        *map_slot = new GeneratorContextImpl(parsed_files);
      }

      if (!GenerateOutput(parsed_files, output_directives_[i], *map_slot)) {
        STLDeleteValues(&output_directories);
        return 1;
      }
    }
  }

  // Write all output to disk.
  for (GeneratorContextMap::iterator iter = output_directories.begin();
       iter != output_directories.end(); ++iter) {
    const string& location = iter->first;
    GeneratorContextImpl* directory = iter->second;
    if (HasSuffixString(location, "/")) {
      if (!directory->WriteAllToDisk(location)) {
        STLDeleteValues(&output_directories);
        return 1;
      }
    } else {
      if (HasSuffixString(location, ".jar")) {
        directory->AddJarManifest();
      }

      if (!directory->WriteAllToZip(location)) {
        STLDeleteValues(&output_directories);
        return 1;
      }
    }
  }

  STLDeleteValues(&output_directories);

  if (!descriptor_set_name_.empty()) {
    if (!WriteDescriptorSet(parsed_files)) {
      return 1;
    }
  }

  if (mode_ == MODE_ENCODE || mode_ == MODE_DECODE) {
    if (codec_type_.empty()) {
      // HACK:  Define an EmptyMessage type to use for decoding.
      DescriptorPool pool;
      FileDescriptorProto file;
      file.set_name("empty_message.proto");
      file.add_message_type()->set_name("EmptyMessage");
      GOOGLE_CHECK(pool.BuildFile(file) != NULL);
      codec_type_ = "EmptyMessage";
      if (!EncodeOrDecode(&pool)) {
        return 1;
      }
    } else {
      if (!EncodeOrDecode(importer.pool())) {
        return 1;
      }
    }
  }

  return 0;
}

void CommandLineInterface::Clear() {
  // Clear all members that are set by Run().  Note that we must not clear
  // members which are set by other methods before Run() is called.
  executable_name_.clear();
  proto_path_.clear();
  input_files_.clear();
  output_directives_.clear();
  codec_type_.clear();
  descriptor_set_name_.clear();

  mode_ = MODE_COMPILE;
  imports_in_descriptor_set_ = false;
  source_info_in_descriptor_set_ = false;
  disallow_services_ = false;
}

bool CommandLineInterface::MakeInputsBeProtoPathRelative(
    DiskSourceTree* source_tree) {
  for (int i = 0; i < input_files_.size(); i++) {
    string virtual_file, shadowing_disk_file;
    switch (source_tree->DiskFileToVirtualFile(
        input_files_[i], &virtual_file, &shadowing_disk_file)) {
      case DiskSourceTree::SUCCESS:
        input_files_[i] = virtual_file;
        break;
      case DiskSourceTree::SHADOWED:
        cerr << input_files_[i] << ": Input is shadowed in the --proto_path "
                "by \"" << shadowing_disk_file << "\".  Either use the latter "
                "file as your input or reorder the --proto_path so that the "
                "former file's location comes first." << endl;
        return false;
      case DiskSourceTree::CANNOT_OPEN:
        cerr << input_files_[i] << ": " << strerror(errno) << endl;
        return false;
      case DiskSourceTree::NO_MAPPING:
        // First check if the file exists at all.
        if (access(input_files_[i].c_str(), F_OK) < 0) {
          // File does not even exist.
          cerr << input_files_[i] << ": " << strerror(ENOENT) << endl;
        } else {
          cerr << input_files_[i] << ": File does not reside within any path "
                  "specified using --proto_path (or -I).  You must specify a "
                  "--proto_path which encompasses this file.  Note that the "
                  "proto_path must be an exact prefix of the .proto file "
                  "names -- protoc is too dumb to figure out when two paths "
                  "(e.g. absolute and relative) are equivalent (it's harder "
                  "than you think)." << endl;
        }
        return false;
    }
  }

  return true;
}

CommandLineInterface::ParseArgumentStatus
CommandLineInterface::ParseArguments(int argc, const char* const argv[]) {
  executable_name_ = argv[0];

  // Iterate through all arguments and parse them.
  for (int i = 1; i < argc; i++) {
    string name, value;

    if (ParseArgument(argv[i], &name, &value)) {
      // Returned true => Use the next argument as the flag value.
      if (i + 1 == argc || argv[i+1][0] == '-') {
        cerr << "Missing value for flag: " << name << endl;
        if (name == "--decode") {
          cerr << "To decode an unknown message, use --decode_raw." << endl;
        }
        return PARSE_ARGUMENT_FAIL;
      } else {
        ++i;
        value = argv[i];
      }
    }

    ParseArgumentStatus status = InterpretArgument(name, value);
    if (status != PARSE_ARGUMENT_DONE_AND_CONTINUE)
      return status;
  }

  // If no --proto_path was given, use the current working directory.
  if (proto_path_.empty()) {
    // Don't use make_pair as the old/default standard library on Solaris
    // doesn't support it without explicit template parameters, which are
    // incompatible with C++0x's make_pair.
    proto_path_.push_back(pair<string, string>("", "."));
  }

  // Check some errror cases.
  bool decoding_raw = (mode_ == MODE_DECODE) && codec_type_.empty();
  if (decoding_raw && !input_files_.empty()) {
    cerr << "When using --decode_raw, no input files should be given." << endl;
    return PARSE_ARGUMENT_FAIL;
  } else if (!decoding_raw && input_files_.empty()) {
    cerr << "Missing input file." << endl;
    return PARSE_ARGUMENT_FAIL;
  }
  if (mode_ == MODE_COMPILE && output_directives_.empty() &&
      descriptor_set_name_.empty()) {
    cerr << "Missing output directives." << endl;
    return PARSE_ARGUMENT_FAIL;
  }
  if (imports_in_descriptor_set_ && descriptor_set_name_.empty()) {
    cerr << "--include_imports only makes sense when combined with "
            "--descriptor_set_out." << endl;
  }
  if (source_info_in_descriptor_set_ && descriptor_set_name_.empty()) {
    cerr << "--include_source_info only makes sense when combined with "
            "--descriptor_set_out." << endl;
  }

  return PARSE_ARGUMENT_DONE_AND_CONTINUE;
}

bool CommandLineInterface::ParseArgument(const char* arg,
                                         string* name, string* value) {
  bool parsed_value = false;

  if (arg[0] != '-') {
    // Not a flag.
    name->clear();
    parsed_value = true;
    *value = arg;
  } else if (arg[1] == '-') {
    // Two dashes:  Multi-character name, with '=' separating name and
    //   value.
    const char* equals_pos = strchr(arg, '=');
    if (equals_pos != NULL) {
      *name = string(arg, equals_pos - arg);
      *value = equals_pos + 1;
      parsed_value = true;
    } else {
      *name = arg;
    }
  } else {
    // One dash:  One-character name, all subsequent characters are the
    //   value.
    if (arg[1] == '\0') {
      // arg is just "-".  We treat this as an input file, except that at
      // present this will just lead to a "file not found" error.
      name->clear();
      *value = arg;
      parsed_value = true;
    } else {
      *name = string(arg, 2);
      *value = arg + 2;
      parsed_value = !value->empty();
    }
  }

  // Need to return true iff the next arg should be used as the value for this
  // one, false otherwise.

  if (parsed_value) {
    // We already parsed a value for this flag.
    return false;
  }

  if (*name == "-h" || *name == "--help" ||
      *name == "--disallow_services" ||
      *name == "--include_imports" ||
      *name == "--include_source_info" ||
      *name == "--version" ||
      *name == "--decode_raw") {
    // HACK:  These are the only flags that don't take a value.
    //   They probably should not be hard-coded like this but for now it's
    //   not worth doing better.
    return false;
  }

  // Next argument is the flag value.
  return true;
}

CommandLineInterface::ParseArgumentStatus
CommandLineInterface::InterpretArgument(const string& name,
                                        const string& value) {
  if (name.empty()) {
    // Not a flag.  Just a filename.
    if (value.empty()) {
      cerr << "You seem to have passed an empty string as one of the "
              "arguments to " << executable_name_ << ".  This is actually "
              "sort of hard to do.  Congrats.  Unfortunately it is not valid "
              "input so the program is going to die now." << endl;
      return PARSE_ARGUMENT_FAIL;
    }

    input_files_.push_back(value);

  } else if (name == "-I" || name == "--proto_path") {
    // Java's -classpath (and some other languages) delimits path components
    // with colons.  Let's accept that syntax too just to make things more
    // intuitive.
    vector<string> parts;
    SplitStringUsing(value, kPathSeparator, &parts);

    for (int i = 0; i < parts.size(); i++) {
      string virtual_path;
      string disk_path;

      string::size_type equals_pos = parts[i].find_first_of('=');
      if (equals_pos == string::npos) {
        virtual_path = "";
        disk_path = parts[i];
      } else {
        virtual_path = parts[i].substr(0, equals_pos);
        disk_path = parts[i].substr(equals_pos + 1);
      }

      if (disk_path.empty()) {
        cerr << "--proto_path passed empty directory name.  (Use \".\" for "
                "current directory.)" << endl;
        return PARSE_ARGUMENT_FAIL;
      }

      // Make sure disk path exists, warn otherwise.
      if (access(disk_path.c_str(), F_OK) < 0) {
        cerr << disk_path << ": warning: directory does not exist." << endl;
      }

      // Don't use make_pair as the old/default standard library on Solaris
      // doesn't support it without explicit template parameters, which are
      // incompatible with C++0x's make_pair.
      proto_path_.push_back(pair<string, string>(virtual_path, disk_path));
    }

  } else if (name == "-o" || name == "--descriptor_set_out") {
    if (!descriptor_set_name_.empty()) {
      cerr << name << " may only be passed once." << endl;
      return PARSE_ARGUMENT_FAIL;
    }
    if (value.empty()) {
      cerr << name << " requires a non-empty value." << endl;
      return PARSE_ARGUMENT_FAIL;
    }
    if (mode_ != MODE_COMPILE) {
      cerr << "Cannot use --encode or --decode and generate descriptors at the "
              "same time." << endl;
      return PARSE_ARGUMENT_FAIL;
    }
    descriptor_set_name_ = value;

  } else if (name == "--include_imports") {
    if (imports_in_descriptor_set_) {
      cerr << name << " may only be passed once." << endl;
      return PARSE_ARGUMENT_FAIL;
    }
    imports_in_descriptor_set_ = true;

  } else if (name == "--include_source_info") {
    if (source_info_in_descriptor_set_) {
      cerr << name << " may only be passed once." << endl;
      return PARSE_ARGUMENT_FAIL;
    }
    source_info_in_descriptor_set_ = true;

  } else if (name == "-h" || name == "--help") {
    PrintHelpText();
    return PARSE_ARGUMENT_DONE_AND_EXIT;  // Exit without running compiler.

  } else if (name == "--version") {
    if (!version_info_.empty()) {
      cout << version_info_ << endl;
    }
    cout << "libprotoc "
         << protobuf::internal::VersionString(GOOGLE_PROTOBUF_VERSION)
         << endl;
    return PARSE_ARGUMENT_DONE_AND_EXIT;  // Exit without running compiler.

  } else if (name == "--disallow_services") {
    disallow_services_ = true;

  } else if (name == "--encode" || name == "--decode" ||
             name == "--decode_raw") {
    if (mode_ != MODE_COMPILE) {
      cerr << "Only one of --encode and --decode can be specified." << endl;
      return PARSE_ARGUMENT_FAIL;
    }
    if (!output_directives_.empty() || !descriptor_set_name_.empty()) {
      cerr << "Cannot use " << name
           << " and generate code or descriptors at the same time." << endl;
      return PARSE_ARGUMENT_FAIL;
    }

    mode_ = (name == "--encode") ? MODE_ENCODE : MODE_DECODE;

    if (value.empty() && name != "--decode_raw") {
      cerr << "Type name for " << name << " cannot be blank." << endl;
      if (name == "--decode") {
        cerr << "To decode an unknown message, use --decode_raw." << endl;
      }
      return PARSE_ARGUMENT_FAIL;
    } else if (!value.empty() && name == "--decode_raw") {
      cerr << "--decode_raw does not take a parameter." << endl;
      return PARSE_ARGUMENT_FAIL;
    }

    codec_type_ = value;

  } else if (name == "--error_format") {
    if (value == "gcc") {
      error_format_ = ERROR_FORMAT_GCC;
    } else if (value == "msvs") {
      error_format_ = ERROR_FORMAT_MSVS;
    } else {
      cerr << "Unknown error format: " << value << endl;
      return PARSE_ARGUMENT_FAIL;
    }

  } else if (name == "--plugin") {
    if (plugin_prefix_.empty()) {
      cerr << "This compiler does not support plugins." << endl;
      return PARSE_ARGUMENT_FAIL;
    }

    string plugin_name;
    string path;

    string::size_type equals_pos = value.find_first_of('=');
    if (equals_pos == string::npos) {
      // Use the basename of the file.
      string::size_type slash_pos = value.find_last_of('/');
      if (slash_pos == string::npos) {
        plugin_name = value;
      } else {
        plugin_name = value.substr(slash_pos + 1);
      }
      path = value;
    } else {
      plugin_name = value.substr(0, equals_pos);
      path = value.substr(equals_pos + 1);
    }

    plugins_[plugin_name] = path;

  } else {
    // Some other flag.  Look it up in the generators list.
    const GeneratorInfo* generator_info =
        FindOrNull(generators_by_flag_name_, name);
    if (generator_info == NULL &&
        (plugin_prefix_.empty() || !HasSuffixString(name, "_out"))) {
      // Check if it's a generator option flag.
      generator_info = FindOrNull(generators_by_option_name_, name);
      if (generator_info == NULL) {
        cerr << "Unknown flag: " << name << endl;
        return PARSE_ARGUMENT_FAIL;
      } else {
        string* parameters = &generator_parameters_[generator_info->flag_name];
        if (!parameters->empty()) {
          parameters->append(",");
        }
        parameters->append(value);
      }
    } else {
      // It's an output flag.  Add it to the output directives.
      if (mode_ != MODE_COMPILE) {
        cerr << "Cannot use --encode or --decode and generate code at the "
                "same time." << endl;
        return PARSE_ARGUMENT_FAIL;
      }

      OutputDirective directive;
      directive.name = name;
      if (generator_info == NULL) {
        directive.generator = NULL;
      } else {
        directive.generator = generator_info->generator;
      }

      // Split value at ':' to separate the generator parameter from the
      // filename.  However, avoid doing this if the colon is part of a valid
      // Windows-style absolute path.
      string::size_type colon_pos = value.find_first_of(':');
      if (colon_pos == string::npos || IsWindowsAbsolutePath(value)) {
        directive.output_location = value;
      } else {
        directive.parameter = value.substr(0, colon_pos);
        directive.output_location = value.substr(colon_pos + 1);
      }

      output_directives_.push_back(directive);
    }
  }

  return PARSE_ARGUMENT_DONE_AND_CONTINUE;
}

void CommandLineInterface::PrintHelpText() {
  // Sorry for indentation here; line wrapping would be uglier.
  cerr <<
"Usage: " << executable_name_ << " [OPTION] PROTO_FILES\n"
"Parse PROTO_FILES and generate output based on the options given:\n"
"  -IPATH, --proto_path=PATH   Specify the directory in which to search for\n"
"                              imports.  May be specified multiple times;\n"
"                              directories will be searched in order.  If not\n"
"                              given, the current working directory is used.\n"
"  --version                   Show version info and exit.\n"
"  -h, --help                  Show this text and exit.\n"
"  --encode=MESSAGE_TYPE       Read a text-format message of the given type\n"
"                              from standard input and write it in binary\n"
"                              to standard output.  The message type must\n"
"                              be defined in PROTO_FILES or their imports.\n"
"  --decode=MESSAGE_TYPE       Read a binary message of the given type from\n"
"                              standard input and write it in text format\n"
"                              to standard output.  The message type must\n"
"                              be defined in PROTO_FILES or their imports.\n"
"  --decode_raw                Read an arbitrary protocol message from\n"
"                              standard input and write the raw tag/value\n"
"                              pairs in text format to standard output.  No\n"
"                              PROTO_FILES should be given when using this\n"
"                              flag.\n"
"  -oFILE,                     Writes a FileDescriptorSet (a protocol buffer,\n"
"    --descriptor_set_out=FILE defined in descriptor.proto) containing all of\n"
"                              the input files to FILE.\n"
"  --include_imports           When using --descriptor_set_out, also include\n"
"                              all dependencies of the input files in the\n"
"                              set, so that the set is self-contained.\n"
"  --include_source_info       When using --descriptor_set_out, do not strip\n"
"                              SourceCodeInfo from the FileDescriptorProto.\n"
"                              This results in vastly larger descriptors that\n"
"                              include information about the original\n"
"                              location of each decl in the source file as\n"
"                              well as surrounding comments.\n"
"  --error_format=FORMAT       Set the format in which to print errors.\n"
"                              FORMAT may be 'gcc' (the default) or 'msvs'\n"
"                              (Microsoft Visual Studio format)." << endl;
  if (!plugin_prefix_.empty()) {
    cerr <<
"  --plugin=EXECUTABLE         Specifies a plugin executable to use.\n"
"                              Normally, protoc searches the PATH for\n"
"                              plugins, but you may specify additional\n"
"                              executables not in the path using this flag.\n"
"                              Additionally, EXECUTABLE may be of the form\n"
"                              NAME=PATH, in which case the given plugin name\n"
"                              is mapped to the given executable even if\n"
"                              the executable's own name differs." << endl;
  }

  for (GeneratorMap::iterator iter = generators_by_flag_name_.begin();
       iter != generators_by_flag_name_.end(); ++iter) {
    // FIXME(kenton):  If the text is long enough it will wrap, which is ugly,
    //   but fixing this nicely (e.g. splitting on spaces) is probably more
    //   trouble than it's worth.
    cerr << "  " << iter->first << "=OUT_DIR "
         << string(19 - iter->first.size(), ' ')  // Spaces for alignment.
         << iter->second.help_text << endl;
  }
}

bool CommandLineInterface::GenerateOutput(
    const vector<const FileDescriptor*>& parsed_files,
    const OutputDirective& output_directive,
    GeneratorContext* generator_context) {
  // Call the generator.
  string error;
  if (output_directive.generator == NULL) {
    // This is a plugin.
    GOOGLE_CHECK(HasPrefixString(output_directive.name, "--") &&
          HasSuffixString(output_directive.name, "_out"))
        << "Bad name for plugin generator: " << output_directive.name;

    // Strip the "--" and "_out" and add the plugin prefix.
    string plugin_name = plugin_prefix_ + "gen-" +
        output_directive.name.substr(2, output_directive.name.size() - 6);

    if (!GeneratePluginOutput(parsed_files, plugin_name,
                              output_directive.parameter,
                              generator_context, &error)) {
      cerr << output_directive.name << ": " << error << endl;
      return false;
    }
  } else {
    // Regular generator.
    string parameters = output_directive.parameter;
    if (!generator_parameters_[output_directive.name].empty()) {
      if (!parameters.empty()) {
        parameters.append(",");
      }
      parameters.append(generator_parameters_[output_directive.name]);
    }
    for (int i = 0; i < parsed_files.size(); i++) {
      if (!output_directive.generator->Generate(parsed_files[i], parameters,
                                                generator_context, &error)) {
        // Generator returned an error.
        cerr << output_directive.name << ": " << parsed_files[i]->name() << ": "
             << error << endl;
        return false;
      }
    }
  }

  return true;
}

bool CommandLineInterface::GeneratePluginOutput(
    const vector<const FileDescriptor*>& parsed_files,
    const string& plugin_name,
    const string& parameter,
    GeneratorContext* generator_context,
    string* error) {
  CodeGeneratorRequest request;
  CodeGeneratorResponse response;

  // Build the request.
  if (!parameter.empty()) {
    request.set_parameter(parameter);
  }

  set<const FileDescriptor*> already_seen;
  for (int i = 0; i < parsed_files.size(); i++) {
    request.add_file_to_generate(parsed_files[i]->name());
    GetTransitiveDependencies(parsed_files[i],
                              true,  // Include source code info.
                              &already_seen, request.mutable_proto_file());
  }

  // Invoke the plugin.
  Subprocess subprocess;

  if (plugins_.count(plugin_name) > 0) {
    subprocess.Start(plugins_[plugin_name], Subprocess::EXACT_NAME);
  } else {
    subprocess.Start(plugin_name, Subprocess::SEARCH_PATH);
  }

  string communicate_error;
  if (!subprocess.Communicate(request, &response, &communicate_error)) {
    *error = strings::Substitute("$0: $1", plugin_name, communicate_error);
    return false;
  }

  // Write the files.  We do this even if there was a generator error in order
  // to match the behavior of a compiled-in generator.
  scoped_ptr<io::ZeroCopyOutputStream> current_output;
  for (int i = 0; i < response.file_size(); i++) {
    const CodeGeneratorResponse::File& output_file = response.file(i);

    if (!output_file.insertion_point().empty()) {
      // Open a file for insert.
      // We reset current_output to NULL first so that the old file is closed
      // before the new one is opened.
      current_output.reset();
      current_output.reset(generator_context->OpenForInsert(
          output_file.name(), output_file.insertion_point()));
    } else if (!output_file.name().empty()) {
      // Starting a new file.  Open it.
      // We reset current_output to NULL first so that the old file is closed
      // before the new one is opened.
      current_output.reset();
      current_output.reset(generator_context->Open(output_file.name()));
    } else if (current_output == NULL) {
      *error = strings::Substitute(
        "$0: First file chunk returned by plugin did not specify a file name.",
        plugin_name);
      return false;
    }

    // Use CodedOutputStream for convenience; otherwise we'd need to provide
    // our own buffer-copying loop.
    io::CodedOutputStream writer(current_output.get());
    writer.WriteString(output_file.content());
  }

  // Check for errors.
  if (!response.error().empty()) {
    // Generator returned an error.
    *error = response.error();
    return false;
  }

  return true;
}

bool CommandLineInterface::EncodeOrDecode(const DescriptorPool* pool) {
  // Look up the type.
  const Descriptor* type = pool->FindMessageTypeByName(codec_type_);
  if (type == NULL) {
    cerr << "Type not defined: " << codec_type_ << endl;
    return false;
  }

  DynamicMessageFactory dynamic_factory(pool);
  scoped_ptr<Message> message(dynamic_factory.GetPrototype(type)->New());

  if (mode_ == MODE_ENCODE) {
    SetFdToTextMode(STDIN_FILENO);
    SetFdToBinaryMode(STDOUT_FILENO);
  } else {
    SetFdToBinaryMode(STDIN_FILENO);
    SetFdToTextMode(STDOUT_FILENO);
  }

  io::FileInputStream in(STDIN_FILENO);
  io::FileOutputStream out(STDOUT_FILENO);

  if (mode_ == MODE_ENCODE) {
    // Input is text.
    ErrorPrinter error_collector(error_format_);
    TextFormat::Parser parser;
    parser.RecordErrorsTo(&error_collector);
    parser.AllowPartialMessage(true);

    if (!parser.Parse(&in, message.get())) {
      cerr << "Failed to parse input." << endl;
      return false;
    }
  } else {
    // Input is binary.
    if (!message->ParsePartialFromZeroCopyStream(&in)) {
      cerr << "Failed to parse input." << endl;
      return false;
    }
  }

  if (!message->IsInitialized()) {
    cerr << "warning:  Input message is missing required fields:  "
         << message->InitializationErrorString() << endl;
  }

  if (mode_ == MODE_ENCODE) {
    // Output is binary.
    if (!message->SerializePartialToZeroCopyStream(&out)) {
      cerr << "output: I/O error." << endl;
      return false;
    }
  } else {
    // Output is text.
    if (!TextFormat::Print(*message, &out)) {
      cerr << "output: I/O error." << endl;
      return false;
    }
  }

  return true;
}

bool CommandLineInterface::WriteDescriptorSet(
    const vector<const FileDescriptor*> parsed_files) {
  FileDescriptorSet file_set;

  if (imports_in_descriptor_set_) {
    set<const FileDescriptor*> already_seen;
    for (int i = 0; i < parsed_files.size(); i++) {
      GetTransitiveDependencies(parsed_files[i],
                                source_info_in_descriptor_set_,
                                &already_seen, file_set.mutable_file());
    }
  } else {
    for (int i = 0; i < parsed_files.size(); i++) {
      FileDescriptorProto* file_proto = file_set.add_file();
      parsed_files[i]->CopyTo(file_proto);
      if (source_info_in_descriptor_set_) {
        parsed_files[i]->CopySourceCodeInfoTo(file_proto);
      }
    }
  }

  int fd;
  do {
    fd = open(descriptor_set_name_.c_str(),
              O_WRONLY | O_CREAT | O_TRUNC | O_BINARY, 0666);
  } while (fd < 0 && errno == EINTR);

  if (fd < 0) {
    perror(descriptor_set_name_.c_str());
    return false;
  }

  io::FileOutputStream out(fd);
  if (!file_set.SerializeToZeroCopyStream(&out)) {
    cerr << descriptor_set_name_ << ": " << strerror(out.GetErrno()) << endl;
    out.Close();
    return false;
  }
  if (!out.Close()) {
    cerr << descriptor_set_name_ << ": " << strerror(out.GetErrno()) << endl;
    return false;
  }

  return true;
}

void CommandLineInterface::GetTransitiveDependencies(
    const FileDescriptor* file, bool include_source_code_info,
    set<const FileDescriptor*>* already_seen,
    RepeatedPtrField<FileDescriptorProto>* output) {
  if (!already_seen->insert(file).second) {
    // Already saw this file.  Skip.
    return;
  }

  // Add all dependencies.
  for (int i = 0; i < file->dependency_count(); i++) {
    GetTransitiveDependencies(file->dependency(i), include_source_code_info,
                              already_seen, output);
  }

  // Add this file.
  FileDescriptorProto* new_descriptor = output->Add();
  file->CopyTo(new_descriptor);
  if (include_source_code_info) {
    file->CopySourceCodeInfoTo(new_descriptor);
  }
}


}  // namespace compiler
}  // namespace protobuf
}  // namespace google
