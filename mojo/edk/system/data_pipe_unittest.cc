// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/data_pipe.h"

#include <stddef.h>
#include <stdint.h>

#include <limits>

#include "mojo/edk/system/configuration.h"
#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace system {
namespace {

const uint32_t kSizeOfCreateOptions =
    static_cast<uint32_t>(sizeof(MojoCreateDataPipeOptions));

// Does a cursory sanity check of |validated_options|. Calls
// |ValidateCreateOptions()| on already-validated options. The validated options
// should be valid, and the revalidated copy should be the same.
void RevalidateCreateOptions(
    const MojoCreateDataPipeOptions& validated_options) {
  EXPECT_EQ(kSizeOfCreateOptions, validated_options.struct_size);
  // Nothing to check for flags.
  EXPECT_GT(validated_options.element_num_bytes, 0u);
  EXPECT_GT(validated_options.capacity_num_bytes, 0u);
  EXPECT_EQ(0u, validated_options.capacity_num_bytes %
                    validated_options.element_num_bytes);

  MojoCreateDataPipeOptions revalidated_options = {};
  EXPECT_EQ(MOJO_RESULT_OK,
            DataPipe::ValidateCreateOptions(MakeUserPointer(&validated_options),
                                            &revalidated_options));
  EXPECT_EQ(validated_options.struct_size, revalidated_options.struct_size);
  EXPECT_EQ(validated_options.element_num_bytes,
            revalidated_options.element_num_bytes);
  EXPECT_EQ(validated_options.capacity_num_bytes,
            revalidated_options.capacity_num_bytes);
  EXPECT_EQ(validated_options.flags, revalidated_options.flags);
}

// Checks that a default-computed capacity is correct. (Does not duplicate the
// checks done by |RevalidateCreateOptions()|.)
void CheckDefaultCapacity(const MojoCreateDataPipeOptions& validated_options) {
  EXPECT_LE(validated_options.capacity_num_bytes,
            GetConfiguration().default_data_pipe_capacity_bytes);
  EXPECT_GT(validated_options.capacity_num_bytes +
                validated_options.element_num_bytes,
            GetConfiguration().default_data_pipe_capacity_bytes);
}

// Tests valid inputs to |ValidateCreateOptions()|.
TEST(DataPipeTest, ValidateCreateOptionsValid) {
  // Default options.
  {
    MojoCreateDataPipeOptions validated_options = {};
    EXPECT_EQ(MOJO_RESULT_OK, DataPipe::ValidateCreateOptions(
                                  NullUserPointer(), &validated_options));
    RevalidateCreateOptions(validated_options);
    CheckDefaultCapacity(validated_options);
  }

  // Size member, but nothing beyond.
  {
    MojoCreateDataPipeOptions options = {
        offsetof(MojoCreateDataPipeOptions, flags)  // |struct_size|.
    };
    MojoCreateDataPipeOptions validated_options = {};
    EXPECT_EQ(MOJO_RESULT_OK,
              DataPipe::ValidateCreateOptions(MakeUserPointer(&options),
                                              &validated_options));
    RevalidateCreateOptions(validated_options);
    CheckDefaultCapacity(validated_options);
  }

  // Different flags.
  MojoCreateDataPipeOptionsFlags flags_values[] = {
      MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE};
  for (size_t i = 0; i < MOJO_ARRAYSIZE(flags_values); i++) {
    const MojoCreateDataPipeOptionsFlags flags = flags_values[i];

    // Flags member, but nothing beyond.
    {
      MojoCreateDataPipeOptions options = {
          // |struct_size|.
          offsetof(MojoCreateDataPipeOptions, element_num_bytes),
          flags  // |flags|.
      };
      MojoCreateDataPipeOptions validated_options = {};
      EXPECT_EQ(MOJO_RESULT_OK,
                DataPipe::ValidateCreateOptions(MakeUserPointer(&options),
                                                &validated_options));
      RevalidateCreateOptions(validated_options);
      EXPECT_EQ(options.flags, validated_options.flags);
      CheckDefaultCapacity(validated_options);
    }

    // Different capacities (size 1).
    for (uint32_t capacity = 1; capacity <= 100 * 1000 * 1000; capacity *= 10) {
      MojoCreateDataPipeOptions options = {
          kSizeOfCreateOptions,  // |struct_size|.
          flags,                 // |flags|.
          1,                     // |element_num_bytes|.
          capacity               // |capacity_num_bytes|.
      };
      MojoCreateDataPipeOptions validated_options = {};
      EXPECT_EQ(MOJO_RESULT_OK,
                DataPipe::ValidateCreateOptions(MakeUserPointer(&options),
                                                &validated_options))
          << capacity;
      RevalidateCreateOptions(validated_options);
      EXPECT_EQ(options.flags, validated_options.flags);
      EXPECT_EQ(options.element_num_bytes, validated_options.element_num_bytes);
      EXPECT_EQ(options.capacity_num_bytes,
                validated_options.capacity_num_bytes);
    }

    // Small sizes.
    for (uint32_t size = 1; size < 100; size++) {
      // Different capacities.
      for (uint32_t elements = 1; elements <= 1000 * 1000; elements *= 10) {
        MojoCreateDataPipeOptions options = {
            kSizeOfCreateOptions,  // |struct_size|.
            flags,                 // |flags|.
            size,                  // |element_num_bytes|.
            size * elements        // |capacity_num_bytes|.
        };
        MojoCreateDataPipeOptions validated_options = {};
        EXPECT_EQ(MOJO_RESULT_OK,
                  DataPipe::ValidateCreateOptions(MakeUserPointer(&options),
                                                  &validated_options))
            << size << ", " << elements;
        RevalidateCreateOptions(validated_options);
        EXPECT_EQ(options.flags, validated_options.flags);
        EXPECT_EQ(options.element_num_bytes,
                  validated_options.element_num_bytes);
        EXPECT_EQ(options.capacity_num_bytes,
                  validated_options.capacity_num_bytes);
      }

      // Default capacity.
      {
        MojoCreateDataPipeOptions options = {
            kSizeOfCreateOptions,  // |struct_size|.
            flags,                 // |flags|.
            size,                  // |element_num_bytes|.
            0                      // |capacity_num_bytes|.
        };
        MojoCreateDataPipeOptions validated_options = {};
        EXPECT_EQ(MOJO_RESULT_OK,
                  DataPipe::ValidateCreateOptions(MakeUserPointer(&options),
                                                  &validated_options))
            << size;
        RevalidateCreateOptions(validated_options);
        EXPECT_EQ(options.flags, validated_options.flags);
        EXPECT_EQ(options.element_num_bytes,
                  validated_options.element_num_bytes);
        CheckDefaultCapacity(validated_options);
      }

      // No capacity field.
      {
        MojoCreateDataPipeOptions options = {
            // |struct_size|.
            offsetof(MojoCreateDataPipeOptions, capacity_num_bytes),
            flags,  // |flags|.
            size    // |element_num_bytes|.
        };
        MojoCreateDataPipeOptions validated_options = {};
        EXPECT_EQ(MOJO_RESULT_OK,
                  DataPipe::ValidateCreateOptions(MakeUserPointer(&options),
                                                  &validated_options))
            << size;
        RevalidateCreateOptions(validated_options);
        EXPECT_EQ(options.flags, validated_options.flags);
        EXPECT_EQ(options.element_num_bytes,
                  validated_options.element_num_bytes);
        CheckDefaultCapacity(validated_options);
      }
    }

    // Larger sizes.
    for (uint32_t size = 100; size <= 100 * 1000; size *= 10) {
      // Capacity of 1000 elements.
      {
        MojoCreateDataPipeOptions options = {
            kSizeOfCreateOptions,  // |struct_size|.
            flags,                 // |flags|.
            size,                  // |element_num_bytes|.
            1000 * size            // |capacity_num_bytes|.
        };
        MojoCreateDataPipeOptions validated_options = {};
        EXPECT_EQ(MOJO_RESULT_OK,
                  DataPipe::ValidateCreateOptions(MakeUserPointer(&options),
                                                  &validated_options))
            << size;
        RevalidateCreateOptions(validated_options);
        EXPECT_EQ(options.flags, validated_options.flags);
        EXPECT_EQ(options.element_num_bytes,
                  validated_options.element_num_bytes);
        EXPECT_EQ(options.capacity_num_bytes,
                  validated_options.capacity_num_bytes);
      }

      // Default capacity.
      {
        MojoCreateDataPipeOptions options = {
            kSizeOfCreateOptions,  // |struct_size|.
            flags,                 // |flags|.
            size,                  // |element_num_bytes|.
            0                      // |capacity_num_bytes|.
        };
        MojoCreateDataPipeOptions validated_options = {};
        EXPECT_EQ(MOJO_RESULT_OK,
                  DataPipe::ValidateCreateOptions(MakeUserPointer(&options),
                                                  &validated_options))
            << size;
        RevalidateCreateOptions(validated_options);
        EXPECT_EQ(options.flags, validated_options.flags);
        EXPECT_EQ(options.element_num_bytes,
                  validated_options.element_num_bytes);
        CheckDefaultCapacity(validated_options);
      }

      // No capacity field.
      {
        MojoCreateDataPipeOptions options = {
            // |struct_size|.
            offsetof(MojoCreateDataPipeOptions, capacity_num_bytes),
            flags,  // |flags|.
            size    // |element_num_bytes|.
        };
        MojoCreateDataPipeOptions validated_options = {};
        EXPECT_EQ(MOJO_RESULT_OK,
                  DataPipe::ValidateCreateOptions(MakeUserPointer(&options),
                                                  &validated_options))
            << size;
        RevalidateCreateOptions(validated_options);
        EXPECT_EQ(options.flags, validated_options.flags);
        EXPECT_EQ(options.element_num_bytes,
                  validated_options.element_num_bytes);
        CheckDefaultCapacity(validated_options);
      }
    }
  }
}

TEST(DataPipeTest, ValidateCreateOptionsInvalid) {
  // Invalid |struct_size|.
  {
    MojoCreateDataPipeOptions options = {
        1,                                        // |struct_size|.
        MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
        1,                                        // |element_num_bytes|.
        0                                         // |capacity_num_bytes|.
    };
    MojoCreateDataPipeOptions unused;
    EXPECT_EQ(
        MOJO_SYSTEM_RESULT_INVALID_ARGUMENT,
        DataPipe::ValidateCreateOptions(MakeUserPointer(&options), &unused));
  }

  // Unknown |flags|.
  {
    MojoCreateDataPipeOptions options = {
        kSizeOfCreateOptions,  // |struct_size|.
        ~0u,                   // |flags|.
        1,                     // |element_num_bytes|.
        0                      // |capacity_num_bytes|.
    };
    MojoCreateDataPipeOptions unused;
    EXPECT_EQ(
        MOJO_SYSTEM_RESULT_UNIMPLEMENTED,
        DataPipe::ValidateCreateOptions(MakeUserPointer(&options), &unused));
  }

  // Invalid |element_num_bytes|.
  {
    MojoCreateDataPipeOptions options = {
        kSizeOfCreateOptions,                     // |struct_size|.
        MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
        0,                                        // |element_num_bytes|.
        1000                                      // |capacity_num_bytes|.
    };
    MojoCreateDataPipeOptions unused;
    EXPECT_EQ(
        MOJO_SYSTEM_RESULT_INVALID_ARGUMENT,
        DataPipe::ValidateCreateOptions(MakeUserPointer(&options), &unused));
  }
  // |element_num_bytes| too big.
  {
    MojoCreateDataPipeOptions options = {
        kSizeOfCreateOptions,                     // |struct_size|.
        MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
        std::numeric_limits<uint32_t>::max(),     // |element_num_bytes|.
        std::numeric_limits<uint32_t>::max()      // |capacity_num_bytes|.
    };
    MojoCreateDataPipeOptions unused;
    EXPECT_EQ(
        MOJO_SYSTEM_RESULT_RESOURCE_EXHAUSTED,
        DataPipe::ValidateCreateOptions(MakeUserPointer(&options), &unused));
  }
  {
    MojoCreateDataPipeOptions options = {
        kSizeOfCreateOptions,                         // |struct_size|.
        MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,      // |flags|.
        std::numeric_limits<uint32_t>::max() - 1000,  // |element_num_bytes|.
        std::numeric_limits<uint32_t>::max() - 1000   // |capacity_num_bytes|.
    };
    MojoCreateDataPipeOptions unused;
    EXPECT_EQ(
        MOJO_SYSTEM_RESULT_RESOURCE_EXHAUSTED,
        DataPipe::ValidateCreateOptions(MakeUserPointer(&options), &unused));
  }

  // Invalid |capacity_num_bytes|.
  {
    MojoCreateDataPipeOptions options = {
        kSizeOfCreateOptions,                     // |struct_size|.
        MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
        2,                                        // |element_num_bytes|.
        1                                         // |capacity_num_bytes|.
    };
    MojoCreateDataPipeOptions unused;
    EXPECT_EQ(
        MOJO_SYSTEM_RESULT_INVALID_ARGUMENT,
        DataPipe::ValidateCreateOptions(MakeUserPointer(&options), &unused));
  }
  {
    MojoCreateDataPipeOptions options = {
        kSizeOfCreateOptions,                     // |struct_size|.
        MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
        2,                                        // |element_num_bytes|.
        111                                       // |capacity_num_bytes|.
    };
    MojoCreateDataPipeOptions unused;
    EXPECT_EQ(
        MOJO_SYSTEM_RESULT_INVALID_ARGUMENT,
        DataPipe::ValidateCreateOptions(MakeUserPointer(&options), &unused));
  }
  {
    MojoCreateDataPipeOptions options = {
        kSizeOfCreateOptions,                     // |struct_size|.
        MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
        5,                                        // |element_num_bytes|.
        104                                       // |capacity_num_bytes|.
    };
    MojoCreateDataPipeOptions unused;
    EXPECT_EQ(
        MOJO_SYSTEM_RESULT_INVALID_ARGUMENT,
        DataPipe::ValidateCreateOptions(MakeUserPointer(&options), &unused));
  }
  // |capacity_num_bytes| too big.
  {
    MojoCreateDataPipeOptions options = {
        kSizeOfCreateOptions,                     // |struct_size|.
        MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE,  // |flags|.
        8,                                        // |element_num_bytes|.
        0xffff0000                                // |capacity_num_bytes|.
    };
    MojoCreateDataPipeOptions unused;
    EXPECT_EQ(
        MOJO_SYSTEM_RESULT_RESOURCE_EXHAUSTED,
        DataPipe::ValidateCreateOptions(MakeUserPointer(&options), &unused));
  }
}

}  // namespace
}  // namespace system
}  // namespace mojo
