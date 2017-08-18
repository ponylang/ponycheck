use "ponytest"
use ".."
use "collections"
use "itertools"
use "random"
use "time"

class GenRndTest is UnitTest
  fun name(): String => "Gen/random_behaviour"

  fun apply(h: TestHelper) =>
    let gen = Generators.u32()
    let rnd1 = Randomness(0)
    let rnd2 = Randomness(0)
    let rnd3 = Randomness(1)
    var same: U32 = 0
    for x in Range(0, 100) do
      let g1 = gen.generate(rnd1)
      let g2 = gen.generate(rnd2)
      let g3 = gen.generate(rnd3)
      h.assert_eq[U32](g1, g2)
      if g1 == g3 then
        same = same + 1
      end
    end
    h.assert_ne[U32](same, 100)


class GenFilterTest is UnitTest
  fun name(): String => "Gen/filter"

  fun apply(h: TestHelper) =>
    """
    ensure that filter condition is met for all generated results
    """
    let gen = Generators.u32().filter({
      (u: U32^): (U32^, Bool) =>
        (u, (u%2) == 0)
    })
    let rnd = Randomness(Time.millis())
    for x in Range(0, 100) do
      let v = gen.generate(rnd)
      h.assert_true((v%2) == 0)
    end

class GenFrequencyTest is UnitTest
  fun name(): String => "Gen/frequency"

  fun apply(h: TestHelper) =>
    """
    ensure that Generators.frequency(...) generators actually return values
    from different with given frequency
    """
    try
      let gen = Generators.frequency[U8]([
         as WeightedGenerator[U8]:
          (1, Generators.unit[U8](0))
          (0, Generators.unit[U8](42))
          (2, Generators.unit[U8](1)) ])?
      let rnd: Randomness ref = Randomness(Time.millis())

      let generated = Array[U8](100)
      for i in Range(0, 100) do
        generated.push(gen.generate(rnd))
      end
      h.assert_false(generated.contains(U8(42)), "frequency generated value with 0 weight")
      h.assert_true(generated.contains(U8(0)), "frequency did not generate value with weight of 1")
      h.assert_true(generated.contains(U8(1)), "frequency did not generate value with weight of 2")
    else
      h.fail("error creating frequency generator")
    end

class SetOfTest is UnitTest
  fun name(): String => "Gen/set_of"

  fun apply(h: TestHelper) =>
    """
    this mainly tests that a source generator with a smaller range
    than max is terminating and generating sane sets
    """
    let set_gen =
      Generators.set_of[U8](
        Generators.u8(),
        1024)
    let rnd = Randomness(Time.millis())
    for i in Range(0, 100) do
      let sample: Set[U8] = set_gen.generate(rnd)
      h.assert_true(sample.size() <= 256, "something about U8 is not right")
    end

class SetOfMaxTest is UnitTest
  fun name(): String => "Gen/set_of_max"

  fun apply(h: TestHelper) =>
    """
    """
    let rnd = Randomness(Time.millis())
    for size in Range[USize](1, U8.max_value().usize()) do
      let set_gen =
        Generators.set_of[U8](
          Generators.u8(),
          size)
      let sample: Set[U8] = set_gen.generate(rnd)
      h.assert_true(sample.size() <= size, "generated set is too big.")
    end


class SetOfEmptyTest is UnitTest
  fun name(): String => "Gen/set_of_empty"

  fun apply(h: TestHelper) =>
    """
    """
    let set_gen =
      Generators.set_of[U8](
        Generators.u8(),
        0)
    let rnd = Randomness(Time.millis())
    for i in Range(0, 100) do
      let sample: Set[U8] = set_gen.generate(rnd)
      h.assert_true(sample.size() == 0, "non-empty set created.")
    end

class SetIsOfIdentityTest is UnitTest
  fun name(): String => "Gen/set_is_of_identity"
  fun apply(h: TestHelper) =>
    """
    """
    let set_is_gen_same =
      Generators.set_is_of[String](
        Generators.unit[String]("the highlander"),
        100)
    let rnd = Randomness(Time.millis())
    let sample: SetIs[String] = set_is_gen_same.generate(rnd)
    h.assert_true(sample.size() <= 1,
        "invalid SetIs instances generated: size " + sample.size().string())

