"""
    install(skill=nothing)

Install the skill. If `skill` is not specified, 
install the HermesMQTT framework.
"""
function install(skill=nothing)
    
    if isnothing(skill)     # Install the framework

        # Check if the framework is already installed
        #
        println("Scanning for an existing installation...")
        candidates = find_all_files("/", "config.ini")
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
            println("Which installation do you want to overwrite? (1, 2, ... or \"new\")")
            s = readline()

            if startswith(s, "n")
                install_HermesMQTT()  # ask for installation dir later
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

    if isnothing(skills_dir)
        println("Enter the directory where the framework should be installed:")
        println("(leave empty to use /opt/HermesMQTT/)")
        skills_dir = readline()
        if isnothing(skills_dir) || isempty(skills_dir)
            skills_dir = "/opt/HermesMQTT/"
        end
    end
    
    if !endswith(skills_dir, "HermesMQTT.jl")
        hermes_dir = joinpath(skills_dir, "HermesMQTT.jl")
    end

    is_update = false
    if isfile(joinpath(hermes_dir, "config.ini"))
        println("It seems that HermesMQTT is already installed at: \n$skills_dir")
        println("Do you want to delete and (r)eplace or (u)pdate the installation?")
        println("or (a)bort? (r/u/a)")
        s = readline()
        if isnothing(s) || isempty(s) || !startswith(s, r"(r|u)")
            println("Installation aborted.")
            return
        elseif startswith(s, "r")
            println("Are you shure you want to delete and replace the framework at: \n$skills_dir? (y/n)")
            s = readline()
            if isnothing(s) || isempty(s) || !startswith(s, r"(y)")
                println("Installation aborted.")
                return
            end
            rm(hermes_dir, recursive=true)
        elseif startswith(s, "u")
            println("Updating installation (the configuration is retained)")
            println("Please have a look at the new config.ini.template file and 
update your config.ini file accordingly.")
            is_update = true
        end
    end
    println("Are you shure you want to install the framework at: \n$skills_dir? (y/n)")
    s = readline()
    if isnothing(s) || isempty(s) || !startswith(s, "y")
        println("Installation aborted.")
        return
    end 

    # copy Framework to installation location:
    #
    println("Installing HermesMQTT framework...")
    # create dir hermes_dir if it not exist:
    #
    if !isdir(hermes_dir)
        mkpath(hermes_dir)
    end

    # copy a directory and set write permission:
    #
    copydir(joinpath(PACKAGE_BASE_DIR, "bin"), hermes_dir)
    copydir(joinpath(PACKAGE_BASE_DIR, "profiles"), hermes_dir)
    cp(joinpath(PACKAGE_BASE_DIR, "config.ini.template"), 
                joinpath(hermes_dir, "config.ini.template"), 
                force=true)

    if !boolrun(`sudo chmod -R 755 $(joinpath(hermes_dir, "bin"))`) || 
        !boolrun(`sudo chmod -R 755 $(joinpath(hermes_dir, "profiles"))`)
        println("Error: Could not set write permission for $hermes_dir")
        return
    end


    
    # create config.ini:
    #
    if !is_update
        configure_hermesMQTT(hermes_dir)
    end
    load_hermes_config(hermes_dir)
    
    set_skills_dir(skills_dir)
    # copy sentences:
    #
    install_sentences_and_slots("HermesMQTT.jl")

    # install the default skills:
    #
    install_skill("SusiScheduler")
end



function configure_hermesMQTT(hermes_dir)

    status = false
    r = nothing
    rhasspy_url = "http://localhost:12101/api"
    while !status
        println("Please enter host of the running Rhasspy web-interface:")
        println("(leave empty to use the default: localhost)")
        rhasspy_host = readline()
        if isnothing(rhasspy_host) || isempty(rhasspy_host)
            rhasspy_host = "localhost"
        end

        println(" ")
        println("Please enter the port of the running Rhasspy web-interface:")
        println("(leave empty to use the default: 12101)")
        rhasspy_port = readline()
        if isnothing(rhasspy_port) || isempty(rhasspy_port)
            rhasspy_port = "12101"
        end

        rhasspy_url = "http://$rhasspy_host:$rhasspy_port/api"
        println(" ")
        println("Trying to get profile from Rhasspy...")
        
        r = HTTP.request("GET", "$rhasspy_url/profile") 

        if r.status < 200 || r.status >= 300
            println(" ")
            println("Could not get profile from Rhasspy at: $rhasspy_url")
            println("Please check if Rhasspy is running and the url is correct.")
            println(" ")
            println("Do you want to try again? (y/n)")
            s = readline()
            if isnothing(s) || isempty(s) || !startswith(s, "y")
                println("HermesMQTT configuration aborted.")
                return
            end
        else
            status = true
        end
    end  # loop until url OK

    # fix, if ints are retured:
    #
        s = ""
        for i in r.body
            s = s * string(Char(i))
        end
    profile = JSON.parse(s)

    # make config.ini from template:
    #
    config_ini_name = joinpath(hermes_dir, "config.ini")
    config_template_name = joinpath(hermes_dir, "config.ini.template")

    ini = readlines(config_template_name)
    for i in eachindex(ini)
        if startswith(ini[i], "language")
            ini[i] = "language = $(profile["language"])"
        elseif startswith(ini[i], "mqtt_host")
            ini[i] = "mqtt_host = $(profile["mqtt"]["host"])"
        elseif startswith(ini[i], "mqtt_port")
            ini[i] = "mqtt_port = $(profile["mqtt"]["port"])"
        elseif startswith(ini[i], "mqtt_user")
            ini[i] = "mqtt_user = $(profile["mqtt"]["username"])"
        elseif startswith(ini[i], "mqtt_password")
            ini[i] = "mqtt_password = $(profile["mqtt"]["password"])"
        elseif startswith(ini[i], "rhasspy_url")
            ini[i] = "rhasspy_url = $rhasspy_url/"
        end
    end

    # write config.ini:
    #
    open(config_ini_name, "w") do f
        for line in ini
            write(f, line * "\n")
        end
    end
end





# install a skill from github.
# skill_url is the url of the github repository.
#
function install_skill(skill_url)

    # read config.ini:
    #
    skills_dir = get_skills_dir()
    if isnothing(skills_dir)
        println("Please install the HermesMQTT-framework first.") 
        return nothing
    end
    load_hermes_config(joinpath(skills_dir, "HermesMQTT.jl"))

    # if ado's skill, no url is needed:
    #
    if !endswith(skill_url, ".git")
        skill_url = "https://github.com/andreasdominik/$skill_url.git"
    end

    m = match(r"https.*/(?<skill_name>.*).git", skill_url)
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
            install_sentences_and_slots(skill_name)
        else
            println("Installation aborted.")
            return
        end
    else   
        # normal installation:
        #
        println("Installing skill: $skill_url")
        println("at: $skills_dir\n")

        run(`git clone $skill_url $skill_dir`)

        if isfile(conf_template)
            cp(conf_template, conf_ini, force=true)
        end
        install_sentences_and_slots(skill_name)
    
        # remove .git directory:
        #
        #git_dir = joinpath(skill_dir, ".git")
        #rm(git_dir, recursive=true, force=true)

    end
end



"""
    upload_intents(skill_name=nothing)

Upload the intents and slots for the given skill to Rhasspy.

### Arguments:
- `skill_name`: name of the skill. 
                The name must match the name of the skill directory to make it 
                possible to find the intents and slots in the 
                directory `<skillname>/profiles/<lang>/`.
"""
function upload_intents(skill_name=nothing)
    return install_sentences_and_slots(skill_name)
end


function install_sentences_and_slots(skill_name="skill")

    api_url = get_config_skill("rhasspy_url", skill="HermesMQTT")
    if isnothing(api_url)
        println("No Rhasspy url found in config.ini.")
        println("Please configure the Rhasspy url first!")
        return
    end

    println("Upload intents and slots for $skill_name to Rhasspy? (y/n)")
    s = readline()
    doit = !isnothing(s) && !isempty(s) && startswith(s, "y")
    if !doit
        println("""
        Installation of profile for the NLU aborted.
        Please make sure to install the sentences and slots manually
        by copying the files to the correct profile directory or
        by adding the sentences and slots to the sentence.ini file.""")
    else
        # copy profile files:
        #
        skill_dir = joinpath(get_skills_dir(), skill_name)
        lang = get_language()
        profile_dir = joinpath(skill_dir, "profiles", lang)
        
        println("Uploading sentences and slots for $skill_name")
        println("  from profile dir: $profile_dir")
        println("  to $(replace(api_url, r"api/$" => "")) ...")
        
        slots_dir = joinpath(profile_dir, "slots")
        if isdir(slots_dir)
            slots = joinpath.("slots", readdir(slots_dir, join=false)) .|> basename
        else
            slots = []
        end

        sentences_dir = joinpath(profile_dir, "intents")
        if isdir(sentences_dir)
            sentences = joinpath.("intents", readdir(sentences_dir, join=false)) .|> basename
        else
            sentences = []
        end

        for slot in slots
            upload_one_slot(slot, profile_dir, api_url)
        end
        for sentence in sentences
            upload_one_intent(sentence, profile_dir, api_url)
        end
    end
end
            


# upload slots and intents to Rhasspy:
#
upload_one_slot(slot, profile_dir, url)  = upload_one_file(slot, profile_dir, url, "slots")
upload_one_intent(slot, profile_dir, url)  = upload_one_file(slot, profile_dir, url, "intents")

function upload_one_file(file_name, profile_dir, url, file_type="intents")

    # clean url:
    # 
    url = replace(url, r"/$" => "")

    # read slot from file:
    #
    file_string = read(joinpath(profile_dir, file_type, file_name), String)
    # print debugging info:
    #
    file_field = "$file_type/$file_name"

    if file_type == "slots"
        file_field = "$file_name"
        url = "$url/slots"

    elseif file_type == "intents"
        file_field = "intents/$file_name"
        url = "$url/sentences"
    else
        println("  Error: Could not upload $file_type $file_name")
        return
    end

     println("\n\n\n  uploading $file_type: $file_name")
     println("  path: $(joinpath(profile_dir, file_type, file_name))")
     println("  url: $url")
     println("  field: $file_field")
     println(file_string)


    r = nothing
    try
        r = HTTP.request("POST", "$url", 
            ["Content-Type" => "application/json"], 
            JSON.json(Dict(file_field=>file_string)), verbose=0)
    catch
        println("  Error: Could not upload $file_type $file_name")
        return
    end
    if 200 <= r.status < 300
        println("  ... uploaded $file_type $file_name.")
    else
        println("  Error: Could not upload $file_type $file_name")
    end

    println("\n")
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
    load_hermes_config(joinpath(skills_dir, "HermesMQTT.jl"))

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
    


"""
    install_service()

Install a service to make sure that HermesMQTT.jl is started on system start 
and always runs (i.e. restarts if it crashes).

The service can be controlled with `systemctl` command as:
    
        systemctl status hermesmqtt
        systemctl start hermesmqtt
        systemctl stop hermesmqtt
        systemctl restart hermesmqtt

### Details:
The service is configured with the full path to the julia executable.
Therefore, it is not necessary to have julia in the PATH **but** 
if a new version of julia is installed, the service has to be reinstalled.
"""
function install_service()
    
    skills_dir = get_skills_dir()
    if isnothing(skills_dir)
        println("Please install the HermesMQTT-framework first.") 
        return nothing
    end
    load_hermes_config(joinpath(skills_dir, "HermesMQTT.jl"))

    println("The new Skill $skill_name will be installed at: \n$skills_dir\n\n")
    println("Install a service for HermesMQTT.jl? (y/n)")
    if !startswith(readline(), "y")
        println("OK - aborted!\n")
        return nothing
    end

    # set user:
    #
    user = ENV["USER"]
    println("Run service as user $user? (leave empty for yes, enter user name for no)")
    s = readline()
    if !(s == "" || s == "y")
        user = s
    end
    println("Running service as user $user")

    # set julia exec:
    #
    julia_exec = joinpath(Sys.BINDIR, "julia")

    cmd = joinpath(get_skills_dir(), "HermesMQTT.jl", "bin", "make_service.sh")
    if !boolrun(`sudo $cmd $(get_skills_dir()) $user $julia_exec`)
        println("Error executing installation script!")
        return nothing
    end

    println("Service installed. You can start, stop or restart it with:")
    println("    systemctl start hermesmqtt")
    println("    systemctl stop hermesmqtt")
    println("    systemctl restart hermesmqtt")

    println("You can also check the status with:")
    println("    systemctl status hermesmqtt")

    println("Start the service now? (y/n)")
    if startswith(readline(), "y")
        if !boolrun(`sudo systemctl start hermesmqtt`)
            println("Error starting the service!")
        end
    else
        println("OK - please start the service manually!\n")
    end

    println("Configure the service to start on system start? (y/n)")
    if startswith(readline(), "y")
        if !boolrun(`sudo systemctl enable hermesmqtt`)
            println("Error - could not configure the service!")
        end
    else
        println("OK - please configure the service manually!\n")
    end
end
