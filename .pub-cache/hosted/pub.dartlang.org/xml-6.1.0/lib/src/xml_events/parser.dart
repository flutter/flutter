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

  Parser<XmlStartElementEvent> startElement() => [
        XmlToken.openElement.toParser(),
        ref0(nameToken),
        ref0(attributes),
        ref0(spaceOptional),
        [
          XmlToken.closeElement.toParser(),
          XmlToken.closeEndElement.toParser(),
        ].toChoiceParser(failureJoiner: selectFirst),
      ].toSequenceParser().map((each) => XmlStartElementEvent(
          each[1] as String,
          each[2] as List<XmlEventAttribute>,
          each[4] == XmlToken.closeEndElement));

  Parser<List<XmlEventAttribute>> attributes() => ref0(attribute).star();

  Parser<XmlEventAttribute> attribute() => [
        ref0(space),
        ref0(nameToken),
        ref0(spaceOptional),
        XmlToken.equals.toParser(),
        ref0(spaceOptional),
        ref0(attributeValue),
      ].toSequenceParser().map((each) {
        final attributeValue = each[5] as List<String>;
        return XmlEventAttribute(
            each[1] as String,
            entityMapping.decode(attributeValue[1]),
            XmlAttributeType.fromToken(attributeValue[0]));
      });

  Parser<List<String>> attributeValue() => [
        ref0(attributeValueDouble),
        ref0(attributeValueSingle),
      ].toChoiceParser();

  Parser<List<String>> attributeValueDouble() => [
        XmlToken.doubleQuote.toParser(),
        XmlCharacterDataParser(XmlToken.doubleQuote, 0),
        XmlToken.doubleQuote.toParser(),
      ].toSequenceParser();

  Parser<List<String>> attributeValueSingle() => [
        XmlToken.singleQuote.toParser(),
        XmlCharacterDataParser(XmlToken.singleQuote, 0),
        XmlToken.singleQuote.toParser(),
      ].toSequenceParser();

  Parser<XmlEndElementEvent> endElement() => [
        XmlToken.openEndElement.toParser(),
        ref0(nameToken),
        ref0(spaceOptional),
        XmlToken.closeElement.toParser(),
      ].toSequenceParser().map((each) => XmlEndElementEvent(each[1]));

  Parser<XmlCommentEvent> comment() => [
        XmlToken.openComment.toParser(),
        any()
            .starLazy(XmlToken.closeComment.toParser())
            .flatten('"${XmlToken.closeComment}" expected'),
        XmlToken.closeComment.toParser(),
      ].toSequenceParser().map((each) => XmlCommentEvent(each[1]));

  Parser<XmlCDATAEvent> cdata() => [
        XmlToken.openCDATA.toParser(),
        any()
            .starLazy(XmlToken.closeCDATA.toParser())
            .flatten('"${XmlToken.closeCDATA}" expected'),
        XmlToken.closeCDATA.toParser(),
      ].toSequenceParser().map((each) => XmlCDATAEvent(each[1]));

  Parser<XmlDeclarationEvent> declaration() => [
        XmlToken.openDeclaration.toParser(),
        ref0(attributes),
        ref0(spaceOptional),
        XmlToken.closeDeclaration.toParser(),
      ].toSequenceParser().map(
          (each) => XmlDeclarationEvent(each[1] as List<XmlEventAttribute>));

  Parser<XmlProcessingEvent> processing() => [
        XmlToken.openProcessing.toParser(),
        ref0(nameToken),
        [
          ref0(space),
          any()
              .starLazy(XmlToken.closeProcessing.toParser())
              .flatten('"${XmlToken.closeProcessing}" expected'),
        ].toSequenceParser().pick(1).optionalWith(''),
        XmlToken.closeProcessing.toParser(),
      ].toSequenceParser().map((each) => XmlProcessingEvent(each[1], each[2]));

  Parser<XmlDoctypeEvent> doctype() => [
        XmlToken.openDoctype.toParser(),
        ref0(space),
        ref0(nameToken),
        ref0(doctypeExternalId).skip(before: ref0(space)).optional(),
        ref0(spaceOptional),
        ref0(doctypeIntSubset).optional(),
        ref0(spaceOptional),
        XmlToken.closeDoctype.toParser(),
      ].toSequenceParser().map((each) {
        final name = each[2] as String;
        final externalId = each[3] as DtdExternalId?;
        final internalSubset = each[5] as String?;
        return XmlDoctypeEvent(name, externalId, internalSubset);
      });

  // DTD entities

  Parser<DtdExternalId> doctypeExternalId() => [
        [
          XmlToken.doctypeSystemId.toParser(),
          ref0(space),
          ref0(attributeValue),
        ].toSequenceParser().map((each) {
          final system = each[2] as List<String>;
          return DtdExternalId.system(
            system[1],
            XmlAttributeType.fromToken(system[0]),
          );
        }),
        [
          XmlToken.doctypePublicId.toParser(),
          ref0(space),
          ref0(attributeValue),
          ref0(space),
          ref0(attributeValue),
        ].toSequenceParser().map((each) {
          final public = each[2] as List<String>;
          final system = each[4] as List<String>;
          return DtdExternalId.public(
            public[1],
            XmlAttributeType.fromToken(public[0]),
            system[1],
            XmlAttributeType.fromToken(system[0]),
          );
        }),
      ].toChoiceParser();

  Parser<String> doctypeIntSubset() => [
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
      ].toSequenceParser().pick(1);

  Parser doctypeElementDecl() => [
        XmlToken.doctypeElementDecl.toParser(),
        [
          ref0(nameToken),
          ref0(attributeValue),
          any(),
        ].toChoiceParser().starLazy(XmlToken.doctypeDeclEnd.toParser()),
        XmlToken.doctypeDeclEnd.toParser(),
      ].toSequenceParser();

  Parser doctypeAttlistDecl() => [
        XmlToken.doctypeAttlistDecl.toParser(),
        [
          ref0(nameToken),
          ref0(attributeValue),
          any(),
        ].toChoiceParser().starLazy(XmlToken.doctypeDeclEnd.toParser()),
        XmlToken.doctypeDeclEnd.toParser(),
      ].toSequenceParser();

  Parser doctypeEntityDecl() => [
        XmlToken.doctypeEntityDecl.toParser(),
        [
          ref0(nameToken),
          ref0(attributeValue),
          any(),
        ].toChoiceParser().starLazy(XmlToken.doctypeDeclEnd.toParser()),
        XmlToken.doctypeDeclEnd.toParser(),
      ].toSequenceParser();

  Parser doctypeNotationDecl() => [
        XmlToken.doctypeNotationDecl.toParser(),
        [
          ref0(nameToken),
          ref0(attributeValue),
          any(),
        ].toChoiceParser().starLazy(XmlToken.doctypeDeclEnd.toParser()),
        XmlToken.doctypeDeclEnd.toParser(),
      ].toSequenceParser();

  Parser doctypeReference() => [
        XmlToken.doctypeReferenceStart.toParser(),
        ref0(nameToken),
        XmlToken.doctypeReferenceEnd.toParser(),
      ].toSequenceParser();

  // Tokens

  Parser<String> space() => whitespace().plus().flatten('whitespace expected');

  Parser<String> spaceOptional() =>
      whitespace().star().flatten('whitespace expected');

  Parser<String> nameToken() => [
        ref0(nameStartChar),
        ref0(nameChar).star(),
      ].toSequenceParser().flatten('name expected');

  Parser<String> nameStartChar() => pattern(XmlToken.nameStartChars);

  Parser<String> nameChar() => pattern(XmlToken.nameChars);
}

final XmlCache<XmlEntityMapping, Parser<XmlEvent>> eventParserCache =
    XmlCache((entityMapping) => XmlEventParser(entityMapping).build(), 5);
