# moonbots

![http://www.love2d.org](https://img.shields.io/badge/Love2D-0.10.1-EA316E.svg)

---

A thing where in artificial life, represented by little creatures equipped with messy neural networks, are *forced* to fight for their *lives* in
a chaos of imaginary blood and predator-prey dynamics.

> May the odds be ever in your favor. - *table 0x1337A21*

---

Using
---
Either use the *pre-built* `.love` files in `builds/` or run from source using MoonScript and Love:
```
$ make run
```
---

Controls
---
The agents behave and do stuff themselves ... though:

```
SPACE : toggle *science view*; draw eyes and text rather than colors, numbers and lines.
C     : close world; no angents will be added per *x* iterations neither randomly nor by crossover.
S     : save generations; an *ini-file* containing all agents' - of the current iteration - data to clipboard (this might take a little while).
L     : load generations; loads saved agents from clipboard as *ini-file*.
T     : toggle kinda annoying text guides.
```

Anatomy of a *Bot*(aka. *Agent*)
---

An agent has four *eyes* on the front and two *eyes* on the back for sensing other agents; this is done through color. Also agents can sense *blood*, smell and sound, in the nearby area.

- color: the color of an agent.
- blood: the health of the agent.
- smell: basically a decayed distance to the agent.
- sound: a scalar of the sound emitted by the agent.

All this input along with two *clocks* on different frequencies, add up to 19 input elements that are fed to a *recurrent and/or neural network* or rather, a *DWRAON*(damp weighted recurrent and/or network) based brain with about 30 hidden neurons all with three connecting synapses.

The agent reacts to the input through movement(wheel speeds), sound emission, spike length, boosting, color and distribution of food.

- movement: an agent moves based on two wheels placed on the back right and -left side of the agent(not visualized) that makes up the final movement vector through *atan2* to the coordinates of the middle of the agent. (this could've been done better)

- sound: an agent can emit *sound* (visualized by the row before bottom most, right to the green/black health bar), giving the agent a way to communicate with nearby agents.

- spike length: an agent has a spike which it can use to kill other agents, by running into them with a decent speed.

- boosting: an agent can double its speed by boosting - also causes it to spend more food.

- color: basically the color of the agent as visualized on its body - this is also a potential way for the agent to express itself to nearby agents (also potential camouflage ...).

- distribution of food: a decently healthy agent can donate food to nearby agents (visualized by the bottom most row right to the health bar being brown-ish).

When an agent's reproduction-meter reaches zero (decreases when eating food) it makes a clone of itself whose brain is slightly mutated (by a given probability).

> Unless the world is *closed* agents will be added when population gets below 30. Also on a given interval, the world will choose healthy, old agents which to use to make a crossover agent; a hybrud that is a mix of the two (visualized by top-most row being blue).

...

On every 60th iteration a random food field is filled (food is visualized by gray squares).

When an agent dies some food will be distributed to agents in the nearby area - if anyone's there.

###TL;DR

Agents have a green health bar to the right, blue rectangle if hybrid, underneath a red, brown or green rectangle depending on how much carnivore to herbivore the agent is. An agent has eyes. Agents kill each other with a red thing which is extended through the fron of their *body*.

---

Based on Andrej Karpathy's *ScriptBots*; rewritten and - in ways - improved by me.
