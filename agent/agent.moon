export class Agent
    new: =>
        @pos = Vector (util.randf 0, conf.width), (util.randf 0, conf.height)
        @angle = util.randf -math.pi, math.pi

        @health = 1 + util.randf 0, 0.1
        @age = 0

        @spike_length = 0

        @color = {
            r: util.randf 0, 255,
            g: util.randf 0, 255,
            b: util.randf 0, 255,
        }

        @dfood = 0

        @w1 = 0
        @w2 = 0

        @sound_mul = 1

        @clock_f1 = util.randf 5, 100
        @clock_f2 = util.randf 5, 100

        @boost = false

        @indicator = 0
        @gen_count = 0

        @select_flag = 0

        @i_color = {
            r: 0,
            g: 0,
            b: 0,
        }

        @hybrid = false
        @herbivore = util.randf 0, 1

        @rep_count = @herbivore * (util.randf conf.rep_rate_c - 0.1, conf.rep_rate_h + 0.1) + (1 - @herbivore) * util.randf conf.rep_rate_c - 0.1, conf.rep_rate_h + 0.1

        @id = 0

        @mut_rate1 = 0.003
        @mut_rate2 = 0.05

        @give = 0

        @brain = DWRAONBrain!

        @out = {}
        for i = 1, OUTPUT_SIZE
            @out[i] = 0

        @inp  = {}
        for i = 1, INPUT_SIZE
            @inp[i] = 0

    print_self: =>
        print "Agent->age=#{@age}"

    init_rate: (size, r, g, b) =>
        @color = {
            :r,
            :g,
            :b,
        }

    reproduce: (mr, mr2) =>
        a2 = Agent!

        -- spawn baby behind current
        off = Vector conf.bot_radius, 0
        off *= Vector (math.cos a2.angle), math.sin a2.angle

        a2.pos = @pos + off + (Vector (util.randf -conf.bot_radius * 2, conf.bot_radius * 2), util.randf -conf.bot_radius * 2, conf.bot_radius * 2)

        a2.pos.x %= conf.width
        a2.pos.y %= conf.height

        a2.gen_count = @gen_count + 1
        a2.rep_count = a2.herbivore * (util.randf conf.rep_rate_c - 0.1, conf.rep_rate_h + 0.1) + (1 - @herbivore) * util.randf conf.rep_rate_c - 0.1, conf.rep_rate_h + 0.1

        -- bad attribute passing
        a2.mut_rate1 = @mut_rate1
        a2.mut_rate2 = @mut_rate2

        if 0.2 > util.randf 0, 1
            a2.mut_rate1 = util.randn @mut_rate1, conf.meta_mutation1
        if 0.2 > util.randf 0, 1
            a2.mut_rate2 = util.randn @mut_rate2, conf.meta_mutation2

        if @mut_rate1 < 0.001
            @mut_rate1 = 0.001
        if @mut_rate2 < 0.02
            @mut_rate2 = 0.02

        a2.herbivore = util.sign @herbivore, mr2 * 4

        if mr * 5 > util.randf 0, 1
            a2.clock_f1 = util.randn a2.clock_f1, mr2
        if mr * 5 > util.randf 0, 1
            a2.clock_f2 = util.randn a2.clock_f2, mr2

        if a2.clock_f1 < 2
            a2.clock_f1 = 2
        if a2.clock_f2 < 2
            a2.clock_f2 = 2

        a2.brain = DWRAONBrain\from_brain @brain
        a2.brain\mutate mr, mr2

        a2

    crossover: (other) =>
        a_new = Agent!

        a_new.hybrid = true
        a_new.gen_count = @gen_count

        if other.gen_count < a_new.gen_count
            a_new.gen_count = other.gen_count

        a_new.clock_f1 = other.clock_f1
        a_new.clock_f2 = other.clock_f2

        a_new.herbivore = other.herbivore

        a_new.mut_rate1 = other.mut_rate1
        a_new.mut_rate2 = other.mut_rate2

        if 0.5 > util.randf 0, 1
            a_new.clock_f1 = @clock_f1
        if 0.5 > util.randf 0, 1
            a_new.clock_f2 = @clock_f2
        if 0.5 > util.randf 0, 1
            a_new.herbivore = @herbivore
        if 0.5 > util.randf 0, 1
            a_new.mut_rate1 = @mut_rate1
        if 0.5 > util.randf 0, 1
            a_new.mut_rate2 = @mut_rate2

        a_new.brain = @brain\crossover other.brain

        a_new

    tick: =>
        @brain\tick @inp, @out
