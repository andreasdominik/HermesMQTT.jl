# HermesMQTT

This is a "quick-and-Dirty" framework for Snips.ai-style home assistants 
(such as *Rhasspy*)
written in Julia.
I comes with generator script
which can be used as starting point for own skills.

To learn about Snips, goto [snips.ai](https://docs.snips.ai/reference/).    
To learn about Rhasspy, goto 
[rhasspy](https://rhasspy.readthedocs.io/en/latest/).       
To get introduced with Julia, see [julialang.org](https://julialang.org/).


## Similarities and differences to the Hermes dialogue manager

The framework allows for setting up skills/apps the same way as
with the Python libraries. However, according to the more functional
programming style in Julia, more direct interactions are provided
and
technical stuff (such as siteId, sessionId, callback-functions, etc.)
are handled transparently by the framework in the background.

As an example, the function `listenIntentsOneTime()` can be used
without a callback-function. Recognised intent and payload
are returned as function value.

On top of `listenIntentsOneTime()`, SnipsHermesQnD comes with
a simple question/answer methods to
ask questions answered with *Yes* or *No*
(`ask_yes_or_no()` and `ask_yes_or_no_or_unknown()`).
As a result, it is possible to get a quick user-feedback without leaving
the control flow of a function.
