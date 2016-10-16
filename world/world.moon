export class World
    new: =>
        @fw = conf.width / conf.cz
        @fh = conf.height / conf.cz

        @epochs = 0
        @mod_count = 0
        @id_count = 0

        @agents = {}
        @food   = {}

        @closed = false

        add_bots conf.num_bots

        for x = 0, @fw
            for y = 0, @fh
                food[x][y] = 0

    update: (dt) =>
        @mod_count += 1

        if @mod_count % 100 == 0
            for i = 1, #@agents
                @agents[i].age += 1

        if @mod_count >= 10000
            @mod_count = 0
            @epochs += 1

        if @mod_count % conf.food_add_freq
            fx = util.randi 0, fw
            fy = util.randi 0, fh

            food[fx][fy] = conf.food_max

        set_inputs!
        set_brains!

        process_output!

        -- health and deaths
        for i = 1, #@agents
            base_loss = 0.0002 + 0.0001 * (math.abs @agents[i].w1) + (math.abs @agents[i].w2) / 2

            if @agents[i].w1 < 0.1 and @agents[i].w2 < 0.1
                base_loss = 0.0001

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
                    if @agents[j].health > 0
                        d = (@agents[i].pos - @agents[j].pos)\length!

                        if d < conf.food_distribution_radius
                            num_around += 1

                if num_around > 0
                    -- distribute food of dead agent
                    for j = 1, #@agents
                        d = (@agents[i].pos - agents[j].pos)\length!

                        if d < conf.food_distribution_radius
                            @agents[j].health += 3 * (1 - @agents[j].herbivore) * (1 - @agents[j].herbivore) / num_around
                            @agents[j].rep_count -= 2 *(1 - @agents[j].herbivore) * (1 - @agents[j].herbivore) / num_around

                            if @agents[j].health > 2
                                @agents[j].health = 2

                            @agents[j]\init_rate 30, 1, 1, 1 -- white means that an agent has just ate!

        -- remove dead stuff
        for i = 1, #@agents
            if @agents[i].health <= 0
                table.remove @agents, i

        -- reproduction
        for i = 1, #@agents
            if @agents[i].rep_count < 0 and @agents[i].health > 0.65
                @\reproduce i, @agents[i].mut_rate1, @agents[i].mut_rate2
                @agents[i].rep_count = @agents[i].herbivore * (util.randf conf.rep_rate_c - 0.1, conf.rep_rate_h + 0.1) + (1 - @herbivore) * util.randf conf.rep_rate_c - 0.1, conf.rep_rate_h + 0.1

        for x = 0, @fw
            for y = 0, @fh
                @food[x][y] += conf.food_growth

                if @food[x][y] > conf.food_max
                    food[x][y] = conf.food_max

        unless @closed
            if #@agents < conf.num_bots
                add_bots 1

            if mod_count % 200 == 0
                if 0.5 > util.randf 0, 1
                    add_bots 1
                else
                    add_bots_crossover 1

    set_inputs: =>
        -- "Yo look at me, I'm not wasting memory! <3"
        pi8  = math.pi / 8 / 2
        pi38 = pi8 * 3

        for i = 1, #@agents
            a = @agents[i]
            -- health
            a.in[11] = util.sign a.health / 2

            -- food
            cx = a.pos.x / conf.cz
            cy = a.pos.y / conf.cz

            a.in[4] = @food[cx][cy] / conf.food_max

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


    add_bots: (n) =>
        for i = 1, n
            a = Agent!
            a.id = @id_count
            @id_count += 1

            @agents[#agents + 1] = a

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
