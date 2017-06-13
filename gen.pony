use "random"
use "collections"

class Randomness
    """
    all primitive number method create numbers in range [min, max)

    TODO: generate values from the full range if possible without overflow
    """
    let _random: Random

    new create(seed: U64 = 42) =>
        _random = MT(seed)

    fun ref u8(min: U8 = U8.min_value(), max: U8 = U8.max_value()): U8 =>
        """
        generates a U8 in closed interval [min, max]
        """
        //Fact(min < max, "invalid range for u8")
        min + _random.int((max - min).u64() + 1).u8()

    fun ref u16(min: U16 = U16.min_value(), max: U16 = U16.max_value()): U16 =>
        """
        generates a U16 in closed interval [min, max]
        """
        //Fact(min < max, "invalid range for u16")
        min + _random.int((max - min).u64() + 1).u16()

    fun ref u32(min: U32 = U32.min_value(), max: U32 = U32.max_value()): U32 =>
        """
        generates a U32 in closed interval [min, max]
        """
        //Fact(min < max, "invalid range for u32")
        min + _random.int((max - min).u64() + 1).u32()
    
    fun ref u64(min: U64 = U64.min_value(), max: U64 = U64.max_value()): U64     =>
        """
        generates a U64 in closed interval [min, max]
        """
        //Fact(min < max, "invalid range for u64")
        // hacky way to get a U64 from for the full range
        if min > U32.max_value().u64() then
            (u32((min >> 32).u32(), (max >> 32).u32).u64() << 32) or _random.next()
        elseif max > U32.max_value().u64() then
            let high = (u32((min >> 32).u32(), (max >> 32).u32()).u64() << 32)
            let low = if high > 0 then
                _random.next()
            else
                u32(min.u32(), U32.max_value()).u64()
            end
            high or low
        else
            // range within U32 range
            u32(min.u32(), max.u32())
        end
    
    fun ref u128(min: U128 = U128.min_value(), max: U128 = U128.max_value()): U128   =>
        """
        generates a U128 in closed interval [min, max]
        """
        //Fact(min < max, "invalid range for u128")
        
        if min > U64.max_value().u128() then
            // both above U64 range - chose random low 64 bits
            (u64((min >> 64).u64(), (max >> 64).u64()).u128() << 64) or u64().u128()
        
        elseif max > U64.max_value().u128() then
            // min below U64 max value
            let high = (u64((min >> 64).u64(), (max >> 64).u64()).u128() << 64)
            let low = if high > 0 then
                // number will be bigger than U64 max anyway, so chose a random lower u64
                u64().u128()
            else
                // number <= U64 max, so chose lower u64 while considering requested range min
                u64(min.u64(), U64.max_value()).u128()
            end
            high or low
        else
            // range within u64 range
            u64(min.u64(), max.u64()).u128()
        end
    
    fun ref ulong(min: ULong = ULong.min_value(), max: ULong = ULong.max_value()): ULong =>
        //Fact(min < max, "invalid range for ulong")
        min + u64((max - min).u64()).ulong()
    
    fun ref usize(min: USize = USize.min_value(), max: USize = USize.max_value()): USize =>
        //Fact(min < max, "invalid range for usize")
        min + u64((max - min).u64()).usize()
   
    // TODO: those won't work for all ranges
    fun ref i8(min: I8 = I8.min_value(), max: I8 = I8.max_value()): I8       =>
        //Fact(min < max, "invalid range for i8")
        min + _random.int((max - min).u64()).i8()

    fun ref i16(min: I16 = I16.min_value(), max: I16 = I16.max_value()): I16     =>
        //Fact(min < max, "invalid range for i16")
        min + _random.int((max - min).u64()).i16()

    fun ref i32(min: I32 = I32.min_value(), max: I32 = I32.max_value()): I32     =>
        //Fact(min < max, "invalid range for i32")
        min + _random.int((max - min).u64()).i32()

    fun ref i64(min: I64 = I64.min_value(), max: I64 = I64.max_value()): I64     =>
        //Fact(min < max, "invalid range for i64")
        min + _random.int((max - min).u64()).i64()
    
    /*
    fun ref i128(min: I128 = I128.min_value(), max: I128 = I128.max_value()): I128   =>
        // TODO: this is not really random and doesnt work for ranges > U64
        Fact(min < max, "invalid range for i128")
        min + _random.int((max - min).u64()).i128()
    */

    fun ref ilong(min: ILong = ILong.min_value(), max: ILong = ILong.max_value()): ILong =>
        //Fact(min < max, "invalid range for iLong")
        min + _random.int((max - min).u64()).ilong()

    fun ref isize(min: ISize = ISize.min_value(), max: ISize = ISize.max_value()): ISize =>
        //Fact(min < max, "invalid range for iSize")
        min + _random.int((max - min).u64()).isize()


    fun ref f32(min: F32 = 0.0, max: F32 = 1.0): F32 =>
        """a random F32 value between given min and max"""
        (_random.real().f32() * (max-min)) + min


    fun ref f64(min: F64 = 0.0, max: F64 = 1.0): F64 =>
        """a random F64 value between given min and max"""
        (_random.real() * (max-min)) + min

    fun ref bool(): Bool   => (_random.next() % 2) == 0


