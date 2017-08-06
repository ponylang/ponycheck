use "ponytest"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)

  new make() => None

  fun tag tests(test: PonyTest) =>
    test(GenRndTest)
    test(GenFilterTest)
    test(GenFrequencyTest)
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
    test(PropertyAsUnitTest)
    test(FailingPropertyAsUnitTest)
    test(ErroringPropertyAsUnitTest)
    test(ForAllTest)
    test(MultipleForAllTest)
