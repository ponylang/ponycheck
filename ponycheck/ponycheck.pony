
"""
"""
/*
 *
 * execute in context of a UnitTest
 *
 * trait Property is UnitTest
 *      ... translate UnitTest calls to Property calls ...
 *
 *    fun apply(h: TestHelper) =>
 *
 *
 * trait PropertyHelper
 *    new create(h': TestHelper) =>
 *       h = h'
 *    // mirror testhelper api
 *    // but only report to testhelper the property verification result
 *
 * class MyProp is Property1[T]
 *
 *      def size(): USize = 10
 *
 *      def gen(): Generator[T]
 *
 *      def property(arg1: T, h: PropertyHelper) =>
 *          // CODE UNDER TEST
 *
 *
 * Alternate syntax:
 *
 * class MyTest is UnitTest
 *
 *     fun apply(h: TestHelper) =>
 *         Ponycheck.forAll[U8](Generator.unit[U8](0))({(u: U8, ph: PropertyHelper) =>
 *             ph.assert_eq(u, 0)
 *         })
 *
 */
use "ponytest"


class ForAll[T]
    let _gen: Generator[T]
    let _helper: TestHelper

    new create(gen': Generator[T], testHelper: TestHelper) =>
        _gen = gen'
        _helper = testHelper

    fun apply(prop: {(T, PropertyHelper) ?} val) ? =>
        """
        execute
        """
        let prop1 = object is Property1[T]
            fun name(): String => ""
            fun gen(): Generator[T] => _gen
            fun property(arg1: T, h: PropertyHelper) ? =>
                prop(consume arg1, h)
        end
        prop1.apply(_helper)


primitive Ponycheck
    fun forAll[T](gen: Generator[T], h: TestHelper): ForAll[T] =>
        """
        convenience method for running 1 to many properties as part of
        one ponytest UnitTest.

        Example:

        class MyTestWithSomeProperties is UnitTest
            fun name(): String => "mytest/withMultipleProperties"

            fun apply(h: TestHelper) =>
                Ponycheck.forAll[U8](Generators.unit[U8](0), h)({(u: U8, h: PropertyHelper): U8^ =>
                    h.assert_eq(u, 0)
                    consume u
                })
        """
        ForAll[T](gen, h)

