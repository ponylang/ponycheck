use "ponytest"
use ".."

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)

  new make() => None

  fun tag tests(test: PonyTest) =>
    test(GenRndTest)
    test(GenFilterTest)
    test(GenUnionTest)
    test(GenFrequencyTest)
    test(GenFrequencySafeTest)
    test(GenOneOfTest)
    test(GenOneOfSafeTest)
    test(SeqOfTest)
    test(SetOfTest)
    test(SetOfMaxTest)
    test(SetOfEmptyTest)
    test(SetIsOfIdentityTest)
    test(MapOfEmptyTest)
    test(MapOfMaxTest)
    test(MapOfIdentityTest)
    test(MapIsOfEmptyTest)
    test(MapIsOfMaxTest)
    test(MapIsOfIdentityTest)

    AsUnitTestTests.tests(test)

    ForAllTests.tests(test)

    test(ASCIIRangeTest)
    test(UTF32CodePointStringTest)
    test(SignedShrinkTest)
    test(UnsignedShrinkTest)
    test(ASCIIStringShrinkTest)
    test(MinASCIIStringShrinkTest)
    test(UnicodeStringShrinkTest)
    test(MinUnicodeStringShrinkTest)
    test(FilterMapShrinkTest)
    test(RunnerInfiniteShrinkTest)
    test(RunnerReportFailedSampleTest)
    test(RunnerErroringGeneratorTest)
    test(RunnerSometimesErroringGeneratorTest)
    test(RunnerAsyncPropertyCompleteTest)
    test(RunnerAsyncPropertyCompleteFalseTest)
    test(RunnerAsyncFailTest)
    test(RunnerAsyncCompleteActionTest)
    test(RunnerAsyncCompleteMultiActionTest)
    test(RunnerAsyncCompleteMultiSucceedActionTest)
    test(RunnerAsyncMultiCompleteSucceedTest)
    test(RunnerAsyncMultiCompleteFailTest)

    IntPropertyTests.tests(test)

