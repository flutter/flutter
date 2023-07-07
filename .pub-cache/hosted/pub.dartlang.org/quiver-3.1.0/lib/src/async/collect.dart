// Copyright 2014 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Returns a stream of completion events for the input [futures].
///
/// Successfully completed futures yield data events, while futures completed
/// with errors yield error events.
///
/// The iterator obtained from [futures] is only advanced once the previous
/// future completes and yields an event.  Thus, lazily creating the futures is
/// supported, for example:
///
///     collect(files.map((file) => file.readAsString()));
///
/// If you need to modify [futures], or a backing collection thereof, before
/// the returned stream is done, pass a copy instead to avoid a
/// [ConcurrentModificationError]:
///
///     collect(files.toList().map((file) => file.readAsString()));
Stream<T> collect<T>(Iterable<Future<T>> futures) =>
    Stream.fromIterable(futures).asyncMap((f) => f);
