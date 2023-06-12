import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:test/test.dart';

void main() {
  group('upgrading DateTimeAdapter to DateTimeWithTimeZoneAdapter', () {
    group('TypeRegistry', () {
      late TypeRegistryImpl registry;

      setUp(() {
        registry = TypeRegistryImpl();
        registry.registerAdapter(DateTimeWithTimezoneAdapter(), internal: true);
        registry.registerAdapter(DateTimeAdapter(), internal: true);
      });

      tearDown(() {
        registry.resetAdapters();
      });

      test('uses DateTimeWithTimeZoneAdapter for writing new values', () {
        var result = registry.findAdapterForValue(DateTime.now())!;
        expect(result, isNotNull);
        expect(result.adapter, isA<DateTimeWithTimezoneAdapter>());
      });

      test('uses DateTimeWithTimeZoneAdapter for reading if typeId = 18', () {
        var result = registry.findAdapterForTypeId(18)!;
        expect(result, isNotNull);
        expect(result.adapter, isA<DateTimeWithTimezoneAdapter>());
      });

      test('uses DateTimeAdapter for reading if typeId = 16', () {
        var result = registry.findAdapterForTypeId(16)!;
        expect(result, isNotNull);
        expect(result.adapter, isA<DateTimeAdapter>());
      });
    });
  });
}
