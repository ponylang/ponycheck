use "ponytest"
use ".."

class ForAllTest is UnitTest
    fun name(): String => "ponycheck/forall"

    fun apply(h: TestHelper) ? =>
        Ponycheck.forAll[U8](Generators.unit[U8](0), h)({(u: U8, h: PropertyHelper): U8^ =>
            h.assert_true(u == 0, u.string() + " == 0")
            consume u
        })