trait Generator[T]
    fun box generate(rnd: Randomness): T^

    fun map[U](mapFn: {(T): U^} val): Generator[U] =>
        MappedGenerator[T, U](this, mapFn)

    fun flatMap[U](flatMapFn: {(T): Generator[U]} val): Generator[U] =>
        """
        for each value of this generator create a generator that is then combined
        """
        FlatMappedGenerator[T, U](this, flatMapFn)

    fun filter(predicate: {(T): (T^, Bool)} val): Generator[T] =>
        FilteredGenerator[T](this, predicate)


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

class val FilteredGenerator[T] is Generator[T]

    let _source: Generator[T] box
    let _predicate: {(T): (T^, Bool)} val

    new create(source: Generator[T] box, predicate: {(T): (T^, Bool)} val) =>
        _source = source
        _predicate = predicate

    fun box generate(rnd: Randomness): T^ =>
        (var t, var matches) = _predicate(_source.generate(rnd))
        while not matches do
            (t, matches) = _predicate(_source.generate(rnd))
        end
        consume t


class val StaticGenerator[S] is Generator[box->S]
    let _value: S

    new create(s: S) =>
        _value = consume s

    fun box generate(rnd: Randomness): this->S =>
        _value
/*
interface Shrinkable[T]
    fun shrink(randomness: Randomness, larger: T): List[T]
*/


