use "ponytest"
use "collections"

class PropertyParams
  """
  parameters for Property Execution

  * seed: the seed for the source of Randomness
  * num_samples: the number of samples to produce from the property generator
  * max_shrink_rounds: the maximum rounds of shrinking to perform
  * max_shrink_samples: the maximum number of shrunken samples to consider in 1 shrink round
  """
  let seed: U64
  let num_samples: USize
  let max_shrink_rounds: USize
  let max_shrink_samples: USize

  new create(num_samples': USize = 100,
    seed': U64 = 42,
    max_shrink_rounds': USize = 10,
    max_shrink_samples': USize = 100) =>
    num_samples = num_samples'
    seed = seed'
    max_shrink_rounds = max_shrink_rounds'
    max_shrink_samples = max_shrink_samples'


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
  The generator produces ``PropertyParams.num_samples`` samples and each is
  passed to the ``property`` method for verification.

  If the property did not verify, the given sample is shrunken, if the generator
  supports shrinking (i.e. implements ``Shrinkable``).
  The smallest shrunken sample will then be reported to the user.
  """
  fun params(): PropertyParams => PropertyParams

  fun gen(): Generator[T]

  fun ref property(arg1: T, h: PropertyHelper ref) ?
    """
    a method verifying that a certain property holds for all given ``arg1``
    with the help of ``PropertyHelper`` ``h``.
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
    for i in Range[USize].create(0, parameters.num_samples) do
      var sample: T = generator.generate(rnd)

      // create a string representation before consuming ``sample`` with property
      (sample, var sample_repr: String) = _to_string(consume sample)
      // shrink before consuming ``sample`` with property
      (sample, var shrinks: Seq[T]) = _shrink(consume sample, generator)
      try
        me.property(consume sample, helper)?
      else
        // report error with given sample
        helper.reportError(sample_repr, 0)
        error
      end
      if helper.failed() then
        var shrink_rounds: USize = 0
        let num_shrinks = shrinks.size()

        // safeguard against generators that generate huge or even infinite shrink seqs
        let shrinks_to_ignore =
          if num_shrinks > parameters.max_shrink_samples then
            num_shrinks - parameters.max_shrink_samples
          else
            0
          end
        while
          (shrinks.size() > shrinks_to_ignore)
            and (shrink_rounds < parameters.max_shrink_rounds)
        do
          var failedShrink: T = shrinks.pop()?
          (failedShrink, let shrink_repr: String) = _to_string(consume failedShrink)
          (failedShrink, let next_shrinks: Seq[T]) = _shrink(consume failedShrink, generator)
          helper.reset()
          try
            me.property(consume failedShrink, helper)?
          else
            helper.reportError(shrink_repr, shrink_rounds)
            error
          end
          if helper.failed() then
            // we have a failing shrink sample
            shrink_rounds = shrink_rounds + 1
            shrinks = consume next_shrinks
            sample_repr = shrink_repr
            continue
          end
        end
        helper.reportFailed[T](sample_repr, shrink_rounds)
        break
      end
    end
    if not helper.failed() then
      helper.reportSuccess()
    end

  fun ref _to_string(sample: T): (T^, String) =>
    """
    format the given sample to a string representation,
    use digestof if nothing else is available
    """
    Stringifier.stringify[T](consume sample)

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

primitive Stringifier
  fun stringify[T](t: T): (T^, String) =>
    """turn anything into a string"""
    let digest = (digestof t)
    let s =
      iftype T <: Stringable #read then
        t.string()
      else
        "<identity:" + digest.string() + ">"
      end
    (consume t, consume s)
