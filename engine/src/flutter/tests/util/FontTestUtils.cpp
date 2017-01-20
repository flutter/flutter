/*
 * Copyright (C) 2015 The Android Open Source Project
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

#define LOG_TAG "Minikin"

#include <libxml/tree.h>
#include <unistd.h>

#include <log/log.h>

#include "FontLanguage.h"
#include "MinikinFontForTest.h"
#include <minikin/FontCollection.h>
#include <minikin/FontFamily.h>

namespace minikin {

FontCollection* getFontCollection(const char* fontDir, const char* fontXml) {
    xmlDoc* doc = xmlReadFile(fontXml, NULL, 0);
    xmlNode* familySet = xmlDocGetRootElement(doc);

    std::vector<FontFamily*> families;
    for (xmlNode* familyNode = familySet->children; familyNode; familyNode = familyNode->next) {
        if (xmlStrcmp(familyNode->name, (const xmlChar*)"family") != 0) {
            continue;
        }

        xmlChar* variantXmlch = xmlGetProp(familyNode, (const xmlChar*)"variant");
        int variant = VARIANT_DEFAULT;
        if (variantXmlch) {
            if (xmlStrcmp(variantXmlch, (const xmlChar*)"elegant") == 0) {
                variant = VARIANT_ELEGANT;
            } else if (xmlStrcmp(variantXmlch, (const xmlChar*)"compact") == 0) {
                variant = VARIANT_COMPACT;
            }
        }

        xmlChar* lang = xmlGetProp(familyNode, (const xmlChar*)"lang");
        FontFamily* family;
        if (lang == nullptr) {
            family = new FontFamily(variant);
        } else {
            uint32_t langId = FontStyle::registerLanguageList(
                    std::string((const char*)lang, xmlStrlen(lang)));
            family = new FontFamily(langId, variant);
        }

        for (xmlNode* fontNode = familyNode->children; fontNode; fontNode = fontNode->next) {
            if (xmlStrcmp(fontNode->name, (const xmlChar*)"font") != 0) {
                continue;
            }

            int weight = atoi((const char*)(xmlGetProp(fontNode, (const xmlChar*)"weight"))) / 100;
            bool italic = xmlStrcmp(
                    xmlGetProp(fontNode, (const xmlChar*)"style"), (const xmlChar*)"italic") == 0;
            xmlChar* index = xmlGetProp(familyNode, (const xmlChar*)"index");

            xmlChar* fontFileName = xmlNodeListGetString(doc, fontNode->xmlChildrenNode, 1);
            std::string fontPath = fontDir + std::string((const char*)fontFileName);
            xmlFree(fontFileName);

            if (access(fontPath.c_str(), R_OK) != 0) {
                ALOGW("%s is not found.", fontPath.c_str());
                continue;
            }

            if (index == nullptr) {
                MinikinAutoUnref<MinikinFontForTest>
                        minikinFont(new MinikinFontForTest(fontPath));
                family->addFont(minikinFont.get(), FontStyle(weight, italic));
            } else {
                MinikinAutoUnref<MinikinFontForTest>
                        minikinFont(new MinikinFontForTest(fontPath, atoi((const char*)index)));
                family->addFont(minikinFont.get(), FontStyle(weight, italic));
            }
        }
        families.push_back(family);
    }
    xmlFreeDoc(doc);

    FontCollection* collection = new FontCollection(families);
    for (size_t i = 0; i < families.size(); ++i) {
        families[i]->Unref();
    }
    return collection;
}

}  // namespace minikin
