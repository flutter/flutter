// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/node_text_expectations.dart';
import 'abi_specific_integer_mapping_test.dart' as abi_specific_integer_mapping;
import 'abstract_class_member_test.dart' as abstract_class_member;
import 'abstract_field_constructor_initializer_test.dart'
    as abstract_field_constructor_initializer;
import 'abstract_field_initializer_test.dart' as abstract_field_initializer;
import 'abstract_super_member_reference_test.dart'
    as abstract_super_member_reference;
import 'ambiguous_export_test.dart' as ambiguous_export;
import 'ambiguous_extension_member_access_test.dart'
    as ambiguous_extension_member_access;
import 'ambiguous_import_test.dart' as ambiguous_import;
import 'ambiguous_set_or_map_literal_test.dart' as ambiguous_set_or_map_literal;
import 'analysis_options/test_all.dart' as analysis_options;
import 'annotation_on_pointer_field_test.dart' as annotation_on_pointer_field;
import 'annotation_syntax_test.dart' as annotation_syntax;
import 'argument_must_be_a_constant_test.dart' as argument_must_be_a_constant;
import 'argument_type_not_assignable_test.dart' as argument_type_not_assignable;
import 'argument_type_not_assignable_to_error_handler_test.dart'
    as argument_type_not_assignable_to_error_handler;
import 'assert_in_redirecting_constructor_test.dart'
    as assert_in_redirecting_constructor;
import 'assignment_of_do_not_store_test.dart' as assignment_of_do_not_store;
import 'assignment_to_const_test.dart' as assignment_to_const;
import 'assignment_to_final_local_test.dart' as assignment_to_final_local;
import 'assignment_to_final_no_setter_test.dart'
    as assignment_to_final_no_setter;
import 'assignment_to_final_test.dart' as assignment_to_final;
import 'assignment_to_function_test.dart' as assignment_to_function;
import 'assignment_to_method_test.dart' as assignment_to_method;
import 'assignment_to_type_test.dart' as assignment_to_type;
import 'async_for_in_wrong_context_test.dart' as async_for_in_wrong_context;
import 'async_keyword_used_as_identifier_test.dart'
    as async_keyword_used_as_identifier;
import 'await_in_late_local_variable_initializer_test.dart'
    as await_in_late_local_variable_initializer;
import 'await_in_wrong_context_test.dart' as await_in_wrong_context;
import 'base_class_implemented_outside_of_library_test.dart'
    as base_class_implemented_outside_of_library;
import 'base_mixin_implemented_outside_of_library_test.dart'
    as base_mixin_implemented_outside_of_library;
import 'binary_operator_written_out_test.dart' as binary_operator_written_out;
import 'body_might_complete_normally_catch_error_test.dart'
    as body_might_complete_normally_catch_error;
import 'body_might_complete_normally_nullable_test.dart'
    as body_might_complete_normally_nullable;
import 'body_might_complete_normally_test.dart' as body_might_complete_normally;
import 'built_in_identifier_as_extension_name_test.dart'
    as built_in_as_extension_name;
import 'built_in_identifier_as_prefix_name_test.dart'
    as built_in_as_prefix_name;
import 'built_in_identifier_as_type_name_test.dart' as built_in_as_type_name;
import 'built_in_identifier_as_type_parameter_name_test.dart'
    as built_in_as_type_parameter_name;
import 'built_in_identifier_as_typedef_name_test.dart'
    as built_in_as_typedef_name;
import 'can_be_null_after_null_aware_test.dart' as can_be_null_after_null_aware;
import 'case_block_not_terminated_test.dart' as case_block_not_terminated;
import 'case_expression_type_implements_equals_test.dart'
    as case_expression_type_implements_equals;
import 'case_expression_type_is_not_switch_expression_subtype_test.dart'
    as case_expression_type_is_not_switch_expression_subtype;
import 'cast_from_null_always_fails_test.dart' as cast_from_null_always_fails;
import 'cast_to_non_type_test.dart' as cast_to_non_type;
import 'class_instantiation_access_to_member_test.dart'
    as class_instantiation_access_to_member;
import 'class_used_as_mixin_test.dart' as class_used_as_mixin;
import 'concrete_class_has_enum_superinterface_test.dart'
    as concrete_class_has_enum_superinterface;
import 'concrete_class_with_abstract_member_test.dart'
    as concrete_class_with_abstract_member;
import 'conflicting_constructor_and_static_field_test.dart'
    as conflicting_constructor_and_static_field;
import 'conflicting_constructor_and_static_method_test.dart'
    as conflicting_constructor_and_static_method;
import 'conflicting_field_and_method_test.dart' as conflicting_field_and_method;
import 'conflicting_generic_interfaces_test.dart'
    as conflicting_generic_interfaces;
import 'conflicting_method_and_field_test.dart' as conflicting_method_and_field;
import 'conflicting_static_and_instance_test.dart'
    as conflicting_static_and_instance;
import 'conflicting_type_variable_and_container_test.dart'
    as conflicting_type_variable_and_container;
import 'conflicting_type_variable_and_member_test.dart'
    as conflicting_type_variable_and_member;
import 'const_constructor_field_type_mismatch_test.dart'
    as const_constructor_field_type_mismatch;
import 'const_constructor_param_type_mismatch_test.dart'
    as const_constructor_param_type_mismatch;
import 'const_constructor_with_field_initialized_by_non_const_test.dart'
    as const_constructor_with_field_initialized_by_non_const;
import 'const_constructor_with_mixin_with_field_test.dart'
    as const_constructor_with_mixin_with_field;
import 'const_constructor_with_non_const_super_test.dart'
    as const_constructor_with_non_const_super;
import 'const_constructor_with_non_final_field_test.dart'
    as const_constructor_with_non_final_field;
import 'const_deferred_class_test.dart' as const_deferred_class;
import 'const_eval_throws_exception_test.dart' as const_eval_throws_exception;
import 'const_eval_throws_idbze_test.dart' as const_eval_throws_idbze;
import 'const_eval_type_bool_int_test.dart' as const_eval_type_bool_int;
import 'const_eval_type_bool_num_string_test.dart'
    as const_eval_type_bool_num_string;
import 'const_eval_type_bool_test.dart' as const_eval_type_bool;
import 'const_eval_type_num_test.dart' as const_eval_type_num;
import 'const_field_initializer_not_assignable_test.dart'
    as const_field_initializer_not_assignable;
import 'const_initialized_with_non_constant_value_from_deferred_library_test.dart'
    as const_initialized_with_non_constant_value_from_deferred_library;
import 'const_initialized_with_non_constant_value_test.dart'
    as const_initialized_with_non_constant_value;
import 'const_instance_field_test.dart' as const_instance_field;
import 'const_map_key_not_primitive_equality_test.dart'
    as const_map_key_not_primitive_equality;
import 'const_not_initialized_test.dart' as const_not_initialized;
import 'const_set_element_not_primitive_equality_test.dart'
    as const_set_element_not_primitive_equality;
import 'const_spread_expected_list_or_set_test.dart'
    as const_spread_expected_list_or_set;
import 'const_spread_expected_map_test.dart' as const_spread_expected_map;
import 'const_with_non_const_test.dart' as const_with_non_const;
import 'const_with_non_constant_argument_test.dart'
    as const_with_non_constant_argument;
import 'const_with_non_type_test.dart' as const_with_non_type;
import 'const_with_type_parameters_test.dart' as const_with_type_parameters;
import 'const_with_undefined_constructor_test.dart'
    as const_with_undefined_constructor;
import 'constant_pattern_never_matches_value_type_test.dart'
    as constant_pattern_never_matches_value_type;
import 'constant_pattern_with_non_constant_expression_test.dart'
    as constant_pattern_with_non_constant_expression;
import 'continue_label_invalid_test.dart' as continue_label_invalid;
import 'could_not_infer_test.dart' as could_not_infer;
import 'creation_of_struct_or_union_test.dart' as creation_of_struct_or_union;
import 'dead_code_test.dart' as dead_code;
import 'dead_null_aware_expression_test.dart' as dead_null_aware_expression;
import 'default_value_in_function_type_test.dart'
    as default_value_in_function_type;
import 'default_value_in_redirecting_factory_constructor_test.dart'
    as default_value_in_redirecting_factory_constructor;
import 'default_value_on_required_parameter_test.dart'
    as default_value_on_required_parameter;
import 'deferred_import_of_extension_test.dart' as deferred_import_of_extension;
import 'definitely_unassigned_late_local_variable_test.dart'
    as definitely_unassigned_late_local_variable;
import 'deprecated_colon_for_default_value_test.dart'
    as deprecated_colon_for_default_value;
import 'deprecated_export_use_test.dart' as deprecated_export_use;
import 'deprecated_extends_function_test.dart' as deprecated_extends_function;
import 'deprecated_implements_function_test.dart'
    as deprecated_implements_function;
import 'deprecated_member_use_test.dart' as deprecated_member_use;
import 'deprecated_mixin_function_test.dart' as deprecated_mixin_function;
import 'division_optimization_test.dart' as division_optimization;
import 'duplicate_augmentation_import_test.dart'
    as duplicate_augmentation_import;
import 'duplicate_constructor_default_test.dart'
    as duplicate_constructor_default;
