require "utils/settings"
require "utils/util"
require "utils/vector"

require "agent/dwraon_brain"
require "agent/agent"

require "world/world"

require "lib/deepcopy"

require "lib/ini"

math.randomseed os.time!

lg = love.graphics
lk = love.keyboard

science_mode = true
guides       = true

local view, world

class View
    new: (@world) =>
        @yes_food = true

    -- no science here
    draw_eye: (x, y) =>
        lg.setColor 255, 255, 255
        lg.circle "fill", x, y, 4

        lg.setColor 0, 0, 0
        lg.circle "fill", x, y, 2

    render_scene: =>
        @world\draw @, @yes_food

    draw_food: (x, y, q) =>
        lg.setColor (0.9 - q) * 255, (0.9 - q) * 255, (1 - q) * 255
        lg.rectangle "fill", x * conf.cz - conf.cz, y * conf.cz - conf.cz, conf.cz, conf.cz

    draw_agent: (a) => -- complete mess, might fix ... at some point.
        r = conf.bot_radius

        lg.setColor 255, 255, 0
        lg.circle "fill", a.pos.x, a.pos.y, r

        if science_mode
            -- eyes
            lg.setColor 255 / 2, 255 / 2, 255 / 2

            for j = -3, 3
                if j == 0
                    continue
                lg.line a.pos.x, a.pos.y, a.pos.x + (conf.bot_radius * 4) * (math.cos a.angle + j * math.pi / 8), a.pos.y + (conf.bot_radius * 4) * math.sin a.angle + j * math.pi / 8

            -- eye on back
            lg.line a.pos.x, a.pos.y, a.pos.x + (conf.bot_radius * 1.5) * (math.cos a.angle + math.pi + 3 * math.pi / 16), a.pos.y + (conf.bot_radius * 1.5) * math.sin a.angle + math.pi + 3 * math.pi / 16
            lg.line a.pos.x, a.pos.y, a.pos.x + (conf.bot_radius * 1.5) * (math.cos a.angle + math.pi - 3 * math.pi / 16), a.pos.y + (conf.bot_radius * 1.5) * math.sin a.angle + math.pi - 3 * math.pi / 16

        -- body
        lg.setColor a.color.r * 255, a.color.g * 255, a.color.b * 255
        lg.circle "fill", a.pos.x, a.pos.y, conf.bot_radius

        -- outline
        if a.boost
            lg.setColor 0.8 * 255, 0, 0
        else
            lg.setColor 0, 0, 0

        lg.circle "line", a.pos.x, a.pos.y, r

        -- spike
        lg.setColor 0.5 * 255, 0, 0
        lg.line a.pos.x, a.pos.y, a.pos.x + (3 * r * a.spike_length) * (math.cos a.angle), a.pos.y + (3 * r * a.spike_length) * math.sin a.angle

        -- health
        xo = 18  -- offset x
        yo = -15 -- offset y

        lg.setColor 0, 0.8 * 255, 0
        lg.rectangle "fill", a.pos.x + xo, a.pos.y + yo, 5, 40

        lg.setColor 0, 0, 0
        lg.rectangle "fill", a.pos.x + xo, a.pos.y + yo, 5, 20 * (2 - a.health)

        -- marker: hybrid
        if a.hybrid
            lg.setColor 0, 0, 0.8 * 255
            lg.rectangle "fill", a.pos.x + xo + 6, a.pos.y + yo, 6, 10

        -- "did you just assume my -vore?!"
        lg.setColor (1 - a.herbivore) * 255, a.herbivore * 255, 0
        lg.rectangle "fill", a.pos.x + xo + 6, a.pos.y + yo + 10, 6, 10

        -- marker: loudness
        lg.setColor a.sound_mul * 255, a.sound_mul * 255, a.sound_mul * 255
        lg.rectangle "fill", a.pos.x + xo + 6, a.pos.y + yo + 20, 6, 10

        -- giving/receiving
        if a.dfood != 0
            mag = util.sign (math.abs a.dfood) / conf.food_transfer / 3
            if a.dfood > 0
                lg.setColor 0, mag * 255, 0
            else
                lg.setColor mag * 255, 0, 0

            lg.rectangle "fill", a.pos.x + xo + 6, a.pos.y + yo + 30, 6, 10

        if science_mode
            -- actual readable things: stats
            lg.setColor 0, 0, 0
            -- generation
            lg.print a.gen_count, a.pos.x - conf.bot_radius * 1.5, a.pos.y + conf.bot_radius * 1.8
            -- age
            lg.print a.age, a.pos.x - conf.bot_radius * 1.5, a.pos.y + conf.bot_radius * 1.8 + 12
            -- health
            lg.print (string.format "%.2f", a.health), a.pos.x - conf.bot_radius * 1.5, a.pos.y + conf.bot_radius * 1.8  + 24
            -- reproductions
            lg.print (string.format "%.2f", a.rep_count), a.pos.x - conf.bot_radius * 1.5, a.pos.y + conf.bot_radius * 1.8 + 36
        else
            for j = -3, 3
                if j % 2 == 0
                    continue
                @draw_eye a.pos.x + (conf.bot_radius * 0.95) * (math.cos a.angle + j * math.pi / 8), a.pos.y + (conf.bot_radius * 0.95) * math.sin a.angle + j * math.pi / 8

            if a.sound_mul > 0
                text = "o shit waddup"

                lg.setColor 0, 0, 0
                lg.print text, a.pos.x - (lg.getFont!\getWidth text) / 2, a.pos.y - conf.bot_radius * 3

herb_carn = ->
    h, c = 0, 0
    for i = 1, #world.agents
        if world.agents[i].herbivore >= 0.5
            h += 1
        else
            c += 1
    return h, c

love.load = ->
    world = World!
    view  = View world

love.update = (dt) ->
    conf.width  = lg.getWidth!
    conf.height = lg.getHeight!

    world\update dt

love.draw = ->
    view\render_scene!

    if guides
        lg.setColor 0, 0, 0
        h, c = herb_carn!
        lg.print ("Herbivores: %d\nCarnivores: %d\n\nFPS: %d\n\nEpochs: %d\n\nWorld closed: %s\nRetard mode: %s\n\n[takes time] Press 's' to save agents' brains to clipboard\n[takes time] Press 'l' to load agents' brains from clipboard\n\nPress 't' to toggle alle this text"\format h, c, love.timer.getFPS!, world.epochs, (tostring world.closed), (tostring not science_mode)), 10, 10

love.keypressed = (key) ->
    if key == "space"
        science_mode = not science_mode
    elseif key == "c"
        world.closed = not world.closed
    elseif key == "s"
        love.system.setClipboardText generate world.agents
    elseif key == "l"
        agents = load love.system.getClipboardText!
        world.agents = {}
        for i = 1, #agents
            world\load_bot agents[i]

    elseif key == "t"
        guides = not guides
