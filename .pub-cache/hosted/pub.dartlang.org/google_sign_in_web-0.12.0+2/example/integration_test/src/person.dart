// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

const String expectedPersonId = '1234567890';
const String expectedPersonName = 'Vincent Adultman';
const String expectedPersonEmail = 'adultman@example.com';
const String expectedPersonPhoto =
    'https://thispersondoesnotexist.com/image?x=.jpg';

/// A subset of https://developers.google.com/people/api/rest/v1/people#Person.
final Map<String, Object?> person = <String, Object?>{
  'resourceName': 'people/$expectedPersonId',
  'emailAddresses': <Object?>[
    <String, Object?>{
      'metadata': <String, Object?>{
        'primary': false,
      },
      'value': 'bad@example.com',
    },
    <String, Object?>{
      'metadata': <String, Object?>{},
      'value': 'nope@example.com',
    },
    <String, Object?>{
      'metadata': <String, Object?>{
        'primary': true,
      },
      'value': expectedPersonEmail,
    },
  ],
  'names': <Object?>[
    <String, Object?>{
      'metadata': <String, Object?>{
        'primary': true,
      },
      'displayName': expectedPersonName,
    },
    <String, Object?>{
      'metadata': <String, Object?>{
        'primary': false,
      },
      'displayName': 'Fakey McFakeface',
    },
  ],
  'photos': <Object?>[
    <String, Object?>{
      'metadata': <String, Object?>{
        'primary': true,
      },
      'url': expectedPersonPhoto,
    },
  ],
};

/// Returns a copy of [map] without the [keysToRemove].
T mapWithoutKeys<T extends Map<String, Object?>>(
  T map,
  Set<String> keysToRemove,
) {
  return Map<String, Object?>.fromEntries(
    map.entries.where((MapEntry<String, Object?> entry) {
      return !keysToRemove.contains(entry.key);
    }),
  ) as T;
}
