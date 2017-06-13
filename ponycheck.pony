use "time"

actor Main
    new create(env: Env) =>
        env.out.print("ponycheck")
        env.out.print((U8.max_value() + 1).string())
        let gen = Generators.i8(I8(-5), I8(21)).map[I32]({(i: I8): I32 => I32(i.i32()-1)})
        let rnd = Randomness(U64(Time.millis()))
        let si: String iso = recover
            let s = String.create(3)
            s.append("abc")
            s
        end
        let static: Generator[String tag] = Generators.unit[String iso](consume si)
        let sg: String tag = static.generate(rnd)
        env.out.print("STATIC: " + (static.generate(rnd) is "abc").string())
        env.out.print("STATIC: " + (static.generate(rnd) is "").string())
        let mapped = static.map[Bool]({(s: String tag): Bool => (s is s)})
        env.out.print("MAPPED: " + mapped.generate(rnd).string())
        let filtered = gen.filter({(i: I32): (I32, Bool) => (i, (i%2) == 0) })
        env.out.print(gen.generate(rnd).string())
        env.out.print(filtered.generate(rnd).string())
        env.out.print(filtered.generate(rnd).string())
        env.out.print(filtered.generate(rnd).string())
        env.out.print(filtered.generate(rnd).string())
        

        let static2 = Generators.unit[(I32, String)]((I32(-1), "foo"))
