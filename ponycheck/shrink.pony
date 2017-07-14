
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

interface ShrinkEvaluate[T]
    fun ref evaluate(t: T): (T^, Bool) ?

primitive Shrink
    fun shrink[T](sample: T, shrinkable: Shrinkable[T] box, shrinkEvaluate: ShrinkEvaluate[T]): (T^, USize) ? =>
        var shrinkRounds: USize = 0
        var shrunken: T = consume sample
        while true do
            (shrunken, let shrinks: Seq[T])= shrinkable.shrink(consume shrunken)
            if shrinks.size() == 0 then
                break
            else
                shrinkRounds = shrinkRounds + 1
                while shrinks.size() > 0 do
                    let shrinkT: T = shrinks.pop()
                    (let propShrink, let shrinkFailed) = shrinkEvaluate.evaluate(consume shrinkT)
                    if shrinkFailed then
                        shrunken = consume propShrink
                        break // just break out this for loop,
                              // try to shrink the failing example further
                    end
                end
                // all shrinks have been processed, but none of them failed
                break
            end
        end
        (consume shrunken, shrinkRounds)

