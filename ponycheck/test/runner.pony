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

    let property = recover iso InfiniteShrinkProperty end
    let params = property.params()

    h.long_test(params.timeout)

    let runner = PropertyRunner[String](
      consume property,
      params,
      UnitTestPropertyNotify(h, false),
      UnitTestPropertyLogger(h),
      h.env)
    runner.run()

class ErroringGeneratorProperty is Property1[String]
  fun name(): String => "property_runner/erroring_generator/property"

  fun gen(): Generator[String] =>
    Generator[String](
      object is GenObj[String]
        fun generate(r: Randomness): String^ ? =>
          error
      end)

  fun property(sample: String, h: PropertyHelper) =>
    None

class iso RunnerErroringGeneratorTest is UnitTest
  fun name(): String => "property_runner/erroring_generator"

  fun apply(h: TestHelper) =>
    let property = recover iso ErroringGeneratorProperty end
    let params = property.params()

    h.long_test(params.timeout)

    let runner = PropertyRunner[String](
      consume property,
      params,
      UnitTestPropertyNotify(h, false),
      UnitTestPropertyLogger(h),
      h.env)
    runner.run()

class SometimesErroringGeneratorProperty is Property1[String]
  fun name(): String => "property_runner/sometimes_erroring_generator"
  fun params(): PropertyParams =>
    PropertyParams(where
      num_samples' = 3,
      seed' = 6, // known seed to produce a value, an error and a value
      max_generator_retries' = 1
    )
  fun gen(): Generator[String] =>
    Generator[String](
      object is GenObj[String]
        fun generate(r: Randomness): String^ ? =>
          match (r.u64() % 2)
          | 0 => "foo"
          else
            error
          end
      end
    )

  fun property(sample: String, h: PropertyHelper) =>
    None


class RunnerSometimesErroringGeneratorTest is UnitTest
  fun name(): String => "property_runner/sometimes_erroring_generator"

  fun apply(h: TestHelper) =>
    let property = recover iso SometimesErroringGeneratorProperty end
    let params = property.params()

    h.long_test(params.timeout)

    let runner = PropertyRunner[String](
      consume property,
      params,
      UnitTestPropertyNotify(h, true),
      UnitTestPropertyLogger(h),
      h.env)
    runner.run()

class ReportFailedSampleProperty is Property1[U8]
  fun name(): String => "property_runner/sample_reporting/property"
  fun gen(): Generator[U8] => Generators.u8(0, 1)
  fun property(sample: U8, h: PropertyHelper) =>
    h.assert_eq[U8](sample, U8(0))

class iso RunnerReportFailedSampleTest is UnitTest
  fun name(): String => "property_runner/sample_reporting"
  fun apply(h: TestHelper) =>
    let property = recover iso ReportFailedSampleProperty end
    let params = property.params()

    h.long_test(params.timeout)

    let logger =
      object val is PropertyLogger
        fun log(msg: String, verbose: Bool) =>
          if msg.contains("Property failed for sample 1 ") then
            h.complete(true)
          elseif msg.contains("Propety failed for sample 0 ") then
            h.fail("wrong sample reported.")
            h.complete(false)
          end
      end
    let notify =
      object val is PropertyResultNotify
        fun fail(msg: String) =>
          h.log("FAIL: " + msg)
        fun complete(success: Bool) =>
          h.assert_false(success, "property did not fail")
      end

    let runner = PropertyRunner[U8](
      consume property,
      params,
      UnitTestPropertyNotify(h, false),
      logger,
      h.env)
    runner.run()