primitive Generators

    
    fun unit[T](t: T): Generator[box->T] =>
        StaticGenerator[T](consume t)
    
    fun bool(): Generator[Bool] val =>
        object val is Generator[Bool]
            fun box generate(rnd: Randomness): Bool =>
                rnd.bool()
        end

    fun u8(min: U8 = U8.min_value(), max: U8 = U8.max_value()): Generator[U8] val =>
        """create a generator for U8 values"""
        object val is Generator[U8]
            fun box generate(rnd: Randomness): U8^ =>
                rnd.u8(min, max)
        end
    
    fun u16(min: U16 = U16.min_value(), max: U16 = U16.max_value(), minInc: Bool = true, maxInc: Bool = true): Generator[U16] val =>
        """create a generator for U16 values"""
        object val is Generator[U16]
            fun box generate(rnd: Randomness): U16^ =>
                rnd.u16(
                    if minInc then min else min + 1 end,
                    if maxInc then max else max + 1 end
                )
        end

    fun u32(min: U32 = U32.min_value(), max: U32 = U32.max_value(), minInc: Bool = true, maxInc: Bool = true): Generator[U32] val =>
        """create a generator for U32 values"""
        object val is Generator[U32]
            fun box generate(rnd: Randomness): U32^ =>
                rnd.u32(
                    if minInc then min else min + 1 end,
                    if maxInc then max else max + 1 end
                )
        end

    fun u64(min: U64 = U64.min_value(), max: U64 = U64.max_value(), minInc: Bool = true, maxInc: Bool = true): Generator[U64] val =>
        """create a generator for U64 values"""
        object val is Generator[U64]
            fun box generate(rnd: Randomness): U64^ =>
                rnd.u64(
                    if minInc then min else min + 1 end,
                    if maxInc then max else max + 1 end
                )
        end
    
    fun u128(min: U128 = U128.min_value(), max: U128 = U128.max_value(), minInc: Bool = true, maxInc: Bool = true): Generator[U128] val =>
        """create a generator for U128 values"""
        object val is Generator[U128]
            fun box generate(rnd: Randomness): U128^ =>
                rnd.u128(
                    if minInc then min else min + 1 end,
                    if maxInc then max else max + 1 end
                )
        end

    fun uLong(min: ULong = ULong.min_value(), max: ULong = ULong.max_value(), minInc: Bool = true, maxInc: Bool = true): Generator[ULong] val =>
        """create a generator for ULong values"""
        object val is Generator[ULong]
            fun box generate(rnd: Randomness): ULong^ =>
                rnd.ulong(
                    if minInc then min else min + 1 end,
                    if maxInc then max else max + 1 end
                )
        end

    fun uSize(min: USize = USize.min_value(), max: USize = USize.max_value(), minInc: Bool = true, maxInc: Bool = true): Generator[USize] val =>
        """create a generator for USize values"""
        object val is Generator[USize]
            fun box generate(rnd: Randomness): USize^ =>
                rnd.usize(
                    if minInc then min else min + 1 end,
                    if maxInc then max else max + 1 end
                )
        end

    fun i8(min: I8 = I8.min_value(), max: I8 = I8.max_value(), minInc: Bool = true, maxInc: Bool = true): Generator[I8] val =>
        """create a generator for I8 values"""
        object val is Generator[I8]
            fun box generate(rnd: Randomness): I8^ =>
                rnd.i8(
                    if minInc then min else min + 1 end,
                    if maxInc then max else max + 1 end
                )
        end

    fun i16(min: I16 = I16.min_value(), max: I16 = I16.max_value(), minInc: Bool = true, maxInc: Bool = true): Generator[I16] val =>
        """create a generator for I16 values"""
        object val is Generator[I16]
            fun box generate(rnd: Randomness): I16^ =>
                rnd.i16(
                    if minInc then min else min + 1 end,
                    if maxInc then max else max + 1 end
                )
        end

    fun i32(min: I32 = I32.min_value(), max: I32 = I32.max_value(), minInc: Bool = true, maxInc: Bool = true): Generator[I32] val =>
        """create a generator for I32 values"""
        object val is Generator[I32]
            fun box generate(rnd: Randomness): I32^ =>
                rnd.i32(
                    if minInc then min else min + 1 end,
                    if maxInc then max else max + 1 end
                )
        end

    fun i64(min: I64 = I64.min_value(), max: I64 = I64.max_value(), minInc: Bool = true, maxInc: Bool = true): Generator[I64] val =>
        """create a generator for I64 values"""
        object val is Generator[I64]
            fun box generate(rnd: Randomness): I64^ =>
                rnd.i64(
                    if minInc then min else min + 1 end,
                    if maxInc then max else max + 1 end
                )
        end
/*
    fun i128(min: I128 = I128.min_value(), max: I128 = I128.max_value(), minInc: Bool = true, maxInc: Bool = true): Generator[I128] val =>
        """create a generator for I128 values"""
        let range = NumericRange[I128].create(min, max, minInc, maxInc)
        NumericGenerator[I128](range, {(rnd: Randomness): I128 => rnd.i128()})
*/
    fun iLong(min: ILong = ILong.min_value(), max: ILong = ILong.max_value(), minInc: Bool = true, maxInc: Bool = true): Generator[ILong] val =>
        """create a generator for ILong values"""
        object val is Generator[ILong]
            fun box generate(rnd: Randomness): ILong^ =>
                rnd.ilong(
                    if minInc then min else min + 1 end,
                    if maxInc then max else max + 1 end
                )
        end

    fun iSize(min: ISize = ISize.min_value(), max: ISize = ISize.max_value(), minInc: Bool = true, maxInc: Bool = true): Generator[ISize] val =>
        """create a generator for ISize values"""
        object val is Generator[ISize]
            fun box generate(rnd: Randomness): ISize^ =>
                rnd.isize(
                    if minInc then min else min + 1 end,
                    if maxInc then max else max + 1 end
                )
        end

