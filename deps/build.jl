using Downloads

# Link from https://mvnrepository.com/artifact/org.jacop/jacop/4.8.0
const jacop_url = "https://repo1.maven.org/maven2/org/jacop/jacop/4.8.0/jacop-4.8.0.jar"

const depsfile = joinpath(dirname(@__FILE__), "deps.jl")
if isfile(depsfile)
    rm(depsfile)
end

function write_depsfile(path)
    open(depsfile, "w") do f
        println(f, "const libjacopjava = \"$(escape_string(path))\"")
        return
    end
    return
end

const jacop_path = joinpath(dirname(@__FILE__), "jacop.jar")
Downloads.download(jacop_url, jacop_path, verbose=true)
if isfile(jacop_path)
    write_depsfile(jacop_path)
end
