export class Vector
    new: (@x, @y = @x) =>

    length_squared: =>
        @x^2 + @y^2

    length: =>
        math.sqrt @x^2 + @y^2

    inverted: =>
        x, y = 0, 0

        unless @x == 0
            x = 1 / @x

        unless @y == 0
            y = 1 / @y

        (Vector x, y)

    invert: =>
        unless @x == 0
            @x = 1 / @x

        unless @y == 0
            @y = 1 / @y
        @

    angle_between: (b) =>
        cross = @x * b.y - @y * b.x
        dot   = @x * b.x + @y * b.y

        (math.atan2 cross, dot)

    rotate: (a) =>
        @x = @x * (math.cos a) - @y * math.sin a
        @y = @x * (math.sin a) - @y * math.cos a

    @vectorify: (a) =>
        a.__sub = (@, other) ->
            return Vector @x - other.x, @y - other.y

        a.__add = (@, other) ->
            return Vector @x + other.x, @y + other.y

        a.__div = (@, other) ->
            if "number" == type other
                return Vector @x / other, @y / other
            else
                return Vector @x / other.x, @y / other.y

        a.__mul = (@, other) ->
            if "number" == type other
                return Vector @x * other, @y * other
            else
                return Vector @x * other.x, @y * other.y

        a.__unm = ->
            return Vector -@x, -@y

        a.__eq = (@, other) ->
            return @x == other.x and @y == other.y

        a.__tostring = ->
            return "Vector(#{@x}, #{@y})"
        a

    @top: =>
        (Vector 0, -1)

    @bottom: =>
        (Vector 0, 1)

    @left: =>
        (Vector -1, 0)

    @right: =>
        (Vector 1, 0)

    __sub: (other) =>
        return Vector @x - other.x, @y - other.y

    __add: (other) =>
        return Vector @x + other.x, @y + other.y

    __div: (other) =>
        if "number" == type other
            return Vector @x / other, @y / other
        else
            return Vector @x / other.x, @y / other.y

    __mul: (other) =>
        if "number" == type other
            return Vector @x * other, @y * other
        else
            return Vector @x * other.x, @y * other.y

    __unm: =>
        return Vector -@x, -@y

    __eq: (other) =>
        return @x == other.x and @y == other.y

    __tostring: =>
        return "Vector(#{@x}, #{@y})"