import 'duplicate_constructor_name_test.dart' as duplicate_constructor_name;
import 'duplicate_definition_test.dart' as duplicate_definition;
import 'duplicate_field_formal_parameter_test.dart'
    as duplicate_field_formal_parameter;
import 'duplicate_field_name_test.dart' as duplicate_field_name;
import 'duplicate_hidden_name_test.dart' as duplicate_hidden_name;
import 'duplicate_ignore_test.dart' as duplicate_ignore;
import 'duplicate_import_test.dart' as duplicate_import;
import 'duplicate_named_argument_test.dart' as duplicate_named_argument;
import 'duplicate_part_test.dart' as duplicate_part;
import 'duplicate_pattern_assignment_variable_test.dart'
    as duplicate_pattern_assignment_variable;
import 'duplicate_pattern_field_test.dart' as duplicate_pattern_field;
import 'duplicate_rest_element_in_pattern_test.dart'
    as duplicate_rest_element_in_pattern;
import 'duplicate_shown_name_test.dart' as duplicate_shown_name;
import 'duplicate_variable_pattern_test.dart' as duplicate_variable_pattern;
import 'enum_constant_same_name_as_enclosing_test.dart'
    as enum_constant_same_name_as_enclosing;
import 'enum_constant_with_non_const_constructor_test.dart'
    as enum_constant_with_non_const_constructor;
import 'enum_instantiated_to_bounds_is_not_well_bounded_test.dart'
    as enum_instantiated_to_bounds_is_not_well_bounded;
import 'enum_mixin_with_instance_variable_test.dart'
    as enum_mixin_with_instance_variable;
import 'enum_with_abstract_member_test.dart' as enum_with_abstract_member;
import 'enum_with_name_values_test.dart' as enum_with_name_values;
import 'equal_elements_in_const_set_test.dart' as equal_elements_in_const_set;
import 'equal_elements_in_set_test.dart' as equal_elements_in_set;
import 'equal_keys_in_const_map_test.dart' as equal_keys_in_const_map;
import 'equal_keys_in_map_pattern_test.dart' as equal_keys_in_map_pattern;
import 'equal_keys_in_map_test.dart' as equal_keys_in_map;
import 'expected_one_list_pattern_type_arguments_test.dart'
    as expected_one_list_pattern_type_arguments;
import 'expected_one_list_type_arguments_test.dart'
    as expected_one_list_type_arguments;
import 'expected_one_set_type_arguments_test.dart'
    as expected_one_set_type_arguments;
import 'expected_two_map_pattern_type_arguments_test.dart'
    as expected_two_map_pattern_type_arguments;
import 'expected_two_map_type_arguments_test.dart'
    as expected_two_map_type_arguments;
import 'experiment_not_enabled_test.dart' as experiment_not_enabled;
import 'export_internal_library_test.dart' as export_internal_library;
import 'export_legacy_symbol_test.dart' as export_legacy_symbol;
import 'export_of_non_library_test.dart' as export_of_non_library;
import 'expression_in_map_test.dart' as expression_in_map;
import 'extends_deferred_class_test.dart' as extends_deferred_class;
import 'extends_disallowed_class_test.dart' as extends_disallowed_class;
import 'extends_non_class_test.dart' as extends_non_class;
import 'extends_type_alias_expands_to_type_parameter_test.dart'
    as extends_type_alias_expands_to_type_parameter;
import 'extension_as_expression_test.dart' as extension_as_expression;
import 'extension_conflicting_static_and_instance_test.dart'
    as extension_conflicting_static_and_instance;
import 'extension_declares_abstract_method_test.dart'
    as extension_declares_abstract_method;
import 'extension_declares_constructor_test.dart'
    as extension_declares_constructor;
import 'extension_declares_field_test.dart' as extension_declares_field;
import 'extension_declares_member_of_object_test.dart'
    as extension_declares_member_of_object;
import 'extension_override_access_to_static_member_test.dart'
    as extension_override_access_to_static_member;
import 'extension_override_argument_not_assignable_test.dart'
    as extension_override_argument_not_assignable;
import 'extension_override_with_cascade_test.dart'
    as extension_override_with_cascade;
import 'extension_override_without_access_test.dart'
    as extension_override_without_access;
import 'external_field_constructor_initializer_test.dart'
    as external_field_constructor_initializer;
import 'external_field_initializer_test.dart' as external_field_initializer;
import 'external_variable_initializer_test.dart'
    as external_variable_initializer;
import 'extra_annotation_on_struct_field_test.dart'
    as extra_annotation_on_struct_field;
import 'extra_positional_arguments_test.dart' as extra_positional_arguments;
import 'extra_size_annotation_carray_test.dart' as extra_size_annotation_carray;
import 'extraneous_modifier_test.dart' as extraneous_modifier;
import 'ffi_leaf_call_must_not_use_handle_test.dart'
    as ffi_leaf_call_must_not_use_handle;
import 'ffi_native_test.dart' as ffi_native_test;
import 'field_in_struct_with_initializer_test.dart'
    as field_in_struct_with_initializer;
import 'field_initialized_by_multiple_initializers_test.dart'
    as field_initialized_by_multiple_initializers;
import 'field_initialized_in_initializer_and_declaration_test.dart'
    as field_initialized_in_initializer_and_declaration;
import 'field_initialized_in_parameter_and_initializer_test.dart'
    as field_initialized_in_parameter_and_initializer;
import 'field_initializer_factory_constructor_test.dart'
    as field_initializer_factory_constructor;
import 'field_initializer_in_struct_test.dart' as field_initializer_in_struct;
import 'field_initializer_not_assignable_test.dart'
    as field_initializer_not_assignable;
import 'field_initializer_outside_constructor_test.dart'
    as field_initializer_outside_constructor;
import 'field_initializer_redirecting_constructor_test.dart'
    as field_initializer_redirecting_constructor;
import 'field_initializing_formal_not_assignable_test.dart'
    as field_initializing_formal_not_assignable;
import 'field_must_be_external_in_struct_test.dart'
    as field_must_be_external_in_struct;
import 'final_class_extended_outside_of_library_test.dart'
    as final_class_extended_outside_of_library;
import 'final_class_implemented_outside_of_library_test.dart'
    as final_class_implemented_outside_of_library;
import 'final_initialized_in_declaration_and_constructor_test.dart'
    as final_initialized_in_declaration_and_constructor;
import 'final_mixin_implemented_outside_of_library_test.dart'
    as final_mixin_implemented_outside_of_library;
import 'final_mixin_mixed_in_outside_of_library_test.dart'
    as final_mixin_mixed_in_outside_of_library;
import 'final_not_initialized_constructor_test.dart'
    as final_not_initialized_constructor;
import 'final_not_initialized_test.dart' as final_not_initialized;
import 'for_in_of_invalid_element_type_test.dart'
    as for_in_of_invalid_element_type;
import 'for_in_of_invalid_type_test.dart' as for_in_of_invalid_type;
import 'for_in_with_const_variable_test.dart' as for_in_with_const_variable;
import 'function_typed_parameter_var_test.dart' as function_typed_parameter_var;
import 'generic_function_type_cannot_be_bound_test.dart'
    as generic_function_type_cannot_be_bound;
import 'generic_struct_subclass_test.dart' as generic_struct_subclass;
import 'getter_not_assignable_setter_types_test.dart'
    as getter_not_assignable_setter_types;
import 'getter_not_subtype_setter_types_test.dart'
    as getter_not_subtype_setter_types;
import 'if_element_condition_from_deferred_library_test.dart'
    as if_element_condition_from_deferred_library;
import 'illegal_async_generator_return_type_test.dart'
    as illegal_async_generator_return_type;
import 'illegal_async_return_type_test.dart' as illegal_async_return_type;
import 'illegal_concrete_enum_member_declaration_test.dart'
    as illegal_concrete_enum_member_declaration;
import 'illegal_concrete_enum_member_inheritance_test.dart'
    as illegal_concrete_enum_member_inheritance;
import 'illegal_enum_values_declaration_test.dart'
    as illegal_enum_values_declaration;
import 'illegal_enum_values_inheritance_test.dart'
    as illegal_enum_values_inheritance;
import 'illegal_language_version_override_test.dart'
    as illegal_language_version_override;
import 'illegal_sync_generator_return_type_test.dart'
    as illegal_sync_generator_return_type;
import 'implements_deferred_class_test.dart' as implements_deferred_class;
import 'implements_disallowed_class_test.dart' as implements_disallowed_class;
import 'implements_non_class_test.dart' as implements_non_class;
import 'implements_repeated_test.dart' as implements_repeated;
import 'implements_super_class_test.dart' as implements_super_class;
import 'implements_type_alias_expands_to_type_parameter_test.dart'
    as implements_type_alias_expands_to_type_parameter;
import 'implicit_dynamic_field_test.dart' as implicit_dynamic_field;
import 'implicit_dynamic_function_test.dart' as implicit_dynamic_function;
import 'implicit_dynamic_list_literal_test.dart'
    as implicit_dynamic_list_literal;
import 'implicit_dynamic_map_literal_test.dart' as implicit_dynamic_map_literal;
import 'implicit_this_reference_in_initializer_test.dart'
    as implicit_this_reference_in_initializer;
import 'import_deferred_library_with_load_function_test.dart'
    as import_deferred_library_with_load_function;
