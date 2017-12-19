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

  fun _test_int_constraints[T: (Int & Integer[T] val)](
    h: TestHelper,
    gen: Generator[T],
    x: T,
    min: T = T.min_value()
  ) ?
    =>
    let shrinks = shrink[T](gen, min)
    h.assert_false(shrinks.has_next(), "non-empty shrinks for minimal value " + min.string())

    let shrinks1 = _collect_shrinks[T](gen, min + 1)
    h.assert_array_eq[T]([min], shrinks1, "didn't include min in shrunken list of samples")

    let shrinks2 = shrink[T](gen, x)
    h.assert_true(
      Iter[T^](shrinks2)
        .all(
          {(u: T): Bool =>
            match x.compare(min)
            | Less =>
              (u <= min) and (u > x)
            | Equal => true
            | Greater =>
              (u >= min) and (u < x)
            end
          }),
      "generated shrinks from " + x.string() + " that violate minimum or maximum")

    let count_shrinks = shrink[T](gen, x)
    let max_count =
      if (x - min) < 0 then
        -(x - min)
      else
        x - min
      end
    let actual_count = T.from[USize](Iter[T^](count_shrinks).count())
    h.assert_true(
      actual_count <= max_count,
      "generated too much values from " + x.string() + " : " + actual_count.string() + " > " + max_count.string())

class UnsignedShrinkTest is ShrinkTest
  fun name(): String => "shrink/unsigned_generators"

  fun apply(h: TestHelper)? =>
    let gen = Generators.u8()
    _test_int_constraints[U8](h, gen, U8(42))?
    _test_int_constraints[U8](h, gen, U8.max_value())?

    let min = U64(10)
    let gen_min = Generators.u64(where min=min)
    _test_int_constraints[U64](h, gen_min, 42, min)?

class SignedShrinkTest is ShrinkTest
  fun name(): String => "shrink/signed_generators"

  fun apply(h: TestHelper) ? =>
    let gen = Generators.i64()
    _test_int_constraints[I64](h, gen, (I64.min_value() + 100))?

    let gen2 = Generators.i64(-10, 20)
    _test_int_constraints[I64](h, gen2, 20, -10)?
    _test_int_constraints[I64](h, gen2, 30, -10)?
    _test_int_constraints[I64](h, gen2, -12, -10)? // weird case but should still work


class ASCIIStringShrinkTest is ShrinkTest
  fun name(): String => "shrink/ascii_string_generators"

  fun apply(h: TestHelper) =>
    let gen = Generators.ascii(where min=0)

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


class FilterMapShrinkTest is ShrinkTest
  fun name(): String => "shrink/filter_map"

  fun apply(h: TestHelper) =>
    let gen: Generator[U64] =
      Generators.u8()
        .filter({(byte) => (byte, byte > 10) })
        .map[U64]({(byte) => (byte * 2).u64() })
    // shrink from 100 and only expect even values > 20
    let shrink_iter = shrink[U64](gen, U64(100))
    h.assert_true(
      Iter[U64](shrink_iter)
        .all({(u) =>
          (u > 20) and ((u % 2) == 0) }),
      "shrinking does not maintain filter invariants")

