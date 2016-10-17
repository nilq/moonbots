export *

INPUT_SIZE  = 20
OUTPUT_SIZE = 9
CONNS       = 3
BRAIN_SIZE  = 100

----------------------------------
-- DWRAON: Damped Weighted Recurrent AND/OR Network
----------------------------------
class DWRAONBrain
    new: =>
        @boxes = {}

        for i = 1, BRAIN_SIZE
            a = Box!

            @boxes[#@boxes + 1] = a

            for j = 1, CONNS
                if 0.05 > util.randf 0, 1
                    a.id[j] = 1
                if 0.05 > util.randf 0, 1
                    a.id[j] = 5
                if 0.05 > util.randf 0, 1
                    a.id[j] = 12
                if 0.05 > util.randf 0, 1
                    a.id[j] = 4

                if i < BRAIN_SIZE / 2
                    a.id[j] = util.randi 1, INPUT_SIZE

    @from_brain: (other) =>
        brain = DWRAONBrain!
        brain.boxes = {table.unpack other.boxes}
        brain

    tick: (inp, out) =>
        for i = 1, INPUT_SIZE
            @boxes[i].out = inp[i]

        for i = INPUT_SIZE, BRAIN_SIZE
            a = @boxes[i]

            if a.type == 0 -- and
                res = 1

                for j = 1, CONNS
                    idx = a.id[j]
                    val = @boxes[idx].out

                    if a.notted[j]
                        val = 1 - val

                    res *= val

                res *= a.bias
                a.target = res

            else -- or
                res = 0

                for j = 1, CONNS
                    idx = a.id[j]
                    val = @boxes[idx].out

                    if a.notted[j]
                        val = 1 - val

                    res += val * a.w[j]

                res += a.bias
                a.target = res

            -- sigmoid plz?
            if a.target < 0
                a.target = 0
            elseif a.target > 1
                a.target = 1

        for i = INPUT_SIZE, BRAIN_SIZE
            a = @boxes[i]
            a.out += (a.target - a.out) * a.kp

        for i = 1, OUTPUT_SIZE
            out[i] = @boxes[BRAIN_SIZE - i].out

    mutate: (mr, mr2) =>
        for i = 0, BRAIN_SIZE

            if mr * 3 > util.randf 0, 1
                @boxes[i].bias += util.randn 0, mr2

            if mr * 3 > util.randf 0, 1
                rc = util.randi 1, CONNS

                @boxes[i].w[rc] += util.randn 0, mr2
                if @boxes[i].w[rc] > 0.01
                    @boxes[i].w[rc] = 0.01

            if mr > util.randf 0, 1
                rc = util.randi 1, CONNS
                ri = util.randi 1, BRAIN_SIZE

                @boxes[i].id[rc] = ri

            if mr > util.randf 0, 1
                rc = util.randi 1, CONNS

                @boxes[i].notted[rc] = not @boxes[i].notted[rc]

            if mr > util.randf 0, 1
                @boxes[i].type = 1 - @boxes[i].type

    crossover: (other) =>
        new_brain = DWRAONBrain\from_brain @

        for i = 1, #new_brain.boxes

            new_brain.boxes[i].bias = other.boxes[i].bias
            new_brain.boxes[i].kp = other.boxes[i].kp
            new_brain.boxes[i].type = other.boxes[i].type

            if 0.5 > util.randf 0, 1
                new_brain.boxes[i].bias = @boxes[i].bias
            if 0.5 > util.randf 0, 1
                new_brain.boxes[i].kp = @boxes[i].kp
            if 0.5 > util.randf 0, 1
                new_brain.boxes[i].type = @boxes[i].type

            for j = 1, #new_brain.boxes[i].id

                new_brain.boxes[i].id[j] = other.boxes[i].id[j]
                new_brain.boxes[i].notted[j] = other.boxes[i].notted[j]
                new_brain.boxes[i].w[j] = other.boxes[i].w[j]

                if 0.5 > util.randf 0, 1
                    new_brain.boxes[i].id[j] = @boxes[i].id[j]
                if 0.5 > util.randf 0, 1
                    new_brain.boxes[i].notted[j] = @boxes[i].notted[j]
                if 0.5 > util.randf 0, 1
                    new_brain.boxes[i].w[j] = @boxes[i].w[j]

        new_brain

class Box
    new: =>
        -- and/or
        @type = 0
        if 0.5 > util.randf 0, 1
            @type = 1


        @kp = util.randf 0.8, 1 -- damping stength

        @w = {}
        @id = {} -- connected box index
        @notted = {} -- notted connected

        for i = 1, CONNS
            @w[i]  = util.randf 0.1, 2
            @id[i] = util.randi 1, BRAIN_SIZE

            if 0.2 > util.randf 0, 1
                @id[i] = util.randi 1, INPUT_SIZE

            @notted[i] = 0.5 > util.randf 0, 1

        @bias = util.randf -1, 1

        @target = 0
        @out = 0
