// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

abstract class CharacterData extends Node {
    // Constructors

    // Attributes
    String get data native "CharacterData_data_Getter";
    void set data(String value) native "CharacterData_data_Setter";
    int get length native "CharacterData_length_Getter";

    // Methods
    String substringData(int offset, int length) native "CharacterData_substringData_Callback";
    void appendData(String data) native "CharacterData_appendData_Callback";
    void insertData(int offset, String data) native "CharacterData_insertData_Callback";
    void deleteData(int offset, int length) native "CharacterData_deleteData_Callback";
    void replaceData(int offset, int length, String data) native "CharacterData_replaceData_Callback";

    // Operators
}
