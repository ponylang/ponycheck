use "collections"
use "itertools"

trait box GenObj[T]
  fun generate(rnd: Randomness): T^

  fun shrink(t: T): (T^, Seq[T]) =>
    (consume t, Array[T](0))

  fun iter(rnd: Randomness): Iterator[T^]^ =>
    let gen: GenObj[T] = this
    object is Iterator[T^]
      fun ref has_next(): Bool => true
      fun ref next(): T^ => gen.generate(rnd)
    end

class box Generator[T] is GenObj[T]
  let _gen: GenObj[T]

  new create(gen: GenObj[T]) =>
    _gen = gen

  fun generate(rnd: Randomness): T^ =>
    _gen.generate(rnd)

  fun shrink(t: T): (T^, Seq[T]) =>
    _gen.shrink(consume t)

  fun filter(predicate: {(T): (T^, Bool)} box): Generator[T] =>
    Generator[T](
      object is GenObj[T]
        fun generate(rnd: Randomness): T^ =>
          (var t, var matches) = predicate(_gen.generate(rnd))
          while not matches do
            (t, matches) = predicate(_gen.generate(rnd))
          end
          consume t
      end)

  fun map[U](fn: {(T): U^} box): Generator[U] =>
    Generator[U](
      object is GenObj[U]
        fun generate(rnd: Randomness): U^ =>
          fn(_gen.generate(rnd))
      end)

  fun flat_map[U](fn: {(T): Generator[U]} box): Generator[U] =>
    """
    For each value of this generator create a generator that is then combined.
    """
    Generator[U](
      object is GenObj[U]
        fun generate(rnd: Randomness): U^ =>
          fn(_gen.generate(rnd)).generate(rnd)
      end)

type WeightedGenerator[T] is (USize, Generator[T] box)

