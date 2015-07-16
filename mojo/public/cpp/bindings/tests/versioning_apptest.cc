// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/application/application_impl.h"
#include "mojo/public/cpp/application/application_test_base.h"
#include "mojo/public/cpp/system/macros.h"
#include "mojo/public/interfaces/bindings/tests/versioning_test_client.mojom.h"

namespace mojo {
namespace test {
namespace versioning {

class VersioningApplicationTest : public ApplicationTestBase {
 public:
  VersioningApplicationTest() : ApplicationTestBase() {}
  ~VersioningApplicationTest() override {}

 protected:
  // ApplicationTestBase overrides.
  void SetUp() override {
    ApplicationTestBase::SetUp();

    application_impl()->ConnectToService("mojo:versioning_test_service",
                                         &database_);
  }

  HumanResourceDatabasePtr database_;

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(VersioningApplicationTest);
};

TEST_F(VersioningApplicationTest, Struct) {
  // The service side uses a newer version of Employee defintion.
  // The returned struct should be truncated.
  EmployeePtr employee(Employee::New());
  employee->employee_id = 1;
  employee->name = "Homer Simpson";
  employee->department = DEPARTMENT_DEV;

  database_->QueryEmployee(1, true,
                           [&employee](EmployeePtr returned_employee,
                                       Array<uint8_t> returned_finger_print) {
                             EXPECT_TRUE(employee->Equals(*returned_employee));
                             EXPECT_FALSE(returned_finger_print.is_null());
                           });
  database_.WaitForIncomingResponse();

  // Passing a struct of older version to the service side works.
  EmployeePtr new_employee(Employee::New());
  new_employee->employee_id = 2;
  new_employee->name = "Marge Simpson";
  new_employee->department = DEPARTMENT_SALES;

  database_->AddEmployee(new_employee.Clone(),
                         [](bool success) { EXPECT_TRUE(success); });
  database_.WaitForIncomingResponse();

  database_->QueryEmployee(
      2, false, [&new_employee](EmployeePtr returned_employee,
                                Array<uint8_t> returned_finger_print) {
        EXPECT_TRUE(new_employee->Equals(*returned_employee));
        EXPECT_TRUE(returned_finger_print.is_null());
      });
  database_.WaitForIncomingResponse();
}

TEST_F(VersioningApplicationTest, QueryVersion) {
  EXPECT_EQ(0u, database_.version());
  database_.QueryVersion([](uint32_t version) { EXPECT_EQ(1u, version); });
  database_.WaitForIncomingResponse();
  EXPECT_EQ(1u, database_.version());
}

TEST_F(VersioningApplicationTest, RequireVersion) {
  EXPECT_EQ(0u, database_.version());

  database_.RequireVersion(1);
  EXPECT_EQ(1u, database_.version());
  database_->QueryEmployee(3, false,
                           [](EmployeePtr returned_employee,
                              Array<uint8_t> returned_finger_print) {});
  database_.WaitForIncomingResponse();
  EXPECT_FALSE(database_.encountered_error());

  // Requiring a version higher than what the service side implements will close
  // the pipe.
  database_.RequireVersion(3);
  EXPECT_EQ(3u, database_.version());
  database_->QueryEmployee(1, false,
                           [](EmployeePtr returned_employee,
                              Array<uint8_t> returned_finger_print) {});
  database_.WaitForIncomingResponse();
  EXPECT_TRUE(database_.encountered_error());
}

TEST_F(VersioningApplicationTest, CallNonexistentMethod) {
  EXPECT_EQ(0u, database_.version());

  Array<uint8_t> new_finger_print(128);
  for (size_t i = 0; i < 128; ++i)
    new_finger_print[i] = i + 13;

  // Although the client side doesn't know whether the service side supports
  // version 1, calling a version 1 method succeeds as long as the service side
  // supports version 1.
  database_->AttachFingerPrint(1, new_finger_print.Clone(),
                               [](bool success) { EXPECT_TRUE(success); });
  database_.WaitForIncomingResponse();

  // Calling a version 2 method (which the service side doesn't support) closes
  // the pipe.
  database_->ListEmployeeIds([](Array<uint64_t> ids) { EXPECT_TRUE(false); });
  database_.WaitForIncomingResponse();
  EXPECT_TRUE(database_.encountered_error());
}

}  // namespace versioning
}  // namespace examples
}  // namespace mojo
