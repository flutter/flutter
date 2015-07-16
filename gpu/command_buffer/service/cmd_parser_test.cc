// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Tests for the command parser.

#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "gpu/command_buffer/service/cmd_parser.h"
#include "gpu/command_buffer/service/mocks.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace gpu {

using testing::_;
using testing::Invoke;
using testing::Mock;
using testing::Return;
using testing::Sequence;
using testing::SetArgPointee;
using testing::Truly;

// Test fixture for CommandParser test - Creates a mock AsyncAPIInterface, and
// a fixed size memory buffer. Also provides a simple API to create a
// CommandParser.
class CommandParserTest : public testing::Test {
 protected:
  virtual void SetUp() {
    api_mock_.reset(new AsyncAPIMock(false));
    buffer_entry_count_ = 20;
    buffer_.reset(new CommandBufferEntry[buffer_entry_count_]);
  }
  virtual void TearDown() {}

  void AddDoCommandsExpect(error::Error _return,
                           unsigned int num_commands,
                           int num_entries,
                           int num_processed) {
    EXPECT_CALL(*api_mock_, DoCommands(num_commands, _, num_entries, _))
        .InSequence(sequence_)
        .WillOnce(DoAll(SetArgPointee<3>(num_processed), Return(_return)));
  }

  // Creates a parser, with a buffer of the specified size (in entries).
  CommandParser *MakeParser(unsigned int entry_count) {
    size_t shm_size = buffer_entry_count_ *
                      sizeof(CommandBufferEntry);  // NOLINT
    size_t command_buffer_size = entry_count *
                                 sizeof(CommandBufferEntry);  // NOLINT
    DCHECK_LE(command_buffer_size, shm_size);
    CommandParser* parser = new CommandParser(api_mock());

    parser->SetBuffer(buffer(), shm_size, 0, command_buffer_size);
    return parser;
  }

  unsigned int buffer_entry_count() { return 20; }
  AsyncAPIMock *api_mock() { return api_mock_.get(); }
  CommandBufferEntry *buffer() { return buffer_.get(); }
 private:
  unsigned int buffer_entry_count_;
  scoped_ptr<AsyncAPIMock> api_mock_;
  scoped_ptr<CommandBufferEntry[]> buffer_;
  Sequence sequence_;
};

// Tests initialization conditions.
TEST_F(CommandParserTest, TestInit) {
  scoped_ptr<CommandParser> parser(MakeParser(10));
  EXPECT_EQ(0, parser->get());
  EXPECT_EQ(0, parser->put());
  EXPECT_TRUE(parser->IsEmpty());
}

// Tests simple commands.
TEST_F(CommandParserTest, TestSimple) {
  scoped_ptr<CommandParser> parser(MakeParser(10));
  CommandBufferOffset put = parser->put();
  CommandHeader header;

  // add a single command, no args
  header.size = 1;
  header.command = 123;
  buffer()[put++].value_header = header;
  parser->set_put(put);
  EXPECT_EQ(put, parser->put());

  AddDoCommandsExpect(error::kNoError, 1, 1, 1);
  EXPECT_EQ(error::kNoError, parser->ProcessCommands(1));
  EXPECT_EQ(put, parser->get());
  Mock::VerifyAndClearExpectations(api_mock());

  // add a single command, 2 args
  header.size = 3;
  header.command = 456;
  buffer()[put++].value_header = header;
  buffer()[put++].value_int32 = 2134;
  buffer()[put++].value_float = 1.f;
  parser->set_put(put);
  EXPECT_EQ(put, parser->put());

  AddDoCommandsExpect(error::kNoError, 1, 3, 3);
  EXPECT_EQ(error::kNoError, parser->ProcessCommands(1));
  EXPECT_EQ(put, parser->get());
  Mock::VerifyAndClearExpectations(api_mock());
}

