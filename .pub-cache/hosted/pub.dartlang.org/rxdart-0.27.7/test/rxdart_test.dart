library test.rx;

import 'streams/combine_latest_test.dart' as combine_latest_test;
import 'streams/composite_subscription_test.dart'
    as composite_subscription_test;
import 'streams/concat_eager_test.dart' as concat_eager_test;
import 'streams/concat_test.dart' as concat_test;
import 'streams/defer_test.dart' as defer_test;
import 'streams/fork_join_test.dart' as fork_join_test;
import 'streams/from_callable_test.dart' as from_callable_test;
import 'streams/merge_test.dart' as merge_test;
import 'streams/never_test.dart' as never_test;
import 'streams/publish_connectable_stream_test.dart'
    as publish_connectable_stream_test;
import 'streams/race_test.dart' as race_test;
import 'streams/range_test.dart' as range_test;
import 'streams/repeat_test.dart' as repeat_test;
import 'streams/replay_connectable_stream_test.dart'
    as replay_connectable_stream_test;
import 'streams/retry_test.dart' as retry_test;
import 'streams/retry_when_test.dart' as retry_when_test;
import 'streams/sequence_equals_test.dart' as sequence_equals_test;
import 'streams/switch_latest_test.dart' as switch_latest_test;
import 'streams/timer_test.dart' as timer_test;
import 'streams/using_test.dart' as using_test;
import 'streams/value_connectable_stream_test.dart'
    as value_connectable_stream_test;
import 'streams/zip_test.dart' as zip_test;
import 'subject/behavior_subject_test.dart' as behaviour_subject_test;
import 'subject/publish_subject_test.dart' as publish_subject_test;
import 'subject/replay_subject_test.dart' as replay_subject_test;
import 'transformers/backpressure/buffer_count_test.dart' as buffer_count_test;
import 'transformers/backpressure/buffer_test.dart' as buffer_test;
import 'transformers/backpressure/buffer_test_test.dart' as buffer_test_test;
import 'transformers/backpressure/buffer_time_test.dart' as buffer_time_test;
import 'transformers/backpressure/debounce_test.dart' as debounce_test;
import 'transformers/backpressure/debounce_time_test.dart'
    as debounce_time_test;
import 'transformers/backpressure/pairwise_test.dart' as pairwise_test;
import 'transformers/backpressure/sample_test.dart' as sample_test;
import 'transformers/backpressure/sample_time_test.dart' as sample_time_test;
import 'transformers/backpressure/throttle_test.dart' as throttle_test;
import 'transformers/backpressure/throttle_time_test.dart'
    as throttle_time_test;
import 'transformers/backpressure/window_count_test.dart' as window_count_test;
import 'transformers/backpressure/window_test.dart' as window_test;
import 'transformers/backpressure/window_test_test.dart' as window_test_test;
import 'transformers/backpressure/window_time_test.dart' as window_time_test;
import 'transformers/concat_with_test.dart' as concat_with_test;
import 'transformers/default_if_empty_test.dart' as default_if_empty_test;
import 'transformers/delay_test.dart' as delay_test;
import 'transformers/delay_when_test.dart' as delay_when_test;
import 'transformers/dematerialize_test.dart' as dematerialize_test;
import 'transformers/distinct_test.dart' as distinct_test;
import 'transformers/distinct_unique_test.dart' as distinct_unique_test;
import 'transformers/do_test.dart' as do_test;
import 'transformers/end_with_many_test.dart' as end_with_many_test;
import 'transformers/end_with_test.dart' as end_with_test;
import 'transformers/exhaust_map_test.dart' as exhaust_map_test;
import 'transformers/flat_map_iterable_test.dart' as flat_map_iterable_test;
import 'transformers/flat_map_test.dart' as flat_map_test;
import 'transformers/group_by_test.dart' as group_by_test;
import 'transformers/ignore_elements_test.dart' as ignore_elements_test;
import 'transformers/interval_test.dart' as interval_test;
import 'transformers/join_test.dart' as join_test;
import 'transformers/map_not_null_test.dart' as map_not_null_test;
import 'transformers/map_to_test.dart' as map_to_test;
import 'transformers/materialize_test.dart' as materialize_test;
import 'transformers/merge_with_test.dart' as merge_with_test;
import 'transformers/on_error_return_test.dart' as on_error_resume_test;
import 'transformers/on_error_return_test.dart' as on_error_return_test;
import 'transformers/on_error_return_with_test.dart'
    as on_error_return_with_test;
