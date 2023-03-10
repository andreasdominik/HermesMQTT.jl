# HermesMQTT.jl - Julia package for Snips/Rhasspy skill development

## Julia

The HermesMQTT.jl framework is written in the
modern programming language Julia (because Julia is faster
then Python and coding is much much easier and much more straight forward).
However "Pythonians" often need some time to get familiar with Julia.

If you are ready for the step forward, start here: https://julialang.org/

Learn more about writing skills in Julia with HermesMQTT.jl here: 
 [![](https://img.shields.io/badge/docs-latest-blue.svg)](https://andreasdominik.github.io/HermesMQTT.jl/dev)


## Installation

The package can be installed with the Julia package manager. From the Julia REPL, type ] to enter the Pkg REPL mode and run:

```julia
add git@github.com:andreasdominik/HermesMQTT.jl.git
```

## Skill generation

New skills can be easily created with the `generate_skill()` function
which creates the skeleton of a already working skill with demo code that 
echoes its name (aka *hello world*) and the values of recognised slots.
The skeleton may be used as a starting point for your own skills.

## Skill installation

If a skill is hosted on GitHub, it can be installed with 
the `install_skill(<github-url>)` function from the Julia REPL.
For skills of the author, this is even simpler, as only the 
skill name is needed (i.e. `install_skill("SusiLights")`).

## Available skills

As the framework is set up to enable quick skill development for
everybody, only a small number of prepared skills is available yet:

- SusiLights: control lights (shelly-devices and gpio)
- SusiDateTime: tell the current date or time
- SusiWeekly: program a weekly schedule with profiles  
- SusiScheduler: organise a database of scheduled events (this
  skill is always installed with the framework)
