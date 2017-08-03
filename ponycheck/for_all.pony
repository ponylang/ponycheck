use "ponytest"

class ForAll[T]
  let _gen: Generator[T]
  let _helper: TestHelper

  new create(gen': Generator[T], testHelper: TestHelper) =>
    _gen = gen'
    _helper = testHelper

  fun apply(prop: {(T, PropertyHelper) ?} val) ? =>
    """execute"""
    let prop1 =
      object is Property1[T]
        fun name(): String => ""

        fun gen(): Generator[T] => _gen

        fun property(arg1: T, h: PropertyHelper) ? =>
          prop(consume arg1, h)?
      end
    prop1.apply(_helper)?

