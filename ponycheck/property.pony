use "ponytest"
use "itertools"
use "collections"
use "time"

class val PropertyParams
  """
  parameters for Property Execution

  * seed: the seed for the source of Randomness
  * num_samples: the number of samples to produce from the property generator
  * max_shrink_rounds: the maximum rounds of shrinking to perform
  * max_shrink_samples: the maximum number of shrunken samples to consider in 1 shrink round
  * timeout: the timeout for the ponytest runner, in nanseconds
  """
  let seed: U64
  let num_samples: USize
  let max_shrink_rounds: USize
  let max_shrink_samples: USize
  let timeout: U64

  new val create(
    num_samples': USize = 100,
    seed': U64 = Time.millis(),
    max_shrink_rounds': USize = 10,
    max_shrink_samples': USize = 100,
    timeout': U64 = 60_000_000_000)
  =>
    num_samples = num_samples'
    seed = seed'
    max_shrink_rounds = max_shrink_rounds'
    max_shrink_samples = max_shrink_samples'
    timeout = timeout'


trait val Property1[T]
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

  fun val gen(): Generator[T]

  fun val property(arg1: T, h: PropertyHelper) ?
    """
    a method verifying that a certain property holds for all given ``arg1``
    with the help of ``PropertyHelper`` ``h``.
    """

  fun val unit_test(): Property1UnitTest[T]^ =>
    Property1UnitTest[T](this)

primitive Stringify[T]
  fun apply(t: T): (T^, String) =>
    """turn anything into a string"""
    let digest = (digestof t)
    let s =
      iftype T <: Stringable #read then
        t.string()
      elseif T <: ReadSeq[Stringable] #read then
        "[" + " ".join(t.values()) + "]"
      else
        "<identity:" + digest.string() + ">"
      end
    (consume t, consume s)

class iso Property1UnitTest[T] is UnitTest
  let _prop1: Property1[T]

  new iso create(p1: Property1[T]) =>
    _prop1 = p1

  fun name(): String =>
    _prop1.name()

  fun ref apply(h: TestHelper) =>
    h.long_test(_prop1.params().timeout)
    _Runner[T](_prop1, h).run()

actor _Runner[T]
  let _prop1: Property1[T]
  let _h: TestHelper
  let _rnd: Randomness
  let _ph: PropertyHelper
  let _gen: Generator[T]
  var _shrinker: Iterator[T^] = _EmptyIterator[T^]

  new create(p1: Property1[T], h: TestHelper) =>
    _prop1 = consume p1
    _h = consume h
    _rnd = Randomness(_prop1.params().seed)
    _ph = PropertyHelper(_prop1.params(), _h)
    _gen = _prop1.gen()

  be run(n: USize = 0) =>
    if n == _prop1.params().num_samples then
      complete()
      return
    end
    (var sample, _shrinker) = _gen.generate_and_shrink(_rnd)
    // create a string representation before consuming ``sample`` with property
    (sample, let sample_repr) = Stringify[T](consume sample)
    try
      _prop1.property(consume sample, _ph)?
    else
      // report error with given sample
      _ph.report_error(sample_repr, 0)
      fail()
      return
    end
    if _ph.failed() then
      // the shrinking Iterator is an iterator that returns more and more
      // shrunken samples from the generator
      // safeguard against generators that generate huge or even infinite shrink
      if not _shrinker.has_next() then
        _h.log("no shrinks available")
      else
        do_shrink(sample_repr)
      end
      fail()
      return
    end

    run(n + 1)

  be do_shrink(repr: String, rounds: USize = 0) =>
    (let shrink, let shrink_repr) =
      try
        Stringify[T](_shrinker.next()?)
      else
        _ph.report_failed[T](repr, rounds)
        return
      end

    _ph.reset()

    try
      _prop1.property(consume shrink, _ph)?
    else
      _ph.report_error(shrink_repr, rounds)
      fail()
      return
    end

    if not _ph.failed() then
      // we have a sample that did not fail and thus can stop shrinking
      _h.log("shrink: " + shrink_repr + " did not fail")
      _ph.report_failed[T](repr, rounds)
      return
    end

    //_h.log("shrink: " + shrink_repr + " did fail")
    // we have a failing shrink sample
    do_shrink(shrink_repr, rounds + 1)

  fun ref complete() =>
    if not _ph.failed() then
      _ph.report_success()
      _h.complete(true)
    end

  fun ref fail() =>
    _h.complete(false)

class _EmptyIterator[T]
  fun ref has_next(): Bool => false
  fun ref next(): T^ ? => error
