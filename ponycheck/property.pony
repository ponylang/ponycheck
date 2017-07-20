use "ponytest"
use "collections"

class PropertyParams
    """
    parameters for Property Execution

    * seed: the seed for the source of Randomness
    * numSamples: the number of samples to produce from the property generator
    """
    let seed: U64
    let numSamples: USize

    new create(numSamples': USize = 100,
               seed': U64 = 42) =>
        numSamples = numSamples'
        seed = seed'


trait Property1[T] is UnitTest
    """
    A property that consumes 1 argument of type ``T``.

    A property can be used with ``ponytest`` like a normal UnitTest
    and be included into an aggregated TestList
    or simply fed to ``PonyTest.apply(UnitTest iso)``.



    A property is defined by a ``Generator``, returned by the ``gen()`` method
    and a ``property`` method that consumes the generators output and
    verifies a custom property with the help of a ``PropertyHelper``.

    A property is verified if no failed assertion on ``PropertyHelper`` has been
    reported for all the samples it consumed.

    The property execution can be customized by returning a custom ``PropertyParams``
    from the ``params()`` method.

    The ``gen()`` method is called exactly once to instantiate the generator.
    The generator produces ``PropertyParams.numSamples`` samples and each is
    passed to the ``property`` method for verification.

    If the property did not verify, the given sample is shrunken, if the generator
    supports shrinking (i.e. implements ``Shrinkable``).
    The smallest shrunken sample will then be reported to the user.
    """
    fun params(): PropertyParams => PropertyParams

    fun gen(): Generator[T]

    fun ref property(arg1: T, h: PropertyHelper ref): T^ ?
        """
        because we need the arg for shrinking and reporting later,
        it needs to be returned by this function again
        in case it is an iso
        """
    
    fun ref apply(h: TestHelper) ? =>
        """
        integration into ponytest
        """
        let parameters = params()
        let rnd = Randomness(parameters.seed)
        let helper: PropertyHelper ref = PropertyHelper(parameters, h)
        let generator: Generator[T] = gen()
        let me: Property1[T] = this
        for i in Range[USize].create(0, parameters.numSamples) do
            var sample: T = generator.generate(rnd)
            sample = try
                me.property(consume sample, helper)
            else
                // report error with given sample
                helper.reportError(0)
                error
            end
            if helper.failed() then
                let evaluator = Property1ShrinkEvaluate[T](helper, this)
                (let shrunken: T, let shrinkRounds: USize) = match generator
                    | let shrinkable: Shrinkable[T] box =>
                       Shrink.shrink[T](
                            consume sample,
                            shrinkable,
                            evaluator
                        )
                    else
                        (consume sample, 0)
                end
                helper.reportFailed[T](consume shrunken, shrinkRounds)
            end
        end
        if not helper.failed() then
            helper.reportSuccess()
        end

class ref Property1ShrinkEvaluate[T]
    """
    WORKAROUND, because for some reason:

    ```
    let that = this
    object ref is ShrinkEvaluate[T]
        fun ref evaluate(t: T): (T^, Bool) ? =>
            helper.reset()
            let res: T = that.property(consume t, helper)
            (consume res, helper.failed())
    end
    ```

    does not compile:

    ```
    /home/mwahl/dev/pony/ponycheck/ponycheck/property.pony:78:81: can't find definition of 'T'
                let evaluator: ShrinkEvaluate[T] = object ref is ShrinkEvaluate[T]
    ```
    """
    let helper: PropertyHelper ref
    let property1: Property1[T] ref

    new ref create(helper': PropertyHelper ref, property1': Property1[T] ref) =>
        helper = helper'
        property1 = property1'

    fun ref evaluate(t: T): (T^, Bool) ? =>
        helper.reset()
        let res: T = property1.property(consume t, helper)
        (consume res, helper.failed())

