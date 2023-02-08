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

The framework is installed, by running `HermesMQTT`.

+ find a intstallation directory `/opt/HermesMQTT` may be a good choice.
+ clone the project from github.
+ run the loader.
+ MQTT communication is performed via `Eclipse mosquitto` client,
  therefore this must be installed, too. On a Raspberry Pi the packages
  `mosquitto` and/or `mosquitto-clients` are needed:

```sh
sudo apt-get install mosquitto
sudo apt-get install mosquitto-clients

sudo mkdir /opt/HermesMQTT
cd /opt/HermesMQTT
git clone git@github.com:andreasdominik/HermesMQTT.jl.git
cd bin 
julia action-hermesMQTT.jl
```

For production it might be a good idea to run the loader as a service.
