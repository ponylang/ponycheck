# Ponycheck

![travis ci build status](https://travis-ci.org/mfelsche/ponycheck.svg?branch=master) ![this is awesome](https://img.shields.io/badge/this%20is-awesome-green.svg)

Property based testing for ponylang (>= 0.19.0).

[API docs](https://mfelsche.github.io/ponycheck/ponycheck--index/)

## Features

* Integration with ponytest
* Extensive list of builtin Generators for you convencience (There will be even more)
* Shrinking of failed samples for more useful test output
* ...
* **P-R-O-P-E-R-T-Y**
* **B-A-S-E-D**
* **T-E-S-T-I-N-G !!!**


## Usage

Ponycheck comes in two flavors:

* by implementing the trait ``Property1[T]``
* by using the ``Ponycheck.forAll`` method in a ``UnitTest``

### Using Property1

The classical List reverse properties from the quickcheck paper:

```pony

use "ponycheck"
use "collections"

class ListReverseProperty is Property1[List[USize]]
    
    fun name(): String => "list/reverse"

    fun gen(): Generator[List[USize]] => Generators.listOf[USize](Generators.uSize())
    
    fun property(arg1: List[USize], ph: PropertyHelper) =>
        ph.assert_array_eq[USize](arg1, arg1.reverse().reverse())

class ListReverseOneProperty is Property1[List[USize]]

    fun name(): String => "list/reverse/one"

    fun gen(): Generator[List[USize]] => Generators.listOfN[USize](1, Generators.uSize())

    fun property(arg1: List[USize], ph: PropertyHelper) =>
        ph.assert_array_eq[USize](arg1, arg1.reverse())

```

### Using Ponycheck.forAll

It is also possible to verify any number of properties
within one ``UnitTest`` using the ``forAll`` syntax:

```pony
class ListReverseProperties is UnitTest

    fun name(): String => "list/properties"

    fun apply(h: TestHelper) ? =>
        let gen1 = Generators.listOf[USize](Generators.uSize())
        Ponycheck.forAll[List[USize]](gen1, h)({
            (arg1: List[USize], ph: PropertyHelper) =>
                ph.assert_array_eq[USize](arg1, arg1.reverse().reverse())
        })
        let gen2 = Generators.listOfN[USize](1, Generators.uSize())
        Ponycheck.forAll[List[USize]](gen2, h)({
            (arg1: List[USize], ph: PropertyHelper) =>
                ph.assert_array_eq[USize](arg1, arg1.reverse())
        })

```