// Tests having multiple commands in the buffer.
TEST_F(CommandParserTest, TestMultipleCommands) {
  scoped_ptr<CommandParser> parser(MakeParser(10));
  CommandBufferOffset put = parser->put();
  CommandHeader header;

  // add 2 commands, test with single ProcessCommands()
  header.size = 2;
  header.command = 789;
  buffer()[put++].value_header = header;
  buffer()[put++].value_int32 = 5151;

  CommandBufferOffset put_cmd2 = put;
  header.size = 2;
  header.command = 876;
  buffer()[put++].value_header = header;
  buffer()[put++].value_int32 = 3434;
  parser->set_put(put);
  EXPECT_EQ(put, parser->put());

  // Process up to 1 command.  4 entries remaining.
  AddDoCommandsExpect(error::kNoError, 1, 4, 2);
  EXPECT_EQ(error::kNoError, parser->ProcessCommands(1));
  EXPECT_EQ(put_cmd2, parser->get());

  // Process up to 1 command.  2 entries remaining.
  AddDoCommandsExpect(error::kNoError, 1, 2, 2);
  EXPECT_EQ(error::kNoError, parser->ProcessCommands(1));
  EXPECT_EQ(put, parser->get());
  Mock::VerifyAndClearExpectations(api_mock());

  // add 2 commands again, test with ProcessAllCommands()
  header.size = 2;
  header.command = 123;
  buffer()[put++].value_header = header;
  buffer()[put++].value_int32 = 5656;

  header.size = 2;
  header.command = 321;
  buffer()[put++].value_header = header;
  buffer()[put++].value_int32 = 7878;
  parser->set_put(put);
  EXPECT_EQ(put, parser->put());

  // 4 entries remaining.
  AddDoCommandsExpect(
      error::kNoError, CommandParser::kParseCommandsSlice, 4, 4);
  EXPECT_EQ(error::kNoError, parser->ProcessAllCommands());
  EXPECT_EQ(put, parser->get());
  Mock::VerifyAndClearExpectations(api_mock());
}

// Tests that the parser will wrap correctly at the end of the buffer.
TEST_F(CommandParserTest, TestWrap) {
  scoped_ptr<CommandParser> parser(MakeParser(5));
  CommandBufferOffset put = parser->put();
  CommandHeader header;

  // add 3 commands with no args (1 word each)
  for (unsigned int i = 0; i < 3; ++i) {
    header.size = 1;
    header.command = i;
    buffer()[put++].value_header = header;
  }
  parser->set_put(put);
  EXPECT_EQ(put, parser->put());

  // Process up to 10 commands.  3 entries remaining to put.
  AddDoCommandsExpect(error::kNoError, 10, 3, 3);
  EXPECT_EQ(error::kNoError, parser->ProcessCommands(10));
  EXPECT_EQ(put, parser->get());
  Mock::VerifyAndClearExpectations(api_mock());

  // add 1 command with 1 arg (2 words). That should put us at the end of the
  // buffer.
  header.size = 2;
  header.command = 3;
  buffer()[put++].value_header = header;
  buffer()[put++].value_int32 = 5;

  DCHECK_EQ(5, put);
  put = 0;

  // add 1 command with 1 arg (2 words).
  header.size = 2;
  header.command = 4;
  buffer()[put++].value_header = header;
  buffer()[put++].value_int32 = 6;

  // 2 entries remaining to end of buffer.
  AddDoCommandsExpect(
      error::kNoError, CommandParser::kParseCommandsSlice, 2, 2);
  // 2 entries remaining to put.
  AddDoCommandsExpect(
      error::kNoError, CommandParser::kParseCommandsSlice, 2, 2);
  parser->set_put(put);
  EXPECT_EQ(put, parser->put());

  EXPECT_EQ(error::kNoError, parser->ProcessAllCommands());
  EXPECT_EQ(put, parser->get());
  Mock::VerifyAndClearExpectations(api_mock());
}