import 'transformers/scan_test.dart' as scan_test;
import 'transformers/skip_last_test.dart' as skip_last_test;
import 'transformers/skip_until_test.dart' as skip_until_test;
import 'transformers/start_with_many_test.dart' as start_with_many_test;
import 'transformers/start_with_test.dart' as start_with_test;
import 'transformers/switch_if_empty_test.dart' as switch_if_empty_test;
import 'transformers/switch_map_test.dart' as switch_map_test;
import 'transformers/take_last_test.dart' as take_last_test;
import 'transformers/take_until_test.dart' as take_until_test;
import 'transformers/take_while_inclusive_test.dart'
    as take_while_inclusive_test;
import 'transformers/time_interval_test.dart' as time_interval_test;
import 'transformers/timeout_test.dart' as timeout_test;
import 'transformers/timestamp_test.dart' as timestamp_test;
import 'transformers/where_not_null_test.dart' as where_not_null_test;
import 'transformers/where_type_test.dart' as where_type_test;
import 'transformers/with_latest_from_test.dart' as with_latest_from_test;
import 'transformers/zip_with_test.dart' as zip_with_test;

void main() {
  // Streams
  combine_latest_test.main();
  concat_eager_test.main();
  concat_test.main();
  defer_test.main();
  fork_join_test.main();
  from_callable_test.main();
  merge_test.main();
  never_test.main();
  range_test.main();
  race_test.main();
  repeat_test.main();
  retry_test.main();
  retry_when_test.main();
  sequence_equals_test.main();
  switch_latest_test.main();
  using_test.main();
  zip_test.main();

  // StreamTransformers
  concat_with_test.main();
  default_if_empty_test.main();
  delay_test.main();
  delay_when_test.main();
  dematerialize_test.main();
  distinct_test.main();
  distinct_unique_test.main();
  do_test.main();
  end_with_test.main();
  end_with_many_test.main();
  exhaust_map_test.main();
  flat_map_test.main();
  flat_map_iterable_test.main();
  group_by_test.main();
  ignore_elements_test.main();
  interval_test.main();
  join_test.main();
  map_not_null_test.main();
  map_to_test.main();
  materialize_test.main();
  merge_with_test.main();
  on_error_resume_test.main();
  on_error_return_test.main();
  on_error_return_with_test.main();
  scan_test.main();
  skip_last_test.main();
  skip_until_test.main();
  start_with_many_test.main();
  start_with_test.main();
  switch_if_empty_test.main();
  switch_map_test.main();
  take_last_test.main();
  take_until_test.main();
  take_while_inclusive_test.main();
  time_interval_test.main();
  timeout_test.main();
  timestamp_test.main();
  timer_test.main();
  where_not_null_test.main();
  where_type_test.main();
  with_latest_from_test.main();
  zip_with_test.main();

  // Backpressure
  buffer_test.main();
  buffer_count_test.main();
  buffer_test_test.main();
  buffer_time_test.main();
  debounce_test.main();
  debounce_time_test.main();
  pairwise_test.main();
  sample_test.main();
  sample_time_test.main();
  throttle_test.main();
  throttle_time_test.main();
  window_test.main();
  window_count_test.main();
  window_test_test.main();
  window_time_test.main();

  // Subjects
  behaviour_subject_test.main();
  publish_subject_test.main();
  replay_subject_test.main();

  // Connectable Streams
  value_connectable_stream_test.main();
  replay_connectable_stream_test.main();
  publish_connectable_stream_test.main();

  // Utilities
  composite_subscription_test.main();
}
