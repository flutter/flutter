/*
 * Copyright (C) 2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2008, 2009, 2010 Apple Inc. All rights reserved.
 * Copyright (C) 2008 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2009 - 2010  Torch Mobile (Beijing) Co. Ltd. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#ifndef BisonCSSParser_h
#define BisonCSSParser_h

#include "gen/sky/core/CSSPropertyNames.h"
#include "gen/sky/core/CSSValueKeywords.h"
#include "sky/engine/core/css/CSSCalculationValue.h"
#include "sky/engine/core/css/CSSFilterValue.h"
#include "sky/engine/core/css/CSSGradientValue.h"
#include "sky/engine/core/css/CSSProperty.h"
#include "sky/engine/core/css/CSSPropertySourceData.h"
#include "sky/engine/core/css/CSSSelector.h"
#include "sky/engine/core/css/MediaQuery.h"
#include "sky/engine/core/css/StylePropertySet.h"
#include "sky/engine/core/css/parser/CSSParserMode.h"
#include "sky/engine/core/css/parser/CSSParserObserver.h"
#include "sky/engine/core/css/parser/CSSParserValues.h"
#include "sky/engine/core/css/parser/CSSPropertyParser.h"
#include "sky/engine/core/css/parser/CSSTokenizer.h"
#include "sky/engine/platform/graphics/Color.h"
#include "sky/engine/wtf/HashSet.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/Vector.h"
#include "sky/engine/wtf/text/AtomicString.h"
#include "sky/engine/wtf/text/TextPosition.h"

namespace blink {

class AnimationParseContext;
class CSSBorderImageSliceValue;
class CSSPrimitiveValue;
class CSSSelectorList;
class CSSValue;
class CSSValueList;
class CSSBasicShape;
class CSSBasicShapeInset;
class Document;
class Element;
class ImmutableStylePropertySet;
class MediaQueryExp;
class MediaQuerySet;
class MutableStylePropertySet;
class StyleColor;
class StyleKeyframe;
class StylePropertyShorthand;
class StyleRuleBase;
class StyleRuleKeyframes;
class StyleKeyframe;
class StyleSheetContents;
class UseCounter;

// FIXME: This class is shared with CSSTokenizer so should we rename it to CSSSourceLocation?
struct CSSParserLocation {
    unsigned offset;
    unsigned lineNumber;
    CSSParserString token;
};

class BisonCSSParser {
    STACK_ALLOCATED();
    friend inline int cssyylex(void*, BisonCSSParser*);
public:
    explicit BisonCSSParser(const CSSParserContext&);
    ~BisonCSSParser();

    void rollbackLastProperties(int num);
    void setCurrentProperty(CSSPropertyID);

    void parseSheet(StyleSheetContents*, const String&, const TextPosition& startPosition = TextPosition::minimumPosition(), CSSParserObserver* = 0, bool = false);
    PassRefPtr<StyleRuleBase> parseRule(StyleSheetContents*, const String&);
    PassRefPtr<StyleKeyframe> parseKeyframeRule(StyleSheetContents*, const String&);
    bool parseSupportsCondition(const String&);
    static bool parseValue(MutableStylePropertySet*, CSSPropertyID, const String&, bool important, CSSParserMode, StyleSheetContents*);
    static bool parseColor(RGBA32& color, const String&, bool strict = false);
    static StyleColor colorFromRGBColorString(const String&);
    static bool parseSystemColor(RGBA32& color, const String&);
    static PassRefPtr<CSSValueList> parseFontFaceValue(const AtomicString&);
    static PassRefPtr<CSSValue> parseAnimationTimingFunctionValue(const String&);
    bool parseDeclaration(MutableStylePropertySet*, const String&, CSSParserObserver*, StyleSheetContents* contextStyleSheet);
    static PassRefPtr<ImmutableStylePropertySet> parseInlineStyleDeclaration(const String&, Element*);
    PassRefPtr<MediaQuerySet> parseMediaQueryList(const String&);
    PassOwnPtr<Vector<double> > parseKeyframeKeyList(const String&);
    bool parseAttributeMatchType(CSSSelector::AttributeMatchType&, const String&);

    static bool parseValue(MutableStylePropertySet*, CSSPropertyID, const String&, bool important, const Document&);

    bool parseValue(CSSPropertyID, bool important);
    void parseSelector(const String&, CSSSelectorList&);

    CSSParserSelector* createFloatingSelector();
    CSSParserSelector* createFloatingSelectorWithTagName(const QualifiedName&);
    PassOwnPtr<CSSParserSelector> sinkFloatingSelector(CSSParserSelector*);

    Vector<OwnPtr<CSSParserSelector> >* createFloatingSelectorVector();
    PassOwnPtr<Vector<OwnPtr<CSSParserSelector> > > sinkFloatingSelectorVector(Vector<OwnPtr<CSSParserSelector> >*);

    CSSParserValueList* createFloatingValueList();
    PassOwnPtr<CSSParserValueList> sinkFloatingValueList(CSSParserValueList*);

    CSSParserFunction* createFloatingFunction();
    CSSParserFunction* createFloatingFunction(const CSSParserString& name, PassOwnPtr<CSSParserValueList> args);
    PassOwnPtr<CSSParserFunction> sinkFloatingFunction(CSSParserFunction*);

    CSSParserValue& sinkFloatingValue(CSSParserValue&);

    MediaQuerySet* createMediaQuerySet();
    StyleKeyframe* createKeyframe(CSSParserValueList*);
    StyleRuleKeyframes* createKeyframesRule(const String&, PassOwnPtr<Vector<RefPtr<StyleKeyframe> > >, bool isPrefixed);

    typedef Vector<RefPtr<StyleRuleBase> > RuleList;
    StyleRuleBase* createMediaRule(MediaQuerySet*, RuleList*);
    RuleList* createRuleList();
    RuleList* appendRule(RuleList*, StyleRuleBase*);
    StyleRuleBase* createStyleRule(Vector<OwnPtr<CSSParserSelector> >* selectors);
    StyleRuleBase* createFontFaceRule();
    StyleRuleBase* createSupportsRule(bool conditionIsSupported, RuleList*);
    void markSupportsRuleHeaderStart();
    void markSupportsRuleHeaderEnd();
    PassRefPtr<CSSRuleSourceData> popSupportsRuleData();
    StyleRuleBase* createHostRule(RuleList* rules);

    void startDeclarationsForMarginBox();
    void endDeclarationsForMarginBox();

    MediaQueryExp* createFloatingMediaQueryExp(const AtomicString&, CSSParserValueList*);
    PassOwnPtr<MediaQueryExp> sinkFloatingMediaQueryExp(MediaQueryExp*);
    Vector<OwnPtr<MediaQueryExp> >* createFloatingMediaQueryExpList();
    PassOwnPtr<Vector<OwnPtr<MediaQueryExp> > > sinkFloatingMediaQueryExpList(Vector<OwnPtr<MediaQueryExp> >*);
    MediaQuery* createFloatingMediaQuery(MediaQuery::Restrictor, const AtomicString&, PassOwnPtr<Vector<OwnPtr<MediaQueryExp> > >);
    MediaQuery* createFloatingMediaQuery(PassOwnPtr<Vector<OwnPtr<MediaQueryExp> > >);
    MediaQuery* createFloatingNotAllQuery();
    PassOwnPtr<MediaQuery> sinkFloatingMediaQuery(MediaQuery*);

    Vector<RefPtr<StyleKeyframe> >* createFloatingKeyframeVector();
    PassOwnPtr<Vector<RefPtr<StyleKeyframe> > > sinkFloatingKeyframeVector(Vector<RefPtr<StyleKeyframe> >*);

    CSSParserSelector* rewriteSpecifiersWithElementName(const AtomicString& namespacePrefix, const AtomicString& elementName, CSSParserSelector*, bool isNamespacePlaceholder = false);
    CSSParserSelector* rewriteSpecifiersWithNamespaceIfNeeded(CSSParserSelector*);
    CSSParserSelector* rewriteSpecifiers(CSSParserSelector*, CSSParserSelector*);
    CSSParserSelector* rewriteSpecifiersForShadowDistributed(CSSParserSelector* specifiers, CSSParserSelector* distributedPseudoElementSelector);

    void invalidBlockHit();

    Vector<OwnPtr<CSSParserSelector> >* reusableSelectorVector() { return &m_reusableSelectorVector; }

    void clearProperties();

    PassRefPtr<ImmutableStylePropertySet> createStylePropertySet();

    CSSParserContext m_context;

    bool m_important;
    CSSPropertyID m_id;
    RawPtr<StyleSheetContents> m_styleSheet;
    RefPtr<StyleRuleBase> m_rule;
    RefPtr<StyleKeyframe> m_keyframe;
    RefPtr<MediaQuerySet> m_mediaList;
    OwnPtr<CSSParserValueList> m_valueList;
    bool m_supportsCondition;

    Vector<CSSProperty, 256> m_parsedProperties;
    CSSSelectorList* m_selectorListForParseSelector;

    unsigned m_numParsedPropertiesBeforeMarginBox;

    bool m_hadSyntacticallyValidCSSRule;
    bool m_logErrors;
    bool m_ignoreErrors;

    AtomicString m_defaultNamespace;

    // tokenizer methods and data
    CSSParserObserver* m_observer;

    // Local functions which just call into CSSParserObserver if non-null.
    void startRule();
    void endRule(bool valid);
    void startRuleHeader(CSSRuleSourceData::Type);
    void endRuleHeader();
    void startSelector();
    void endSelector();
    void startRuleBody();
    void startProperty();
    void endProperty(bool isImportantFound, bool isPropertyParsed, CSSParserError = NoCSSError);
    void startEndUnknownRule();

    void endInvalidRuleHeader();
    void reportError(const CSSParserLocation&, CSSParserError = GeneralCSSError);
    void resumeErrorLogging() { m_ignoreErrors = false; }
    void setLocationLabel(const CSSParserLocation& location) { m_locationLabel = location; }
    const CSSParserLocation& lastLocationLabel() const { return m_locationLabel; }

    void tokenToLowerCase(CSSParserString& token);

    CSSParserLocation currentLocation() { return m_tokenizer.currentLocation(); }

private:
    inline void ensureLineEndings();

    void setStyleSheet(StyleSheetContents* styleSheet) { m_styleSheet = styleSheet; }

    bool inViewport() const { return m_inViewport; }

    void recheckAtKeyword(const UChar* str, int len);

    template<unsigned prefixLength, unsigned suffixLength>
    inline void setupParser(const char (&prefix)[prefixLength], const String& string, const char (&suffix)[suffixLength])
    {
        setupParser(prefix, prefixLength - 1, string, suffix, suffixLength - 1);
    }
    void setupParser(const char* prefix, unsigned prefixLength, const String&, const char* suffix, unsigned suffixLength);

    bool parseValue(MutableStylePropertySet*, CSSPropertyID, const String&, bool important, StyleSheetContents* contextStyleSheet);
    PassRefPtr<ImmutableStylePropertySet> parseDeclaration(const String&, StyleSheetContents* contextStyleSheet);

    bool parseColor(const String&);

    const String* m_source;
    TextPosition m_startPosition;
    CSSRuleSourceData::Type m_ruleHeaderType;
    unsigned m_ruleHeaderStartOffset;
    int m_ruleHeaderStartLineNumber;
    OwnPtr<Vector<unsigned> > m_lineEndings;

    bool m_ruleHasHeader;

    bool m_allowImportRules;
    bool m_allowNamespaceDeclarations;

    bool m_inViewport;

    CSSParserLocation m_locationLabel;

    Vector<RefPtr<StyleRuleBase> > m_parsedRules;
    Vector<RefPtr<StyleKeyframe> > m_parsedKeyframes;
    Vector<RefPtr<MediaQuerySet> > m_parsedMediaQuerySets;
    Vector<OwnPtr<RuleList> > m_parsedRuleLists;
    Vector<CSSParserSelector*> m_floatingSelectors;
    Vector<Vector<OwnPtr<CSSParserSelector> >*> m_floatingSelectorVectors;
    Vector<CSSParserValueList*> m_floatingValueLists;
    Vector<CSSParserFunction*> m_floatingFunctions;

    OwnPtr<MediaQuery> m_floatingMediaQuery;
    OwnPtr<MediaQueryExp> m_floatingMediaQueryExp;
    OwnPtr<Vector<OwnPtr<MediaQueryExp> > > m_floatingMediaQueryExpList;

    OwnPtr<Vector<RefPtr<StyleKeyframe> > > m_floatingKeyframeVector;

    Vector<OwnPtr<CSSParserSelector> > m_reusableSelectorVector;

    OwnPtr<RuleSourceDataList> m_supportsRuleDataStack;

    bool isLoggingErrors();
    void logError(const String& message, const CSSParserLocation&);

    CSSTokenizer m_tokenizer;

    friend class TransformOperationInfo;
    friend class FilterOperationInfo;
};

inline int cssyylex(void* yylval, BisonCSSParser* parser)
{
    return parser->m_tokenizer.lex(yylval);
}

bool isValidNthToken(const CSSParserString&);

} // namespace blink

#endif // BisonCSSParser_h
