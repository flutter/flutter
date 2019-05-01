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

#import <EarlGrey/GREYConstants.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Modeled after NSLayoutConstraint, this class captures information related to a layout
 *  constraint: two attributes and a relation that must be satisfied between them.
 */
@interface GREYLayoutConstraint : NSObject

/**
 *  Creates a GREYLayoutConstraint to verify a constraint attribute on an element. The relation is
 *  given by : @c attribute value = @c referenceAttribute * @c multiplier + @c constant.
 *
 *  For example, with constraint relation @c kGREYLayoutRelationEqual, multiplier 2.0 and
 *  constant 10.0, the attribute values of 20.0 and 5.0 satisfy the constraint because:
 *  20.0 = 5.0 * 2.0 + 10.0 but 30.0 and 40.0 don't because 30.0 != 40.0 * 2.0 + 10.0.
 *
 *  @param attribute          A layout attribute to create the constraint from.
 *  @param relation           The GREYLayoutRelation between the @c attribute and
 *                            the @c referenceAttribute
 *  @param referenceAttribute The layout attribute whose relation is being checked
 *                            with respect to @attribute.
 *  @param multiplier         Value to multiply the @c referenceAttribute value.
 *  @param constant           Any constant to be added to the relation being checked.
 *
 *  @return A GREYLayoutConstraint instance, that constrains an element's attribute with
 *          respect to a reference.
 */
+ (instancetype)layoutConstraintWithAttribute:(GREYLayoutAttribute)attribute
                                    relatedBy:(GREYLayoutRelation)relation
                         toReferenceAttribute:(GREYLayoutAttribute)referenceAttribute
                                   multiplier:(CGFloat)multiplier
                                     constant:(CGFloat)constant;

/**
 *  Creates a GREYLayoutConstraint that checks the position of a UI element with respect to a
 *  particular direction
 *
 *  @param direction  The direction being checked against the reference element.
 *  @param separation The separation between an element and an edge in the given @c direction.
 *
 *  @return A GREYLayoutConstraint instance that constrains an element to a particular direction.
 */
+ (instancetype)layoutConstraintForDirection:(GREYLayoutDirection)direction
                        andMinimumSeparation:(CGFloat)separation;

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Checks if the given element satisfies the provided constraints, as shown by a reference element.
 *
 *  @param element          The element being checked for the constraints.
 *  @param referenceElement The reference element to check the @c element against.
 *
 *  @return @c YES if the the given elements satisify the constraint, else @NO.
 */
- (BOOL)satisfiedByElement:(id)element andReferenceElement:(id)referenceElement;

/**
 *  @return A description of the GREYLayoutConstraint created.
 */
- (NSString *)description;

/**
 *  The attribute constraint being checked.
 */
@property(nonatomic, assign) GREYLayoutAttribute attribute;
/**
 *  The GREYLayoutRelation between the @c attribute and the @c referenceAttribute.
 */
@property(nonatomic, assign) GREYLayoutRelation relation;
/**
 *  The value the @c attribute is being compared to.
 */
@property(nonatomic, assign) GREYLayoutAttribute referenceAttribute;
/**
 *  Value to multiply the @c referenceAttribute value with.
 */
@property(nonatomic, assign) CGFloat multiplier;
/**
 *  Any constant to be added to the relation being checked.
 */
@property(nonatomic, assign) CGFloat constant;
@end

NS_ASSUME_NONNULL_END
