PLUGIN_SRC = \
	prepend.dart \
	bin/protoc_plugin.dart \
	lib/*.dart \
	lib/src/descriptor.pb.dart \
	lib/src/plugin.pb.dart

OUTPUT_DIR=out
PLUGIN_NAME=protoc-gen-dart
PLUGIN_PATH=bin/$(PLUGIN_NAME)

TEST_PROTO_LIST = \
	_leading_underscores \
	google/protobuf/any \
	google/protobuf/api \
	google/protobuf/duration \
	google/protobuf/empty \
	google/protobuf/field_mask \
	google/protobuf/source_context \
	google/protobuf/struct \
	google/protobuf/timestamp \
	google/protobuf/type \
	google/protobuf/unittest_import \
	google/protobuf/unittest_nested_any \
	google/protobuf/unittest_optimize_for \
	google/protobuf/unittest_well_known_types \
	google/protobuf/unittest \
	google/protobuf/wrappers \
	bytes \
	custom_option \
	dart_name \
        default_value_escape \
	enum_extension \
	enum_name \
	extend_unittest \
	ExtensionEnumNameConflict \
	ExtensionNameConflict \
	foo \
	high_tagnumber \
	import_clash \
	import_public \
	json_name \
	map_api \
	map_api2 \
	map_enum_value \
	map_field \
	mixins \
	multiple_files_test \
	nested_extension \
	non_nested_extension \
	oneof \
	reserved_names \
	reserved_names_extension \
	reserved_names_message \
	duplicate_names_import \
	package1 \
	package2 \
	package3 \
	proto2_repeated \
	proto3_optional \
	proto3_repeated \
	service \
	service2 \
	service3 \
	toplevel_import \
	toplevel \
	using_any
TEST_PROTO_DIR=$(OUTPUT_DIR)/protos
TEST_PROTO_LIBS=$(foreach f, $(TEST_PROTO_LIST), \
  $(TEST_PROTO_DIR)/$(f).pb.dart \
	$(TEST_PROTO_DIR)/$(f).pbenum.dart \
	$(TEST_PROTO_DIR)/$(f).pbserver.dart \
	$(TEST_PROTO_DIR)/$(f).pbjson.dart)
TEST_PROTO_SRC_DIR=test/protos
TEST_PROTO_SRCS=$(foreach proto, $(TEST_PROTO_LIST), \
  $(TEST_PROTO_SRC_DIR)/$(proto).proto)

PREGENERATED_SRCS=protos/descriptor.proto protos/plugin.proto protos/dart_options.proto

$(TEST_PROTO_LIBS): $(PLUGIN_PATH) $(TEST_PROTO_SRCS)
	[ -d $(TEST_PROTO_DIR) ] || mkdir -p $(TEST_PROTO_DIR)
	protoc\
		--experimental_allow_proto3_optional\
		--dart_out=$(TEST_PROTO_DIR)\
		-Iprotos\
		-I$(TEST_PROTO_SRC_DIR)\
		--plugin=protoc-gen-dart=$(realpath $(PLUGIN_PATH))\
		$(TEST_PROTO_SRCS)
	dart format $(TEST_PROTO_DIR)

build-plugin: $(PLUGIN_PATH)

update-pregenerated: $(PLUGIN_PATH) $(PREGENERATED_SRCS)
	protoc --dart_out=lib/src/generated -Iprotos --plugin=protoc-gen-dart=$(realpath $(PLUGIN_PATH)) $(PREGENERATED_SRCS)
	rm lib/src/generated/descriptor.pb{json,server}.dart
	rm lib/src/generated/dart_options.pb{enum,json,server}.dart
	rm lib/src/generated/plugin.pb{json,server}.dart
	dart format lib/src/generated

protos: $(PLUGIN_PATH) $(TEST_PROTO_LIBS)

run-tests: protos
	dart run test

clean:
	rm -rf benchmark/lib/generated
	rm -rf $(OUTPUT_DIR)
