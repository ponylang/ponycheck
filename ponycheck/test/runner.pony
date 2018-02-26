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

    let logger =
      object val is PropertyLogger
        fun log(msg: String, verbose: Bool) =>
          h.log(msg, verbose)
      end
    let notify =
      object val is PropertyResultNotify
        let _logger: PropertyLogger = logger

        fun fail(msg: String) =>
          _logger.log("FAIL: " + msg)
          h.complete(true)

        fun complete(success: Bool) =>
          _logger.log("COMPLETE: " + success.string())
          h.complete(not success)
      end
    let property = recover iso InfiniteShrinkProperty end
    let params = property.params()

    h.long_test(params.timeout)

    let runner = PropertyRunner[String](
      consume property,
      params,
      notify,
      logger)
    runner.run()

