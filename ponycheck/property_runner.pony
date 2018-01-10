
actor PropertyRunner[T]
  """
  Actor executing a Property1 implementation
  in a way that allows garbage collection between single
  property executions, because it uses recursive behaviours
  for looping.
  """
  let _prop1: Property1[T]
  let _params: PropertyParams
  let _rnd: Randomness
  let _notify: PropertyResultNotify
  let _ph: PropertyHelper
  let _gen: Generator[T]
  var _shrinker: Iterator[T^] = _EmptyIterator[T^]

  new create(
    p1: Property1[T] iso,
    params: PropertyParams,
    notify: PropertyResultNotify
  ) =>
    _prop1 = consume p1
    _params = params
    _notify = notify
    _ph = PropertyHelper(_params, _notify)
    _rnd = Randomness(_params.seed)
    _gen = _prop1.gen()

  be run(n: USize = 0) =>
    if n == _params.num_samples then
      complete() // all samples have been successful
      return
    end
    (var sample, _shrinker) = _gen.generate_and_shrink(_rnd)
    // create a string representation before consuming ``sample`` with property
    (sample, let sample_repr) = _Stringify[T](consume sample)
    try
      _prop1.property(consume sample, _ph)?
    else
      fail(sample_repr, 0 where err=true)
      return
    end
    if _ph.failed() then
      // found a bad example, try to shrink it
      if not _shrinker.has_next() then
        _ph.log("no shrinks available")
        fail(sample_repr, 0)
      else
        do_shrink(sample_repr)
      end
    else
      // property holds, recurse
      run(n + 1)
    end

  be do_shrink(repr: String, rounds: USize = 0) =>
    // shrink iters can be infinite, so we need to limit
    // the examples we consider during shrinking
    if rounds == _params.max_shrink_rounds then
      fail(repr, rounds)
      return
    end

    (let shrink, let shrink_repr) =
      try
        _Stringify[T](_shrinker.next()?)
      else
        // no more shrink samples, report previous failed example
        fail(repr, rounds)
        return
      end

    _ph.reset()

    try
      _prop1.property(consume shrink, _ph)?
    else
      fail(shrink_repr, rounds where err=true)
      return
    end

    if not _ph.failed() then
      // we have a sample that did not fail and thus can stop shrinking
      //_ph.log("shrink: " + shrink_repr + " did not fail")
      fail(repr, rounds)
    else
      // we have a failing shrink sample, recurse
      //_ph.log("shrink: " + shrink_repr + " did fail")
      do_shrink(shrink_repr, rounds + 1)
    end
  
  fun ref complete() =>
    """
    complete the Property execution
    """
    _notify.complete(not _ph.failed())

  fun ref fail(repr: String, rounds: USize = 0, err: Bool = false) =>
    """
    complete the Property execution 
    while signalling failure to the notify
    """
    if err then
      _ph.report_error(repr, rounds)
    else
      _ph.report_failed(repr, rounds)
    end
    _notify.complete(false)


class _EmptyIterator[T]
  fun ref has_next(): Bool => false
  fun ref next(): T^ ? => error

primitive _Stringify[T]
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

