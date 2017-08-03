use "itertools"
use "collections"
use "assert"

trait box Generator[T]
  fun box generate(rnd: Randomness): T^

  fun box shrink(t: T): (T^, Seq[T]) => (consume t, Array[T](0))
/*
  fun map[U](mapFn: {(T): U^} val): Generator[U] =>
    MappedGenerator[T, U](this, mapFn)

  fun flatMap[U](flatMapFn: {(T): Generator[U]} val): Generator[U] =>
    """
    for each value of this generator create a generator that is then combined
    """
    FlatMappedGenerator[T, U](this, flatMapFn)
*/

  fun box filter(predicate: {(T): (T^, Bool)} val): Generator[T] =>
    FilteredGenerator[T](this, predicate)

  /*
     class val FlatMappedGenerator[T0, U0] is Generator[U0]
     let _source: Generator[T0] box
     let _flatMapFn: {(T0): Generator[U0]} val

     new create(source: Generator[T0] box, flatMapFn: {(T0): Generator[U0]} val) =>
     _source = source
     _flatMapFn = flatMapFn

     fun box generate(rnd: Randomness): U0^ =>
     _flatMapFn(_source.generate(rnd)).generate(rnd)

     class val MappedGenerator[T1, U1] is Generator[U1]
     let _source: Generator[T1] box
     let _mapFn: {(T1): U1^} val

     new create(source: Generator[T1] box, mapFn: {(T1): U1^} val) =>
     _source = source
     _mapFn = mapFn

     fun box generate(rnd: Randomness): U1^ =>
     _mapFn(_source.generate(rnd))
   */

class box FilteredGenerator[T] is Generator[T]
  let _source: Generator[T] box
  let _predicate: {(T): (T^, Bool)} val

  new box create(source: Generator[T] box, predicate: {(T): (T^, Bool)} val) =>
    _source = source
    _predicate = predicate

  fun box generate(rnd: Randomness): T^ =>
    (var t, var matches) = _predicate(_source.generate(rnd))
    while not matches do
      (t, matches) = _predicate(_source.generate(rnd))
    end
    consume t

class box StaticGenerator[S] is Generator[box->S]
  let _value: S

  new box create(s: S) =>
    _value = consume s

  fun box generate(rnd: Randomness): this->S =>
    _value