// Tests error conditions.
TEST_F(CommandParserTest, TestError) {
  const unsigned int kNumEntries = 5;
  scoped_ptr<CommandParser> parser(MakeParser(kNumEntries));
  CommandBufferOffset put = parser->put();
  CommandHeader header;

  EXPECT_FALSE(parser->set_get(-1));
  EXPECT_FALSE(parser->set_get(kNumEntries));

  // Generate a command with size 0.
  header.size = 0;
  header.command = 3;
  buffer()[put++].value_header = header;

  parser->set_put(put);
  EXPECT_EQ(put, parser->put());

  AddDoCommandsExpect(
      error::kInvalidSize, CommandParser::kParseCommandsSlice, 1, 0);
  EXPECT_EQ(error::kInvalidSize,
            parser->ProcessAllCommands());
  // check that no DoCommand call was made.
  Mock::VerifyAndClearExpectations(api_mock());

  parser.reset(MakeParser(5));
  put = parser->put();

  // Generate a command with size 6, extends beyond the end of the buffer.
  header.size = 6;
  header.command = 3;
  buffer()[put++].value_header = header;

  parser->set_put(put);
  EXPECT_EQ(put, parser->put());

  AddDoCommandsExpect(
      error::kOutOfBounds, CommandParser::kParseCommandsSlice, 1, 0);
  EXPECT_EQ(error::kOutOfBounds,
            parser->ProcessAllCommands());
  // check that no DoCommand call was made.
  Mock::VerifyAndClearExpectations(api_mock());

  parser.reset(MakeParser(5));
  put = parser->put();

  // Generates 2 commands.
  header.size = 1;
  header.command = 3;
  buffer()[put++].value_header = header;
  CommandBufferOffset put_post_fail = put;
  header.size = 1;
  header.command = 4;
  buffer()[put++].value_header = header;

  parser->set_put(put);
  EXPECT_EQ(put, parser->put());
  // have the first command fail to parse.
  AddDoCommandsExpect(
      error::kUnknownCommand, CommandParser::kParseCommandsSlice, 2, 1);
  EXPECT_EQ(error::kUnknownCommand,
            parser->ProcessAllCommands());
  // check that only one command was executed, and that get reflects that
  // correctly.
  EXPECT_EQ(put_post_fail, parser->get());
  Mock::VerifyAndClearExpectations(api_mock());
  // make the second one succeed, and check that the parser recovered fine.
  AddDoCommandsExpect(
      error::kNoError, CommandParser::kParseCommandsSlice, 1, 1);
  EXPECT_EQ(error::kNoError, parser->ProcessAllCommands());
  EXPECT_EQ(put, parser->get());
  Mock::VerifyAndClearExpectations(api_mock());
}

TEST_F(CommandParserTest, SetBuffer) {
  scoped_ptr<CommandParser> parser(MakeParser(3));
  CommandBufferOffset put = parser->put();
  CommandHeader header;

  // add a single command, no args
  header.size = 2;
  header.command = 123;
  buffer()[put++].value_header = header;
  buffer()[put++].value_int32 = 456;
  parser->set_put(put);

  AddDoCommandsExpect(
      error::kNoError, CommandParser::kParseCommandsSlice, 2, 2);
  EXPECT_EQ(error::kNoError, parser->ProcessAllCommands());
  // We should have advanced 2 entries
  EXPECT_EQ(2, parser->get());
  Mock::VerifyAndClearExpectations(api_mock());

  scoped_ptr<CommandBufferEntry[]> buffer2(new CommandBufferEntry[2]);
  parser->SetBuffer(
      buffer2.get(), sizeof(CommandBufferEntry) * 2, 0,
      sizeof(CommandBufferEntry) * 2);
  // The put and get should have reset to 0.
  EXPECT_EQ(0, parser->get());
  EXPECT_EQ(0, parser->put());
}

}  // namespace gpu