class MapOfEmptyTest is UnitTest
  fun name(): String => "Gen/map_of_empty"

  fun apply(h: TestHelper) =>
    """
    """
    let map_gen =
      Generators.map_of[String, I64](
        Generators.zip2[String, I64](
          Generators.u8().map[String]({(u: U8): String^ =>
            let s = u.string()
            consume s }),
          Generators.i64(-10, 10)
          ),
        0)
    let rnd = Randomness(Time.millis())
    let sample = map_gen.generate(rnd)
    h.assert_eq[USize](sample.size(), 0, "non-empty map created")

class MapOfMaxTest is UnitTest
  fun name(): String => "Gen/map_of_max"

  fun apply(h: TestHelper) =>
    let rnd = Randomness(Time.millis())

    for size in Range(1, U8.max_value().usize()) do
      let map_gen =
        Generators.map_of[String, I64](
          Generators.zip2[String, I64](
            Generators.u16().map[String]({(u: U16): String^ =>
              let s = u.string()
              consume s }),
            Generators.i64(-10, 10)
            ),
        size)
      let sample = map_gen.generate(rnd)
      h.assert_true(sample.size() <= size, "generated map is too big.")
    end

class MapOfIdentityTest is UnitTest
  fun name(): String => "Gen/map_of_identity"

  fun apply(h: TestHelper) =>
    let rnd = Randomness(Time.millis())
    let map_gen =
      Generators.map_of[String, I64](
        Generators.zip2[String, I64](
          Generators.repeatedly[String]({(): String^ =>
            let s = recover String.create(14) end
            s.add("the highlander")
            consume s }),
          Generators.i64(-10, 10)
          ),
      100)
    let sample = map_gen.generate(rnd)
    h.assert_true(sample.size() <= 1)

class MapIsOfEmptyTest is UnitTest
  fun name(): String => "Gen/map_is_of_empty"

  fun apply(h: TestHelper) =>
    """
    """
    let map_is_gen =
      Generators.map_is_of[String, I64](
        Generators.zip2[String, I64](
          Generators.u8().map[String]({(u: U8): String^ =>
            let s = u.string()
            consume s }),
          Generators.i64(-10, 10)
          ),
        0)
    let rnd = Randomness(Time.millis())
    let sample = map_is_gen.generate(rnd)
    h.assert_eq[USize](sample.size(), 0, "non-empty map created")

class MapIsOfMaxTest is UnitTest
  fun name(): String => "Gen/map_is_of_max"

  fun apply(h: TestHelper) =>
    let rnd = Randomness(Time.millis())

    for size in Range(1, U8.max_value().usize()) do
      let map_is_gen =
        Generators.map_is_of[String, I64](
          Generators.zip2[String, I64](
            Generators.u16().map[String]({(u: U16): String^ =>
              let s = u.string()
              consume s }),
            Generators.i64(-10, 10)
            ),
        size)
      let sample = map_is_gen.generate(rnd)
      h.assert_true(sample.size() <= size, "generated map is too big.")
    end

class MapIsOfIdentityTest is UnitTest
  fun name(): String => "Gen/map_is_of_identity"

  fun apply(h: TestHelper) =>
    let rnd = Randomness(Time.millis())
    let map_gen =
      Generators.map_is_of[String, I64](
        Generators.zip2[String, I64](
          Generators.unit[String]("the highlander"),
          Generators.i64(-10, 10)
          ),
      100)
    let sample = map_gen.generate(rnd)
    h.assert_true(sample.size() <= 1)

class ASCIIRangeTest is UnitTest
  fun name(): String => "Gen/ascii_range"
  fun apply(h: TestHelper) =>
    let rnd = Randomness(Time.millis())
    let ascii_gen = Generators.ascii_range( where min=1, max=1)

    for i in Range[USize](0, 100) do
      let sample = ascii_gen.generate(rnd)
      h.assert_true(ASCIIAll().contains(sample), "\"" + sample + "\" not valid ascii")
    end

class UTF32CodePointStringTest is UnitTest
  fun name(): String => "Gen/utf32_codepoint_string"
  fun apply(h: TestHelper) =>
    let rnd = Randomness(Time.millis())
    let string_gen = Generators.utf32_codepoint_string(
      Generators.u32(),
      50,
      100)

    for i in Range[USize](0, 100) do
      let sample = string_gen.generate(rnd)
      for cp in sample.runes() do
        h.assert_true((cp <= 0xD7FF ) or (cp >= 0xE000), "\"" + sample + "\" invalid utf32")
      end
    end

