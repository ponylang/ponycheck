use "ponytest"
use ".."
use "collections"

class PropertyAsUnitTest is Property1[U8]

    fun name(): String => "property1/asUnitTest"

    fun gen(): Generator[U8] val => Generators.u8(0, 10)

    fun property(arg1: U8, h: PropertyHelper): U8^ ? =>
        h.assert_true(arg1 <= U8(10))
        if arg1 > 100 then
            error
        end
        consume arg1


