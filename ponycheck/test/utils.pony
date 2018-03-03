use ".."
use "ponytest"

primitive Async
  """
  utility to run tests for async properties
  """
  fun run_async_test(
    h: TestHelper,
    action: {(PropertyHelper): None} val,
    should_succeed: Bool = true)
  =>
    """
    Run the given action in an asynchronous property
    providing if you expect success or failure with `should_succeed`.
    """
    let property = AsyncProperty(action)
    let params = property.params()
    h.long_test(params.timeout)

    let runner = PropertyRunner[String](
      consume property,
      params,
      UnitTestPropertyNotify(h, should_succeed),
      UnitTestPropertyLogger(h),
      h.env)
    runner.run()

class val UnitTestPropertyLogger is PropertyLogger
  """
  just forwarding logs to the TestHelper log
  with a custom prefix
  """
  let _th: TestHelper

  new val create(th: TestHelper) =>
    _th = th

  fun log(msg: String, verbose: Bool) =>
    _th.log("[PROPERTY] " + msg, verbose)

class val UnitTestPropertyNotify is PropertyResultNotify
  let _th: TestHelper
  let _should_succeed: Bool

  new val create(th: TestHelper, should_succeed: Bool = true) =>
    _should_succeed = should_succeed
    _th = th

  fun fail(msg: String) =>
    _th.log("FAIL: " + msg)

  fun complete(success: Bool) =>
    _th.log("COMPLETE: " + success.string())
    let result = (success and _should_succeed) or ((not success) and (not _should_succeed))
    _th.complete(result)


actor AsyncDelayingActor
  """
  running the given action in a behavior
  """

  let _ph: PropertyHelper
  let _action: {(PropertyHelper): None} val

  new create(ph: PropertyHelper, action: {(PropertyHelper): None} val) =>
    _ph = ph
    _action = action

  be do_it() =>
    _action.apply(_ph)

class iso AsyncProperty is Property1[String]
  """
  A simple property running the given action
  asynchronously in an `AsyncDelayingActor`.
  """

  let _action: {(PropertyHelper): None} val
  new iso create(action: {(PropertyHelper): None } val) =>
    _action = action

  fun name(): String => "property_runner/async/property"

  fun params(): PropertyParams =>
    PropertyParams(where async' = true)

  fun gen(): Generator[String] =>
    Generators.ascii_printable()

  fun property(arg1: String, ph: PropertyHelper) =>
    AsyncDelayingActor(ph, _action).do_it()

