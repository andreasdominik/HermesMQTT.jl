# Some details

## Strategy

The idea behind the framework is to put as much as possible in the background,
so that a developer only needs to provide the code for the
functions executed for an intent.

The MQTT-messages of *Hermes* and the *Dialogue Manager* are wrapped and
additional interfaces to *Hermes* are provided to enable direct
dialogues without using callbacks.

In addion background information, such as current session-ID or
current site-ID, are handled in the background and are not exposed to a skill
developer.

Additional utilities are provided to
- read values from intent slots,
- read values from `config.ini`,
- write apps for more then one language,
- get an answer form the NLU back as function value in the
  control flow of a function,
- use a global intent for switching a device on or off,
- let the assistant ask a question and get "yes" or "no" back as boolean value,
- let the assistant continue a conversation without the need to utter the,
  hotword again,
- execute actions of other skills by submitting system triggers.


## Reduce false activations of intents by using the same intent for on/off

The on/off-intent, integrated with the SnipsHermesQnD framework, allows for
writing apps to power up or down devices, without the need to create a new
intent for every device.

Background: All home assistants run into problems when many intents are
responsible to switch on or off a device. Obviously all these intends
are very similar and reliable detection of the correct intent is not easy.

HermesMQTT tries to work around this issue, by using only one intent
for all on/off-commands.

All supported devices are listed in the slot `device` of the intent
`Snips:OnOff<EN/DE>` and defined in the slot type `device_type`.

The skill part of `HermesMQTT` has some code behind to handle unrecognised
devises. The associated `config.ini` defines the list of devices handled
by skills in your assistant.
Any device that is not in this list, will be ignored; 
i.e. the framework will
end the respective Snips:OnOff-session without any action immediately.

If you want to use the intent to swich an additional device on or off
- firstly look in the intent `Snips:OnOff<EN/DE>` if the device
  is already defined in the slot type `device_type`. If not,
  you will have to
  add a new device to the values
  of the slot type `device_type`.
- secondly the new device must be added to the list of devices in the
  `config.ini` of the framework (`HermesMQTT/config.ini`). Add the
  name to the comma-separated list of devices in the parameter
  `on_off_devices`.

The framework comes with a function 
`is_on_off-matched(payload, DEVICE_NAME)`
which can be called with the current payload and the name (and
optionally with the siteId) of the device of interest.
It will return one of
- `:on`, if an "ON" is recognised for the device
- `:off`, if an "OFF" is recognised for the device
- `:matched`, if the device is recognised but no specific on or off
- `:unmatched`, if the device is not recognised.

The tutorial shows a simple example how to use this functionality.



## Reduce false activations of intents by doublechecking commands

Intents with simple commands or without slots are sometimes recognised
by Snips with high confidence, even if only parts of the command
matches. This is because Snips tries to find the best matching
intent for every uttered command.

The HermesMQTT-framework provides a mechanism to cancel intents, recognised
by the NLU, by double-checking against ordered lists of words that
must be present in a command to be valid.

This is configured in the `config.ini` with optional 
parameters of the form:

- `<intentname>:must_include:<description>=<list of words>`
- `<intentname>:must_chain:<description>=<list of words>`
- `<intentname>:must_span:<description>=<list of words>`

Examples:
- `switchOnOff:must_include:1=on,light`
- `switchOnOff:must_include:rev=light,on`
- `switchOnOff:must_include:with_regex=(light|bulb),on`

Several lines of colon-separated parts are possible:
- the first part is the intent name (because one `config.ini` is responsible for all intents of a skill)
- the second part must be exactly one of the phrases `must_include`,
  `must_chain` or `must_span`.
- the last part of the parameter name can be used as a description and
  is necessary to make all parameter lines unique
- the parameter value is a comma-separated list of words or regular expressions.

For `must_include` each uttered command must include all words.

For `must_chain` each uttered command must include all words
and the words must be in the given order.

For `must_span` each uttered command must include all words
and the words must be in the correct order
and they must span the complete command; i.e. the first word in the list
must be the first word of the command and the last must be the last one.

The framework performs this doublecheck before an action is started. If the
check fails the session is ended silently.


## Reduce false activations of intents by disabling intents

The skill `DoNotListen` with the intents `Snips:DoNotListen<DE/EN>` and
`Snips:ListenAgain<DE/EN>` can be used to temporarily disable intents.

The intents themself use strict doublechecking (see section above) to
make sure, that only very specific commands are recognised.

In addition, the skill can subscripe to MQTT topics containing triggers.
Triggers can be
published by the API-functions `publish_listen_trigger(:stop)`
and `publish_listenTrigger(:start)` by other apps.
This way it is possible to programically disable intents as part of an
intent that starts to make *background noise* (like `watchTVshow`) and
enable them again later.



## Ask and answer Yes-or-No

An often needed functionality is a quick confirmation feedback
of the user. This is provided by the framework function `ask_yes_or_no(question)`.

See the following self-exlpaining code as example:

```Julia
"""
    destroy_action(topic, payload)

Initialise self-destruction.
"""
function destroy_action(topic, payload)

  # log message:
  print_log("[Snips:DestroyYourself]: action destroy_action() started.")

  if ask_yes_or_no("Do you really want to initiate self-destruction?")
    publishEndSession("Self-destruction sequence started!")
    boom()  # call implementaion
  else
    publishEndSession("""OK.
                      Self-destruction sequence is aborted!
                      Live long and in peace.""")
  end

  return true
end
```

