
interface Shrinkable[T]
  fun box shrink(t: T): (T^, Seq[T])
    """
    shrink the given value ``t``
    to a possibly emtpy Seq of elements of type ``T``
    which are supposed to be smaller than ``t``.

    It is necessary to return t itself as ``T^``
    as it is needed for reporting if the returned Seq is empty.
    And a ``Shrinkable`` must be able to handle ``iso`` types.

    Example:

    ```pony
    U8Shrinkable is Shrinkable[U8]
      fun box shrink(t: U8): (U8^, Seq[U8]) =>
        let size = t.min(10)
        let shrinks = Array[U8](t.min(10))
        for i in Range(1, size) do
          shrinks.push(t - i)
        end
        (consume t, shrinks)
    ```
    """
