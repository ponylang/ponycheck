use "ponytest"

class ForAll[T]
  let _gen: Generator[T] val
  let _helper: TestHelper

  new create(gen': Generator[T] val, testHelper: TestHelper) =>
    _gen = gen'
    _helper = testHelper

  fun ref apply(prop: {(T, PropertyHelper) ?} val) ? =>
    """execute"""
    (object val is Property1[T]
      fun name(): String => ""

      fun gen(): Generator[T] => _gen

      fun property(arg1: T, h: PropertyHelper) ? =>
        prop(consume arg1, h)?
    end)
      .unit_test().apply(_helper)?
