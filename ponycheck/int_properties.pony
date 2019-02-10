type IntUnitTest is Property1UnitTest[(U8, U128)]

trait IntProperty is Property1[(U8, U128)]
  """
  A property implementation for conveniently evaluating properties
  for all Pony Integer types at once.

  The property needs to be formulated inside the method `int_property`:

  ```pony
  class DivisionByZeroProperty is IntProperty
    fun name(): String => "div/0"

    fun int_property[T: (Int & Integer[T] val)](x: T, h: PropertyHelper)? =>
      h.assert_eq[T](T.from[U8](0), x / T.from[U8](0))
  ```
  """
  fun gen(): Generator[(U8, U128)] =>
    Generators.zip2[U8, U128](
      Generators.u8(),
      Generators.u128())

  fun property(sample: (U8, U128), h: PropertyHelper) ? =>
    let t: U8 = sample._1
    let x = sample._2
    match t % 14
    | 0 => int_property[U8](x.u8(), h)?
    | 1 => int_property[U16](x.u16(), h)?
    | 2 => int_property[U32](x.u32(), h)?
    | 3 => int_property[U64](x.u64(), h)?
    | 4 => int_property[ULong](x.ulong(), h)?
    | 5 => int_property[USize](x.usize(), h)?
    | 6 => int_property[U128](x, h)?
    | 7 => int_property[I8](x.i8(), h)?
    | 8 => int_property[I16](x.i16(), h)?
    | 9 => int_property[I32](x.i32(), h)?
    | 10 => int_property[I64](x.i64(), h)?
    | 11 => int_property[ILong](x.ilong(), h)?
    | 12 => int_property[ISize](x.isize(), h)?
    | 13 => int_property[I128](x.i128(), h)?
    end

fun int_property[T: (Int & Integer[T] val)](x: T, h: PropertyHelper)?

type IntPairUnitTest is Property1UnitTest[(U8, (U128, U128))]

trait IntPairProperty is Property1[(U8, (U128, U128))]
  """
  A property implementation for conveniently evaluating properties
  for pairs of integers of all Pony integer types at once.

  The property needs to be formulated inside the method `int_property`:

  ```pony
  class CommutativeMultiplicationProperty is IntPairProperty
    fun name(): String => "commutativity/mul"

    fun int_property[T: (Int & Integer[T] val)](x: T, y: T, h: PropertyHelper)? =>
      h.assert_eq[T](x * y, y * x)
  ```
  """
  fun gen(): Generator[(U8, (U128, U128))] =>
    Generators.zip2[U8, (U128, U128)](
      Generators.u8(),
      Generators.zip2[U128, U128](
        Generators.u128(),
        Generators.u128()
      ))

  fun property(sample: (U8, (U128, U128)), h: PropertyHelper) ? =>
    let t: U8 = sample._1
    let x = sample._2._1
    let y = sample._2._2
    match t % 14
    | 0 => int_property[U8](x.u8(), y.u8(), h)?
    | 1 => int_property[U16](x.u16(), y.u16(), h)?
    | 2 => int_property[U32](x.u32(), y.u32(), h)?
    | 3 => int_property[U64](x.u64(), y.u64(), h)?
    | 4 => int_property[ULong](x.ulong(), y.ulong(), h)?
    | 5 => int_property[USize](x.usize(), y.usize(), h)?
    | 6 => int_property[U128](x, y, h)?
    | 7 => int_property[I8](x.i8(), y.i8(), h)?
    | 8 => int_property[I16](x.i16(), y.i16(), h)?
    | 9 => int_property[I32](x.i32(), y.i32(), h)?
    | 10 => int_property[I64](x.i64(), y.i64(), h)?
    | 11 => int_property[ILong](x.ilong(), y.ilong(), h)?
    | 12 => int_property[ISize](x.isize(), y.isize(), h)?
    | 13 => int_property[I128](x.i128(), y.i128(), h)?
    end

  fun int_property[T: (Int & Integer[T] val)](x: T, y: T, h: PropertyHelper)?
