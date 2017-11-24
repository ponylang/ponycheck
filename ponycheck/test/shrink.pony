use "ponytest"
use ".."
use "random"
use "time"
use "itertools"
use "debug"

trait ShrinkTest is UnitTest
  fun shrink[T](gen: Generator[T], shrink_elem: T): Iterator[T^] =>
    (_, let shrinks': Iterator[T^]) = gen.shrink(consume shrink_elem)
    shrinks'

  fun _collect_shrinks[T](gen: Generator[T], shrink_elem: T): Array[T] =>
    Iter[T^](shrink[T](gen, consume shrink_elem)).collect[Array[T]](Array[T])

  fun _size(shrinks: Iterator[Any^]): USize =>
    Iter[Any^](shrinks).count()

class UnsignedShrinkTest is ShrinkTest
  fun name(): String => "shrink/unsigned_generators"

  fun apply(h: TestHelper) =>
    let gen = Generators.u8()


    let shrinks = shrink[U8](gen, U8.min_value())
    h.assert_false(shrinks.has_next(), "shrunk minimal value to non-empty list of samples")

    let shrinks1 = _collect_shrinks[U8](gen, U8(1))

    h.assert_eq[USize](1, shrinks1.size(), "create too much results")
    h.assert_true(shrinks1.contains(U8.min_value()), "didn't include min in shrunken list of samples")

    let collected = _collect_shrinks[U8](gen, U8.max_value())
    h.assert_true(collected.contains(U8.min_value()))
    h.assert_true(collected.contains(U8.min_value() / 2))

class MinUnsignedShrinkTest is ShrinkTest
  fun name(): String => "shrink/min_unsigned_generators"

  fun apply(h: TestHelper) =>
    let min = U64(10)
    let gen = Generators.u64(where min=min)

    let shrinks = shrink[U64](gen, min)
    h.assert_false(shrinks.has_next(), "non-empty shrinks for minimal value")

    let shrinks2 = shrink[U64](gen, 42)
    h.assert_true(
      Iter[U64^](shrinks2)
        .all({(u: U64): Bool => (u >= min) and (u < 42) }),
      "generated shrinks that violate minimum or maximum")


class SignedShrinkTest is ShrinkTest
  fun name(): String => "shrink/signed_generators"

  fun apply(h: TestHelper) ? =>
    let gen = Generators.i64()

    let shrinksmin = shrink[I64](gen, I64.min_value())
    h.assert_false(shrinksmin.has_next(), "shrunk minimal value to non-empty list of samples")

    let shrinks1 = _collect_shrinks[I64](gen, I64.min_value() + 1)
    h.assert_eq[I64](I64.min_value(), shrinks1(0)?, "didn't include min in shrunken list of samples")
    h.assert_false(shrinks1.contains(I64.min_value() + 1), "shrink arg included in shrink list")

    let shrinksx = _collect_shrinks[I64](gen, I64.min_value() + 100)
    h.assert_true(shrinksx.contains(I64.min_value()))
    h.assert_false(shrinksx.contains(I64.min_value() + 100), "shrink arg included in shrink list")

    let gen2 = Generators.i64(-10, 10)
    for x in Iter[I64](shrink[I64](gen2, 10)).take(100) do
      Debug(x.string())
    end


class MinSignedShrinkTest is ShrinkTest
  fun name(): String => "shrink/min_signed_generators"

  fun apply(h: TestHelper) =>
    let min = I16(-10)
    let gen = Generators.i16(where min=min)

    let shrinks = shrink[I16](gen, min)
    h.assert_false(shrinks.has_next(), "non-empty shrinks for minimal value")

    let shrinks2 = shrink[I16](gen, -2)
    h.assert_true(
      Iter[I16](shrinks)
        .all({(i: I16): Bool => i >= min}),
      "generated shrinks that violate minimum")


class ASCIIStringShrinkTest is ShrinkTest
  fun name(): String => "shrink/ascii_string_generators"

  fun apply(h: TestHelper) =>
    let gen = Generators.ascii(where min=0)

    for s in Iter[String](shrink[String](gen, "")).take(100) do
      Debug("|" + s + "|")
    end

    let shrinks_min = shrink[String](gen, "")
    h.assert_false(shrinks_min.has_next(), "non-empty shrinks for minimal value")

    let sample = "ABCDEF"
    let shrinks = _collect_shrinks[String](gen, sample)
    h.assert_array_eq[String](
      ["ABCDE"; "ABCD"; "ABC"; "AB"; "A"; ""],
      shrinks)

    let short_sample = "A"
    let short_shrinks = _collect_shrinks[String](gen, short_sample)
    h.assert_array_eq[String]([""], short_shrinks, "shrinking 'A' returns wrong results")

class MinASCIIStringShrinkTest is ShrinkTest
  fun name(): String => "shrink/min_ascii_string_generators"

  fun apply(h: TestHelper) =>
    let min: USize = 10
    let gen = Generators.ascii(where min=min)

    let shrinks_min = shrink[String](gen, "abcdefghi")
    h.assert_false(shrinks_min.has_next(), "generated non-empty shrinks for string smaller than minimum")

    let shrinks = shrink[String](gen, "abcdefghijlkmnop")
    h.assert_true(
      Iter[String](shrinks)
        .all({(s: String): Bool => s.size() >= min}), "generated shrinks that violate minimum string length")

class UnicodeStringShrinkTest is ShrinkTest
  fun name(): String => "shrink/unicode_string_generators"

  fun apply(h: TestHelper) =>
    let gen = Generators.unicode()

    let shrinks_min = shrink[String](gen, "")
    h.assert_false(shrinks_min.has_next(), "non-empty shrinks for minimal value")

    let sample2 = "ΣΦΩ"
    let shrinks2 = _collect_shrinks[String](gen, sample2)
    h.assert_false(shrinks2.contains(sample2))
    h.assert_true(shrinks2.size() > 0, "empty shrinks for non-minimal unicode string")

    let sample3 = "Σ"
    let shrinks3 = _collect_shrinks[String](gen, sample3)
    h.assert_array_eq[String]([""], shrinks3, "minimal non-empty string not properly shrunk")

class MinUnicodeStringShrinkTest is ShrinkTest
  fun name(): String => "shrink/min_unicode_string_generators"

  fun apply(h: TestHelper) =>
    let min = USize(5)
    let gen = Generators.unicode(where min=min)

    let min_sample = "ΣΦΩ"
    let shrinks_min = shrink[String](gen, min_sample)
    h.assert_false(shrinks_min.has_next(), "non-empty shrinks for minimal value")

    let sample = "ΣΦΩΣΦΩ"
    let shrinks = _collect_shrinks[String](gen, sample)
    h.assert_true(
      Iter[String](shrinks.values())
        .all({(s: String): Bool => s.codepoints() >= min}),
      "generated shrinks that violate minimum string length")
    h.assert_false(
      shrinks.contains(sample),
      "shrinks contain sample value")