The intent to capture the user response comes with the framework and
is activated just for this dialogue.


## Continue conversation without hotword

Sometimes it is necessary to control a device with a sequence of several
comands. In this case it is not natural to speak the hotword everytime.
like:

> *hey Snips*
>
> *switch on the light*
>
> *hey Snips*
>
> *dim the light*
>
> *hey Snips*
>
> *dim the light again*
>
> *hey Snips*
>
> *dim the light again*    

Instead, we want something like:

> *hey Snips*
>
> *switch on the light*
>
> *dim the light*
>
> *dim the light again*
>
> *dim the light again*    


This can be achieved by starting a new session just after an intent is processed.
In the HermesMQTT framework this is controlled by two mechanisms:

The `config.jl` defines a constant `const CONTINUE_WO_HOTWORD = false`.
`false` is the default and hence continuation without hotword is disabled
by default. To completely disable it for your skill, just set the constant
to `false`.    
The second mechanism is the return value of every single skill-action.
A new session will only be started if both are true, the
constant `CONTINUE_WO_HOTWORD` and the return value of the function.
This way it is possible to decide for each action individually, if
a hotword is required for the next command.


## Multi-language support

Multi-language skills need to be able to switch between laguages.
In the context of Snips this requires special handling in two cases:
- All text, uttered by the assistant must be defined in all languages.
- An intent is always tied to one language. Therefore for multi-language
  skills similar intents (with the same slots) must be created for each supported language.

Multi-language support ist added in 4 steps:

### 1) Define language in config.ini:

The `config.ini` must have a line like:
```Julia
language=en
```

### 2) Define the texts in all languages:
To let the assistant speak different languages, all texts must be added to a 
database
for all target languages. These are defined in the 
`config.ini` file by connecting a language, a key and the sentence.
Text sniplets for each key must be defined in each language:

```
[de]
:skill_echo =  Hallo, ich bin die Hermes-Skill
:slot_echo_1 = der Wert des Slots
:slot_echo_2 = ist
:end_say =     das wars
:ask_echo_slots = soll ich die Slots des Intent aufsagen?
:no_slots =    der Intent hat keine Slots

[en]
:skill_echo =  hello, i am the Hermes skill
:skill_echo =  i am your new Hermes skill
:skill_echo =  i am 
:slot_echo_1 = the value of the slot
:slot_echo_2 = is
:end_say =     and done
:ask_echo_slots = do you want me to list the slots of this intent?
:no_slots =    the intent has no slots
...
```
+ **language:** Sentences for each language are defined in sections of 
        the config file with the 2-character language codes as heading.
+ **key:** Keys are *julia*-style Symbols and can be specified with a
        leading colon (however this is not mandatory, just good style).
        Several sentences can be provided with the same key - 
        the `HermesMQTT.publishSay()` will select one of the sentences
        randomly.
+ **sentence:** The sentence is added after the `=` without quoting.



### 3) Create similar intents for all languages:

The most time-consuming step ist to create the intents in the
Snips/Rhasspy console - however this is necessary, because speach-to-text as well as
natural language understanding highly depend on the language.


### 4) Switch between languages:

A language can be selected in the `config.ini` of `HermesMQTT` or 
the `config.ini` of each skill.


### 5) Utter texts in the defined language:

In the code, the text sniplets can be used by specifying the keys
(as Symbols) just like String literals or values
and lined up, such as:

```Julia
publish_end_session("This is a hard-coded message")
publish_end_session(:skill_echo)
publish_end_session(:skill_echo, "This is a hard-coded message")

str = "String variable"
val = 42
publish_end_session(:skill_echo, "and values from variables", 
                    "string", str, "or value", val)
```


## System triggers

Triggers extend the concept of sending MQTT-messages between assistant
components to communication between apps or the system or timers and apps.
A trigger is a MQTT with a topic like

```
qnd/trigger/andreasdominik:Susi:Lights<EN>
```

and a payload in JSON format:

```
    {
      "target" : "qnd/trigger/andreasdominik:Snips:Lights<EN>",
      "origin" : "Susi:Scheduler<EN>",
      "time" : timeString,
      "trigger" : {
        "room" : "default",
        "device" : "floor_lamp",
        "onOrOff" : "ON",
        "settings" : "undefined"
      }
    }
```

Skills can subscribe to triggers as to normal Hermes intents with the
function `register_trigger_action()` as well as publish triggers
with `publish_trigger_action()`. This way it is possible to

* execute actions in other skills (by publishing the respective trigger)
* execute action at a specified a time.


## Managing the Julia footprint

Unfortunately, the language Julia has a much bigger 
footprint as Python, consuming
pretty much memory per Julia instance. In consequence it is not possible
to run many Julia skills as separate processes, like it is possible
with Python programs.

To work around this issue, all skills within this framework are
running in the same Julia procress. 
This reduces the footprint as well as the
compile times (because the libraries must be compiled only once).

To run the HermesMQTT skills, all skills must be installed 
in directories parallel to `HermesMQTT`. When the `action-*.jl` of
HermesMQTT is executed, it will load all other `loader-*.jl` functions and load the skills.

All skills are executed in parallel 
(thanks to Julia this is super easy to implement)
and as separate Modules, so that the namespaces are separated
and each skill can be implemented without caring about the rest.
