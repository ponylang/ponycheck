use "time"
use "collections"
use "ponytest"
/*
 *
 * execute in context of a UnitTest
 *
 * trait Property is UnitTest
 *      ... translate UnitTest calls to Property calls ...
 *
 *    fun apply(h: TestHelper) =>
 *
 *
 * trait PropertyHelper
 *    new create(h': TestHelper) =>
 *       h = h'
 *    // mirror testhelper api
 *    // but only report to testhelper the property verification result
 *
 * class MyProp is Property1[T]
 *
 *      def size(): USize = 10
 *
 *      def gen(): Generator[T]
 *
 *      def property(arg1: T, h: PropertyHelper) =>
 *          // CODE UNDER TEST
 *
 *
 * Alternate syntax:
 *
 * class MyTest is UnitTest
 *
 *     fun apply(h: TestHelper) =>
 *         Ponycheck.forAll(Generator.unit[U8](0))({(u: U8) =>
 *             h.assert_eq(u, 0)
 *         })
 *
 */

class PropertyParams
    let seed: U64
    let size: USize
    let numSamples: USize

    new create(size': USize = 10,
               numSamples': USize = 100,
               seed': U64 = 42) =>
        size = size'
        numSamples = numSamples'
        seed = seed'


trait Property1[T] is UnitTest
    fun params(): PropertyParams => PropertyParams

    fun gen(): Generator[T] val

    fun property(arg1: T, h: PropertyHelper): T^ ?
        """
        because we need the arg for shrinking and reporting later,
        it needs to be returned by this function again
        in case it is an iso
        """
    
    fun apply(h: TestHelper) ? =>
        """
        """
        let parameters = params()
        let rnd = Randomness(parameters.seed)
        let helper = PropertyHelper(h)
        let generator: Generator[T] val = gen()
        for i in Range(0, parameters.numSamples) do
            var sample: T = generator.generate(rnd)
            sample = try
                property(consume sample, helper)
            else
                // report error with given sample
                helper.reportError(parameters, 0)
                return
            end
            if helper._failed() then
                var shrinkRounds: USize = 0
                var shrunken: T = consume sample
                while true do
                    (shrunken, let shrinks: Seq[T])= generator.shrink(consume shrunken)
                    if shrinks.size() == 0 then
                        break
                    else
                        shrinkRounds = shrinkRounds + 1
                        while shrinks.size() > 0 do
                            let shrink: T = shrinks.pop()
                            helper.reset()
                            let propShrink: T = property(consume shrink, helper)
                            if helper._failed() then
                                shrunken = consume propShrink
                                break // just break out this for loop,
                                      // try to shrink the failing example further
                            end
                        end
                    end
                end
                // report error with shrunken value
                helper.reportFailed[T](consume shrunken, parameters, shrinkRounds)

                break
            end
        end
        if not helper._failed() then
            helper.reportSuccess(parameters)
        end
/*
class _ForAll[T]
    let gen: Generator[T]

    new create(gen': Generator[T]) =>
        gen = gen'

    fun apply(prop: {(T)}): Property1[T] =>
        """
        take the generator
        """

primitive Properties
    fun forAll(gen: Generator[T]): Property1[T]
*/

class MyLittleProp is Property1[U8]

    fun name(): String => "mylittleprop"

    fun gen(): Generator[U8] val => Generators.u8(0, 10)

    fun property(arg1: U8, h: PropertyHelper): U8^ ? =>
        h.assert_true(arg1 <= U8(10))
        if arg1 > 100 then
            error
        end
        consume arg1

actor PropList is TestList
    new create(env: Env) =>
        PonyTest(env, this)

    fun tag tests(test: PonyTest) =>
        test(MyLittleProp)

actor Main
    new create(env: Env) =>
        env.out.print("ponycheck")
        let gen = Generators.u8(U8(1), U8(21))//.map[I32]({(u: U8): I32 => I32(u.i32()-1)})
        let rnd = Randomness(U64(Time.millis()))
        let si: String iso = recover
            let s = String.create(3)
            s.append("abc")
            s
        end
        let static: Generator[String tag] = Generators.unit[String iso](consume si)
        let sg: String tag = static.generate(rnd)
        env.out.print("STATIC: " + (static.generate(rnd) is "abc").string())
        env.out.print("STATIC: " + (static.generate(rnd) is "").string())
        //let mapped = static.map[Bool]({(s: String tag): Bool => (s is s)})
        //env.out.print("MAPPED: " + mapped.generate(rnd).string())
        let filtered = gen.filter({(u: U8): (U8, Bool) => (u, (u%2) == 0) })
        env.out.print(gen.generate(rnd).string())
        env.out.print(filtered.generate(rnd).string())
        env.out.print(filtered.generate(rnd).string())
        env.out.print(filtered.generate(rnd).string())
        env.out.print(filtered.generate(rnd).string())
        

        let static2 = Generators.unit[(I32, String)]((I32(-1), "foo"))

        let propList = PropList.create(env)

