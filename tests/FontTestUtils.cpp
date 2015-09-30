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

#include <libxml/tree.h>

#include <minikin/FontCollection.h>
#include <minikin/FontFamily.h>

#include "MinikinFontForTest.h"

const char kFontDir[] = "/system/fonts/";
const char kFontXml[] = "/system/etc/fonts.xml";

std::unique_ptr<android::FontCollection> getFontCollection() {
    xmlDoc* doc = xmlReadFile(kFontXml, NULL, 0);
    xmlNode* familySet = xmlDocGetRootElement(doc);

    std::vector<android::FontFamily*> families;
    for (xmlNode* familyNode = familySet->children; familyNode; familyNode = familyNode->next) {
        if (xmlStrcmp(familyNode->name, (const xmlChar*)"family") != 0) {
            continue;
        }

        xmlChar* variantXmlch = xmlGetProp(familyNode, (const xmlChar*)"variant");
        int variant = android::VARIANT_DEFAULT;
        if (variantXmlch) {
            if (xmlStrcmp(variantXmlch, (const xmlChar*)"elegant") == 0) {
                variant = android::VARIANT_ELEGANT;
            } else if (xmlStrcmp(variantXmlch, (const xmlChar*)"compact") == 0) {
                variant = android::VARIANT_COMPACT;
            }
        }

        xmlChar* lang = xmlGetProp(familyNode, (const xmlChar*)"lang");

        android::FontFamily* family = new android::FontFamily(
                android::FontLanguage((const char*)lang, xmlStrlen(lang)), variant);

        for (xmlNode* fontNode = familyNode->children; fontNode; fontNode = fontNode->next) {
            if (xmlStrcmp(fontNode->name, (const xmlChar*)"font") != 0) {
                continue;
            }

            int weight = atoi((const char*)(xmlGetProp(fontNode, (const xmlChar*)"weight"))) / 100;
            bool italic = xmlStrcmp(
                    xmlGetProp(fontNode, (const xmlChar*)"style"), (const xmlChar*)"italic") == 0;

            xmlChar* fontFileName = xmlNodeListGetString(doc, fontNode->xmlChildrenNode, 1);
            std::string fontPath = kFontDir + std::string((const char*)fontFileName);
            xmlFree(fontFileName);

            if (access(fontPath.c_str(), R_OK) != 0) {
                // Skip not accessible fonts.
                continue;
            }

            family->addFont(new MinikinFontForTest(fontPath), android::FontStyle(weight, italic));
        }
        families.push_back(family);
    }
    xmlFreeDoc(doc);

    std::unique_ptr<android::FontCollection> r(new android::FontCollection(families));
    for (size_t i = 0; i < families.size(); ++i) {
        families[i]->Unref();
    }
    return r;
}
