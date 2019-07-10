/*
 * Copyright 2017 Google, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <string>

#include "flutter/fml/command_line.h"
#include "txt/font_collection.h"
#include "txt/paragraph_builder_txt.h"
#include "txt/paragraph_txt.h"

namespace txt {

const std::string& GetFontDir();

void SetFontDir(const std::string& dir);

const fml::CommandLine& GetCommandLineForProcess();

void SetCommandLine(fml::CommandLine cmd);

std::shared_ptr<FontCollection> GetTestFontCollection();

std::unique_ptr<ParagraphTxt> BuildParagraph(ParagraphBuilderTxt& builder);

}  // namespace txt
