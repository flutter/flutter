/*
 * Copyright (C) 2011 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"

#include "wtf/RefCounted.h"
#include "wtf/Functional.h"
#include <gtest/gtest.h>

namespace {

using namespace WTF;

static int returnFortyTwo()
{
    return 42;
}

TEST(FunctionalTest, Basic)
{
    Function<int()> emptyFunction;
    EXPECT_TRUE(emptyFunction.isNull());

    Function<int()> returnFortyTwoFunction = bind(returnFortyTwo);
    EXPECT_FALSE(returnFortyTwoFunction.isNull());
    EXPECT_EQ(42, returnFortyTwoFunction());
}

static int multiplyByTwo(int n)
{
    return n * 2;
}

static double multiplyByOneAndAHalf(double d)
{
    return d * 1.5;
}

TEST(FunctionalTest, UnaryBind)
{
    Function<int()> multiplyFourByTwoFunction = bind(multiplyByTwo, 4);
    EXPECT_EQ(8, multiplyFourByTwoFunction());

    Function<double()> multiplyByOneAndAHalfFunction = bind(multiplyByOneAndAHalf, 3);
    EXPECT_EQ(4.5, multiplyByOneAndAHalfFunction());
}

TEST(FunctionalTest, UnaryPartBind)
{
    Function<int(int)> multiplyByTwoFunction = bind<int>(multiplyByTwo);
    EXPECT_EQ(8, multiplyByTwoFunction(4));

    Function<double(double)> multiplyByOneAndAHalfFunction = bind<double>(multiplyByOneAndAHalf);
    EXPECT_EQ(4.5, multiplyByOneAndAHalfFunction(3));
}

static int multiply(int x, int y)
{
    return x * y;
}

static int subtract(int x, int y)
{
    return x - y;
}

TEST(FunctionalTest, BinaryBind)
{
    Function<int()> multiplyFourByTwoFunction = bind(multiply, 4, 2);
    EXPECT_EQ(8, multiplyFourByTwoFunction());

    Function<int()> subtractTwoFromFourFunction = bind(subtract, 4, 2);
    EXPECT_EQ(2, subtractTwoFromFourFunction());
}

TEST(FunctionalTest, BinaryPartBind)
{
    Function<int(int)> multiplyFourFunction = bind<int>(multiply, 4);
    EXPECT_EQ(8, multiplyFourFunction(2));
    Function<int(int, int)> multiplyFunction = bind<int, int>(multiply);
    EXPECT_EQ(8, multiplyFunction(4, 2));

    Function<int(int)> subtractFromFourFunction = bind<int>(subtract, 4);
    EXPECT_EQ(2, subtractFromFourFunction(2));
    Function<int(int, int)> subtractFunction = bind<int, int>(subtract);
    EXPECT_EQ(2, subtractFunction(4, 2));
}

static void sixArgFunc(int a, double b, char c, int* d, double* e, char* f)
{
    *d = a;
    *e = b;
    *f = c;
}

static void assertArgs(int actualInt, double actualDouble, char actualChar, int expectedInt, double expectedDouble, char expectedChar)
{
    EXPECT_EQ(expectedInt, actualInt);
    EXPECT_EQ(expectedDouble, actualDouble);
    EXPECT_EQ(expectedChar, actualChar);
}

TEST(FunctionalTest, MultiPartBind)
{
    int a = 0;
    double b = 0.5;
    char c = 'a';

    Function<void(int, double, char, int*, double*, char*)> unbound =
        bind<int, double, char, int*, double*, char*>(sixArgFunc);
    unbound(1, 1.5, 'b', &a, &b, &c);
    assertArgs(a, b, c, 1, 1.5, 'b');

    Function<void(double, char, int*, double*, char*)> oneBound =
        bind<double, char, int*, double*, char*>(sixArgFunc, 2);
    oneBound(2.5, 'c', &a, &b, &c);
    assertArgs(a, b, c, 2, 2.5, 'c');

    Function<void(char, int*, double*, char*)> twoBound =
        bind<char, int*, double*, char*>(sixArgFunc, 3, 3.5);
    twoBound('d', &a, &b, &c);
    assertArgs(a, b, c, 3, 3.5, 'd');

    Function<void(int*, double*, char*)> threeBound =
        bind<int*, double*, char*>(sixArgFunc, 4, 4.5, 'e');
    threeBound(&a, &b, &c);
    assertArgs(a, b, c, 4, 4.5, 'e');

    Function<void(double*, char*)> fourBound =
        bind<double*, char*>(sixArgFunc, 5, 5.5, 'f', &a);
    fourBound(&b, &c);
    assertArgs(a, b, c, 5, 5.5, 'f');

    Function<void(char*)> fiveBound =
        bind<char*>(sixArgFunc, 6, 6.5, 'g', &a, &b);
    fiveBound(&c);
    assertArgs(a, b, c, 6, 6.5, 'g');

    Function<void()> sixBound =
        bind(sixArgFunc, 7, 7.5, 'h', &a, &b, &c);
    sixBound();
    assertArgs(a, b, c, 7, 7.5, 'h');
}

class A {
public:
    explicit A(int i)
        : m_i(i)
    {
    }

    int f() { return m_i; }
    int addF(int j) { return m_i + j; }

private:
    int m_i;
};

TEST(FunctionalTest, MemberFunctionBind)
{
    A a(10);
    Function<int()> function1 = bind(&A::f, &a);
    EXPECT_EQ(10, function1());

    Function<int()> function2 = bind(&A::addF, &a, 15);
    EXPECT_EQ(25, function2());
}

TEST(FunctionalTest, MemberFunctionPartBind)
{
    A a(10);
    Function<int(class A*)> function1 = bind<class A*>(&A::f);
    EXPECT_EQ(10, function1(&a));

    Function<int(class A*, int)> unboundFunction2 =
        bind<class A*, int>(&A::addF);
    EXPECT_EQ(25, unboundFunction2(&a, 15));
    Function<int(int)> objectBoundFunction2 =
        bind<int>(&A::addF, &a);
    EXPECT_EQ(25, objectBoundFunction2(15));
}

class Number : public RefCounted<Number> {
public:
    static PassRefPtr<Number> create(int value)
    {
        return adoptRef(new Number(value));
    }

    ~Number()
    {
        m_value = 0;
    }

    int value() const { return m_value; }

private:
    explicit Number(int value)
        : m_value(value)
    {
    }

    int m_value;
};

static int multiplyNumberByTwo(Number* number)
{
    return number->value() * 2;
}

TEST(FunctionalTest, RefCountedStorage)
{
    RefPtr<Number> five = Number::create(5);
    Function<int()> multiplyFiveByTwoFunction = bind(multiplyNumberByTwo, five);
    EXPECT_EQ(10, multiplyFiveByTwoFunction());

    Function<int()> multiplyFourByTwoFunction = bind(multiplyNumberByTwo, Number::create(4));
    EXPECT_EQ(8, multiplyFourByTwoFunction());

    RefPtr<Number> six = Number::create(6);
    Function<int()> multiplySixByTwoFunction = bind(multiplyNumberByTwo, six.release());
    EXPECT_FALSE(six);
    EXPECT_EQ(12, multiplySixByTwoFunction());
}

} // namespace
