#!/bin/bash
set -ex

# Download flutter.
./bin/flutter --version

# Download dependencies.
# We precache this to reduce the number of network round-trips and
# thus speed up Travis.
# Avoid adding anything here if you can. We are trying to limit our
# total dependencies.
pub cache add --all analyzer
pub cache add --all archive
pub cache add --all args
pub cache add --all asn1lib
pub cache add --all async
pub cache add --all barback
pub cache add --all bignum
pub cache add --all boolean_selector
pub cache add --all box2d
pub cache add --all charcode
pub cache add --all cli_util
pub cache add --all code_transformers
pub cache add --all collection
pub cache add --all contrast
pub cache add --all crypto
pub cache add --all csslib
pub cache add --all dart_style
pub cache add --all den_api
pub cache add --all file
pub cache add --all fixnum
pub cache add --all flutter_gallery_assets
pub cache add --all github
pub cache add --all glob
pub cache add --all html
pub cache add --all http
pub cache add --all http_multi_server
pub cache add --all http_parser
pub cache add --all intl
pub cache add --all json_rpc_2
pub cache add --all logging
pub cache add --all markdown
pub cache add --all matcher
pub cache add --all mime
pub cache add --all mockito
pub cache add --all mojo
pub cache add --all mojo_sdk
pub cache add --all mojo_services
pub cache add --all mustache4dart
pub cache add --all package_config
pub cache add --all path
pub cache add --all petitparser
pub cache add --all plugin
pub cache add --all pointycastle
pub cache add --all pool
pub cache add --all pub_package_data
pub cache add --all pub_semver
pub cache add --all quiver
pub cache add --all quiver_collection
pub cache add --all quiver_iterables
pub cache add --all quiver_pattern
pub cache add --all reflectable
pub cache add --all shelf
pub cache add --all shelf_static
pub cache add --all shelf_web_socket
pub cache add --all source_map_stack_trace
pub cache add --all source_maps
pub cache add --all source_span
pub cache add --all stack_trace
pub cache add --all stream_channel
pub cache add --all string_scanner
pub cache add --all test
pub cache add --all utf
pub cache add --all vector_math
pub cache add --all vm_service_client
pub cache add --all watcher
pub cache add --all when
pub cache add --all which
pub cache add --all xml
pub cache add --all yaml
./bin/flutter --verbose update-packages --offline
