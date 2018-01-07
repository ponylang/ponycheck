use "ponytest"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)

  new make() => None

  fun tag tests(test: PonyTest) =>
    test(GenRndTest)
    test(GenFilterTest)
    test(GenFrequencyTest)
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
    test(PropertyAsUnitTest.unit_test())
    test(FailingPropertyAsUnitTest.unit_test())
    test(ErroringPropertyAsUnitTest.unit_test())
    test(ForAllTest)
    test(MultipleForAllTest)
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
