using Documenter, HermesMQTT

makedocs(modules = [HermesMQTT],
         clean = false,
         sitename = "hermesMQTT.jl",
         authors = "Andreas Dominik",
         pages = [
                  "Introduction" => "index.md",
                  "Installation" => "install.md",
                  "Some details" => "details.md",
                  "New skill tutorial" => "makeskill.md",
                  "API Reference" => "api.md",
                  "License" => "license.md",
                  hide("Changelog" => "changelog.md")
                  ],
         # format = Documenter.HTML(prettyurls = false)
         )

deploydocs(
    repo   = "github.com/andreasdominik/HermesMQTT.jl.git")
