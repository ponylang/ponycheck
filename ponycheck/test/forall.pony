use "ponytest"
use ".."

primitive ForAllTests is TestList
  fun tag tests(test: PonyTest) =>
    test(ForAllTest)
    test(MultipleForAllTest)
    test(ForAll2Test)
    test(ForAll3Test)
    test(ForAll4Test)

class ForAllTest is UnitTest
  fun name(): String => "ponycheck/for_all"

  fun apply(h: TestHelper) ? =>
    Ponycheck.for_all[U8](recover Generators.unit[U8](0) end, h)(
      {(u, h) => h.assert_eq[U8](u, 0, u.string() + " == 0") })?

class MultipleForAllTest is UnitTest
  fun name(): String => "ponycheck/multiple_for_all"

  fun apply(h: TestHelper) ? =>
    Ponycheck.for_all[U8](recover Generators.unit[U8](0) end, h)(
      {(u, h) => h.assert_eq[U8](u, 0, u.string() + " == 0") })?

    Ponycheck.for_all[U8](recover Generators.unit[U8](1) end, h)(
      {(u, h) => h.assert_eq[U8](u, 1, u.string() + " == 1") })?

class ForAll2Test is UnitTest
  fun name(): String => "ponycheck/for_all2"

  fun apply(h: TestHelper) ? =>
    Ponycheck.for_all2[U8, String](
      recover Generators.unit[U8](0) end,
      recover Generators.ascii() end,
      h)(
        {(arg1, arg2, h) =>
          h.assert_false(arg2.contains(String.from_array([as U8: arg1])))
          })?

class ForAll3Test is UnitTest
  fun name(): String => "ponycheck/for_all3"

  fun apply(h: TestHelper) ? =>
    Ponycheck.for_all3[U8, U8, String](
      recover Generators.unit[U8](0) end,
      recover Generators.unit[U8](255) end,
      recover Generators.ascii() end,
      h)(
        {(b1, b2, str, h) =>
          h.assert_false(str.contains(String.from_array([b1])))
          h.assert_false(str.contains(String.from_array([b2])))
        })?

class ForAll4Test is UnitTest
  fun name(): String => "ponycheck/for_all4"

  fun apply(h: TestHelper) ? =>
    Ponycheck.for_all4[U8, U8, U8, String](
      recover Generators.unit[U8](0) end,
      recover Generators.u8() end,
      recover Generators.u8() end,
      recover Generators.ascii() end,
      h)(
        {(b1, b2, b3, str, h) =>
          let cmp = String.from_array([b1; b2; b3])
          h.assert_false(str.contains(cmp))
          })?

