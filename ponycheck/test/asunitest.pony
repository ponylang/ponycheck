use "ponytest"
use ".."

primitive AsUnitTestTests is TestList
  fun tag tests(test: PonyTest) =>
    test(SuccessfulPropertyTest)
    test(Property1UnitTest[U8](SuccessfulProperty))
    test(FailingPropertyTest)
    test(ErroringPropertyTest)
    test(Property2UnitTest[U8, U8](SuccessfulProperty2))
    test(SuccessfulProperty2Test)
    test(Property3UnitTest[U8, U8, U8](SuccessfulProperty3))
    test(SuccessfulProperty3Test)
    test(Property4UnitTest[U8, U8, U8, U8](SuccessfulProperty4))
    test(SuccessfulProperty4Test)


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
      property_logger,
      h.env)
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
      property_logger,
      h.env)
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
      property_logger,
      h.env)
    runner.run()


class SuccessfulProperty2 is Property2[U8, U8]
  fun name(): String => "as_unit_test/successful2/property"
  fun gen1(): Generator[U8] => Generators.u8(0, 1)
  fun gen2(): Generator[U8] => Generators.u8(2, 3)

  fun property2(arg1: U8, arg2: U8, h: PropertyHelper) =>
    h.assert_ne[U8](arg1, arg2)

class SuccessfulProperty2Test is UnitTest

  fun name(): String => "as_unit_test/successful2"

  fun apply(h: TestHelper) =>
    let property2 = recover iso SuccessfulProperty2 end
    let property2_notify = UnitTestPropertyNotify(h, true)
    let property2_logger = UnitTestPropertyLogger(h)
    let params = property2.params()
    h.long_test(params.timeout)
    let runner = PropertyRunner[(U8, U8)](
      consume property2,
      params,
      property2_notify,
      property2_logger,
      h.env)
    runner.run()


class SuccessfulProperty3 is Property3[U8, U8, U8]
  fun name(): String => "as_unit_test/successful3/property"
  fun gen1(): Generator[U8] => Generators.u8(0, 1)
  fun gen2(): Generator[U8] => Generators.u8(2, 3)
  fun gen3(): Generator[U8] => Generators.u8(4, 5)

  fun property3(arg1: U8, arg2: U8, arg3: U8, h: PropertyHelper) =>
    h.assert_ne[U8](arg1, arg2)
    h.assert_ne[U8](arg2, arg3)
    h.assert_ne[U8](arg1, arg3)

class SuccessfulProperty3Test is UnitTest

  fun name(): String => "as_unit_test/successful3"

  fun apply(h: TestHelper) =>
    let property3 = recover iso SuccessfulProperty3 end
    let property3_notify = UnitTestPropertyNotify(h, true)
    let property3_logger = UnitTestPropertyLogger(h)
    let params = property3.params()
    h.long_test(params.timeout)
    let runner = PropertyRunner[(U8, U8, U8)](
      consume property3,
      params,
      property3_notify,
      property3_logger,
      h.env)
    runner.run()

class SuccessfulProperty4 is Property4[U8, U8, U8, U8]
  fun name(): String => "as_unit_test/successful4/property"
  fun gen1(): Generator[U8] => Generators.u8(0, 1)
  fun gen2(): Generator[U8] => Generators.u8(2, 3)
  fun gen3(): Generator[U8] => Generators.u8(4, 5)
  fun gen4(): Generator[U8] => Generators.u8(6, 7)

  fun property4(arg1: U8, arg2: U8, arg3: U8, arg4: U8, h: PropertyHelper) =>
    h.assert_ne[U8](arg1, arg2)
    h.assert_ne[U8](arg1, arg3)
    h.assert_ne[U8](arg1, arg4)
    h.assert_ne[U8](arg2, arg3)
    h.assert_ne[U8](arg2, arg4)
    h.assert_ne[U8](arg3, arg4)

class SuccessfulProperty4Test is UnitTest

  fun name(): String => "as_unit_test/successful4"

  fun apply(h: TestHelper) =>
    let property4 = recover iso SuccessfulProperty4 end
    let property4_notify = UnitTestPropertyNotify(h, true)
    let property4_logger = UnitTestPropertyLogger(h)
    let params = property4.params()
    h.long_test(params.timeout)
    let runner = PropertyRunner[(U8, U8, U8, U8)](
      consume property4,
      params,
      property4_notify,
      property4_logger,
      h.env)
    runner.run()

