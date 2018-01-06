use "ponytest"
use ".."

class PropertyAsUnitTest is Property1[U8]
  """
  this just tests that a property is compatible with ponytest
  """
  fun name(): String => "property1/asUnitTest"

  fun gen(): Generator[U8] => Generators.u8(0, 10)

  fun property(arg1: U8, h: PropertyHelper) =>
    h.assert_true(arg1 <= U8(10))

// TODO: test for failing Properties using a separate PonyTest invocation
class FailingPropertyAsUnitTest is Property1[U8]
  fun name(): String => "(fail) property1/asFailingUnitTest"

  fun gen(): Generator[U8] => Generators.u8(0, 10)

  fun property(arg1: U8, h: PropertyHelper) =>
    h.assert_true(arg1 <= U8(5))

class ErroringPropertyAsUnitTest is Property1[U8]
  fun name(): String => "(fail) property/asErroringUnitTest"

  fun gen(): Generator[U8] => Generators.u8(0, 1)

  fun property(arg1: U8, h: PropertyHelper) ? =>
    if arg1 < 2 then
      error
    end
