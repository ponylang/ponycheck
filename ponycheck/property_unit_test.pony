use "ponytest"

class iso Property1UnitTest[T] is UnitTest
  """
  provides plumbing for integration of ponycheck
  [Properties](ponycheck-Property1.md) into [ponytest](ponytest--index.md).

  Wrap your properties into this class and use it in a
  [TestList](ponytest-TestList.md):

  ```pony
  use "ponytest"
  use "ponycheck"

  class MyProperty is Property1[String]
    fun name(): String => "my_property"

    fun gen(): Generator[String] =>
      Generatos.ascii_printable()

    fun property(arg1: String, h: PropertyHelper) =>
      h.assert_true(arg1.size() > 0)

  actor Main is TestList
    new create(env: Env) => PonyTest(env, this)

    fun tag tests(test: PonyTest) =>
      test(Property1UnitTest[String](MyProperty))

  ```



  """
  var _prop1: ( Property1[T] iso | None )
  let _name: String

  new iso create(p1: Property1[T] iso, name': (String | None) = None) =>
    """
    Wrap a [Property1](ponycheck-Property1.md) to make it mimick the a ponytest
    [UnitTest](ponytest-UnitTest.md).

    If `name'` is given, use this as the test name, if not use the properties `name()`.
    """
    _name =
      match name'
      | None => p1.name()
      | let s: String => s
      end
    _prop1 = consume p1


  fun name(): String => _name

  fun ref apply(h: TestHelper) ? =>
    let prop = ((_prop1 = None) as Property1[T] iso^)
    let params = prop.params()
    h.long_test(params.timeout)
    let property_runner =
      PropertyRunner[T](
        consume prop,
        params,
        h, // treat it as PropertyResultNotify
        h,  // is also a PropertyLogger for us
        h.env
      )
    h.dispose_when_done(property_runner)
    property_runner.run()
