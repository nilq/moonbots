# moonbots

![http://www.love2d.org](https://img.shields.io/badge/Love2D-0.10.1-EA316E.svg)

Using
---
Either use the *pre-built* `.love` files in `builds/` or run from source using MoonScript and Love:
```
$ make run
```

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

---

A thing where in artificial life, represented by little creatures equipped with messy neural networks, are *forced* to fight for their *lives* in
a chaos of imaginary blood and predator-prey dynamics.

> May the odds be ever in your favor. - *table 0x1337A21*

---

Based on Andrej Karpathy's *ScriptBots*; rewritten and - in ways - improved by me.
