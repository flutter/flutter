import 'package:petitparser/petitparser.dart';

import '../xml/dtd/external_id.dart';
import '../xml/entities/entity_mapping.dart';
import '../xml/enums/attribute_type.dart';
import '../xml/utils/cache.dart';
import '../xml/utils/character_data_parser.dart';
import '../xml/utils/token.dart';
import 'event.dart';
import 'events/cdata.dart';
import 'events/comment.dart';
import 'events/declaration.dart';
import 'events/doctype.dart';
import 'events/end_element.dart';
import 'events/processing.dart';
import 'events/start_element.dart';
import 'events/text.dart';
import 'utils/event_attribute.dart';

class XmlEventParser {
  const XmlEventParser(this.entityMapping);

  final XmlEntityMapping entityMapping;

  Parser<XmlEvent> build() => resolve<XmlEvent>(ref0(event));

  Parser<XmlEvent> event() => [
        ref0(characterData),
        ref0(startElement),
        ref0(endElement),
        ref0(comment),
        ref0(cdata),
        ref0(declaration),
        ref0(processing),
        ref0(doctype),
      ].toChoiceParser(failureJoiner: selectFarthest);

  // Events

  Parser<XmlTextEvent> characterData() =>
      XmlCharacterDataParser(XmlToken.openElement, 1)
          .map((each) => XmlRawTextEvent(each, entityMapping));

  Parser<XmlStartElementEvent> startElement() => seq5(
        XmlToken.openElement.toParser(),
        ref0(nameToken),
        ref0(attributes),
        ref0(spaceOptional),
        [
          XmlToken.closeElement.toParser(),
          XmlToken.closeEndElement.toParser(),
        ].toChoiceParser(failureJoiner: selectFirst),
      ).map5((_, nameToken, attributes, __, closeElement) =>
          XmlStartElementEvent(
              nameToken, attributes, closeElement == XmlToken.closeEndElement));

  Parser<List<XmlEventAttribute>> attributes() => ref0(attribute).star();

  Parser<XmlEventAttribute> attribute() => seq6(
        ref0(space),
        ref0(nameToken),
        ref0(spaceOptional),
        XmlToken.equals.toParser(),
        ref0(spaceOptional),
        ref0(attributeValue),
      ).map6((_, name, __, ___, ____, attribute) => XmlEventAttribute(
          name,
          entityMapping.decode(attribute.second),
          XmlAttributeType.fromToken(attribute.first)));

  Parser<Sequence3<String, String, String>> attributeValue() => [
        ref0(attributeValueDouble),
        ref0(attributeValueSingle),
      ].toChoiceParser();

  Parser<Sequence3<String, String, String>> attributeValueDouble() => seq3(
        XmlToken.doubleQuote.toParser(),
        XmlCharacterDataParser(XmlToken.doubleQuote, 0),
        XmlToken.doubleQuote.toParser(),
      );

  Parser<Sequence3<String, String, String>> attributeValueSingle() => seq3(
        XmlToken.singleQuote.toParser(),
        XmlCharacterDataParser(XmlToken.singleQuote, 0),
        XmlToken.singleQuote.toParser(),
      );

  Parser<XmlEndElementEvent> endElement() => seq4(
        XmlToken.openEndElement.toParser(),
        ref0(nameToken),
        ref0(spaceOptional),
        XmlToken.closeElement.toParser(),
      ).map4((_, name, __, ___) => XmlEndElementEvent(name));

  Parser<XmlCommentEvent> comment() => seq3(
        XmlToken.openComment.toParser(),
        any()
            .starLazy(XmlToken.closeComment.toParser())
            .flatten('"${XmlToken.closeComment}" expected'),
        XmlToken.closeComment.toParser(),
      ).map3((_, text, __) => XmlCommentEvent(text));

  Parser<XmlCDATAEvent> cdata() => seq3(
        XmlToken.openCDATA.toParser(),
        any()
            .starLazy(XmlToken.closeCDATA.toParser())
            .flatten('"${XmlToken.closeCDATA}" expected'),
        XmlToken.closeCDATA.toParser(),
      ).map3((_, text, __) => XmlCDATAEvent(text));

  Parser<XmlDeclarationEvent> declaration() => seq4(
        XmlToken.openDeclaration.toParser(),
        ref0(attributes),
        ref0(spaceOptional),
        XmlToken.closeDeclaration.toParser(),
      ).map4((_, attributes, __, ___) => XmlDeclarationEvent(attributes));

  Parser<XmlProcessingEvent> processing() => seq4(
        XmlToken.openProcessing.toParser(),
        ref0(nameToken),
        seq2(
          ref0(space),
          any()
              .starLazy(XmlToken.closeProcessing.toParser())
              .flatten('"${XmlToken.closeProcessing}" expected'),
        ).map2((_, text) => text).optionalWith(''),
        XmlToken.closeProcessing.toParser(),
      ).map4((_, target, text, __) => XmlProcessingEvent(target, text));