import 'import_internal_library_test.dart' as import_internal_library;
import 'import_of_legacy_library_into_null_safe_test.dart'
    as import_of_legacy_library_into_null_safe;
import 'import_of_non_library_test.dart' as import_of_non_library;
import 'import_of_not_augmentation_test.dart' as import_of_not_augmentation;
import 'inconsistent_case_expression_types_test.dart'
    as inconsistent_case_expression_types;
import 'inconsistent_inheritance_getter_and_method_test.dart'
    as inconsistent_inheritance_getter_and_method;
import 'inconsistent_inheritance_test.dart' as inconsistent_inheritance;
import 'inconsistent_language_version_override_test.dart'
    as inconsistent_language_version_override;
import 'inference_failure_on_collection_literal_test.dart'
    as inference_failure_on_collection_literal;
import 'inference_failure_on_function_invocation_test.dart'
    as inference_failure_on_function_invocation;
import 'inference_failure_on_function_return_type_test.dart'
    as inference_failure_on_function_return_type;
import 'inference_failure_on_generic_invocation_test.dart'
    as inference_failure_on_generic_invocation;
import 'inference_failure_on_instance_creation_test.dart'
    as inference_failure_on_instance_creation;
import 'inference_failure_on_uninitialized_variable_test.dart'
    as inference_failure_on_uninitialized_variable;
import 'inference_failure_on_untyped_parameter_test.dart'
    as inference_failure_on_untyped_parameter;
import 'initializer_for_non_existent_field_test.dart'
    as initializer_for_non_existent_field;
import 'initializer_for_static_field_test.dart' as initializer_for_static_field;
import 'initializing_formal_for_non_existent_field_test.dart'
    as initializing_formal_for_non_existent_field;
import 'instance_access_to_static_member_test.dart'
    as instance_access_to_static_member;
import 'instance_member_access_from_factory_test.dart'
    as instance_member_access_from_factory;
import 'instance_member_access_from_static_test.dart'
    as instance_member_access_from_static;
import 'instantiate_abstract_class_test.dart' as instantiate_abstract_class;
import 'instantiate_enum_test.dart' as instantiate_enum;
import 'instantiate_type_alias_expands_to_type_parameter_test.dart'
    as instantiate_type_alias_expands_to_type_parameter;
import 'integer_literal_imprecise_as_double_test.dart'
    as integer_literal_imprecise_as_double;
import 'integer_literal_out_of_range_test.dart' as integer_literal_out_of_range;
import 'interface_class_extended_outside_of_library_test.dart'
    as interface_class_extended_outside_of_library;
import 'interface_mixin_mixed_in_outside_of_library_test.dart'
    as interface_mixin_mixed_in_outside_of_library;
import 'invalid_annotation_from_deferred_library_test.dart'
    as invalid_annotation_from_deferred_library;
import 'invalid_annotation_target_test.dart' as invalid_annotation_target;
import 'invalid_annotation_test.dart' as invalid_annotation;
import 'invalid_assignment_test.dart' as invalid_assignment;
import 'invalid_cast_new_expr_test.dart' as invalid_cast_new_expr;
import 'invalid_constant_test.dart' as invalid_constant;
import 'invalid_constructor_name_test.dart' as invalid_constructor_name;
import 'invalid_exception_value_test.dart' as invalid_exception_value;
import 'invalid_export_of_internal_element_test.dart'
    as invalid_export_of_internal_element;
import 'invalid_extension_argument_count_test.dart'
    as invalid_extension_argument_count;
import 'invalid_factory_annotation_test.dart' as invalid_factory_annotation;
import 'invalid_factory_method_impl_test.dart' as invalid_factory_method_impl;
import 'invalid_factory_name_not_a_class_test.dart'
    as invalid_factory_name_not_a_class;
import 'invalid_field_name_test.dart' as invalid_field_name;
import 'invalid_field_type_in_struct_test.dart' as invalid_field_type_in_struct;
import 'invalid_immutable_annotation_test.dart' as invalid_immutable_annotation;
import 'invalid_implementation_override_test.dart'
    as invalid_implementation_override;
import 'invalid_internal_annotation_test.dart' as invalid_internal_annotation;
import 'invalid_language_override_greater_test.dart'
    as invalid_language_override_greater;
import 'invalid_language_override_test.dart' as invalid_language_override;
import 'invalid_literal_annotation_test.dart' as invalid_literal_annotation;
import 'invalid_modifier_on_constructor_test.dart'
    as invalid_modifier_on_constructor;
import 'invalid_modifier_on_setter_test.dart' as invalid_modifier_on_setter;
import 'invalid_non_virtual_annotation_test.dart'
    as invalid_non_virtual_annotation;
import 'invalid_null_aware_operator_test.dart' as invalid_null_aware_operator;
import 'invalid_override_of_non_virtual_member_test.dart'
    as invalid_override_of_non_virtual_member;
import 'invalid_override_test.dart' as invalid_override;
import 'invalid_reference_to_generative_enum_constructor_test.dart'
    as invalid_reference_to_generative_enum_constructor;
import 'invalid_reference_to_this_test.dart' as invalid_reference_to_this;
import 'invalid_required_named_param_test.dart' as invalid_required_named_param;
import 'invalid_required_optional_positional_param_test.dart'
    as invalid_required_optional_positional_param;
import 'invalid_required_positional_param_test.dart'
    as invalid_required_positional_param;
import 'invalid_sealed_annotation_test.dart' as invalid_sealed_annotation;
import 'invalid_super_formal_parameter_location_test.dart'
    as invalid_super_formal_parameter_location;
import 'invalid_super_in_initializer_test.dart' as invalid_super_in_initializer;
import 'invalid_type_argument_in_const_list_test.dart'
    as invalid_type_argument_in_const_list;
import 'invalid_type_argument_in_const_map_test.dart'
    as invalid_type_argument_in_const_map;
import 'invalid_type_argument_in_const_set_test.dart'
    as invalid_type_argument_in_const_set;
import 'invalid_uri_test.dart' as invalid_uri;
import 'invalid_use_of_covariant_in_extension_test.dart'
    as invalid_use_of_covariant_in_extension;
import 'invalid_use_of_covariant_test.dart' as invalid_use_of_covariant;
import 'invalid_use_of_internal_member_test.dart'
    as invalid_use_of_internal_member;
import 'invalid_use_of_protected_member_test.dart'
    as invalid_use_of_protected_member;
import 'invalid_use_of_visible_for_overriding_member_test.dart'
    as invalid_use_of_visible_for_overriding_member;
import 'invalid_use_of_visible_for_template_member_test.dart'
    as invalid_use_of_visible_for_template_member;
import 'invalid_use_of_visible_for_testing_member_test.dart'
    as invalid_use_of_visible_for_testing_member;
import 'invalid_visibility_annotation_test.dart'
    as invalid_visibility_annotation;
import 'invalid_visible_for_overriding_annotation_test.dart'
    as invalid_visible_for_overriding_annotation;
import 'invocation_of_extension_without_call_test.dart'
    as invocation_of_extension_without_call;
import 'invocation_of_non_function_expression_test.dart'
    as invocation_of_non_function_expression;
import 'label_in_outer_scope_test.dart' as label_in_outer_scope;
import 'label_undefined_test.dart' as label_undefined;
import 'late_final_field_with_const_constructor_test.dart'
    as late_final_field_with_const_constructor;
import 'late_final_local_already_assigned_test.dart'
    as late_final_local_already_assigned;
import 'list_element_type_not_assignable_test.dart'
    as list_element_type_not_assignable;
import 'main_first_positional_parameter_type_test.dart'
    as main_first_positional_parameter_type;
import 'main_has_required_named_parameters_test.dart'
    as main_has_required_named_parameters;
import 'main_has_too_many_required_positional_parameters_test.dart'
    as main_has_too_many_required_positional_parameters;
import 'main_is_not_function_test.dart' as main_is_not_function;
import 'map_entry_not_in_map_test.dart' as map_entry_not_in_map;
import 'map_key_type_not_assignable_test.dart' as map_key_type_not_assignable;
import 'map_value_type_not_assignable_test.dart'
    as map_value_type_not_assignable;
import 'member_with_class_name_test.dart' as member_with_class_name;
import 'mismatched_annotation_on_struct_field_test.dart'
    as mismatched_annotation_on_struct_field;
import 'missing_annotation_on_struct_field_test.dart'
    as missing_annotation_on_struct_field;
import 'missing_default_value_for_parameter_test.dart'
    as missing_default_value_for_parameter;
import 'missing_enum_constant_in_switch_test.dart'
    as missing_enum_constant_in_switch;
import 'missing_exception_value_test.dart' as missing_exception_value;
import 'missing_field_type_in_struct_test.dart' as missing_field_type_in_struct;
import 'missing_override_of_must_be_overridden_test.dart'
    as missing_override_of_must_be_overridden;
import 'missing_required_param_test.dart' as missing_required_param;
import 'missing_return_test.dart' as missing_return;
import 'missing_size_annotation_carray_test.dart'
    as missing_size_annotation_carray;
import 'missing_variable_pattern_test.dart' as missing_variable_pattern;
import 'mixin_application_concrete_super_invoked_member_type_test.dart'
    as mixin_application_concrete_super_invoked_member_type;
