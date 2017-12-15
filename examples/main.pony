use "../ponycheck"
use "ponytest"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_ListReverseProperty)
    test(_ListReverseOneProperty)
    test(_ListReverseMultipleProperties)
    test(_CustomClassFlatMapProperty)
    test(_CustomClassMapProperty)
    test(_CustomClassCustomGeneratorProperty)
