import 'package:test/test.dart';
import 'package:xml/xml.dart';

import 'utils/examples.dart';

void main() {
  group('elements', () {
    final bookstore = XmlDocument.parse(bookstoreXml).rootElement;
    final shiporder = XmlDocument.parse(shiporderXsd).rootElement;
    const xsd = 'http://www.w3.org/2001/XMLSchema';
    test('name defined, namespace undefined', () {
      final books = bookstore.findElements('book');
      expect(books.length, 2);
      final orders = shiporder.findElements('element');
      expect(orders.length, 0);
    });
    test('name defined, namespace wildcard', () {
      final books = bookstore.findElements('book', namespace: '*');
      expect(books.length, 2);
      final orders = shiporder.findElements('element', namespace: '*');
      expect(orders.length, 2);
    });
    test('name defined, namespace defined', () {
      final books = bookstore.findElements('book', namespace: xsd);
      expect(books.length, 0);
      final orders = shiporder.findElements('element', namespace: xsd);
      expect(orders.length, 2);
    });
    test('name wildcard, namespace undefined', () {
      final books = bookstore.findElements('*');
      expect(books.length, 2);
      final orders = shiporder.findElements('*');
      expect(orders.length, 7);
    });
    test('name wildcard, namespace wildcard', () {
      final books = bookstore.findElements('*', namespace: '*');
      expect(books.length, 2);
      final orders = shiporder.findElements('*', namespace: '*');
      expect(orders.length, 7);
    });
    test('name wildcard, namespace defined', () {
      final books = bookstore.findElements('*', namespace: xsd);
      expect(books.length, 0);
      final orders = shiporder.findElements('*', namespace: xsd);
      expect(orders.length, 7);
    });
  });
  group('all elements', () {
    final bookstore = XmlDocument.parse(bookstoreXml);
    final shiporder = XmlDocument.parse(shiporderXsd);
    const xsd = 'http://www.w3.org/2001/XMLSchema';
    test('name defined, namespace undefined', () {
      final books = bookstore.findAllElements('book');
      expect(books.length, 2);
      final orders = shiporder.findAllElements('element');
      expect(orders.length, 0);
    });
    test('name defined, namespace wildcard', () {
      final books = bookstore.findAllElements('book', namespace: '*');
      expect(books.length, 2);
      final orders = shiporder.findAllElements('element', namespace: '*');
      expect(orders.length, 17);
    });
    test('name defined, namespace defined', () {
      final books = bookstore.findAllElements('book', namespace: xsd);
      expect(books.length, 0);
      final orders = shiporder.findAllElements('element', namespace: xsd);
      expect(orders.length, 17);
    });
    test('name wildcard, namespace undefined', () {
      final books = bookstore.findAllElements('*');
      expect(books.length, 7);
      final orders = shiporder.findAllElements('*');
      expect(orders.length, 37);
    });
    test('name wildcard, namespace wildcard', () {
      final books = bookstore.findAllElements('*', namespace: '*');
      expect(books.length, 7);
      final orders = shiporder.findAllElements('*', namespace: '*');
      expect(orders.length, 37);
    });
    test('name wildcard, namespace defined', () {
      final books = bookstore.findAllElements('*', namespace: xsd);
      expect(books.length, 0);
      final orders = shiporder.findAllElements('*', namespace: xsd);
      expect(orders.length, 37);
    });
  });
}
