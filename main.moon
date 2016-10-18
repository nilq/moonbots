require "utils/settings"
require "utils/util"
require "utils/vector"

require "agent/dwraon_brain"
require "agent/agent"

require "world/world"

require "lib/deepcopy"

math.randomseed os.time!

lg = love.graphics
lk = love.keyboard

local view, world

class View
    new: (@world) =>
        @yes_food = true

    render_scene: =>
        @world\draw @, @yes_food

    draw_food: (x, y, q) =>
        lg.setColor (0.9 - q) * 255, (0.9 - q) * 255, (1 - q) * 255
        lg.rectangle "fill", x * conf.cz - conf.cz, y * conf.cz - conf.cz, conf.cz, conf.cz

    draw_agent: (a) => -- complete mess, might fix ... at some point.
        r = conf.bot_radius

        lg.setColor 255, 255, 0
        lg.circle "fill", a.pos.x, a.pos.y, r

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

love.load = ->
    world = World!
    view  = View world

love.update = (dt) ->
    conf.width  = lg.getWidth!
    conf.height = lg.getHeight!

    world\update dt

    love.window.setTitle (string.format "Average Delta: %.7fs", love.timer.getAverageDelta!), 10, 10

love.draw = ->
    view\render_scene!