primitive Generators
  fun unit[T](t: T): Generator[box->T] =>
    """
    Generate a reference to the same value over and over again.

    This reference will be of type ``box->T`` and not just ``T``
    as this generator will need to keep a reference to the given value.
    """
    Generator[box->T](
      object is GenObj[box->T]
        let _t: T = consume t
        fun generate(rnd: Randomness): this->T => _t
      end)

  fun repeatedly[T](f: {(): T^} box): Generator[T] =>
    """
    Generate values by calling the lambda ``f`` repeatedly,
    once for every invocation of ``generate``.

    ``f`` needs to return an ephemeral type ``T^``, that means
    in most cases it needs to consume its returned value.
    Otherwise we would end up with
    an alias for ``T`` which is ``T!``.
    (e.g. ``String iso`` would be returned as ``String iso!``
    which is a ``String tag``).

    Example:

    ```pony
    Generators.repeatedly[Writer]({(): Writer^ =>
      let writer = Writer.>write("consume me, please")
      consume writer
    })
    ```
    """
    Generator[T](
      object is GenObj[T]
        fun generate(rnd: Randomness): T^ =>
          f()
      end)

  fun seq_of[T, S: Seq[T] ref](
    gen: Generator[T],
    min: USize = 0,
    max: USize = 100)
    : Generator[S]
  =>
    """
    Create a seq from the given Generator with an optional minimum and
    maximum size, defaults are 0 and 100 respectively.
    """
    Generator[S](
      object is GenObj[S]
        fun generate(rnd: Randomness): S^ =>
          let size = rnd.usize(min, max)
          Iter[T^](gen.iter(rnd))
            .take(size)
            .collect[S](S.create(size))
      end)

  fun set_of[T: (Hashable #read & Equatable[T] #read)](
    gen: Generator[T],
    max: USize = 100)
    : Generator[Set[T]]
  =>
    """
    Create a generator for sets filled with values
    of the given generator ``gen``.
    The returned sets will have a size up to ``max``
    but tend to have fewer than ``max``
    depending on the feeding generator ``gen``.

    E.g. if the given generator is for ``U8`` values and ``max`` is set to 1024
    the set will only ever be of size 256 max.

    Also for efficiency purposes and to not loop forever
    this generator will only try to add at most ``max`` values to the set.
    If there are duplicates, the set won't grow.
    """
    Generator[Set[T]](
      object is GenObj[Set[T]]
        fun generate(rnd: Randomness): Set[T]^ =>
          let size = rnd.usize(0, max)
          let set = Set[T](size)
          for i in Range(0, size) do
            set.set(gen.generate(rnd))
          end
          consume set
      end)


  fun one_of[T](xs: ReadSeq[T]): Generator[box->T] ? =>
    """
    Generate a random value from the given ReadSeq. An error will be thrown
    if the given ReadSeq is empty.
    """
    Generator[box->T](
      let err: box->T = xs(0)?
      object is GenObj[box->T]
        fun generate(rnd: Randomness): box->T =>
          let idx = rnd.usize(0, xs.size() - 1)
          try
            xs(idx)?
          else
            err // will never occur
          end
      end)

  fun frequency[T](
    weighted_generators: ReadSeq[WeightedGenerator[T]])
    : Generator[T] ?
  =>
    """
    chose a value of one of the given Generators,
    while controlling the distribution with the associated weights.

    The weights are of type ``USize`` and control how likely a value is chosen.
    The likelihood of a value ``v`` to be chosen
    is ``weight_v`` / ``weights_sum``.
    If all ``weighted_generators`` have a size of ``1`` the distribution
    will be uniform.

    Example of a generator to output even ``U8`` values
    twice as likely as odd ones:

    ```pony
    Generators.frequency[U8](
      (1, Generators.u8().filter({(u: U8): (U8^, Bool) => (u, (u % 2) == 0 })),
      (2, Generators.u8().filter({(u: U8): (U8^, Bool) => (u, (u % 2) != 0 }))
    )
    ```
    """
    let filtered =
      Iter[WeightedGenerator[T]](weighted_generators.values())
        .filter(
          {(weighted_gen: WeightedGenerator[T]): Bool =>
            weighted_gen._1 > 0
          })
        .collect(Array[WeightedGenerator[T]])

    // nasty hack to avoid handling the theoretical error case where we have
    // no generator and thus would have to change the type signature
    let err = filtered(0)?._2

    Generator[T](
      object is GenObj[T]
        fun generate(rnd: Randomness): T^ =>
          let weight_sum: USize =
            try
              Iter[WeightedGenerator[T]](filtered.values())
                .fold[USize](
                  {(acc: USize, weighted_gen: WeightedGenerator[T]): USize =>
                    weighted_gen._1 + acc
                  },
                  0)?
            else
              0
            end
          let desired_sum = rnd.usize(0, weight_sum)
          var running_sum: USize = 0
          var chosen: (Generator[T] | None) = None
          for weighted_gen in filtered.values() do
            let new_sum = running_sum + weighted_gen._1
            if (running_sum < desired_sum) and (desired_sum <= new_sum) then
              // we just crossed or reached the desired sum
              chosen = weighted_gen._2
              break
            else
              // update running sum
              running_sum = new_sum
            end
          end
          match chosen
          | let x: Generator[T] box => x.generate(rnd)
          | None => err.generate(rnd)
          end
      end)

  fun zip2[T1, T2](
    gen1: Generator[T1],
    gen2: Generator[T2])
    : Generator[(T1, T2)]
  =>
    """
    zip two generators into a generator of a 2-tuple
    containing the values generated by both generators.
    """
    Generator[(T1, T2)](
      object is GenObj[(T1, T2)]
        fun generate(rnd: Randomness): (T1^, T2^) =>
          (gen1.generate(rnd), gen2.generate(rnd))
        end)

  fun zip3[T1, T2, T3](
    gen1: Generator[T1],
    gen2: Generator[T2],
    gen3: Generator[T3])
    : Generator[(T1, T2, T3)]
  =>
    """
    zip three generators into a generator of a 3-tuple
    containing the values generated by those three generators.
    """
    Generator[(T1, T2, T3)](
      object is GenObj[(T1, T2, T3)]
        fun generate(rnd: Randomness): (T1^, T2^, T3^) =>
          (gen1.generate(rnd), gen2.generate(rnd), gen3.generate(rnd))
        end)

  fun zip4[T1, T2, T3, T4](
    gen1: Generator[T1],
    gen2: Generator[T2],
    gen3: Generator[T3],
    gen4: Generator[T4])
    : Generator[(T1, T2, T3, T4)]
  =>
    """
    zip four generators into a generator of a 4-tuple
    containing the values generated by those four generators.
    """
    Generator[(T1, T2, T3, T4)](
      object is GenObj[(T1, T2, T3, T4)]
        fun generate(rnd: Randomness): (T1^, T2^, T3^, T4^) =>
          (gen1.generate(rnd),
            gen2.generate(rnd),
            gen3.generate(rnd),
            gen4.generate(rnd))
        end)

  fun bool(): Generator[Bool] =>
    """
    create a generator of bool values.
    """
    Generator[Bool](
      object is GenObj[Bool]
        fun generate(rnd: Randomness): Bool =>
          rnd.bool()
        end)

  fun u8(
    min: U8 = U8.min_value(),
    max: U8 = U8.max_value())
    : Generator[U8]
  =>
    """
    create a generator for U8 values
    """
    Generator[U8](
      object is GenObj[U8]
        fun generate(rnd: Randomness): U8^ =>
          rnd.u8(min, max)
      end)

  fun u16(
    min: U16 = U16.min_value(),
    max: U16 = U16.max_value())
    : Generator[U16]
  =>
    """
    create a generator for U16 values
    """
    Generator[U16](
      object is GenObj[U16]
        fun generate(rnd: Randomness): U16^ =>
          rnd.u16(min  max)
      end)

  fun u32(
    min: U32 = U32.min_value(),
    max: U32 = U32.max_value())
    : Generator[U32]
  =>
    """
    create a generator for U32 values
    """
    Generator[U32](
      object is GenObj[U32]
        fun generate(rnd: Randomness): U32^ =>
          rnd.u32(min, max)
      end)

  fun u64(
    min: U64 = U64.min_value(),
    max: U64 = U64.max_value())
    : Generator[U64]
  =>
    """
    create a generator for U64 values
    """
    Generator[U64](
      object is GenObj[U64]
        fun generate(rnd: Randomness): U64^ =>
          rnd.u64(min, max)
      end)

  fun u128(
    min: U128 = U128.min_value(),
    max: U128 = U128.max_value())
    : Generator[U128]
  =>
    """
    create a generator for U128 values
    """
    Generator[U128](
      object is GenObj[U128]
        fun generate(rnd: Randomness): U128^ =>
          rnd.u128(min, max)
      end)

  fun usize(
    min: USize = USize.min_value(),
    max: USize = USize.max_value())
    : Generator[USize]
  =>
    """
    create a generator for USize values
    """
    Generator[USize](
      object is GenObj[USize]
        fun generate(rnd: Randomness): USize^ =>
          rnd.usize(min, max)
      end)

  fun ulong(
    min: ULong = ULong.min_value(),
    max: ULong = ULong.max_value())
    : Generator[ULong]
  =>
    """
    create a generator for ULong values
    """
    Generator[ULong](
      object is GenObj[ULong]
        fun generate(rnd: Randomness): ULong^ =>
          rnd.ulong(min, max)
      end)

  fun i8(
    min: I8 = I8.min_value(),
    max: I8 = I8.max_value())
    : Generator[I8]
  =>
    """
    create a generator for I8 values
    """
    Generator[I8](
      object is GenObj[I8]
        fun generate(rnd: Randomness): I8^ =>
          rnd.i8(min, max)
      end)

  fun i16(
    min: I16 = I16.min_value(),
    max: I16 = I16.max_value())
    : Generator[I16]
  =>
    """
    create a generator for I16 values
    """
    Generator[I16](
      object is GenObj[I16]
        fun generate(rnd: Randomness): I16^ =>
          rnd.i16(min, max)
      end)

  fun i32(
    min: I32 = I32.min_value(),
    max: I32 = I32.max_value())
    : Generator[I32]
  =>
    """
    create a generator for I32 values
    """
    Generator[I32](
      object is GenObj[I32]
        fun generate(rnd: Randomness): I32^ =>
          rnd.i32(min, max)
      end)

  fun i64(
    min: I64 = I64.min_value(),
    max: I64 = I64.max_value())
    : Generator[I64]
  =>
    """
    create a generator for I64 values
    """
    Generator[I64](
      object is GenObj[I64]
        fun generate(rnd: Randomness): I64^ =>
          rnd.i64(min, max)
        end)

// TODO: add i128 fun

  fun ilong(
    min: ILong = ILong.min_value(),
    max: ILong = ILong.max_value())
    : Generator[ILong]
    =>
    """
    create a generator for ILong values
    """
    Generator[ILong](
      object is GenObj[ILong]
        fun generate(rnd: Randomness): ILong^ =>
          rnd.ilong(min, max)
      end)

  fun isize(
    min: ISize = ISize.min_value(),
    max: ISize = ISize.max_value())
    : Generator[ISize]
  =>
    """
    create a generator for ISize values
    """
    Generator[ISize](
      object is GenObj[ISize]
        fun generate(rnd: Randomness): ISize^ =>
          rnd.isize(min, max)
      end)
