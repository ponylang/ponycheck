use ".."
use "itertools"
use "ponytest"

class InfiniteShrinkProperty is Property1[String]

  fun name(): String => "property_runner/inifinite_shrink/property"

  fun gen(): Generator[String] =>
    Generator[String](
      object is GenObj[String]
        fun generate(r: Randomness): String^ =>
          "decided by fair dice roll, totally random"
        
        fun shrink(t: String): ValueAndShrink[String] =>
          (t, Iter[String^].repeat_value(t))
      end)

  fun property(arg1: String, ph: PropertyHelper) =>
    ph.assert_true(arg1.size() >  100) // assume this failing


class iso RunnerInfiniteShrinkTest is UnitTest
  """
  ensure that having a failing property with an infinite generator
  is not shrinking infinitely
  """
  fun name(): String => "property_runner/infinite_shrink"

  fun apply(h: TestHelper) =>
    h.long_test(20_000_000_000)
    let property_notify =
      object val is PropertyResultNotify
        fun log(msg: String, verbose: Bool) =>
          h.log(msg, verbose)
        fun fail(msg: String) =>
          h.log("FAIL: " + msg)
          h.complete(true)
        fun complete(success: Bool) =>
          h.log("COMPLETE: " + success.string())
          h.complete(not success)
      end
    let property = recover iso InfiniteShrinkProperty end
    let params = property.params()

    let runner = PropertyRunner[String](
      consume property,
      params,
      property_notify)
    runner.run()

