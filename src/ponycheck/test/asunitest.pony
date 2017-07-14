use "ponytest"
use ponycheck = ".."
use "collections"

class PropertyAsUnitTest is ponycheck.Property1[U8]

    fun name(): String => "property1/asUnitTest"

    fun gen(): ponycheck.Generator[U8] val => ponycheck.Generators.u8(0, 10)

    fun property(arg1: U8, h: ponycheck.PropertyHelper): U8^ ? =>
        h.assert_true(arg1 <= U8(10))
        if arg1 > 100 then
            error
        end
        consume arg1


