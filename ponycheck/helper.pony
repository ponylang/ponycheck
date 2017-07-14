use "ponytest"

class ref PropertyHelper
    let testHelper: TestHelper
    var _did_fail: Bool = false

    new ref create(h: TestHelper) =>
        testHelper = h

    fun assert_true(predicate: Bool, msg: String val = "", loc: SourceLoc val = __loc): Bool val =>
        testHelper.assert_true(predicate, msg, loc)

    fun reportSuccess(params: PropertyParams) =>
        """
        """


    fun reportError(params: PropertyParams, shrinkRounds: USize = 0) =>
        """
        """

    fun reportFailed[T](sample: T, params: PropertyParams, shrinkRounds: USize = 0) =>
        """
        """

    fun failed(): Bool =>
        _did_fail

    fun ref reset() =>
        _did_fail = false