  Parser<XmlDoctypeEvent> doctype() => seq8(
        XmlToken.openDoctype.toParser(),
        ref0(space),
        ref0(nameToken),
        ref0(doctypeExternalId).skip(before: ref0(space)).optional(),
        ref0(spaceOptional),
        ref0(doctypeIntSubset).optional(),
        ref0(spaceOptional),
        XmlToken.closeDoctype.toParser(),
      ).map8((_, __, name, externalId, ___, internalSubset, ____, _____) =>
          XmlDoctypeEvent(name, externalId, internalSubset));

  // DTD entities

  Parser<DtdExternalId> doctypeExternalId() => [
        ref0(doctypeExternalIdSystem),
        ref0(doctypeExternalIdPublic),
      ].toChoiceParser();

  Parser<DtdExternalId> doctypeExternalIdSystem() => seq3(
        XmlToken.doctypeSystemId.toParser(),
        ref0(space),
        ref0(attributeValue),
      ).map3((_, __, attribute) => DtdExternalId.system(
          attribute.second, XmlAttributeType.fromToken(attribute.first)));

  Parser<DtdExternalId> doctypeExternalIdPublic() => seq5(
        XmlToken.doctypePublicId.toParser(),
        ref0(space),
        ref0(attributeValue),
        ref0(space),
        ref0(attributeValue),
      ).map5((_, __, publicAttribute, ___, systemAttribute) =>
          DtdExternalId.public(
              publicAttribute.second,
              XmlAttributeType.fromToken(publicAttribute.first),
              systemAttribute.second,
              XmlAttributeType.fromToken(systemAttribute.first)));

  Parser<String> doctypeIntSubset() => seq3(
        XmlToken.openDoctypeIntSubset.toParser(),
        [
          ref0(doctypeElementDecl),
          ref0(doctypeAttlistDecl),
          ref0(doctypeEntityDecl),
          ref0(doctypeNotationDecl),
          ref0(processing),
          ref0(comment),
          ref0(doctypeReference),
          any(),
        ]
            .toChoiceParser()
            .starLazy(XmlToken.closeDoctypeIntSubset.toParser())
            .flatten('"${XmlToken.closeDoctypeIntSubset}" expected'),
        XmlToken.closeDoctypeIntSubset.toParser(),
      ).map3((_, contents, __) => contents);

  Parser doctypeElementDecl() => seq3(
        XmlToken.doctypeElementDecl.toParser(),
        [
          ref0(nameToken),
          ref0(attributeValue),
          any(),
        ].toChoiceParser().starLazy(XmlToken.doctypeDeclEnd.toParser()),
        XmlToken.doctypeDeclEnd.toParser(),
      );

  Parser doctypeAttlistDecl() => seq3(
        XmlToken.doctypeAttlistDecl.toParser(),
        [
          ref0(nameToken),
          ref0(attributeValue),
          any(),
        ].toChoiceParser().starLazy(XmlToken.doctypeDeclEnd.toParser()),
        XmlToken.doctypeDeclEnd.toParser(),
      );

  Parser doctypeEntityDecl() => seq3(
        XmlToken.doctypeEntityDecl.toParser(),
        [
          ref0(nameToken),
          ref0(attributeValue),
          any(),
        ].toChoiceParser().starLazy(XmlToken.doctypeDeclEnd.toParser()),
        XmlToken.doctypeDeclEnd.toParser(),
      );

  Parser doctypeNotationDecl() => seq3(
        XmlToken.doctypeNotationDecl.toParser(),
        [
          ref0(nameToken),
          ref0(attributeValue),
          any(),
        ].toChoiceParser().starLazy(XmlToken.doctypeDeclEnd.toParser()),
        XmlToken.doctypeDeclEnd.toParser(),
      );

  Parser doctypeReference() => seq3(
        XmlToken.doctypeReferenceStart.toParser(),
        ref0(nameToken),
        XmlToken.doctypeReferenceEnd.toParser(),
      );

  // Tokens

  Parser<String> space() => whitespace().plus().flatten('whitespace expected');

  Parser<String> spaceOptional() =>
      whitespace().star().flatten('whitespace expected');

  Parser<String> nameToken() =>
      seq2(ref0(nameStartChar), ref0(nameChar).star()).flatten('name expected');

  Parser<String> nameStartChar() => pattern(XmlToken.nameStartChars);

  Parser<String> nameChar() => pattern(XmlToken.nameChars);
}

final XmlCache<XmlEntityMapping, Parser<XmlEvent>> eventParserCache =
    XmlCache((entityMapping) => XmlEventParser(entityMapping).build(), 5);