import 'mixin_application_no_concrete_super_invoked_member_test.dart'
    as mixin_application_no_concrete_super_invoked_member;
import 'mixin_application_not_implemented_interface_test.dart'
    as mixin_application_not_implemented_interface;
import 'mixin_class_declares_constructor_test.dart'
    as mixin_class_declares_constructor;
import 'mixin_declares_constructor_test.dart' as mixin_declares_constructor;
import 'mixin_deferred_class_test.dart' as mixin_deferred_class;
import 'mixin_inference_no_possible_substitution_test.dart'
    as mixin_inference_no_possible_substitution;
import 'mixin_inherits_from_not_object_test.dart'
    as mixin_inherits_from_not_object;
import 'mixin_instantiate_test.dart' as mixin_instantiate_test;
import 'mixin_of_disallowed_class_test.dart' as mixin_of_disallowed_class;
import 'mixin_of_non_class_test.dart' as mixin_of_non_class;
import 'mixin_of_type_alias_expands_to_type_parameter_test.dart'
    as mixin_of_type_alias_expands_to_type_parameter;
import 'mixin_on_sealed_class_test.dart' as mixin_on_sealed_class;
import 'mixin_on_type_alias_expands_to_type_parameter_test.dart'
    as mixin_on_type_alias_expands_to_type_parameter;
import 'mixin_super_class_constraint_deferred_class_test.dart'
    as mixin_super_class_constraint_deferred_class;
import 'mixin_super_class_constraint_disallowed_class_test.dart'
    as mixin_super_class_constraint_disallowed_class;
import 'mixin_super_class_constraint_non_interface_test.dart'
    as mixin_super_class_constraint_non_interface;
import 'mixin_with_non_class_superclass_test.dart'
    as mixin_with_non_class_superclass;
import 'mixins_super_class_test.dart' as mixins_super_class;
import 'mock_sdk_test.dart' as mock_sdk;
import 'multiple_redirecting_constructor_invocations_test.dart'
    as multiple_redirecting_constructor_invocations;
import 'multiple_super_initializers_test.dart' as multiple_super_initializers;
import 'must_be_a_native_function_type_test.dart'
    as must_be_a_native_function_type;
import 'must_be_a_subtype_test.dart' as must_be_a_subtype;
import 'must_be_immutable_test.dart' as must_be_immutable;
import 'must_call_super_test.dart' as must_call_super;
import 'native_clause_in_non_sdk_code_test.dart'
    as native_clause_in_non_sdk_code;
import 'native_function_body_in_non_sdk_code_test.dart'
    as native_function_body_in_non_sdk_code;
import 'new_with_non_type_test.dart' as new_with_non_type;
import 'new_with_undefined_constructor_test.dart'
    as new_with_undefined_constructor;
import 'no_annotation_constructor_arguments_test.dart'
    as no_annotation_constructor_arguments;
import 'no_combined_super_signature_test.dart' as no_combined_super_signature;
import 'no_default_super_constructor_test.dart' as no_default_super_constructor;
import 'no_generative_constructors_in_superclass_test.dart'
    as no_generative_constructors_in_superclass;
import 'non_abstract_class_inherits_abstract_member_test.dart'
    as non_abstract_class_inherits_abstract_member;
import 'non_bool_condition_test.dart' as non_bool_condition;
import 'non_bool_expression_test.dart' as non_bool_expression;
import 'non_bool_negation_expression_test.dart' as non_bool_negation_expression;
import 'non_bool_operand_test.dart' as non_bool_operand;
import 'non_const_call_to_literal_constructor_test.dart'
    as non_const_call_to_literal_constructor;
import 'non_const_generative_enum_constructor_test.dart'
    as non_const_generative_enum_constructor;
import 'non_const_map_as_expression_statement_test.dart'
    as non_const_map_as_expression_statement;
import 'non_constant_annotation_constructor_test.dart'
    as non_constant_annotation_constructor;
import 'non_constant_case_expression_from_deferred_library_test.dart'
    as non_constant_case_expression_from_deferred_library;
import 'non_constant_case_expression_test.dart' as non_constant_case_expression;
import 'non_constant_default_value_from_deferred_library_test.dart'
    as non_constant_default_value_from_deferred_library;
import 'non_constant_default_value_test.dart' as non_constant_default_value;
import 'non_constant_list_element_from_deferred_library_test.dart'
    as non_constant_list_element_from_deferred_library;
import 'non_constant_list_element_test.dart' as non_constant_list_element;
import 'non_constant_map_element_test.dart' as non_constant_map_element;
import 'non_constant_map_key_from_deferred_library_test.dart'
    as non_constant_map_key_from_deferred_library;
import 'non_constant_map_key_test.dart' as non_constant_map_key;
import 'non_constant_map_pattern_key_test.dart' as non_constant_map_pattern_key;
import 'non_constant_map_value_from_deferred_library_test.dart'
    as non_constant_map_value_from_deferred_library;
import 'non_constant_map_value_test.dart' as non_constant_map_value;
import 'non_constant_relational_pattern_expression_test.dart'
    as non_constant_relational_pattern_expression;
import 'non_constant_set_element_test.dart' as non_constant_set_element;
import 'non_constant_type_argument_test.dart' as non_constant_type_argument;
import 'non_exhaustive_switch_test.dart' as non_exhaustive_switch;
import 'non_final_field_in_enum_test.dart' as non_final_field_in_enum;
import 'non_generative_constructor_test.dart' as non_generative_constructor;
import 'non_generative_implicit_constructor_test.dart'
    as non_generative_implicit_constructor;
import 'non_native_function_type_argument_to_pointer_test.dart'
    as non_native_function_type_argument_to_pointer;
import 'non_null_opt_out_test.dart' as non_null_opt_out;
import 'non_positive_array_dimension_test.dart' as non_positive_array_dimension;
import 'non_sized_type_argument_test.dart' as non_sized_type_argument;
import 'non_type_as_type_argument_test.dart' as non_type_as_type_argument;
import 'non_type_in_catch_clause_test.dart' as non_type_in_catch_clause;
import 'non_void_return_for_operator_test.dart' as non_void_return_for_operator;
import 'non_void_return_for_setter_test.dart' as non_void_return_for_setter;
import 'not_a_type_test.dart' as not_a_type;
import 'not_assigned_potentially_non_nullable_local_variable_test.dart'
    as not_assigned_potentially_non_nullable_local_variable;
import 'not_binary_operator_test.dart' as not_binary_operator;
import 'not_enough_positional_arguments_test.dart'
    as not_enough_positional_arguments;
import 'not_initialized_non_nullable_instance_field_test.dart'
    as not_initialized_non_nullable_instance_field;
import 'not_initialized_non_nullable_variable_test.dart'
    as not_initialized_non_nullable_variable;
import 'not_instantiated_bound_test.dart' as not_instantiated_bound;
import 'not_iterable_spread_test.dart' as not_iterable_spread;
import 'not_map_spread_test.dart' as not_map_spread;
import 'not_null_aware_null_spread_test.dart' as not_null_aware_null_spread;
import 'null_argument_to_non_null_type_test.dart'
    as null_argument_to_non_null_type;
import 'null_aware_before_operator_test.dart' as null_aware_before_operator;
import 'null_aware_in_condition_test.dart' as null_aware_in_condition;
import 'null_aware_in_logical_operator_test.dart'
    as null_aware_in_logical_operator;
import 'null_check_always_fails_test.dart' as null_check_always_fails;
import 'null_safety_read_write_test.dart' as null_safety_read_write;
import 'nullable_type_in_catch_clause_test.dart'
    as nullable_type_in_catch_clause;
import 'nullable_type_in_extends_clause_test.dart'
    as nullable_type_in_extends_clause;
import 'nullable_type_in_implements_clause_test.dart'
    as nullable_type_in_implements_clause;
import 'nullable_type_in_on_clause_test.dart' as nullable_type_in_on_clause;
import 'nullable_type_in_with_clause_test.dart' as nullable_type_in_with_clause;
import 'object_cannot_extend_another_class_test.dart'
    as object_cannot_extend_another_class;
import 'obsolete_colon_for_default_value_test.dart'
    as obsolete_colon_for_default_value;
import 'on_repeated_test.dart' as on_repeated;
import 'optional_parameter_in_operator_test.dart'
    as optional_parameter_in_operator;
import 'override_on_non_overriding_field_test.dart'
    as override_on_non_overriding_field;
import 'override_on_non_overriding_getter_test.dart'
    as override_on_non_overriding_getter;
import 'override_on_non_overriding_method_test.dart'
    as override_on_non_overriding_method;
import 'override_on_non_overriding_setter_test.dart'
    as override_on_non_overriding_setter;
import 'packed_annotation_alignment_test.dart' as packed_annotation_alignment;
import 'packed_annotation_test.dart' as packed_annotation;
import 'part_of_different_library_test.dart' as part_of_different_library;
import 'part_of_non_part_test.dart' as part_of_non_part;
import 'pattern_assignment_not_local_variable_test.dart'
    as pattern_assignment_not_local_variable;
import 'pattern_type_mismatch_in_irrefutable_context_test.dart'
    as pattern_type_mismatch_in_irrefutable_context;
import 'pattern_variable_assignment_inside_guard_test.dart'
    as pattern_variable_assignment_inside_guard;
