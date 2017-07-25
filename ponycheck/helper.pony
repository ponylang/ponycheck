use "ponytest"

interface FailureCallback
    """something to call in case of error"""
    fun fail(msg: String)

interface Logger
    """something to log messages to"""
    fun log(msg: String, verbose: Bool = false)

type _TestLogger is (FailureCallback val & Logger val)
    """stripped down interface for TestHelper as this is all we need"""

class ref PropertyHelper
    """
    Helper for ponycheck properties.

    Contains assertion methods.

    Mirrors the TestHelper assertion API.

    logic: don't just fail the runner if an assert method failed,
           record the fail and mark this helper as failed,
           so we can get into the shrinking and reporting phases.
    """
    let _params: PropertyParams
    let _params_fmt: String
    let _th: _TestLogger
    var _did_fail: Bool = false

    new ref create(params: PropertyParams, h: _TestLogger) =>
        _params = params
        _params_fmt = _format_params(params)
        _th = h

/****** START DUPLICATION FROM TESTHELPER ********/

    fun ref assert_false(predicate: Bool, msg: String val = "", loc: SourceLoc val = __loc): Bool val =>
        if predicate then
            _fail(_fmt_msg(loc, "Assert false failed. " + msg))
            return false
        end
        _th.log(_fmt_msg(loc, "Assert false passed. " + msg))
        true

    fun ref assert_true(predicate: Bool, msg: String val = "", loc: SourceLoc val = __loc): Bool val =>
        if not predicate then
            _fail(_fmt_msg(loc, "Assert true failed. " + msg))
            return false
        end
        _th.log(_fmt_msg(loc, "Assert true passed. " + msg))
        true

    fun ref assert_error(test: ITest box, msg: String = "", loc: SourceLoc = __loc): Bool =>
        """
        Assert that the given test function throws an error when run.
        """
        try
          test()
          _fail(_fmt_msg(loc, "Assert error failed. " + msg))
          false
        else
          _th.log(_fmt_msg(loc, "Assert error passed. " + msg), true)
          true
        end

    fun ref assert_no_error(test: ITest box, msg: String = "", loc: SourceLoc = __loc): Bool =>
        """
        Assert that the given test function does not throw an error when run.
        """
        try
          test()
          _th.log(_fmt_msg(loc, "Assert no error passed. " + msg), true)
          true
        else
          _fail(_fmt_msg(loc, "Assert no error failed. " + msg))
          false
        end

    fun ref assert_is[A](
        expect: A,
        actual: A,
        msg: String = "",
        loc: SourceLoc = __loc): Bool =>
        """
        Assert that the 2 given expressions resolve to the same instance
        """
        if expect isnt actual then
          _fail(_fmt_msg(loc, "Assert is failed. " + msg
            + " Expected (" + (digestof expect).string() + ") is ("
            + (digestof actual).string() + ")"))
          return false
        end

        _th.log(
          _fmt_msg(loc, "Assert is passed. " + msg
            + " Got (" + (digestof expect).string() + ") is ("
            + (digestof actual).string() + ")"),
          true)
        true

    fun ref assert_isnt[A](
        not_expect: A,
        actual: A,
        msg: String = "",
        loc: SourceLoc = __loc): Bool =>
        """
        Assert that the 2 given expressions resolve to different instances.
        """
        if not_expect is actual then
          _fail(_fmt_msg(loc, "Assert isn't failed. " + msg
            + " Expected (" + (digestof not_expect).string() + ") isnt ("
            + (digestof actual).string() + ")"))
          return false
        end

        _th.log(
          _fmt_msg(loc, "Assert isn't passed. " + msg
            + " Got (" + (digestof not_expect).string() + ") isnt ("
            + (digestof actual).string() + ")"),
          true)
        true

    fun ref assert_eq[A: (Equatable[A] #read & Stringable #read)]
        (expect: A, actual: A, msg: String = "", loc: SourceLoc = __loc): Bool =>
        """
        Assert that the 2 given expressions are equal.
        """
        if expect != actual then
          _fail(_fmt_msg(loc,  "Assert eq failed. " + msg
            + " Expected (" + expect.string() + ") == (" + actual.string() + ")"))
          return false
        end

        _th.log(_fmt_msg(loc, "Assert eq passed. " + msg
          + " Got (" + expect.string() + ") == (" + actual.string() + ")"), true)
        true

     fun ref assert_ne[A: (Equatable[A] #read & Stringable #read)]
        (not_expect: A, actual: A, msg: String = "", loc: SourceLoc = __loc): Bool =>
        """
        Assert that the 2 given expressions are not equal.
        """
        if not_expect == actual then
          _fail(_fmt_msg(loc, "Assert ne failed. " + msg
            + " Expected (" + not_expect.string() + ") != (" + actual.string()
            + ")"))
          return false
        end

        _th.log(
          _fmt_msg(loc, "Assert ne passed. " + msg
            + " Got (" + not_expect.string() + ") != (" + actual.string() + ")"),
          true)
        true

    fun ref assert_array_eq[A: (Equatable[A] #read & Stringable #read)](
        expect: ReadSeq[A],
        actual: ReadSeq[A],
        msg: String = "",
        loc: SourceLoc = __loc): Bool =>
        """
        Assert that the contents of the 2 given ReadSeqs are equal.
        """
        var ok = true

        if expect.size() != actual.size() then
          ok = false
        else
          try
            var i: USize = 0
            while i < expect.size() do
              if expect(i) != actual(i) then
                ok = false
                break
              end

              i = i + 1
            end
          else
            ok = false
          end
        end

        if not ok then
          _fail(_fmt_msg(loc, "Assert EQ failed. " + msg + " Expected ("
            + _print_array[A](expect) + ") == (" + _print_array[A](actual) + ")"))
          return false
        end

        _th.log(
          _fmt_msg(loc, "Assert EQ passed. " + msg + " Got ("
            + _print_array[A](expect) + ") == (" + _print_array[A](actual) + ")"),
          true)
        true

  fun ref assert_array_eq_unordered[A: (Equatable[A] #read & Stringable #read)](
    expect: ReadSeq[A],
    actual: ReadSeq[A],
    msg: String = "",
    loc: SourceLoc = __loc): Bool =>
    """
    Assert that the contents of the 2 given ReadSeqs are equal ignoring order.
    """
    try
      let missing = Array[box->A]
      let consumed = Array[Bool].init(false, actual.size())
      for e in expect.values() do
        var found = false
        var i: USize = -1
        for a in actual.values() do
          i = i + 1
          if consumed(i) then continue end
          if e == a then
            consumed.update(i, true)
            found = true
            break
          end
        end
        if not found then
          missing.push(e)
        end
      end

      let extra = Array[box->A]
      for (i, c) in consumed.pairs() do
        if not c then extra.push(actual(i)) end
      end

      if (extra.size() != 0) or (missing.size() != 0) then
        _fail(
          _fmt_msg(loc, "Assert EQ_UNORDERED failed. " + msg
            + " Expected (" + _print_array[A](expect) + ") == ("
            + _print_array[A](actual) + "):"
            + "\nMissing: " + _print_array[box->A](missing)
            + "\nExtra: " + _print_array[box->A](extra))
        )
        return false
      end
      _th.log(
        _fmt_msg(loc, "Assert EQ_UNORDERED passed. " + msg + " Got ("
          + _print_array[A](expect) + ") == (" + _print_array[A](actual) + ")"),
        true)
      true
    else
      _fail("Assert EQ_UNORDERED failed from an internal error.")
      false
    end

    fun _print_array[A: Stringable #read](array: ReadSeq[A]): String =>
        """
        Generate a printable string of the contents of the given readseq to use in
        error messages.
        """
        "[len=" + array.size().string() + ": " + ", ".join(array) + "]"


/****** END DUPLICATION FROM TESTHELPER *********/

    fun ref _fail(msg: String) =>
        _did_fail = true
        _th.log(msg)
    
    fun _fmt_msg(loc: SourceLoc, msg: String): String =>
        let msg_prefix = _params_fmt + " " + _format_loc(loc)
        if msg.size() > 0 then
            msg_prefix + ": " + msg
        else
            msg_prefix
        end

    fun _format_loc(loc: SourceLoc): String =>
        loc.file() + ":" + loc.line().string()

    fun tag _format_params(params: PropertyParams): String =>
        "Params(seed=" + params.seed.string() + ")"


    fun reportSuccess() =>
        """
        report success to the property test runner
        """


    fun reportError(sampleRepr: String,
                    shrinkRounds: USize = 0,
                    loc: SourceLoc = __loc) =>
        """
        report an error that happened during property evaluation
        """
        _th.log(_fmt_msg(loc, "Property errored for sample " + sampleRepr + " (after " + shrinkRounds.string() + " shrinks)"), false)

    fun reportFailed[T](sampleRepr: String,
                        shrinkRounds: USize = 0,
                        loc: SourceLoc = __loc) =>
        """
        report a failed property
        """
        _th.fail(_fmt_msg(loc, "Property failed for sample " + sampleRepr + " (after " + shrinkRounds.string() + " shrinks)"))

    fun failed(): Bool =>
        """
        returns true if a property has failed using this instance
        """
        _did_fail

    fun ref reset() =>
        """
        reset the state of this instance,
        so that it can be reused for further property executions
        """
        _did_fail = false
