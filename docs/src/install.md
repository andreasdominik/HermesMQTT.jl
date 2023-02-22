# Installation

## Julia

*HermesMQTT* is written in the
modern programming language Julia (because Julia is faster
then Python and coding is much easier and much more straight forward).
However "Pythonians" often need some time to get familiar with Julia.

If you are ready for the step forward, start here:
[https://julialang.org/](https://julialang.org/)

### Installation of Julia language

Installation of Julia is simple:
* just download the tar-ball for
  your architecture (most probably Raspberry-Pi/arm).
* save it in an appropriate folder (`/opt/Julia/` might be a good idea).
* unpack: `tar -xvzf julia-<version>.tar.gz`
* make sure, that the julia executable is executable. You find it
  as `/opt/Julia/julia-<version>/bin/julia`.
  If it is not executable run `chmod 755 /opt/Julia/julia-<version>/bin/julia`
* Add a symbolic link from a location which is in the search path, such as
  `/usr/local/bin`:

All together:

```sh
sudo chown $(whoami) /opt    
mkdir /opt/Julia    
mv ~/Downloads/julia-<version>.tar.gz .    
tar -xvzf julia-<version>.tar.gz    
chmod 755 /opt/Julia/julia-<version>/bin/julia    
cd /usr/local/bin    
sudo ln -s /opt/Julia/julia-<version>/bin/julia    
```

  **... and you are done!**

  For a very quick *get into,* see
  [learn Julia in Y minutes](http://learnxinyminutes.com/docs/julia/).

### IDEs

Softwarte development is made comfortable by
IDEs (Integrated Development Environements). For Julia, best choices
include:

* [Visual Studio Code](https://code.visualstudio.com) 
  provides very good support for Julia.
* Playing around and learning is best done with
  [Jupyter notebooks](http://jupyter.org). The Jupyter stack can be installed
  easily from the Julia REPL by adding the Package `IJulia`.

### Noteworthy differences between Julia and Python

Julia code looks very much like Python code, except of
* there are no colons,
* whitespaces have no meaning; blocks end with an `end`,
* sometimes types should be given explicitly (for performance and
  explicit polymorphism).

However, Julia is a typed language with all advantages; and code is
run-time-compiled only once, with consequences:
* If a function is called for the first time, there is a time lack, because
  the compiler must finish his work before the actual code starts
  to execute.
* Future function calls will use the precompiled machine code, making Julia
  code execute as fast as compiled c-code!


## HermesMQTT

The framework is installed, by installing the package `HermesMQTT.jl`.
The package is **not** registered in the official Julia package
repository, therefore it must be installed manually:

```julia
using Pkg
Pkg.clone("git@github.com:andreasdominik/HermesMQTT.jl.git")
```

+ find a installation directory; 
  something like `/opt/HermesMQTT` or `~/Rhasspy/HermesMQTT` may be 
  good choices.
+ run the installer from a Julia REPL:

```julia
using HermesMQTT
HermesMQTT.install()
``` 
This will install the package `HermesMQTT.jl` and all its dependencies.
It will also create a directory `bin`, a file `bin/action-hermesMQTT.jl`
and a file `config.ini` 
in the installation directory. The file `action-hermesMQTT.jl` 
is the loader script.

Be sure to have a look into the `config.ini` file and adapt it to your
needs (such as MQTT host, port, user, password, etc.).
  
The loader script can be used to start the framework. It is a
Julia script, which can be run from the Julia REPL or from the
command line. 
Ideally a service may be created to start the loader script.
  
```sh
$ julia action-hermesMQTT.jl
``` 

+ MQTT communication is performed via `Eclipse mosquitto` client,
  therefore this must be installed, too. On a Raspberry Pi the packages
  `mosquitto` and/or `mosquitto-clients` are needed:

```sh
$ sudo apt-get install mosquitto
$ sudo apt-get install mosquitto-clients
```

## Skills

The loader will search for skills in the directory parallel to the
HermesMQTT installation. Each Julia-script with a name like
`loader-<skillname>.jl` will be loaded and executed.

If a skill is hosted at Github, it can be installed by the
`installSkill(<github-url>)` function. It will clone the repository into the
correct `skills` directory or perform an update, if the installation
already exists.

Default-skills (i.e. developed by the author of HermesMQTT) are all
in Github repos like `git@github.com:andreasdominik/SusiScheduler.git`
and can be installed with the skill-name:
```julia


```julia
install_skill("SusiScheduler")
 
# or with complete URL:
#
install_skill("git@github.com:andreasdominik/SusiScheduler.git")
```