import 'positional_super_formal_parameter_with_positional_argument_test.dart'
    as positional_super_formal_parameter_with_positional_argument;
import 'prefix_collides_with_top_level_member_test.dart'
    as prefix_collides_with_top_level_member;
import 'prefix_identifier_not_followed_by_dot_test.dart'
    as prefix_identifier_not_followed_by_dot;
import 'prefix_shadowed_by_local_declaration_test.dart'
    as prefix_shadowed_by_local_declaration;
import 'private_collision_in_mixin_application_test.dart'
    as private_collision_in_mixin_application;
import 'private_optional_parameter_test.dart' as private_optional_parameter;
import 'private_setter_test.dart' as private_setter;
import 'receiver_of_type_never_test.dart' as receiver_of_type_never;
import 'recursive_compile_time_constant_test.dart'
    as recursive_compile_time_constant;
import 'recursive_constructor_redirect_test.dart'
    as recursive_constructor_redirect;
import 'recursive_factory_redirect_test.dart' as recursive_factory_redirect;
import 'recursive_interface_inheritance_extends_test.dart'
    as recursive_interface_inheritance_extends;
import 'recursive_interface_inheritance_implements_test.dart'
    as recursive_interface_inheritance_implements;
import 'recursive_interface_inheritance_test.dart'
    as recursive_interface_inheritance;
import 'recursive_interface_inheritance_with_test.dart'
    as recursive_interface_inheritance_with;
import 'redirect_generative_to_missing_constructor_test.dart'
    as redirect_generative_to_missing_constructor;
import 'redirect_generative_to_non_generative_constructor_test.dart'
    as redirect_generative_to_non_generative_constructor;
import 'redirect_to_abstract_class_constructor_test.dart'
    as redirect_to_abstract_class_constructor;
import 'redirect_to_invalid_function_type_test.dart'
    as redirect_to_invalid_function_type;
import 'redirect_to_invalid_return_type_test.dart'
    as redirect_to_invalid_return_type;
import 'redirect_to_missing_constructor_test.dart'
    as redirect_to_missing_constructor;
import 'redirect_to_non_class_test.dart' as redirect_to_non_class;
import 'redirect_to_non_const_constructor_test.dart'
    as redirect_to_non_const_constructor;
import 'redirect_to_type_alias_expands_to_type_parameter_test.dart'
    as redirect_to_type_alias_expands_to_type_parameter;
import 'referenced_before_declaration_test.dart'
    as referenced_before_declaration;
import 'refutable_pattern_in_irrefutable_context_test.dart'
    as refutable_pattern_in_irrefutable_context;
import 'relational_pattern_operator_return_type_not_assignable_to_bool_test.dart'
    as relational_pattern_operator_return_type_not_assignable_to_bool;
import 'removed_lint_use_test.dart' as removed_lint_in_ignore;
import 'replaced_lint_use_test.dart' as replaced_lint_in_ignore;
import 'rest_element_not_last_in_map_pattern_test.dart'
    as rest_element_not_last_in_map_pattern;
import 'rethrow_outside_catch_test.dart' as rethrow_outside_catch;
import 'return_in_generative_constructor_test.dart'
    as return_in_generative_constructor;
import 'return_in_generator_test.dart' as return_in_generator;
import 'return_of_do_not_store_test.dart' as return_of_do_not_store;
import 'return_of_invalid_type_from_catch_error_test.dart'
    as return_of_invalid_type_from_catch_error;
import 'return_of_invalid_type_test.dart' as return_of_invalid_type;
import 'return_type_invalid_for_catch_error_test.dart'
    as return_type_invalid_for_catch_error;
import 'return_without_value_test.dart' as return_without_value;
import 'sdk_version_as_expression_in_const_context_test.dart'
    as sdk_version_as_expression_in_const_context;
import 'sdk_version_async_exported_from_core_test.dart'
    as sdk_version_async_exported_from_core;
import 'sdk_version_bool_operator_in_const_context_test.dart'
    as sdk_version_bool_operator_in_const_context;
import 'sdk_version_eq_eq_operator_test.dart' as sdk_version_eq_eq_operator;
import 'sdk_version_extension_methods_test.dart'
    as sdk_version_extension_methods;
import 'sdk_version_gt_gt_gt_operator_test.dart'
    as sdk_version_gt_gt_gt_operator;
import 'sdk_version_is_expression_in_const_context_test.dart'
    as sdk_version_is_expression_in_const_context;
import 'sdk_version_never_test.dart' as sdk_version_never;
import 'sdk_version_set_literal_test.dart' as sdk_version_set_literal;
import 'sdk_version_ui_as_code_in_const_context_test.dart'
    as sdk_version_ui_as_code_in_const_context;
import 'sdk_version_ui_as_code_test.dart' as sdk_version_ui_as_code;
import 'sealed_class_subtype_outside_of_library_test.dart'
    as sealed_class_subtype_outside_of_library;
import 'sealed_mixin_subtype_outside_of_library_test.dart'
    as sealed_mixin_subtype_outside_of_library;
import 'set_element_from_deferred_library_test.dart'
    as set_element_from_deferred_library;
import 'set_element_type_not_assignable_test.dart'
    as set_element_type_not_assignable;
import 'shared_deferred_prefix_test.dart' as shared_deferred_prefix;
import 'size_annotation_dimensions_test.dart' as size_annotation_dimensions;
import 'spread_expression_from_deferred_library_test.dart'
    as spread_expression_from_deferred_library;
import 'static_access_to_instance_member_test.dart'
    as static_access_to_instance_member;
import 'strict_raw_type_test.dart' as strict_raw_type;
import 'subtype_of_ffi_class_test.dart' as subtype_of_ffi_class;
import 'subtype_of_sealed_class_test.dart' as subtype_of_sealed_class;
import 'subtype_of_struct_class_test.dart' as subtype_of_struct_class;
import 'super_formal_parameter_type_is_not_subtype_of_associated_test.dart'
    as super_formal_parameter_type_is_not_subtype_of_associated;
import 'super_formal_parameter_without_associated_named_test.dart'
    as super_formal_parameter_without_associated_named;
import 'super_formal_parameter_without_associated_positional_test.dart'
    as super_formal_parameter_without_associated_positional;
import 'super_in_enum_constructor_test.dart' as super_in_enum_constructor;
import 'super_in_extension_test.dart' as super_in_extension;
import 'super_in_invalid_context_test.dart' as super_in_invalid_context;
import 'super_in_redirecting_constructor_test.dart'
    as super_in_redirecting_constructor;
import 'super_initializer_in_object_test.dart' as super_initializer_in_object;
import 'super_invocation_not_last_test.dart' as super_invocation_not_last;
import 'switch_case_completes_normally_test.dart'
    as switch_case_completes_normally;
import 'switch_expression_not_assignable_test.dart'
    as switch_expression_not_assignable;
import 'tearoff_of_generative_constructor_of_abstract_class_test.dart'
    as tearoff_of_generative_constructor_of_abstract_class;
import 'text_direction_code_point_test.dart' as text_direction_code_point;
import 'throw_of_invalid_type_test.dart' as throw_of_invalid_type;
import 'todo_test.dart' as todo_test;
import 'top_level_cycle_test.dart' as top_level_cycle;
import 'top_level_instance_getter_test.dart' as top_level_instance_getter;
import 'type_alias_cannot_reference_itself_test.dart'
    as type_alias_cannot_reference_itself;
import 'type_annotation_deferred_class_test.dart'
    as type_annotation_deferred_class;
import 'type_argument_not_matching_bounds_test.dart'
    as type_argument_not_matching_bounds;
import 'type_check_is_not_null_test.dart' as type_check_is_not_null;
import 'type_check_is_null_test.dart' as type_check_is_null;
import 'type_parameter_referenced_by_static_test.dart'
    as type_parameter_referenced_by_static;
import 'type_parameter_supertype_of_its_bound_test.dart'
    as type_parameter_supertype_of_its_bound;
import 'type_test_with_non_type_test.dart' as type_test_with_non_type;
import 'type_test_with_undefined_name_test.dart'
    as type_test_with_undefined_name;
import 'undefined_annotation_test.dart' as undefined_annotation;
import 'undefined_class_boolean_test.dart' as undefined_class_boolean;
import 'undefined_class_test.dart' as undefined_class;
import 'undefined_constructor_in_initializer_default_test.dart'
    as undefined_constructor_in_initializer_default;
import 'undefined_constructor_in_initializer_test.dart'
    as undefined_constructor_in_initializer;
import 'undefined_enum_constant_test.dart' as undefined_enum_constant;
import 'undefined_enum_constructor_named_test.dart'
    as undefined_enum_constructor_named;
import 'undefined_enum_constructor_unnamed_test.dart'
    as undefined_enum_constructor_unnamed;
import 'undefined_extension_getter_test.dart' as undefined_extension_getter;
import 'undefined_extension_method_test.dart' as undefined_extension_method;
import 'undefined_extension_operator_test.dart' as undefined_extension_operator;
import 'undefined_extension_setter_test.dart' as undefined_extension_setter;
import 'undefined_getter_test.dart' as undefined_getter;
import 'undefined_hidden_name_test.dart' as undefined_hidden_name;
import 'undefined_identifier_await_test.dart' as undefined_identifier_await;
import 'undefined_identifier_test.dart' as undefined_identifier;
import 'undefined_method_test.dart' as undefined_method;
import 'undefined_named_parameter_test.dart' as undefined_named_parameter;
import 'undefined_operator_test.dart' as undefined_operator;
import 'undefined_prefixed_name_test.dart' as undefined_prefixed_name;
import 'undefined_referenced_parameter_test.dart'
    as undefined_referenced_parameter;
