use "ponytest"
use "collections"

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
        for i in Range[USize].create(0, parameters.numSamples) do
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

