# Ponycheck

Property based testing for ponylang.

## Features

* Integration with ponytest
* Extensive list of builtin Generators for you convencience (There will be even more)
* Shrinking of failed samples for more useful test output
* ...
* P-R-O-P-E-R-T-Y
* B-A-S-E-D
* T-E-S-T-I-N-G !!!


### Usage 

**By example:**

The classical List reverse properties from the quickcheck paper:

```pony

use "ponycheck"
use "collections/persistent"

class ListReverseProperty is Property1[List[USize]]
    
    fun name(): String => "list/reverse"

    fun gen(): Generator[List[USize]] => Generators.listOf[USize](Generators.uSize())
    
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
        let gen1 = Generators.listOf[USize](Generators.uSize())
        let gen2 = Generators.listOf[USize](Generators.uSize())
        (gen1, gen2)

    fun property(arg1: List[USize], arg2: List[USize], ph: PropertyHelper) =>
        ph.array_eq[USize](arg1.reverse() ++ arg2.reverse(), (arg1 ++ arg2).reverse())
```

Ponycheck comes in two flavors. It is also possible to run multiple properties 
within one ``UnitTest`` using the ``forAll`` syntax:

```pony

class ListProperties is UnitTest

    fun name(): String => "list/properties"

    fun apply(h: TestHelper) =>
        let gen = Generators.listOf[USize](Generators.uSize()),
        Ponycheck.forAll[U8](gen, h)({
            (arg1: List[USize], ph: PropertyHelper) =>
                ph.array_eq[Usize](arg1, arg1.reverse().reverse())
        })
        Ponycheck.forAll[U8](gen, h)({
            (arg1: List[USize], ph: PropertyHelper) =>
                ph.array_eq(arg1, arg1.reverse())

```

