"""
    install(skill=nothing)

Install the skill. If `skill` is not specified, 
install the HermesMQTT framework.
"""
function install(skill=nothing)
    
    # get module dir:
    #
    script = joinpath(APP_DIR, "bin", "find_installation.sh")


    if isnothing(skill)     # Install the framework

        # Check if the framework is already installed
        #
        println("Scanning for an existing installation...")
        candidates = read(`$script`, String) |> split
        candidates = filter(x->occursin("HermesMQTT.jl/config.ini", x), candidates)
        candidates = dirname.(candidates)

        if length(candidates) == 1

            println("HermesMQTT framework is already installed at: \n", candidates[1])
            println("Do you want to overwrite the installation? (y/n)")
            s = readline()
            if !isnothing(s) && !isempty(s) && startswith(s, "y")
                println("Overwriting installation...")
                install_HermesMQTT(skills_dir)
            else
                install_HermesMQTT()  # ask for installation dir
            end
        elseif length(candidates) > 1
            println("More than one installation found:")
            for (i,c) in enumerate(candidates)
                println("($i) $c")
            end
            println("Which installation do you want to overwrite? (1, 2, ... or new)")
            s = readline()

            if startswith(s, "n")
                install_HermesMQTT()  # ask for installation dir
            else
                i = tryparse(Int, s)
                if !isnothing(i) && i <= length(candidates)
                    println("Overwriting installation...")
                    install_HermesMQTT(dirname(candidates[i]))
                else
                    install_HermesMQTT()  # ask for installation dir
                end
            end
        else
            install_HermesMQTT()
        end
    else
        # Install the skill
        #
        println("Installing skill: $skill")
        install_skill(skill)
    end
end


# Install the framework after asking ...
# save old config.ini as onfig.ini.old
#
function install_HermesMQTT(skills_dir=nothing)

    script = joinpath(PACKAGE_BASE_DIR, "bin", "copy_install.sh")

    if isnothing(skills_dir)
        println("Enter the directory where the framework should be installed:")
        println("(leave empty to use /opt/HermesMQTT/)")
        skills_dir = readline()
        if isnothing(skills_dir) || isempty(skills_dir)
            skills_dir = "/opt/HermesMQTT/"
        end
    end
    
    println("Are you shure you want to install the framework at: \n$skills_dir? (y/n)")
    s = readline()
    if isnothing(s) || isempty(s) || !startswith(s, "y")
        println("Installation aborted.")
        return
    end 

    if !endswith(skills_dir, "HermesMQTT.jl")
        hermes_dir = joinpath(skills_dir, "HermesMQTT.jl")
    end

    println("Installing HermesMQTT framework...")
    run(`$script $PACKAGE_BASE_DIR $hermes_dir`)

    set_skills_dir(skills_dir)

    # install the default skills:
    #
    install_skill("SusiScheduler")
end



# install a skill from github.
# skill_url is the url of the github repository.
#
function install_skill(skill_url)

    skills_dir = get_skills_dir()
    script = joinpath(skills_dir, "HermesMQTT.jl", "bin", "install_skill.sh")

    # if ado's skill, no url is needed:
    #
    if !endswith(skill_url, ".git")
        skill_url = "git@github.com:andreasdominik/$skill_url.git"
    end

    m = match(r"git.*/(?<skill_name>.*).git", skill_url)
    skill_name = m[:skill_name]
    
    skill_dir = joinpath(skills_dir, skill_name)

    # names of ini file versions:
    #
    conf_ini = joinpath(skill_dir, "config.ini")
    conf_template = joinpath(skill_dir, "config.ini.template")

    if isdir(skill_dir)
        println("Skill $skill_name is already installed.")
        println("Do you want to update the skill? (y/n)")
        s = readline()
        if !isnothing(s) && !isempty(s) && startswith(s, "y")

            cd(skill_dir)

            # rescue old config.ini:
            #
            if isfile(conf_ini)
                println("config.ini will be preserved and the new ini-file")
                println("saved as config.ini.template")
            end
            
            run(`git fetch`)
            run(`git reset --hard \@\{u\}`)
        else
            println("Installation aborted.")
            return
        end
    else   # normal installation:
        println("Installing skill: $skill_url")
        println("at: $skills_dir\n")

        run(`$script $skills_dir $skill_url`)
        if isfile(conf_template)
            cp(conf_template, conf_ini, force=true)
        end
    
        # remove .git directory:
        #
        #git_dir = joinpath(skill_dir, ".git")
        #rm(git_dir, recursive=true, force=true)

    end
end



function update_skill(skill_url)
    
    install_skill(skill_url)
end



"""
    generate_skill(skill_name=nothing)

Generate a new skill with the name `skill_name`.
If `skill_name` is not specified, the function asks for the 
name of a new skill.

### Details:

You will be asked to enter names of skill, intents
and slots.
Please be aware that 

#### Skill name
  will end up as a filename; it schould only contain
  allowed charaters (recommended: 'a-zA-Z0-9' and '_')

#### Intent names
  will end up as name of a julia function; although
  special charaters will be replaced by '_' they should be used
  with care. Names like 'Susi:RunIrrigation' are OK.

#### Slot names 
  are will end up as keys for dictionaries and should be
  easily readable in order to allow debugging. It is good practice
  to only have 'a-zA-Z' and _ in the names.
  
"""
function generate_skill(skill_name=nothing)

    if isnothing(skill_name)
        println("Enter the name of the new skill:")
        skill_name = readline()
    end

    skills_dir = get_skills_dir()
    if isnothing(skills_dir)
        println("Please install the HermesMQTT-framework first.") 
        return nothing
    end
    println("The new Skill $skill_name will be installed at: \n$skills_dir\n\n")
    tryrun(`$(joinpath(HermesMQTT.PACKAGE_BASE_DIR, "bin", "generate_skill.sh")) $skill_name $PACKAGE_BASE_DIR $skills_dir`)
    return nothing
end

"""
    set_skills_dir(dir)

Set the directory where the skills are located and save it to
PACKAGE_BASE_DIR/global.ini.
"""
function set_skills_dir(dir)
    
    global_ini = joinpath(HermesMQTT.PACKAGE_BASE_DIR, "global.ini")
    
    open(global_ini, "w") do io
        write(io, dir)
    end
end



"""
    get_skills_dir()

Return the directory where the skills are located.
"""
function get_skills_dir()

    global_ini = joinpath(HermesMQTT.PACKAGE_BASE_DIR, "global.ini")
    if isfile(global_ini)
        return readline(global_ini)
    else
        print_log("global.ini not found. Please run set_skills_dir(dir) first.")
        return nothing
    end
end
    