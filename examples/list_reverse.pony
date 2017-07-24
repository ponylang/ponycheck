
use "ponycheck"
use "ponytest"
use "collections"
actor Main is TestList
    new create(env: Env) =>
        PonyTest(env, this)

    new make() => None

    fun tag tests(test: PonyTest) =>
        test(_ListReverseProperty)
        test(_ListReverseOneProperty)
        test(_ListReverseMultipleProperties)

class _ListReverseProperty is Property1[List[USize]]
    
    fun name(): String => "list/reverse"

    fun gen(): Generator[List[USize]] => Generators.listOf[USize](Generators.uSize())
    
    fun property(arg1: List[USize], ph: PropertyHelper) =>
        ph.assert_array_eq[USize](arg1, arg1.reverse().reverse())

class _ListReverseOneProperty is Property1[List[USize]]

    fun name(): String => "list/reverse/one"

    fun gen(): Generator[List[USize]] => Generators.listOfN[USize](1, Generators.uSize())

    fun property(arg1: List[USize], ph: PropertyHelper) =>
        ph.assert_array_eq[USize](arg1, arg1.reverse())

class _ListReverseMultipleProperties is UnitTest

    fun name(): String => "list/properties"

    fun apply(h: TestHelper) =>
        let gen = Generators.listOf[USize](Generators.uSize())
        Ponycheck.forAll[List[USize]](gen, h)({
            (arg1: List[USize], ph: PropertyHelper) =>
                ph.assert_array_eq[USize](arg1, arg1.reverse().reverse())
        })
        Ponycheck.forAll[List[USize]](gen, h)({
            (arg1: List[USize], ph: PropertyHelper) =>
                ph.assert_array_eq[USize](arg1, arg1.reverse())
        })

