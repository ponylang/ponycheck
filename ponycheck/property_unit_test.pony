use "ponytest"

class iso Property1UnitTest[T] is UnitTest
  var _prop1: ( Property1[T] iso | None )
  let _name: String

  new iso create(p1: Property1[T] iso, name': (String | None) = None) =>
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
    PropertyRunner[T](
      consume prop,
      params,
      h, // treat it as PropertyResultNotify
      h  // is also a PropertyLogger for us
    ).run()
