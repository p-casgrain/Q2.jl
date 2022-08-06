using Downloads

oschar = Dict(:Darwin => 'm', :Linux => 'l')
arch = Sys.ARCH

# Get object file download path
if Sys.isapple()
    if arch == :x86_64
        dl_url = "https://github.com/KxSystems/kdb/raw/master/m64/c.o"
    elseif arch == :x86_32
        dl_url = "https://github.com/KxSystems/kdb/raw/master/m32/c.o"
    else
        dl_url = nothing
    end
elseif Sys.islinux()
    if arch == :x86_64
        dl_url = "https://github.com/KxSystems/kdb/raw/master/l64/c.o"
    elseif arch == :x86_32
        dl_url = "https://github.com/KxSystems/kdb/raw/master/l32/c.o"
    else
        dl_url = nothing
    end
else
    dl_url = nothing
end

# Download object file
if dl_url === nothing
    error("Q2.jl only supports MacOS and Linux x86_64 and x86_32 at the moment.")
else
    dl_path = joinpath(@__DIR__,"..","deps/","c.o")
    Downloads.download(dl_url, dl_path)
end

# Compile to shared object
if Sys.islinux()
    target_path = joinpath(@__DIR__,"..","deps/","c.so")
elseif Sys.isapple()
    target_path = joinpath(@__DIR__,"..","deps/","c.dylib")
end

run(`gcc -shared -fPIC $dl_path -o $target_path`)