use "ponytest"
use ".."

actor AsyncDelayingActor

  let _ph: PropertyHelper
  let _complete_with: Bool

  new create(ph: PropertyHelper, complete_with: Bool) =>
    _ph = ph
    _complete_with = complete_with

  be complete() =>
    do_complete()

  be do_complete() =>
    _ph.complete(_complete_with)

class AsyncProperty is Property1[String]

  let _complete_with: Bool
  new create(complete_with: Bool) =>
    _complete_with = complete_with

  fun name(): String => "property_runner/async/complete/property"

  fun params(): PropertyParams =>
    PropertyParams(where async' = true)

  fun gen(): Generator[String] =>
    Generators.ascii_printable()

  fun property(arg1: String, ph: PropertyHelper) =>
    AsyncDelayingActor(ph, _complete_with).complete()


class iso RunnerAsyncPropertyCompleteTest is UnitTest

  fun name(): String => "property_runner/async/complete"

  fun apply(h: TestHelper) =>
    let property = recover iso AsyncProperty(true) end
    let params = property.params()
    h.long_test(params.timeout)

    let runner = PropertyRunner[String](
      consume property,
      params,
      UnitTestPropertyNotify(h, true),
      UnitTestPropertyLogger(h))
    runner.run()

class iso RunnerAsyncPropertyCompleteFalseTest is UnitTest

  fun name(): String => "property_runner/async/complete-false"

  fun apply(h: TestHelper) =>
    let property = recover iso AsyncProperty(false) end
    let params = property.params()
    h.long_test(params.timeout)

    let runner = PropertyRunner[String](
      consume property,
      params,
      UnitTestPropertyNotify(h, false),
      UnitTestPropertyLogger(h))
    runner.run()

// TODO: test fail, complete_action and fail_action round trips
// TODO: test that multiple calls to complete or fail still only consider the
//       first call and ignore the later ones
