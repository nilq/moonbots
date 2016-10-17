require "utils/settings"
require "utils/util"
require "utils/vector"

require "agent/dwraon_brain"
require "agent/agent"

require "world/world"

require "lib/deepcopy"

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

    draw_agent: (a) =>
        r = conf.bot_radius

        lg.setColor 255, 255, 0
        lg.circle "fill", a.pos.x, a.pos.y, r

love.load = ->
    world = World!
    view  = View world

love.update = ->
    world\update!

love.draw = ->
    view\render_scene!
