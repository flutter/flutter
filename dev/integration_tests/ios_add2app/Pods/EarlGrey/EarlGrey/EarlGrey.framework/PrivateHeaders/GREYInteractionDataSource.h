//
// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

@protocol GREYProvider;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Provides data to a GREYInteraction.
 */
@protocol GREYInteractionDataSource<NSObject>

/**
 *  The root element provider for an interaction. The entire hierarchies starting from the root
 *  elements are searched to find the right element to interact with.
 *
 *  @return A GREYProvider instance providing data for the interaction.
 */
- (id<GREYProvider>)rootElementProvider;

@end

NS_ASSUME_NONNULL_END
