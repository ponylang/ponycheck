use "ponytest"
use ".."

class SuccessfulProperty is Property1[U8]
  """
  this just tests that a property is compatible with ponytest
  """
  fun name(): String => "as_unit_test/successful/property"

  fun gen(): Generator[U8] => Generators.u8(0, 10)

  fun property(arg1: U8, h: PropertyHelper) =>
    h.assert_true(arg1 <= U8(10))

class SuccessfulPropertyTest is UnitTest

  fun name(): String => "as_unit_test/successful"

  fun apply(h: TestHelper) =>
    let property = recover iso SuccessfulProperty end
    let property_notify = UnitTestPropertyNotify(h, true)
    let property_logger = UnitTestPropertyLogger(h)
    let params = property.params()
    h.long_test(params.timeout)
    let runner = PropertyRunner[U8](
      consume property,
      params,
      property_notify,
      property_logger)
    runner.run()


class FailingProperty is Property1[U8]
  fun name(): String => "as_unit_test/failing/property"

  fun gen(): Generator[U8] => Generators.u8(0, 10)

  fun property(arg1: U8, h: PropertyHelper) =>
    h.assert_true(arg1 <= U8(5))

class FailingPropertyTest is UnitTest
  fun name(): String => "as_unit_test/failing"

  fun apply(h: TestHelper) =>
    let property = recover iso FailingProperty end
    let property_notify = UnitTestPropertyNotify(h, false)
    let property_logger = UnitTestPropertyLogger(h)
    let params = property.params()
    h.long_test(params.timeout)
    let runner = PropertyRunner[U8](
      consume property,
      params,
      property_notify,
      property_logger)
    runner.run()


class ErroringProperty is Property1[U8]
  fun name(): String => "as_unit_test/erroring/property"

  fun gen(): Generator[U8] => Generators.u8(0, 1)

  fun property(arg1: U8, h: PropertyHelper) ? =>
    if arg1 < 2 then
      error
    end


class ErroringPropertyTest is UnitTest
  fun name(): String => "as_unit_test/erroring"

  fun apply(h: TestHelper) =>
    h.long_test(20_000_000_000)
    let property = recover iso ErroringProperty end
    let property_notify = UnitTestPropertyNotify(h, false)
    let property_logger = UnitTestPropertyLogger(h)
    let params = property.params()
    let runner = PropertyRunner[U8](
      consume property,
      params,
      property_notify,
      property_logger)
    runner.run()


