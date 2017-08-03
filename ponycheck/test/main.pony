use "ponytest"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)

  new make() => None

  fun tag tests(test: PonyTest) =>
    test(GenRndTest)
    test(GenFilterTest)
    test(PropertyAsUnitTest)
    test(FailingPropertyAsUnitTest)
    test(ErroringPropertyAsUnitTest)
    test(ForAllTest)
    test(MultipleForAllTest)
