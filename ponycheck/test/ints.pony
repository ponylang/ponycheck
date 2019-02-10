use "ponytest"
use ".."

primitive IntPropertyTests is TestList
  fun tag tests(test: PonyTest) =>
    test(SuccessfulIntPropertyTest)
    test(IntUnitTest(SuccessfulIntProperty))
    test(SuccessfulIntPairPropertyTest)
    test(IntPairUnitTest(SuccessfulIntPairProperty))

class SuccessfulIntProperty is IntProperty
  fun name(): String  => "property/int/property"

  fun int_property[T: (Int & Integer[T] val)](x: T, h: PropertyHelper) =>
    h.assert_eq[T](x.min(T.max_value()), x)
    h.assert_eq[T](x.max(T.min_value()), x)

class SuccessfulIntPropertyTest is UnitTest
  fun name(): String => "property/int"

  fun apply(h: TestHelper) =>
    let property = recover iso SuccessfulIntProperty end
    let property_notify = UnitTestPropertyNotify(h, true)
    let property_logger = UnitTestPropertyLogger(h)
    let params = property.params()
    h.long_test(params.timeout)
    let runner = PropertyRunner[(U8, U128)](
      consume property,
      params,
      property_notify,
      property_logger,
      h.env)
    runner.run()

class SuccessfulIntPairProperty is IntPairProperty
  fun name(): String => "property/intpair/property"

  fun int_property[T: (Int & Integer[T] val)](x: T, y: T, h: PropertyHelper) =>
    h.assert_eq[T](x * y, y* x)

class SuccessfulIntPairPropertyTest is UnitTest
  fun name(): String => "property/intpair"

  fun apply(h: TestHelper) =>
    let property = recover iso SuccessfulIntPairProperty end
    let property_notify = UnitTestPropertyNotify(h, true)
    let property_logger = UnitTestPropertyLogger(h)
    let params = property.params()
    h.long_test(params.timeout)
    let runner = PropertyRunner[(U8, (U128, U128))](
      consume property,
      params,
      property_notify,
      property_logger,
      h.env)
    runner.run()

