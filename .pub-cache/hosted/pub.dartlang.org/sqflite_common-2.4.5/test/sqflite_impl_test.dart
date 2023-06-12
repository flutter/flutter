import 'package:sqflite_common/src/collection_utils.dart';
import 'package:sqflite_common/src/exception.dart';
import 'package:test/test.dart';

void main() {
  group('sqflite', () {
    test('Rows', () {
      final raw = <dynamic>[
        <dynamic, dynamic>{'col': 1}
      ];
      final rows = Rows.from(raw);
      final row = rows.first;
      expect(rows, raw);
      expect(row, <String, Object?>{'col': 1});
    });

    test('fromRawOperationResult', () async {
      expect(fromRawOperationResult(<String, Object?>{'result': 1}), 1);
      expect(
          fromRawOperationResult(<String, Object?>{
            'result': <dynamic, dynamic>{
              'columns': <dynamic>['column'],
              'rows': <dynamic>[
                <int>[1]
              ]
            }
          }),
          <Map<String, Object?>>[
            <String, Object?>{'column': 1}
          ]);
      var exception = fromRawOperationResult(<dynamic, dynamic>{
        'error': <dynamic, dynamic>{
          'code': 1234,
          'message': 'hello',
          'data': <dynamic, dynamic>{'some': 'data'}
        }
      }) as SqfliteDatabaseException;
      expect(exception.message, 'hello');
      expect(exception.result, <dynamic, dynamic>{'some': 'data'});
      expect(exception.getResultCode(), null);

      exception = fromRawOperationResult(<dynamic, dynamic>{
        'error': <dynamic, dynamic>{
          'code': 1234,
          'message': 'hello',
          'data': <dynamic, dynamic>{'some': 'data'},
          'resultCode': 1,
        }
      }) as SqfliteDatabaseException;
      expect(exception.message, 'hello');
      expect(exception.result, <dynamic, dynamic>{'some': 'data'});
      expect(exception.getResultCode(), 1);
    });
    test('ResultSet', () {
      final raw = <dynamic, dynamic>{
        'columns': <dynamic>['column'],
        'rows': <dynamic>[
          <int>[1]
        ]
      };
      final queryResultSet = QueryResultSet(<dynamic>[
        'column'
      ], <dynamic>[
        <dynamic>[1]
      ]);
      expect(queryResultSet.columnIndex('dummy'), isNull);
      expect(queryResultSet.columnIndex('column'), 0);
      final row = queryResultSet.first;
      //expect(rows, raw);
      expect(row, <String, Object?>{'column': 1});

      // read only
      try {
        row['column'] = 2;
        fail('should have failed');
      } on UnsupportedError catch (_) {}
      final map = Map<String, Object?>.from(row);
      // now can modify
      map['column'] = 2;

      final queryResultSetMap = <dynamic, dynamic>{
        'columns': <dynamic>['id', 'name'],
        'rows': <List<dynamic>>[
          <dynamic>[1, 'item 1'],
          <dynamic>[2, 'item 2']
        ]
      };
      final expected = <Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'item 1'},
        <String, Object?>{'id': 2, 'name': 'item 2'}
      ];
      expect(queryResultToList(queryResultSetMap), expected);
      expect(queryResultToList(expected), expected);
      expect(queryResultToList(raw), <Map<String, Object?>>[
        <String, Object?>{'column': 1}
      ]);

      expect(queryResultToList(<String, Object?>{}), <dynamic>[]);
    });

    test('duplicated key', () {
      final queryResultSet = QueryResultSet(<dynamic>[
        'col',
        'col'
      ], <dynamic>[
        <dynamic>[1, 2]
      ]);
      // last one wins...
      expect(queryResultSet.columnIndex('col'), 1);
      final row = queryResultSet.first;
      expect(row['col'], 2);

      expect(row.length, 1);
      expect(row.keys, <String>['col']);
      expect(row.values, <dynamic>[2]);
      expect(row, <String, Object?>{'col': 2});
    });

    test('lockWarning', () {});
  });
}
