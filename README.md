# Ponycheck

Property based testing for ponylang.


The classical List reverse properties from the quickcheck paper:

```pony
class ListReverseProperty is Property1[List[USize]]
    
    fun name(): String => "list/reverse"

    fun gen(): Generator[List[USize]] =>
        Generators.uSize(0, 100)
            .flatMap[List[USize]](
                {
                    (size: USize): List[USize] => 
                        Generatos.listOfN(size, Generators.uSize())
                })
    fun property(arg1: List[USize], ph: PropertyHelper) =>
        ph.array_eq[Usize](arg1, arg1.reverse().reverse())

class ListReverseOneProperty is Property1[List[USize]]

    fun name(): String => "list/reverse/one"

    fun gen(): Generator[List[USize]] => Generators.listOfN(1, Generators.uSize())

    fun property(arg1: List[USize], ph: PropertyHelper) =>
        ph.array_eq(arg1, arg1.reverse())

class ListReverseTwoProperty is Property2[List[USize], List[USize]]

    fun name(): String => "list/reverse/two"

    fun gen(): (Generator[List[USize]], Generator[List[USize]]) =>
        let gen1 = Generators.uSize(0, 100)
                             .flatMap[List[USize]]({})
        let gen2 = Generators.uSize(0, 100)
                             .flatMap[List[USize]]({})
        (gen1, gen2)

    fun property(arg1: List[USize], arg2: List[USize], ph: PropertyHelper) =>
        ph.array_eq[USize](arg1.reverse() ++ arg2.reverse(), (arg1 ++ arg2).reverse())
```

