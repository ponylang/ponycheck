use "time"

class val PropertyParams
  """
  parameters for Property Execution

  * seed: the seed for the source of Randomness
  * num_samples: the number of samples to produce from the property generator
  * max_shrink_rounds: the maximum rounds of shrinking to perform
  * timeout: the timeout for the ponytest runner, in nanseconds
  """
  let seed: U64
  let num_samples: USize
  let max_shrink_rounds: USize
  let timeout: U64

  new val create(
    num_samples': USize = 100,
    seed': U64 = Time.millis(),
    max_shrink_rounds': USize = 10,
    timeout': U64 = 60_000_000_000)
  =>
    num_samples = num_samples'
    seed = seed'
    max_shrink_rounds = max_shrink_rounds'
    timeout = timeout'

trait Property1[T]
  """
  A property that consumes 1 argument of type ``T``.

  A property can be used with ``ponytest`` like a normal UnitTest
  and be included into an aggregated TestList
  or simply fed to ``PonyTest.apply(UnitTest iso)`` with the ``unit_test``
  method.


  A property is defined by a ``Generator``, returned by the ``gen()`` method
  and a ``property`` method that consumes the generators output and
  verifies a custom property with the help of a ``PropertyHelper``.

  A property is verified if no failed assertion on ``PropertyHelper`` has been
  reported for all the samples it consumed.

  The property execution can be customized by returning a custom
  ``PropertyParams`` from the ``params()`` method.

  The ``gen()`` method is called exactly once to instantiate the generator.
  The generator produces ``PropertyParams.num_samples`` samples and each is
  passed to the ``property`` method for verification.

  If the property did not verify, the given sample is shrunken, if the
  generator supports shrinking (i.e. implements ``Shrinkable``).
  The smallest shrunken sample will then be reported to the user.
  """
  fun name(): String

  fun params(): PropertyParams => PropertyParams

  fun gen(): Generator[T]

  fun property(arg1: T, h: PropertyHelper) ?
    """
    a method verifying that a certain property holds for all given ``arg1``
    with the help of ``PropertyHelper`` ``h``.
    """
