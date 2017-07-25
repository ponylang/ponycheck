use "ponytest"
use ".."

class ForAllTest is UnitTest
    fun name(): String => "ponycheck/forall"

    fun apply(h: TestHelper) ? =>
        Ponycheck.forAll[U8](Generators.unit[U8](0), h)({
            (u: U8, h: PropertyHelper) =>
                h.assert_eq[U8](u, 0, u.string() + " == 0")
        })

class MultipleForAllTest is UnitTest
    fun name(): String => "ponycheck/multipleForAll"

    fun apply(h: TestHelper) ? =>
        Ponycheck.forAll[U8](Generators.unit[U8](0), h)({
            (u: U8, h: PropertyHelper) =>
                h.assert_eq[U8](u, 0, u.string() + " == 0")
        })
        Ponycheck.forAll[U8](Generators.unit[U8](1), h)({
            (u: U8, h: PropertyHelper) =>
                h.assert_eq[U8](u, 1, u.string() + " == 1")
        })

