use "ponytest"

interface FailureCallback
    fun fail(msg: String)

interface Logger
    fun log(msg: String, verbose: Bool = false)

type _TestLogger is (FailureCallback val & Logger val)

class ref PropertyHelper
    """
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

/*
    fun assert_eq[A: (Equatable[A] #read & Stringable #read)]
      (expect: A, actual: A, msg: String = "", loc: SourceLoc = __loc): Bool =>
        _th.assert_eq(expect, actual, msg, loc)

    fun assert_neq[A: (Equatable[A] #read & Stringable #read)]
    (expect: A, actual: A, msg: String = "", loc: SourceLoc = __loc): Bool
    =>
        _th.assert_neq(expect, actual, msg, loc)
*/
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
        """


    fun reportError(shrinkRounds: USize = 0) =>
        """
        """

    fun reportFailed[T](sample: T, shrinkRounds: USize = 0) =>
        """
        """

    fun box failed(): Bool =>
        _did_fail

    fun ref reset() =>
        _did_fail = false
