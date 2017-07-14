use "ponytest"
use ".."
use "collections"
use "itertools"

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
        """ensure that filter condition is met for all generated results"""
        let gen = Generators.u32().filter({(u: U32^): (U32^, Bool) => (u, (u%2) == 0)})
        let rnd = Randomness(123)
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
            let gen = Generators.frequency[U8]([as (USize, Generator[U8]):
                (1, Generators.unit[U8](U8(0)))
                (0, Generators.unit[U8](U8(42)))
                (2, Generators.unit[U8](U8(1)))
            ])
            let rnd: Randomness ref = Randomness(456)

            let generated = Array[U8](100)
            for i in Range(0, 100) do
                generated(i) = gen.generate(rnd)
            end
            h.assert_false(generated.contains(U8(42)), "frequency generated value with 0 weight")
            h.assert_true(generated.contains(U8(0)), "frequency did not generate value with weight of 1")
            h.assert_true(generated.contains(U8(1)), "frequency did not generate value with weight of 2")
        else
            h.fail("error creating frequency generator")
        end
            