class box OneOfGenerator[T] is Generator[box->T]
  """
  FIXME: this generator will always return box->T and never None
  but as we cant get an element from a seq without the possibility of an error
  we wrap stuff into try end and thus coud theoretically get a None as well
  """
  let xs: ReadSeq[T] box
  let _x: box->T

  new box create(xs': ReadSeq[T] box) ? =>
    Fact(xs'.size() > 0, "empty sequence not supported by oneOf Generator")?
    xs = xs'
    _x = xs(0)?

  fun box generate(rnd: Randomness): box->T =>
    let idx = rnd.usize(0, xs.size()-1)
    try
      xs(idx)?
    else
      // nasty hack to avoid the 'theoretical' error case
      // which should not happen, as we compute index by taking the size
      _x
    end

type WeightedGenerator[T] is (USize, Generator[T] box)

class box FrequencyGenerator[T] is Generator[T]
  let weightedGenerators: ReadSeq[WeightedGenerator[T]]
  let _emergencyGen: Generator[T] box

  new box create(weightedGenerators': ReadSeq[WeightedGenerator[T]]) ? =>
    let filtered =
      Iter[WeightedGenerator[T]](weightedGenerators'.values())
        .filter({(weightedGen: WeightedGenerator[T]): Bool =>
          weightedGen._1 > 0
        })
        .collect(Array[WeightedGenerator[T]])
    Fact(filtered.size() > 0, "no generators with weight > 0 given")?
    weightedGenerators = filtered
    _emergencyGen = filtered(0)?._2

  fun box generate(rnd: Randomness): T^ =>
    let weightSum: USize =
    try
      Iter[WeightedGenerator[T]](weightedGenerators.values()).fold[USize](
        {(acc: USize, weightedGen: WeightedGenerator[T]): USize =>
          weightedGen._1 + acc
        },
        0)?
    else
      0
    end
    let desiredSum = rnd.usize(0, weightSum)
    var runningSum: USize = 0
    var chosen: (Generator[T] box| None) = None
    for weightedGen in weightedGenerators.values() do
      let newSum = runningSum + weightedGen._1
      if (runningSum < desiredSum) and (desiredSum <= newSum) then
        // we just crossed or reached the desired sum
        chosen = weightedGen._2
        break
      else
        // update running sum
        runningSum = newSum
      end
    end
    match chosen
      | let x: Generator[T] box => x.generate(rnd)
      // nasty hack to avoid handling the theoretical error case
      // where we have no generator and thus would have to change the type signature
      | None => _emergencyGen.generate(rnd)
    end

primitive Generators
  fun unit[T](t: T): Generator[box->T] =>
    StaticGenerator[T](consume t)

  fun repeatedly[T](f: {(): T^} val): Generator[T] =>
    object is Generator[T]
      fun box generate(rnd: Randomness): T^ =>
        f()
    end

  fun seqOf[T](
    seqFactory: {(USize): Seq[T]} val = {(s: USize): Seq[T] =>
      Array[T].create(s)
    },
    gen: Generator[T],
    max: USize = 100)
    : Generator[Seq[T]]
  =>
    """
    fill a seq provided from the given ``seqFactory`` ( defaults to creating an Array)
    with at most ``max`` samples from the generator ``gen``.
    """
    object is Generator[Seq[T]]
      fun box generate(rnd: Randomness): Seq[T]^ =>
        let actualSize = rnd.usize(0, max)
        let seq: Seq[T] = seqFactory(actualSize)
        for i in Range[USize](0, max) do
          seq.push(gen.generate(rnd))
        end
        consume seq
    end

  fun listOf[T](gen: Generator[T], max: USize = 100): Generator[List[T]] =>
    """
    create a list from the given Generator
    with an optional maximum size (default max is 100)

    TODO: move size to generator
    """
    object is Generator[List[T]]
      fun box generate(rnd: Randomness): List[T]^ =>
        let actualSize = rnd.usize(0, max)
        let l = List[T].create(actualSize)
        for i in Range[USize](0, max) do
          l.push(gen.generate(rnd))
        end
        consume l
    end

  fun listOfN[T](n: USize, gen: Generator[T]): Generator[List[T]] =>
    object is Generator[List[T]]
      fun box generate(rnd: Randomness): List[T]^ =>
        let l = List[T].create(n)
        for i in Range[USize](0, n) do
          l.push(gen.generate(rnd))
        end
        consume l
    end

  fun oneOf[T](xs: ReadSeq[T] box): Generator[box->T] ? =>
    """
    as it is theoretically possible to error when accessing a ReadSeq by index
    the one-of generator needs to return ``None`` in the theoretical case
    which will never happen
    """
    OneOfGenerator[T](xs)?

  fun frequency[T](
    weightedGenerators: ReadSeq[WeightedGenerator[T]] box)
    : Generator[T] ?
  =>
    FrequencyGenerator[T](weightedGenerators)?

  fun zip2[T1, T2](
    gen1: Generator[T1],
    gen2: Generator[T2])
    : Generator[(T1, T2)]
  =>
    object is Generator[(T1, T2)]
      fun box generate(rnd: Randomness): (T1^, T2^) =>
        (gen1.generate(rnd), gen2.generate(rnd))
      end

  fun bool(): Generator[Bool] =>
    object is Generator[Bool]
      fun box generate(rnd: Randomness): Bool =>
        rnd.bool()
      end

  fun u8(
    min: U8 = U8.min_value(),
    max: U8 = U8.max_value())
    : Generator[U8]
  =>
    """
    create a generator for U8 values
    """
    object is Generator[U8]
      fun box generate(rnd: Randomness): U8^ =>
        rnd.u8(min, max)
    end

  fun u16(
    min: U16 = U16.min_value(),
    max: U16 = U16.max_value())
    : Generator[U16]
  =>
    """
    create a generator for U16 values
    """
    object is Generator[U16]
      fun box generate(rnd: Randomness): U16^ =>
        rnd.u16(min  max)
    end

  fun u32(
    min: U32 = U32.min_value(),
    max: U32 = U32.max_value())
    : Generator[U32]
  =>
    """
    create a generator for U32 values
    """
    object is Generator[U32]
      fun box generate(rnd: Randomness): U32^ =>
        rnd.u32(min, max)
    end

  fun u64(
    min: U64 = U64.min_value(),
    max: U64 = U64.max_value())
    : Generator[U64]
  =>
    """
    create a generator for U64 values
    """
    object is Generator[U64]
      fun box generate(rnd: Randomness): U64^ =>
        rnd.u64(min, max)
    end

  fun u128(
    min: U128 = U128.min_value(),
    max: U128 = U128.max_value())
    : Generator[U128]
  =>
    """
    create a generator for U128 values
    """
    object is Generator[U128]
      fun box generate(rnd: Randomness): U128^ =>
        rnd.u128(min, max)
    end

  fun uLong(
    min: ULong = ULong.min_value(),
    max: ULong = ULong.max_value())
    : Generator[ULong]
  =>
    """
    create a generator for ULong values
    """
    object is Generator[ULong]
      fun box generate(rnd: Randomness): ULong^ =>
        rnd.ulong(min, max)
    end

  fun uSize(
    min: USize = USize.min_value(),
    max: USize = USize.max_value())
    : Generator[USize]
  =>
    """
    create a generator for USize values
    """
    object is Generator[USize]
      fun box generate(rnd: Randomness): USize^ =>
        rnd.usize(min, max)
    end

  fun i8(
    min: I8 = I8.min_value(),
    max: I8 = I8.max_value())
    : Generator[I8]
  =>
    """
    create a generator for I8 values
    """
    object is Generator[I8]
      fun box generate(rnd: Randomness): I8^ =>
        rnd.i8(min, max)
    end

  fun i16(
    min: I16 = I16.min_value(),
    max: I16 = I16.max_value())
    : Generator[I16]
  =>
    """
    create a generator for I16 values
    """
    object is Generator[I16]
      fun box generate(rnd: Randomness): I16^ =>
        rnd.i16(min, max)
    end

  fun i32(
    min: I32 = I32.min_value(),
    max: I32 = I32.max_value())
    : Generator[I32]
  =>
    """
    create a generator for I32 values
    """
    object is Generator[I32]
      fun box generate(rnd: Randomness): I32^ =>
        rnd.i32(min, max)
    end

  fun i64(
    min: I64 = I64.min_value(),
    max: I64 = I64.max_value())
    : Generator[I64]
  =>
    """
    create a generator for I64 values
    """
    object is Generator[I64]
      fun box generate(rnd: Randomness): I64^ =>
        rnd.i64(min, max)
      end

// TODO: add i128 fun

  fun iLong(
    min: ILong = ILong.min_value(),
    max: ILong = ILong.max_value())
    : Generator[ILong]
    =>
    """
    create a generator for ILong values
    """
    object is Generator[ILong]
      fun box generate(rnd: Randomness): ILong^ =>
        rnd.ilong(min, max)
    end

  fun iSize(
    min: ISize = ISize.min_value(),
    max: ISize = ISize.max_value())
    : Generator[ISize]
  =>
    """
    create a generator for ISize values
    """
    object is Generator[ISize]
      fun box generate(rnd: Randomness): ISize^ =>
        rnd.isize(min, max)
    end
