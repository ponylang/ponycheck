use "ponytest"

primitive PrivateTests is TestList
  fun tag tests(test: PonyTest) =>
    test(_StringifyTest)

class iso _StringifyTest is UnitTest

  fun name(): String => "stringify"

  fun apply(h: TestHelper) =>
    (let _, var s) = _Stringify.apply[(U8, U8)]((0, 1))
    h.assert_eq[String](s, "(0, 1)")
    (let _, s) = _Stringify.apply[(U8, U32, U128)]((0, 1, 2))
    h.assert_eq[String](s, "(0, 1, 2)")
    (let _, s) = _Stringify.apply[(U8, (U32, U128))]((0, (1, 2)))
    h.assert_eq[String](s, "(0, (1, 2))")
    (let _, s) = _Stringify.apply[((U8, U32), U128)](((0, 1), 2))
    h.assert_eq[String](s, "((0, 1), 2)")
    let a: Array[U8] = [ U8(0); U8(42) ]
    (let _, s) = _Stringify.apply[Array[U8]](a)
    h.assert_eq[String](s, "[0 42]")

