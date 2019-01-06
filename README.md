# Ponycheck

[![Join the chat at https://gitter.im/ponycheck/community](https://badges.gitter.im/ponycheck/community.svg)](https://gitter.im/ponycheck/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) ![travis ci build status](https://travis-ci.org/mfelsche/ponycheck.svg?branch=master) ![this is awesome](https://img.shields.io/badge/this%20is-awesome-green.svg)

Property based testing for ponylang (>= 0.19.0).

[API docs](https://mfelsche.github.io/ponycheck/ponycheck--index/)

## Features

* Integration with [ponytest](https://stdlib.ponylang.org/ponytest--index).
* Extensive list of builtin Generators for your convencience.
* Shrinking of failed samples for more useful test output.
* Support for asynchronous properties.

## Property Based Testing

In traditional unit testing, it is the duty and burden
of the developer to provide and craft meaningful input examples for the
unit under test (be it a class, a function or whatever) and check if
some output conditions hold. This is a tedious and error-prone activity.

Property based testing leaves generation of test input samples to the testing
engine which generates random examples taken from a description how to do so, so called *Generators*. 
The developer just needs to define a *Generator* and describe the condition 
that should hold for each and every input sample.

Property based Testing first came up as [QuickCheck](http://www.cse.chalmers.se/~rjmh/QuickCheck/)
in Haskell. It has the nice property of automatically infering Generators from
the type of the property parameter, the test input sample.

Ponycheck is heavily inspired by QuickCheck and other great Property Based testing libraries, namely:

* [Hypothesis](https://github.com/HypothesisWorks/hypothesis-python)
* [Theft](https://github.com/silentbicycle/theft)
* [ScalaCheck](https://www.scalacheck.org/)

## Usage

Writing property based tests in ponycheck is done by implementing the trait
[`Property1`](https://mfelsche.github.io/ponycheck/ponycheck-Property1).
A [`Property1`](https://mfelsche.github.io/ponycheck/ponycheck-Property1) needs
to define a type parameter for the type of the input sample, a [Generator](https://mfelsche.github.io/ponycheck/ponycheck-Generator)
and a property function. Here is a stupid barebones example just to get a first feeling:

```pony
use "ponytest"

class MyFirstProperty is Property1[String]

  fun name(): String => "my_first_property"

  fun gen(): Generator[String] => Generators.ascii()

  fun property(arg1: String, h: PropertyHelper) =>
    h.assert_eq[String](arg1, arg1)
```

A Property needs a name for identification in test output.
We created a Generator by using one of the many convenience factory methods and
combinators defined in the [Generators](https://mfelsche.github.io/ponycheck/ponycheck-Generators) primitive
and we used [PropertyHelper](https://mfelsche.github.io/ponycheck/ponycheck-PropertyHelper) 
to assert on a (in this case trivial) condition that should hold for all samples 

Here is the classical List reverse properties from the QuickCheck paper adapted to
Pony Arrays:

```pony

use "ponycheck"
use "collections"

class ListReverseProperty is Property1[Array[USize]]
    
    fun name(): String => "list/reverse"

    fun gen(): Generator[Array[USize]] =>
      Generators.seq_of[USize, Array[USize]](Generators.uSize())
    
    fun property(arg1: Array[USize], ph: PropertyHelper) =>
      ph.assert_array_eq[USize](arg1, arg1.reverse().reverse())

class ListReverseOneProperty is Property1[Array[USize]]

    fun name(): String => "list/reverse/one"

    fun gen(): Generator[Array[USize]] =>
      Generators.seq_of[USize, Array[USize]](1, Generators.uSize() where min=1, max=1)

    fun property(arg1: Array[USize], ph: PropertyHelper) =>
      ph.assert_array_eq[USize](arg1, arg1.reverse())

```

### Integration into Ponytest

A Property defined in Ponycheck needs to be executed to show its full potential
and to actual detect bugs if they exist.

Ponycheck is intended to be run via [ponytest](https://stdlib.ponylang.org/ponytest--index).
To integrate [Property1](https://mfelsche.github.io/ponycheck/ponycheck-Property1) into [ponytest](https://stdlib.ponylang.org/ponytest--index),
it needs to be wrapped inside a [PropertyUnitTest](https://mfelsche.github.io/ponycheck/ponycheck-PropertyUnitTest) and
passed to the PonyTest.apply method as all regular ponytest [UnitTests](https://stdlib.ponylang.org/ponytest-UnitTest) 
(minus the cumbersome test sample creation):

```pony
use "ponytest"
use "ponycheck"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(Property1UnitTest[String](MyFirstProperty))
```

It is also possible to integrate any number of properties directly into one
[UnitTest](https://stdlib.ponylang.org/ponytest-UnitTest) using the [Ponycheck.forAll](https://mfelsche.github.io/ponycheck/ponycheck-Ponycheck)
convenience function:

```pony
class ListReverseProperties is UnitTest

    fun name(): String => "list/properties"

    fun apply(h: TestHelper) ? =>
      let gen1 = Generators.seq_of[USize, Array[USize]](Generators.uSize())
      Ponycheck.forAll[Array[USize]](gen1, h)({
        (arg1: Array[USize], ph: PropertyHelper) =>
          ph.assert_array_eq[USize](arg1, arg1.reverse().reverse())
      })
      let gen2 = Generators.seq_of[USize, Array[USize]](1, Generators.uSize())
      Ponycheck.forAll[Array[USize]](gen2, h)({
        (arg1: Array[USize], ph: PropertyHelper) =>
          ph.assert_array_eq[USize](arg1, arg1.reverse())
      })
```

For more examples on how to use ponycheck take a look at the `examples` directory.

For all the details, take a look at the [API docs](https://mfelsche.github.io/ponycheck/ponycheck--index/).


