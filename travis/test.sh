#!/bin/bash

cd frontend_server
pub get
pub run test/server_test.dart