import 'undefined_setter_test.dart' as undefined_setter;
import 'undefined_shown_name_test.dart' as undefined_shown_name;
import 'undefined_super_getter_test.dart' as undefined_super_getter;
import 'undefined_super_method_test.dart' as undefined_super_method;
import 'undefined_super_operator_test.dart' as undefined_super_operator;
import 'undefined_super_setter_test.dart' as undefined_super_setter;
import 'unignorable_ignore_test.dart' as unignorable_ignore;
import 'unnecessary_cast_pattern_test.dart' as unnecessary_cast_pattern;
import 'unnecessary_cast_test.dart' as unnecessary_cast;
import 'unnecessary_final_test.dart' as unnecessary_final;
import 'unnecessary_ignore_test.dart' as unnecessary_ignore;
import 'unnecessary_import_test.dart' as unnecessary_import;
import 'unnecessary_nan_comparison_test.dart' as unnecessary_nan_comparison;
import 'unnecessary_no_such_method_test.dart' as unnecessary_no_such_method;
import 'unnecessary_non_null_assertion_test.dart'
    as unnecessary_non_null_assertion;
import 'unnecessary_null_assert_pattern_test.dart'
    as unnecessary_null_assert_pattern;
import 'unnecessary_null_check_pattern_test.dart'
    as unnecessary_null_check_pattern;
import 'unnecessary_null_comparison_test.dart' as unnecessary_null_comparison;
import 'unnecessary_question_mark_test.dart' as unnecessary_question_mark;
import 'unnecessary_set_literal_test.dart' as unnecessary_set_literal;
import 'unnecessary_type_check_test.dart' as unnecessary_type_check;
import 'unnecessary_wildcard_pattern_test.dart' as unnecessary_wildcard_pattern;
import 'unqualified_reference_to_non_local_static_member_test.dart'
    as unqualified_reference_to_non_local_static_member;
import 'unqualified_reference_to_static_member_of_extended_type_test.dart'
    as unqualified_reference_to_static_member_of_extended_type;
import 'unreachable_switch_case_test.dart' as unreachable_switch_case;
import 'unused_catch_clause_test.dart' as unused_catch_clause;
import 'unused_catch_stack_test.dart' as unused_catch_stack;
import 'unused_element_test.dart' as unused_element;
import 'unused_field_test.dart' as unused_field;
import 'unused_import_test.dart' as unused_import;
import 'unused_label_test.dart' as unused_label;
import 'unused_local_variable_test.dart' as unused_local_variable;
import 'unused_result_test.dart' as unused_result;
import 'unused_shown_name_test.dart' as unused_shown_name;
import 'uri_does_not_exist_test.dart' as uri_does_not_exist;
import 'uri_with_interpolation_test.dart' as uri_with_interpolation;
import 'use_of_native_extension_test.dart' as use_of_native_extension;
import 'use_of_nullable_value_test.dart' as use_of_nullable_value_test;
import 'use_of_void_result_test.dart' as use_of_void_result;
import 'values_declaration_in_enum_test.dart' as values_declaration_in_enum;
import 'variable_type_mismatch_test.dart' as variable_type_mismatch;
import 'void_with_type_arguments_test.dart' as void_with_type_arguments_test;
import 'wrong_number_of_parameters_for_operator_test.dart'
    as wrong_number_of_parameters_for_operator;
import 'wrong_number_of_parameters_for_setter_test.dart'
    as wrong_number_of_parameters_for_setter;
import 'wrong_number_of_type_arguments_enum_test.dart'
    as wrong_number_of_type_arguments_enum;
import 'wrong_number_of_type_arguments_extension_test.dart'
    as wrong_number_of_type_arguments_extension;
import 'wrong_number_of_type_arguments_test.dart'
    as wrong_number_of_type_arguments;
import 'wrong_type_parameter_variance_in_superinterface_test.dart'
    as wrong_type_parameter_variance_in_superinterface;
import 'yield_each_in_non_generator_test.dart' as yield_each_in_non_generator;
import 'yield_in_non_generator_test.dart' as yield_in_non_generator;
import 'yield_of_invalid_type_test.dart' as yield_of_invalid_type;

