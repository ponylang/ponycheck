use "../ponycheck"
use "ponytest"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_ListReverseProperty.unit_test())
    test(_ListReverseOneProperty.unit_test())
    test(_ListReverseMultipleProperties)
    test(_CustomClassFlatMapProperty.unit_test())
    test(_CustomClassMapProperty.unit_test())
    test(_CustomClassCustomGeneratorProperty.unit_test())
