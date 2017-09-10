use "ponytest"
use ".."
use "random"
use "time"
use "itertools"

class UnsignedShrinkTest is UnitTest
  fun name(): String => "shrink/unsigned_generators"

  fun apply(h: TestHelper) ? =>
    let gen = Generators.u8()

    (_, let shrinks: Seq[U8]) = gen.shrink(U8(0))
    h.assert_eq[USize](shrinks.size(), 0, "shrunk minimal value to non-empty list of samples")

    (_, let shrinks1: Seq[U8]) = gen.shrink(U8(1))
    h.assert_eq[USize](shrinks1.size(), 1, "didn't include 0 in shrunken list of samples")

    (_, let shrinksx: Seq[U8]) = gen.shrink(U8.max_value())
    h.assert_true((shrinksx as Array[U8]).contains(0))
    h.assert_true((shrinksx as Array[U8]).contains(1))

class MinUnsignedShrinkTest is UnitTest
  fun name(): String => "shrink/min_unsigned_generators"

  fun apply(h: TestHelper) =>
    let min = U64(10)
    let gen = Generators.u64(where min=min)

    (_, let shrinks: Seq[U64]) = gen.shrink(min)
    h.assert_eq[USize](shrinks.size(), 0, "non-empty shrinks for minimal value")

    (_, let shrinks2: Seq[U64]) = gen.shrink(42)
    h.assert_true(
      Iter[U64](shrinks.values())
        .all({(u: U64): Bool => u >= min}),
      "generated shrinks that violate minimum")


class SignedShrinkTest is UnitTest
  fun name(): String => "shrink/signed_generators"

  fun apply(h: TestHelper) ? =>
    let gen = Generators.i64()

    (_, let shrinksmin: Seq[I64]) = gen.shrink(I64.min_value())
    h.assert_eq[USize](shrinksmin.size(), 0, "shrunk minimal value to non-empty list of samples")
    h.assert_false((shrinksmin as Array[I64]).contains(I64.min_value()), "shrink arg included in shrink list")

    (_, let shrinks1: Seq[I64]) = gen.shrink(I64.min_value() + 1)
    h.assert_eq[USize](shrinks1.size(), 1, "didn't include 0 in shrunken list of samples")
    h.assert_false((shrinks1 as Array[I64]).contains(I64(-1)), "shrink arg included in shrink list")

    (_, let shrinksx: Seq[I64]) = gen.shrink(I64.max_value())
    h.assert_true((shrinksx as Array[I64]).contains(I64.min_value()))
    h.assert_true((shrinksx as Array[I64]).contains(I64.min_value()+1))
    h.assert_false((shrinksx as Array[I64]).contains(I64.max_value()), "shrink arg included in shrink list")

class MinSignedShrinkTest is UnitTest
  fun name(): String => "shrink/min_signed_generators"

  fun apply(h: TestHelper) =>
    let min = I16(-10)
    let gen = Generators.i16(where min=min)

    (_, let shrinks: Seq[I16]) = gen.shrink(min)
    h.assert_eq[USize](shrinks.size(), 0, "non-empty shrinks for minimal value")

    (_, let shrinks2: Seq[I16]) = gen.shrink(-2)
    h.assert_true(
      Iter[I16](shrinks.values())
        .all({(i: I16): Bool => i >= min}),
      "generated shrinks that violate minimum")


class ASCIIStringShrinkTest is UnitTest
  fun name(): String => "shrink/ascii_string_generators"

  fun apply(h: TestHelper) ? =>
    let gen = Generators.ascii(where min=0)

    (_, let shrinks_min: Seq[String]) = gen.shrink("")
    h.assert_eq[USize](shrinks_min.size(), 0, "non-empty shrinks for minimal value")

    let sample = "ABCDEF"
    (_, let shrinks: Seq[String]) = gen.shrink(sample)
    h.assert_array_eq[String](
      [""; "A"; "ABCDE"],
      (shrinks as Array[String]))

    let short_sample = "A"
    (_, let short_shrinks: Seq[String]) = gen.shrink(short_sample)
    h.assert_true((short_shrinks as Array[String]).contains(""))
    h.assert_false((short_shrinks as Array[String]).contains(short_sample))

class MinASCIIStringShrinkTest is UnitTest
  fun name(): String => "shrink/min_ascii_string_generators"

  fun apply(h: TestHelper) =>
    let min: USize = 10
    let gen = Generators.ascii(where min=min)

    (_, let shrinks_min: Seq[String]) = gen.shrink("abcdefghi")
    h.assert_eq[USize](shrinks_min.size(), 0, "generated non-empty shrinks for string smaller than minimum")

    (_, let shrinks: Seq[String]) = gen.shrink("abcdefghijlkmnop")
    h.assert_true(
      Iter[String](shrinks.values())
        .all({(s: String): Bool => s.size() >= min}), "generated shrinks that violate minimum string length")

class UnicodeStringShrinkTest is UnitTest
  fun name(): String => "shrink/unicode_string_generators"

  fun apply(h: TestHelper) ? =>
    let gen = Generators.unicode()

    (_, let shrinks_min: Seq[String]) = gen.shrink("")
    h.assert_eq[USize](shrinks_min.size(), 0, "non-empty shrinks for minimal value")

    let sample2 = "ΣΦΩ"
    (_, let shrinks2: Seq[String]) = gen.shrink(sample2)
    h.assert_false(
      (shrinks2 as Array[String]).contains(sample2))
    h.assert_true(shrinks2.size() > 0, "empty shrinks for non-minimal unicode string")

    let sample3 = "Σ"
    (_, let shrinks3: Seq[String]) = gen.shrink(sample3)
    h.assert_false(
      (shrinks3 as Array[String]).contains(sample3),
      "shrinks contain sample value")
    h.assert_true(
      (shrinks2 as Array[String]).contains(""),
      "minimal non-empty empty string not properly shrunk")

class MinUnicodeStringShrinkTest is UnitTest
  fun name(): String => "shrink/min_unicode_string_generators"

  fun apply(h: TestHelper) ? =>
    let min = USize(5)
    let gen = Generators.unicode(where min=min)

    let min_sample = "ΣΦΩ"
    (_, let shrinks_min) = gen.shrink(min_sample)
    h.assert_eq[USize](shrinks_min.size(), 0, "non-empty shrinks for minimal value")

    let sample = "ΣΦΩΣΦΩ"
    (_, let shrinks) = gen.shrink(sample)
    h.assert_true(
      Iter[String](shrinks.values())
        .all({(s: String): Bool => s.codepoints() >= min}),
      "generated shrinks that violate minimum string length")
    h.assert_false(
      (shrinks as Array[String]).contains(sample),
      "shrinks contain sample value")



