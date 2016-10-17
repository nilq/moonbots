require "utils/settings"
require "utils/util"
require "utils/vector"

require "agent/dwraon_brain"
require "agent/agent"

require "world/world"

a = Agent!
w = World!

print "#agents:", #w.agents

w\process_output!
