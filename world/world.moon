export class World
    new: =>
        @fw = conf.width / conf.cz + 1
        @fh = conf.height / conf.cz + 1

        @epochs = 0
        @mod_count = 0
        @id_count = 0

        @agents = {}
        @food   = {}

        @closed = false

        @\add_bots conf.num_bots

        for x = 1, @fw
            a = {}
            for y = 1, @fh
                a[#a + 1] = 0
            @food[#@food + 1] = a

    draw: (view, food) =>
        if food
            for i = 1, @fw
                for j = 1, @fh
                    f = 0.5 * @food[i][j] / conf.food_max
                    view\draw_food i, j, f

        for i = 1, #@agents
            view\draw_agent @agents[i]

    update: =>
        @mod_count += 1

        if @mod_count % 100 == 0
            for i = 1, #@agents
                @agents[i].age += 1

        if @mod_count >= 10000
            @mod_count = 0
            @epochs += 1

        if @mod_count % conf.food_add_freq == 0
            fx = util.randi 1, @fw
            fy = util.randi 1, @fh

            @food[fx][fy] = conf.food_max

        @\set_inputs!
        @\set_brains!

        @\process_output!

        -- health and deaths
        for i = 1, #@agents
            base_loss = 0.0002 + 0.0001 * ((math.abs @agents[i].w1) + (math.abs @agents[i].w2)) / 2

            if @agents[i].w1 < 0.1 and @agents[i].w2 < 0.1
                base_loss = 0.001

            base_loss += 0.00005 * @agents[i].sound_mul

            if @agents[i].boost
                @agents[i].health -= base_loss * conf.boost_size_mult * 2
            else
                @agents[i].health -= base_loss

        -- distribute dead stuff
        for i = 1, #@agents
            if @agents[i].health <= 0

                num_around = 0
                for j = 1, #@agents
                    if j == i
                        continue
                    if @agents[j].health > 0
                        d = (@agents[i].pos - @agents[j].pos)\length!

                        if d < conf.food_distribution_radius
                            num_around += 1

                if num_around > 0
                    -- distribute food of dead agent
                    for j = 1, #@agents
                        if j == i
                            continue
                        d = (@agents[i].pos - @agents[j].pos)\length!

                        if d < conf.food_distribution_radius
                            @agents[j].health += 3 * (1 - @agents[j].herbivore)^2 / num_around
                            @agents[j].rep_count -= 2 * (1 - @agents[j].herbivore)^2 / num_around

                            if @agents[j].health > 2
                                @agents[j].health = 2

                            @agents[j]\init_rate 30, 1, 1, 1 -- white means that an agent has just ate!

        -- remove dead stuff
        for i = 1, #@agents
            if not @agents[i]
                continue -- this is quite weird, yes.
            if @agents[i].health <= 0
                table.remove @agents, i

        -- reproduction
        for i = 1, #@agents
            if @agents[i].rep_count < 0 and @agents[i].health > 0.65
                @\reproduce i, @agents[i].mut_rate1, @agents[i].mut_rate2
                @agents[i].rep_count = @agents[i].herbivore * (util.randf conf.rep_rate_c - 0.1, conf.rep_rate_h + 0.1) + (1 - @agents[i].herbivore) * util.randf conf.rep_rate_c - 0.1, conf.rep_rate_h + 0.1

        for x = 1, @fw
            for y = 1, @fh
                @food[x][y] += conf.food_growth

                if @food[x][y] > conf.food_max
                    @food[x][y] = conf.food_max

        unless @closed
            if #@agents < conf.num_bots
                @\add_bots 1

            if @mod_count % 200 == 0
                if 0.5 > util.randf 0, 1
                    @\add_bots 1
                else
                    @\add_bots_crossover 1

    set_inputs: =>
        -- "Yo look at me, I'm not wasting CPU! <3"
        pi8  = math.pi / 8 / 2
        pi38 = pi8 * 3

        for i = 1, #@agents
            a = @agents[i]
            -- health
            a.inp[11] = util.sign a.health / 2

            -- food
            cx = 1 + math.floor a.pos.x / conf.cz
            cy = 1 + math.floor a.pos.y / conf.cz

            a.inp[4] = @food[cx][cy] / conf.food_max

            -- sound, smell, eyes
            p1, r1, g1, b1 = 0, 0, 0, 0
            p2, r2, g2, b2 = 0, 0, 0, 0
            p3, r3, g3, b3 = 0, 0, 0, 0

            soaccum   = 0
            smaccum   = 0
            hearaccum = 0

            blood = 0

            for j = 1, #@agents
                if i == j
                    continue

                a2 = @agents[j]

                x1 = a.pos.x < a2.pos.x - conf.eye_dist
                x2 = a.pos.x > a2.pos.x + conf.eye_dist

                y1 = a.pos.y > a2.pos.y + conf.eye_dist
                y2 = a.pos.y < a2.pos.y - conf.eye_dist

                if x1 or x2 or y1 or y2
                    continue

                d = (a.pos - a2.pos)\length!

                if d < conf.eye_dist
                    -- smell
                    smaccum += 0.3 * (conf.eye_dist - d) / conf.eye_dist

                    -- sound
                    soaccum += 0.4 * (conf.eye_dist - d) / conf.eye_dist

                    -- hearing
                    hearaccum += a2.sound_mul * (conf.eye_dist - d) / conf.eye_dist

                    ang_tmp = (a2.pos - a.pos)
                    ang = math.atan2 ang_tmp.y, ang_tmp.x -- math much

                    -- left and right eyes - my hacky hack
                    --
                    -- Q: "But, I want four eyed, thousand nosed, one eared bot ..!"
                    -- A: "No!"
                    --

                    l_eye_ang = a.angle - pi8
                    r_eye_ang = a.angle + pi8

                    back_angle = a.angle + math.pi
                    forw_angle = a.angle

                    if l_eye_ang < -math.pi
                        l_eye_ang += 2 * math.pi
                    if r_eye_ang > math.pi
                        r_eye_ang -= 2 * math.pi
                    if back_angle > math.pi
                        back_angle -= 2 * math.pi

                    diff1 = l_eye_ang - ang

                    if math.pi < math.abs diff1
                        diff1 = 2 * math.pi - math.abs diff1

                    diff1 = math.abs diff1

                    diff2 = r_eye_ang - ang

                    if math.pi < math.abs diff2
                        diff2 = 2 * math.pi - math.abs diff2

                    diff2 = math.abs diff2

                    diff3 = back_angle - ang

                    if math.pi < math.abs diff3
                        diff3 = 2 * math.pi - math.abs diff3

                    diff3 = math.abs diff3

                    diff4 = forw_angle - ang

                    if math.pi < math.abs forw_angle
                        diff4 = 2 * math.pi - math.abs forw_angle

                    diff4 = math.abs diff4

                    if diff1 < pi38
                        mul1 = conf.eye_sens *((pi38 - diff1) / pi38) * ((conf.eye_dist - d) / conf.eye_dist)

                        p1 += mul1 * (d / conf.eye_dist)

                        r1 += mul1 * a2.color.r
                        g1 += mul1 * a2.color.g
                        b1 += mul1 * a2.color.b

                    if diff2 < pi38
                        mul2 = conf.eye_sens *((pi38 - diff1) / pi38) * ((conf.eye_dist - d) / conf.eye_dist)

                        p2 += mul2 * (d / conf.eye_dist)

                        r2 += mul2 * a2.color.r
                        g2 += mul2 * a2.color.g
                        b2 += mul2 * a2.color.b

                    if diff3 < pi38
                        mul3 = conf.eye_sens *((pi38 - diff1) / pi38) * ((conf.eye_dist - d) / conf.eye_dist)

                        p3 += mul3 * (d / conf.eye_dist)

                        r3 += mul3 * a2.color.r
                        g3 += mul3 * a2.color.g
                        b3 += mul3 * a2.color.b

                    if diff4 < pi38
                        mul4 = conf.blood_sens *((pi38 - diff1) / pi38) * ((conf.eye_dist - d) / conf.eye_dist)

                        blood += mul4 * (1 - @agents[j].health / 2)

                    a.inp[1] = util.sign p1
                    a.inp[2] = util.sign r1
                    a.inp[3] = util.sign g1
                    a.inp[4] = util.sign b1
                    a.inp[5] = util.sign p2
                    a.inp[6] = util.sign r2
                    a.inp[7] = util.sign g2
                    a.inp[8] = util.sign b2

                    a.inp[9] = util.sign soaccum
                    a.inp[10] = util.sign smaccum

                    a.inp[12] = util.sign p3
                    a.inp[13] = util.sign r3
                    a.inp[14] = util.sign g3
                    a.inp[15] = util.sign b3

                    a.inp[16] = math.abs math.sin @mod_count / a.clock_f1
                    a.inp[17] = math.abs math.sin @mod_count / a.clock_f2

                    a.inp[18] = util.sign hearaccum
                    a.inp[19] = util.sign blood

    process_output: =>
        -- assign meaning
        for i = 1, #@agents
            a = @agents[i]

            a.color.r = a.out[3]
            a.color.g = a.out[4]
            a.color.b = a.out[5]

            a.w1 = a.out[1]
            a.w2 = a.out[2]

            a.boost = a.out[7] > 0.5

            a.sound_mul = a.out[8]
            a.give = a.out[9]

            -- spike stuff
            g = a.out[6]
            if a.spike_length < g
                a.spike_length += conf.spike_speed
            elseif a.spike_length > g
                a.spike_length = g

        for i = 1, #@agents
            a = @agents[i]

            off_w1 = Vector conf.bot_radius * (math.cos a.angle + -math.pi / 4), conf.bot_radius * math.sin a.angle + -math.pi / 4
            off_w2 = Vector conf.bot_radius * (math.cos a.angle + math.pi / 4), conf.bot_radius * math.sin a.angle + math.pi / 4

            w1p = a.pos + off_w1
            w2p = a.pos + off_w2

            -- "boost wheel 1", "boost wheel 2" ... for general speed
            bw1 = conf.bot_speed * a.w1 -- w1: speed of wheel one
            bw2 = conf.bot_speed * a.w2 -- w2: ... of wheel two

            if a.boost -- when boosting apply boost to general speed
                bw1 *= conf.boost_size_mult
                bw2 *= conf.boost_size_mult
                -- rotate by speed?

            vv1 =  Vector bw1 * (math.cos math.atan2 w1p.y - a.pos.y, w1p.x - a.pos.x), bw1 * math.sin math.atan2 w1p.y - a.pos.y, w1p.x - a.pos.x
            vv2 = Vector bw2 * (math.cos math.atan2 w2p.y - a.pos.y, w2p.x - a.pos.x), bw2 * math.sin math.atan2 w2p.y - a.pos.y, w2p.x - a.pos.x

            a.angle = math.atan2 (vv1 + vv2).y, (vv1 + vv2).x

            a.pos += vv1
            a.pos += vv2

            a.pos.x %= conf.width
            a.pos.y %= conf.height

        for i = 1, #@agents

            cx = 1 + math.floor @agents[i].pos.x / conf.cz
            cy = 1 + math.floor @agents[i].pos.y / conf.cz

            f = @food[cx][cy]

            if f > 0 and @agents[i].health < 2
                -- eat food
                itk = math.min f, conf.food_intake
                speed_mul = (1 - (math.abs @agents[i].w1 + math.abs @agents[i].w2) / 2) / 2 + 0.5

                -- herbivores gain more from vegetables(ground food)
                itk *= @agents[i].herbivore * @agents[i].herbivore * speed_mul

                @agents[i].health += itk
                @agents[i].rep_count -= 3 * itk

                @food[cx][cy] -= math.min f, conf.food_waste

        for i = 1, #@agents
            @agents[i].dfood = 0

        for i = 1, #@agents
            if @agents[i].give > 0.5
                for j = 1, #@agents
                    d = (@agents[i].pos - @agents[j].pos)\length!

                    if d < conf.food_share_dist
                        if @agents[j].health < 2
                            @agents[j].health += conf.food_transfer

                        @agents[i].health -= conf.food_transfer
                        @agents[j].dfood += conf.food_transfer
                        @agents[i].dfood -= conf.food_transfer

        if @mod_count % 2 == 0
            for i = 1, #@agents
                for j = 1, #@agents
                    if i == j or @agents[i].spike_length < 0.2 or @agents[i].w1 < 0.3 or @agents[i].w2 < 0.3
                        continue

                    d = (@agents[i].pos - @agents[j].pos)\length!

                    if d < 2 * conf.bot_radius
                        v = Vector 1, 0
                        v\rotate @agents[i].angle

                        diff = v\angle_between @agents[j].pos - @agents[i].pos

                        if math.pi / 8 > math.abs diff
                            mult = 1

                            if @agents[i].boost
                                mult = conf.boost_size_mult

                            dmg = conf.spike_mult * @agents[i].spike_length * conf.boost_size_mult * math.max (math.abs @agents[i].w1), math.abs @agents[i].w2

                            print dmg

                            @agents[j].health -= dmg

                            if @agents[i].health > 2
                                @agents[i].health = 2

                            @agents[i].spike_length = 0

                            @agents[i]\init_rate 40 * dmg, 1, 1, 0

                            v2 = Vector 1, 0
                            v2\rotate @agents[j].angle

                            diff = v\angle_between v2

                            if math.pi / 2 > math.abs diff
                                @agents[j].spike_length = 0

    set_brains: =>
        for i = 1, #@agents
            @agents[i]\tick!

    reproduce: (ai, mr, mr2) =>
        if 0.04 > util.randf 0, 1
            mr *= util.randf 1, 10
        if 0.04 > util.randf 0, 1
            mr2 *= util.randf 1, 10

        @agents[ai]\init_rate 30, 0, 0.8, 0 -- agent reproduced: green

        for i = 1, conf.babies
            a = @agents[ai]\reproduce mr, mr2
            a.id = @id_count
            @id_count += 1

            @agents[#@agents + 1] = a -- baby

    reset: =>
        @agents = {}
        add_bots conf.num_bots

    add_bots: (n) =>
        for i = 1, n
            a = Agent!
            a.id = @id_count
            @id_count += 1

            @agents[#@agents + 1] = a

    load_bot: (agent) =>
        a = Agent!

        a.id = agent.id

        a.brain = agent.brain

        a.herbivore = agent.herbivore

        a.hybrid = agent.hybrid

        a.age = agent.age

        a.gen_count = agent.gen_count
        a.rep_count = agent.rep_count

        a.pos = agent.pos

        a.clock_f1 = agent.clock_f1
        a.clock_f2 = agent.clock_f2

        a.mut_rate1 = agent.mut_rate1
        a.mut_rate2 = agent.mut_rate2

        a.w1 = agent.w1
        a.w2 = agent.w2

        @agents[#@agents + 1] = a

    add_bots_crossover: (n) =>
        for i = 1, n
            i1 = util.randi 1, #@agents
            i2 = util.randi 1, #@agents

            for j = 1, #@agents
                if @agents[j].age > @agents[i1].age and 0.1 > util.randf 0, 1
                    i1 = j
                if @agents[j].age > @agents[i2].age and j != i1 and 0.1 > util.randf 0, 1
                    i2 = j

            a1 = @agents[i1]
            a2 = @agents[i2]

            a_new = a1\crossover a2

            a_new.id = @id_count
            @id_count += 1

            @agents[#@agents + 1] = a_new
