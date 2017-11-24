use "ponytest"
use "itertools"
use "collections"
use "debug"
use "../ponycheck"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_ListReverseProperty)
    test(_ListReverseOneProperty)
    test(_ListReverseMultipleProperties)

class _ListReverseProperty is Property1[Array[USize]]
  fun name(): String => "list/reverse"

  fun gen(): Generator[Array[USize]] =>
    Generators.seq_of[USize, Array[USize]](Generators.usize())

  fun property(arg1: Array[USize], ph: PropertyHelper) =>
    ph.assert_array_eq[USize](arg1, arg1.reverse().reverse())

class _ListReverseOneProperty is Property1[Array[USize]]
  fun name(): String => "list/reverse/one"

  fun gen(): Generator[Array[USize]] =>
    Generators.seq_of[USize, Array[USize]](Generators.usize(), 1, 1)

  fun property(arg1: Array[USize], ph: PropertyHelper) =>
    Debug(arg1.space().string() + "\n")
    ph.assert_eq[USize](arg1.size(), 1)
    ph.assert_array_eq[USize](arg1, arg1.reverse())

class _ListReverseMultipleProperties is UnitTest
  fun name(): String => "list/properties"

  fun apply(h: TestHelper) ? =>

    let gen1 = Generators.seq_of[USize, Array[USize]](Generators.usize())
    Ponycheck.forAll[Array[USize]](gen1, h)(
      {(arg1: Array[USize], ph: PropertyHelper): None =>
        ph.assert_array_eq[USize](arg1, arg1.reverse().reverse())
      })?

    let gen2 = Generators.seq_of[USize, Array[USize]](Generators.usize(), 1, 1)
    Ponycheck.forAll[Array[USize]](gen2, h)(
      {(arg1: Array[USize], ph: PropertyHelper): None =>
        ph.assert_array_eq[USize](arg1, arg1.reverse())
      })?

