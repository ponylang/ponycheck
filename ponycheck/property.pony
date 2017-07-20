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

    fun ref property(arg1: T, h: PropertyHelper ref) ?
        """
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

            // create a string representation before consuming ``sample`` with property
            (sample, var sampleRepr: String) = _toString(consume sample)
            // shrink before consuming ``sample`` with property
            (sample, var shrinks: Seq[T]) = _shrink(consume sample, generator)
            try
                me.property(consume sample, helper)
            else
                // report error with given sample
                helper.reportError(sampleRepr, 0)
                error
            end
            if helper.failed() then
                var shrinkRounds: USize = 0
                while shrinks.size() > 0 do
                    var failedShrink: T = shrinks.pop()
                    (failedShrink, let shrinkRepr: String) = _toString(consume failedShrink)
                    (failedShrink, let nextShrinks: Seq[T]) = _shrink(consume failedShrink, generator)
                    helper.reset()
                    try
                        me.property(consume failedShrink, helper)
                    else
                        helper.reportError(shrinkRepr, shrinkRounds)
                        error
                    end
                    if helper.failed() then
                        // we have a failing shrink sample
                        shrinkRounds = shrinkRounds + 1
                        shrinks = consume nextShrinks
                        sampleRepr = shrinkRepr
                        continue
                    end
                end
                helper.reportFailed[T](sampleRepr, shrinkRounds)
            end
        end
        if not helper.failed() then
            helper.reportSuccess()
        end

    fun ref _toString(sample: T): (T^, String) =>
        let str: String = match sample
        | let stringable: Stringable =>
            stringable.string()
        else
            (digestof sample).string()
        end
        (consume sample, str)

    fun ref _shrink(shrinkMe: T, generator: Generator[T]): (T^, Seq[T]) =>
        """
        helper for shrinking a value with the generator it was created with (if it is a Shrinkable)
        """
        match generator
        | let shrinkable: Shrinkable[T] box =>
            shrinkable.shrink(consume shrinkMe)
        else
            (consume shrinkMe, List[T](0))
        end
