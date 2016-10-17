export conf = {
    -- window dimensions
    width: 600,
    height: 600,

    -- cell size in pixels, e.g. food squares
    cz: 50,

    -- initial/minimum population
    num_bots: 30,

    -- for visualization
    bot_radius: 10,
    bot_speed: 0.5,

    -- how quickly attack spike extends
    spike_speed: 0.05,
    -- strength of attack spike on impact
    spike_mult: 0.5,

    -- number of babies per agent
    babies: 2,

    -- speed scalar on boost
    boost_size_mult: 2,

    -- reproduction rate: herbivore/carnivore
    rep_rate_h: 7,
    rep_rate_c: 7,

    -- how far an agent can see
    eye_dist: 150,
    eye_sens: 2,

    -- sensitivity of blood sensors
    blood_sens: 2,

    -- change of mutation on reproduction
    meta_mutation1: 0.002,
    meta_mutation2: 0.05,

    -- how quickly food grows
    food_growth: 0.00001,
    -- how much food an agent consumes
    food_intake: 0.00325,
    -- how much food an agent wastes when eating
    food_waste: 0.001,
    -- max food on a cell
    food_max: 0.5,

    -- how often a food cell is filled : seconds
    food_add_freq: 30,

    -- how much food can be shared between agents
    food_transfer: 0.001,
    -- maximum distance between food sharing agents
    food_share_dist: 50,

    -- radius of area in which food is dead body is distributed on death
    food_distribution_radius: 100,
}
