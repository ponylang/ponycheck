use "ponytest"
use "itertools"
use "collections"
use "time"

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
    seed': U64 = Time.millis(),
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
    for i_sample in Range[USize].create(0, parameters.num_samples) do

      (var sample: T, var shrinks: Iterator[T^]) = generator.generate_and_shrink(rnd)

      // create a string representation before consuming ``sample`` with property
      (sample, var sample_repr: String) = _to_string(consume sample)
      try
        me.property(consume sample, helper)?
      else
        // report error with given sample
        helper.reportError(sample_repr, 0)
        error
      end
      if helper.failed() then
        var shrink_rounds: USize = 0
        // the shrinking Iterator is an iterator that returns more and more
        // shrunken samples from the generator
        // safeguard against generators that generate huge or even infinite shrink seqs
        if (not shrinks.has_next()) then
          h.log("no shrinks available")
        end
        for (i, shrink) in Iter[T^](shrinks).enum().take(parameters.max_shrink_samples) do
          (let local_shrink, let shrink_repr: String) = _to_string(consume shrink)
          helper.reset()
          try
            me.property(consume local_shrink, helper)?
          else
            helper.reportError(shrink_repr, shrink_rounds)
            error
          end
          if helper.failed() then
            //h.log("shrink: " + shrink_repr + " did fail")
            // we have a failing shrink sample
            shrink_rounds = shrink_rounds + 1
            sample_repr = shrink_repr
            continue
          else
            h.log("shrink: " + shrink_repr + " did not fail")
            // we have a sample that did not fail and thus can stop shrinking
            break
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