main() {
  defineReflectiveSuite(() {
    abi_specific_integer_mapping.main();
    abstract_class_member.main();
    abstract_field_constructor_initializer.main();
    abstract_field_initializer.main();
    abstract_super_member_reference.main();
    ambiguous_export.main();
    ambiguous_extension_member_access.main();
    ambiguous_import.main();
    ambiguous_set_or_map_literal.main();
    analysis_options.main();
    annotation_on_pointer_field.main();
    annotation_syntax.main();
    argument_must_be_a_constant.main();
    argument_type_not_assignable.main();
    argument_type_not_assignable_to_error_handler.main();
    assert_in_redirecting_constructor.main();
    assignment_of_do_not_store.main();
    assignment_to_const.main();
    assignment_to_final_local.main();
    assignment_to_final_no_setter.main();
    assignment_to_final.main();
    assignment_to_function.main();
    assignment_to_method.main();
    assignment_to_type.main();
    async_for_in_wrong_context.main();
    async_keyword_used_as_identifier.main();
    await_in_late_local_variable_initializer.main();
    await_in_wrong_context.main();
    base_class_implemented_outside_of_library.main();
    base_mixin_implemented_outside_of_library.main();
    binary_operator_written_out.main();
    body_might_complete_normally_catch_error.main();
    body_might_complete_normally_nullable.main();
    body_might_complete_normally.main();
    built_in_as_extension_name.main();
    built_in_as_prefix_name.main();
    built_in_as_type_name.main();
    built_in_as_type_parameter_name.main();
    built_in_as_typedef_name.main();
    can_be_null_after_null_aware.main();
    case_block_not_terminated.main();
    case_expression_type_implements_equals.main();
    case_expression_type_is_not_switch_expression_subtype.main();
    cast_from_null_always_fails.main();
    cast_to_non_type.main();
    class_instantiation_access_to_member.main();
    class_used_as_mixin.main();
    concrete_class_has_enum_superinterface.main();
    concrete_class_with_abstract_member.main();
    conflicting_constructor_and_static_field.main();
    conflicting_constructor_and_static_method.main();
    conflicting_field_and_method.main();
    conflicting_generic_interfaces.main();
    conflicting_method_and_field.main();
    conflicting_static_and_instance.main();
    conflicting_type_variable_and_container.main();
    conflicting_type_variable_and_member.main();
    const_constructor_field_type_mismatch.main();
    const_constructor_param_type_mismatch.main();
    const_constructor_with_field_initialized_by_non_const.main();
    const_constructor_with_mixin_with_field.main();
    const_constructor_with_non_const_super.main();
    const_constructor_with_non_final_field.main();
    const_deferred_class.main();
    const_eval_throws_exception.main();
    const_eval_throws_idbze.main();
    const_eval_type_bool_int.main();
    const_eval_type_bool_num_string.main();
    const_eval_type_bool.main();
    const_eval_type_num.main();
    const_field_initializer_not_assignable.main();
    const_initialized_with_non_constant_value_from_deferred_library.main();
    const_initialized_with_non_constant_value.main();
    const_instance_field.main();
    const_map_key_not_primitive_equality.main();
    const_not_initialized.main();
    const_set_element_not_primitive_equality.main();
    const_spread_expected_list_or_set.main();
    const_spread_expected_map.main();
    const_with_non_const.main();
    const_with_non_constant_argument.main();
    const_with_non_type.main();
    const_with_type_parameters.main();
    const_with_undefined_constructor.main();
    constant_pattern_never_matches_value_type.main();
    constant_pattern_with_non_constant_expression.main();
    continue_label_invalid.main();
    could_not_infer.main();
    creation_of_struct_or_union.main();
    dead_code.main();
    dead_null_aware_expression.main();
    default_value_in_function_type.main();
    default_value_in_redirecting_factory_constructor.main();
    default_value_on_required_parameter.main();
    deferred_import_of_extension.main();
    definitely_unassigned_late_local_variable.main();
    deprecated_colon_for_default_value.main();
    deprecated_export_use.main();
    deprecated_extends_function.main();
    deprecated_implements_function.main();
    deprecated_member_use.main();
    deprecated_mixin_function.main();
    division_optimization.main();
    duplicate_augmentation_import.main();
    duplicate_constructor_default.main();
    duplicate_constructor_name.main();
    duplicate_definition.main();
    duplicate_field_name.main();
    duplicate_field_formal_parameter.main();
    duplicate_hidden_name.main();
    duplicate_ignore.main();
    duplicate_import.main();
    duplicate_named_argument.main();
    duplicate_part.main();
    duplicate_pattern_assignment_variable.main();
    duplicate_pattern_field.main();
    duplicate_rest_element_in_pattern.main();
    duplicate_shown_name.main();
    duplicate_variable_pattern.main();
    enum_constant_same_name_as_enclosing.main();
    enum_constant_with_non_const_constructor.main();
    enum_instantiated_to_bounds_is_not_well_bounded.main();
    enum_mixin_with_instance_variable.main();
    enum_with_abstract_member.main();
    enum_with_name_values.main();
    equal_elements_in_const_set.main();
    equal_elements_in_set.main();
    equal_keys_in_const_map.main();
    equal_keys_in_map_pattern.main();
    equal_keys_in_map.main();
    expected_one_list_pattern_type_arguments.main();
    expected_one_list_type_arguments.main();
    expected_one_set_type_arguments.main();
    expected_two_map_pattern_type_arguments.main();
    expected_two_map_type_arguments.main();
    experiment_not_enabled.main();
    export_internal_library.main();
    export_legacy_symbol.main();
    export_of_non_library.main();
    expression_in_map.main();
    extends_deferred_class.main();
    extends_disallowed_class.main();
    extends_non_class.main();
    extends_type_alias_expands_to_type_parameter.main();
    extension_as_expression.main();
    extension_conflicting_static_and_instance.main();
    extension_declares_abstract_method.main();
    extension_declares_constructor.main();
    extension_declares_field.main();
    extension_declares_member_of_object.main();
    extension_override_access_to_static_member.main();
    extension_override_argument_not_assignable.main();
    extension_override_with_cascade.main();
    extension_override_without_access.main();
    external_field_constructor_initializer.main();
    external_field_initializer.main();
    external_variable_initializer.main();
    extra_annotation_on_struct_field.main();
    extra_positional_arguments.main();
    extra_size_annotation_carray.main();
    extraneous_modifier.main();
    ffi_leaf_call_must_not_use_handle.main();
    ffi_native_test.main();
    field_in_struct_with_initializer.main();
    field_initialized_by_multiple_initializers.main();
    final_initialized_in_declaration_and_constructor.main();
    field_initialized_in_initializer_and_declaration.main();
    field_initialized_in_parameter_and_initializer.main();
    field_initializer_factory_constructor.main();
    field_initializer_in_struct.main();
    field_initializer_not_assignable.main();
    field_initializer_outside_constructor.main();
    field_initializer_redirecting_constructor.main();
    field_initializing_formal_not_assignable.main();
    field_must_be_external_in_struct.main();
    final_class_extended_outside_of_library.main();
    final_class_implemented_outside_of_library.main();
    final_mixin_implemented_outside_of_library.main();
    final_mixin_mixed_in_outside_of_library.main();
    final_not_initialized_constructor.main();
    final_not_initialized.main();
    for_in_of_invalid_element_type.main();
    for_in_of_invalid_type.main();
    for_in_with_const_variable.main();
    function_typed_parameter_var.main();
    generic_function_type_cannot_be_bound.main();
    generic_struct_subclass.main();
    getter_not_assignable_setter_types.main();
    getter_not_subtype_setter_types.main();
    if_element_condition_from_deferred_library.main();
    illegal_async_generator_return_type.main();
    illegal_async_return_type.main();
    illegal_concrete_enum_member_declaration.main();
    illegal_concrete_enum_member_inheritance.main();
    illegal_enum_values_declaration.main();
    illegal_enum_values_inheritance.main();
    illegal_language_version_override.main();
    illegal_sync_generator_return_type.main();
    implements_deferred_class.main();
    implements_disallowed_class.main();
    implements_non_class.main();
    implements_repeated.main();
    implements_super_class.main();
    implements_type_alias_expands_to_type_parameter.main();
    implicit_dynamic_field.main();
    implicit_dynamic_function.main();
    implicit_dynamic_list_literal.main();
    implicit_dynamic_map_literal.main();
    implicit_this_reference_in_initializer.main();
    import_deferred_library_with_load_function.main();
    import_internal_library.main();
    import_of_legacy_library_into_null_safe.main();
    import_of_non_library.main();
    import_of_not_augmentation.main();
    inconsistent_case_expression_types.main();
    inconsistent_inheritance_getter_and_method.main();
    inconsistent_inheritance.main();
    inconsistent_language_version_override.main();
    inference_failure_on_collection_literal.main();
    inference_failure_on_function_invocation.main();
    inference_failure_on_function_return_type.main();
    inference_failure_on_generic_invocation.main();
    inference_failure_on_instance_creation.main();
    inference_failure_on_uninitialized_variable.main();
    inference_failure_on_untyped_parameter.main();
    initializer_for_non_existent_field.main();
    initializer_for_static_field.main();
    initializing_formal_for_non_existent_field.main();
    instance_access_to_static_member.main();
    instance_member_access_from_factory.main();
    instance_member_access_from_static.main();
    instantiate_abstract_class.main();
    instantiate_enum.main();
    instantiate_type_alias_expands_to_type_parameter.main();
    integer_literal_imprecise_as_double.main();
    integer_literal_out_of_range.main();
    interface_class_extended_outside_of_library.main();
    interface_mixin_mixed_in_outside_of_library.main();
    invalid_annotation.main();
    invalid_annotation_from_deferred_library.main();
    invalid_annotation_target.main();
    invalid_assignment.main();
    invalid_cast_new_expr.main();
    invalid_constant.main();
    invalid_constructor_name.main();
    invalid_exception_value.main();
    invalid_export_of_internal_element.main();
    invalid_extension_argument_count.main();
    invalid_factory_annotation.main();
    invalid_factory_method_impl.main();
    invalid_factory_name_not_a_class.main();
    invalid_field_type_in_struct.main();
    invalid_field_name.main();
    invalid_immutable_annotation.main();
    invalid_implementation_override.main();
    invalid_internal_annotation.main();
    invalid_language_override_greater.main();
    invalid_language_override.main();
    invalid_literal_annotation.main();
    invalid_modifier_on_constructor.main();
    invalid_modifier_on_setter.main();
    invalid_non_virtual_annotation.main();
    invalid_null_aware_operator.main();
    invalid_override_of_non_virtual_member.main();
    invalid_override.main();
    invalid_reference_to_generative_enum_constructor.main();
    invalid_reference_to_this.main();
    invalid_required_named_param.main();
    invalid_required_optional_positional_param.main();
    invalid_required_positional_param.main();
    invalid_sealed_annotation.main();
    invalid_super_formal_parameter_location.main();
    invalid_super_in_initializer.main();
    invalid_type_argument_in_const_list.main();
    invalid_type_argument_in_const_map.main();
    invalid_type_argument_in_const_set.main();
    invalid_uri.main();
    invalid_use_of_covariant.main();
    invalid_use_of_covariant_in_extension.main();
    invalid_use_of_internal_member.main();
    invalid_use_of_protected_member.main();
    invalid_use_of_visible_for_overriding_member.main();
    invalid_use_of_visible_for_template_member.main();
    invalid_use_of_visible_for_testing_member.main();
    invalid_visibility_annotation.main();
    invalid_visible_for_overriding_annotation.main();
    invocation_of_extension_without_call.main();
    invocation_of_non_function_expression.main();
    label_in_outer_scope.main();
    label_undefined.main();
    late_final_field_with_const_constructor.main();
    late_final_local_already_assigned.main();
    list_element_type_not_assignable.main();
    main_first_positional_parameter_type.main();
    main_has_required_named_parameters.main();
    main_has_too_many_required_positional_parameters.main();
    main_is_not_function.main();
    map_entry_not_in_map.main();
    map_key_type_not_assignable.main();
    map_value_type_not_assignable.main();
    member_with_class_name.main();
    mismatched_annotation_on_struct_field.main();
    missing_annotation_on_struct_field.main();
    missing_default_value_for_parameter.main();
    missing_enum_constant_in_switch.main();
    missing_exception_value.main();
    missing_field_type_in_struct.main();
    missing_override_of_must_be_overridden.main();
    missing_required_param.main();
    missing_return.main();
    missing_size_annotation_carray.main();
    missing_variable_pattern.main();
    mixin_application_concrete_super_invoked_member_type.main();
    mixin_application_no_concrete_super_invoked_member.main();
    mixin_application_not_implemented_interface.main();
    mixin_class_declares_constructor.main();
    mixin_declares_constructor.main();
    mixin_deferred_class.main();
    mixin_inference_no_possible_substitution.main();
    mixin_inherits_from_not_object.main();
    mixin_instantiate_test.main();
    mixin_of_disallowed_class.main();
    mixin_of_non_class.main();
    mixin_of_type_alias_expands_to_type_parameter.main();
    mixin_on_sealed_class.main();
    mixin_on_type_alias_expands_to_type_parameter.main();
    mixin_super_class_constraint_deferred_class.main();
    mixin_super_class_constraint_disallowed_class.main();
    mixin_super_class_constraint_non_interface.main();
    mixin_with_non_class_superclass.main();
    mixins_super_class.main();
    mock_sdk.main();
    multiple_redirecting_constructor_invocations.main();
    multiple_super_initializers.main();
    must_be_a_native_function_type.main();
    must_be_a_subtype.main();
    must_be_immutable.main();
    must_call_super.main();
    native_clause_in_non_sdk_code.main();
    native_function_body_in_non_sdk_code.main();
    new_with_non_type.main();
    new_with_undefined_constructor.main();
    no_annotation_constructor_arguments.main();
    no_combined_super_signature.main();
    no_default_super_constructor.main();
    no_generative_constructors_in_superclass.main();
    non_abstract_class_inherits_abstract_member.main();
    non_bool_condition.main();
    non_bool_expression.main();
    non_bool_negation_expression.main();
    non_bool_operand.main();
    non_const_call_to_literal_constructor.main();
    non_const_generative_enum_constructor.main();
    non_const_map_as_expression_statement.main();
    non_constant_annotation_constructor.main();
    non_constant_list_element.main();
    non_constant_case_expression_from_deferred_library.main();
    non_constant_case_expression.main();
    non_constant_default_value_from_deferred_library.main();
    non_constant_default_value.main();
    non_constant_list_element_from_deferred_library.main();
    non_constant_map_key.main();
    non_constant_map_pattern_key.main();
    non_constant_map_key_from_deferred_library.main();
    non_constant_map_element.main();
    non_constant_map_value.main();
    non_constant_relational_pattern_expression.main();
    non_constant_map_value_from_deferred_library.main();
    non_constant_set_element.main();
    non_constant_type_argument.main();
    non_exhaustive_switch.main();
    non_final_field_in_enum.main();
    non_generative_constructor.main();
    non_generative_implicit_constructor.main();
    non_native_function_type_argument_to_pointer.main();
    non_null_opt_out.main();
    non_positive_array_dimension.main();
    non_sized_type_argument.main();
    non_type_as_type_argument.main();
    non_type_in_catch_clause.main();
    non_void_return_for_operator.main();
    non_void_return_for_setter.main();
    not_a_type.main();
    not_assigned_potentially_non_nullable_local_variable.main();
    not_binary_operator.main();
    not_enough_positional_arguments.main();
    not_initialized_non_nullable_instance_field.main();
    not_initialized_non_nullable_variable.main();
    not_instantiated_bound.main();
    not_iterable_spread.main();
    not_map_spread.main();
    not_null_aware_null_spread.main();
    null_argument_to_non_null_type.main();
    null_aware_before_operator.main();
    null_aware_in_condition.main();
    null_aware_in_logical_operator.main();
    null_check_always_fails.main();
    null_safety_read_write.main();
    nullable_type_in_catch_clause.main();
    nullable_type_in_extends_clause.main();
    nullable_type_in_implements_clause.main();
    nullable_type_in_on_clause.main();
    nullable_type_in_with_clause.main();
    object_cannot_extend_another_class.main();
    obsolete_colon_for_default_value.main();
    on_repeated.main();
    optional_parameter_in_operator.main();
    override_on_non_overriding_field.main();
    override_on_non_overriding_getter.main();
    override_on_non_overriding_method.main();
    override_on_non_overriding_setter.main();
    packed_annotation.main();
    packed_annotation_alignment.main();
    part_of_different_library.main();
    part_of_non_part.main();
    pattern_assignment_not_local_variable.main();
    pattern_type_mismatch_in_irrefutable_context.main();
    pattern_variable_assignment_inside_guard.main();
    positional_super_formal_parameter_with_positional_argument.main();
    prefix_collides_with_top_level_member.main();
    prefix_identifier_not_followed_by_dot.main();
    prefix_shadowed_by_local_declaration.main();
    private_collision_in_mixin_application.main();
    private_optional_parameter.main();
    private_setter.main();
    receiver_of_type_never.main();
    recursive_compile_time_constant.main();
    recursive_constructor_redirect.main();
    recursive_factory_redirect.main();
    recursive_interface_inheritance_extends.main();
    recursive_interface_inheritance_implements.main();
    recursive_interface_inheritance.main();
    recursive_interface_inheritance_with.main();
    redirect_generative_to_missing_constructor.main();
    redirect_generative_to_non_generative_constructor.main();
    redirect_to_abstract_class_constructor.main();
    redirect_to_invalid_function_type.main();
    redirect_to_invalid_return_type.main();
    redirect_to_missing_constructor.main();
    redirect_to_non_class.main();
    redirect_to_non_const_constructor.main();
    redirect_to_type_alias_expands_to_type_parameter.main();
    referenced_before_declaration.main();
    refutable_pattern_in_irrefutable_context.main();
    relational_pattern_operator_return_type_not_assignable_to_bool.main();
    removed_lint_in_ignore.main();
    replaced_lint_in_ignore.main();
    rest_element_not_last_in_map_pattern.main();
    rethrow_outside_catch.main();
    return_in_generative_constructor.main();
    return_in_generator.main();
    return_of_do_not_store.main();
    return_of_invalid_type_from_catch_error.main();
    return_of_invalid_type.main();
    return_type_invalid_for_catch_error.main();
    return_without_value.main();
    set_element_from_deferred_library.main();
    sdk_version_as_expression_in_const_context.main();
    sdk_version_async_exported_from_core.main();
    sdk_version_bool_operator_in_const_context.main();
    sdk_version_eq_eq_operator.main();
    sdk_version_extension_methods.main();
    sdk_version_gt_gt_gt_operator.main();
    sdk_version_is_expression_in_const_context.main();
    sdk_version_never.main();
    sdk_version_set_literal.main();
    sdk_version_ui_as_code.main();
    sdk_version_ui_as_code_in_const_context.main();
    sealed_class_subtype_outside_of_library.main();
    sealed_mixin_subtype_outside_of_library.main();
    set_element_type_not_assignable.main();
    shared_deferred_prefix.main();
    size_annotation_dimensions.main();
    spread_expression_from_deferred_library.main();
    static_access_to_instance_member.main();
    strict_raw_type.main();
    subtype_of_ffi_class.main();
    subtype_of_sealed_class.main();
    subtype_of_struct_class.main();
    super_formal_parameter_type_is_not_subtype_of_associated.main();
    super_formal_parameter_without_associated_named.main();
    super_formal_parameter_without_associated_positional.main();
    super_in_enum_constructor.main();
    super_in_extension.main();
    super_in_invalid_context.main();
    super_in_redirecting_constructor.main();
    super_initializer_in_object.main();
    super_invocation_not_last.main();
    switch_case_completes_normally.main();
    switch_expression_not_assignable.main();
    tearoff_of_generative_constructor_of_abstract_class.main();
    text_direction_code_point.main();
    throw_of_invalid_type.main();
    todo_test.main();
    top_level_cycle.main();
    top_level_instance_getter.main();
    type_alias_cannot_reference_itself.main();
    type_annotation_deferred_class.main();
    type_argument_not_matching_bounds.main();
    type_check_is_not_null.main();
    type_check_is_null.main();
    type_parameter_referenced_by_static.main();
    type_parameter_supertype_of_its_bound.main();
    type_test_with_non_type.main();
    type_test_with_undefined_name.main();
    undefined_annotation.main();
    undefined_class_boolean.main();
    undefined_class.main();
    undefined_constructor_in_initializer_default.main();
    undefined_constructor_in_initializer.main();
    undefined_enum_constant.main();
    undefined_enum_constructor_named.main();
    undefined_enum_constructor_unnamed.main();
    undefined_extension_getter.main();
    undefined_extension_method.main();
    undefined_extension_operator.main();
    undefined_extension_setter.main();
    undefined_getter.main();
    undefined_hidden_name.main();
    undefined_identifier_await.main();
    undefined_identifier.main();
    undefined_method.main();
    undefined_named_parameter.main();
    undefined_operator.main();
    undefined_prefixed_name.main();
    undefined_referenced_parameter.main();
    undefined_setter.main();
    undefined_shown_name.main();
    undefined_super_getter.main();
    undefined_super_method.main();
    undefined_super_operator.main();
    undefined_super_setter.main();
    unignorable_ignore.main();
    unnecessary_import.main();
    unnecessary_cast_pattern.main();
    unnecessary_cast.main();
    unnecessary_final.main();
    unnecessary_ignore.main();
    unnecessary_nan_comparison.main();
    unnecessary_no_such_method.main();
    unnecessary_non_null_assertion.main();
    unnecessary_null_assert_pattern.main();
    unnecessary_null_check_pattern.main();
    unnecessary_null_comparison.main();
    unnecessary_question_mark.main();
    unnecessary_set_literal.main();
    unnecessary_type_check.main();
    unnecessary_wildcard_pattern.main();
    unqualified_reference_to_non_local_static_member.main();
    unqualified_reference_to_static_member_of_extended_type.main();
    unreachable_switch_case.main();
    unused_catch_clause.main();
    unused_catch_stack.main();
    unused_element.main();
    unused_field.main();
    unused_import.main();
    unused_label.main();
    unused_local_variable.main();
    unused_result.main();
    unused_shown_name.main();
    uri_does_not_exist.main();
    uri_with_interpolation.main();
    use_of_native_extension.main();
    use_of_nullable_value_test.main();
    use_of_void_result.main();
    values_declaration_in_enum.main();
    variable_type_mismatch.main();
    void_with_type_arguments_test.main();
    wrong_number_of_parameters_for_operator.main();
    wrong_number_of_parameters_for_setter.main();
    wrong_number_of_type_arguments_enum.main();
    wrong_number_of_type_arguments_extension.main();
    wrong_number_of_type_arguments.main();
    wrong_type_parameter_variance_in_superinterface.main();
    yield_each_in_non_generator.main();
    yield_in_non_generator.main();
    yield_of_invalid_type.main();
    defineReflectiveTests(UpdateNodeTextExpectations);
  }, name: 'diagnostics');
}
