use "ponytest"
use ponycheck = ".."
use "collections"

class GenRndTest is UnitTest

    fun name(): String => "Gen/random_behaviour"

    fun apply(h: TestHelper) =>
        let gen = ponycheck.Generators.i32()
        let rnd1 = ponycheck.Randomness(0)
        let rnd2 = ponycheck.Randomness(0)
        let rnd3 = ponycheck.Randomness(1)
        var same: U32 = 0
        for x in Range(0, 100) do
            let g1 = gen.generate(rnd1)
            let g2 = gen.generate(rnd2)
            let g3 = gen.generate(rnd3)
            h.assert_eq[I32](g1, g2)
            if g1 == g3 then
                same = same + 1
            end
        end
        h.assert_ne[U32](same, 100)


class GenFilterTest is UnitTest
    fun name(): String => "Gen/filter"

    fun apply(h: TestHelper) =>
        """ensure that filter condition is met for all generated results"""
        let gen = ponycheck.Generators.i32().filter({(i: I32^): (I32^, Bool) => (i, (i%2) == 0)})
        let rnd = ponycheck.Randomness(123)
        for x in Range(0, 100) do
            let v = gen.generate(rnd)
            h.assert_true((v%2) == 0)
        end

class NumericRangeGeneratorTest is UnitTest
    fun name(): String => "Gen/numeric_range"

    fun apply(h: TestHelper) =>
        let range: ponycheck.NumericRange[I32] val = ponycheck.NumericRange[I32](I32(0), I32(10))
        let gen = ponycheck.NumericGenerator[I32](range, {(rnd: ponycheck.Randomness): I32 => rnd.i32()})
        let rnd = ponycheck.Randomness(0)
        for x in Range(0, 100) do
            let v = gen.generate(rnd)
            h.assert_true((v >= 0) and (v <=10))
        end
