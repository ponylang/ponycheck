use "ponytest"
use ".."



class iso RunnerAsyncPropertyCompleteTest is UnitTest

  fun name(): String => "property_runner/async/complete"

  fun apply(h: TestHelper) =>
    Async.run_async_test(h, {(ph) => ph.complete(true) }, true)

class iso RunnerAsyncPropertyCompleteFalseTest is UnitTest

  fun name(): String => "property_runner/async/complete-false"

  fun apply(h: TestHelper) =>
    Async.run_async_test(h,{(ph) => ph.complete(false) }, false)

class iso RunnerAsyncFailTest is UnitTest

  fun name(): String => "property_runner/async/fail"

  fun apply(h: TestHelper) =>
    Async.run_async_test(h, {(ph) => ph.fail("Oh noes!") }, false)

class iso RunnerAsyncMultiCompleteSucceedTest is UnitTest

  fun name(): String => "property_runner/async/multi_succeed"

  fun apply(h: TestHelper) =>
    Async.run_async_test(
      h,
      {(ph) =>
        ph.complete(true)
        ph.complete(false)
      }, true)

class RunnerAsyncMultiCompleteFailTest is UnitTest
  fun name(): String => "property_runner/async/multi_fail"

  fun apply(h: TestHelper) =>
    Async.run_async_test(
      h,
      {(ph) =>
        ph.complete(false)
        ph.complete(true)
      }, false)

class iso RunnerAsyncCompleteActionTest is UnitTest

  fun name(): String => "property_runner/async/complete_action"

  fun apply(h: TestHelper) =>
    Async.run_async_test(
      h,
      {(ph) =>
        ph.expect_action("blaaaa")
        ph.complete_action("blaaaa")
      },
      true)

class iso RunnerAsyncCompleteFalseActionTest is UnitTest

  fun name(): String => "property_runner/async/complete_action"

  fun apply(h: TestHelper) =>
    Async.run_async_test(
      h,
      {(ph) =>
        ph.expect_action("blaaaa")
        ph.fail_action("blaaaa")
      }, false)

class iso RunnerAsyncCompleteMultiActionTest is UnitTest

  fun name(): String => "property_runner/async/complete_multi_action"

  fun apply(h: TestHelper) =>
    Async.run_async_test(
      h,
      {(ph) =>
        ph.expect_action("only-once")
        ph.fail_action("only-once")
        ph.complete_action("only-once") // should be ignored
      },
      false)

class iso RunnerAsyncCompleteMultiSucceedActionTest is UnitTest

  fun name(): String => "property_runner/async/complete_multi_fail_action"

  fun apply(h: TestHelper) =>
    Async.run_async_test(
      h,
      {(ph) =>
        let action = "succeed-once"
        ph.expect_action(action)
        ph.complete_action(action)
        ph.fail_action(action)
      },
      true)

