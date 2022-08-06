using Clang.Generators
using Clang.LibClang.Clang_jll  # replace this with your jll package

cd(@__DIR__)

include_dir = normpath(Clang_jll.artifact_dir, "include")
clang_dir = joinpath(include_dir, "clang-c")

options = load_options(joinpath(@__DIR__, "gen/gen.toml"))

# add compiler flags, e.g. "-DXXXXXXXXX"
args = get_default_args()  # Note you must call this function firstly and then append your own flags
push!(args, "-I$include_dir")

# headers = [joinpath(clang_dir, header) for header in readdir(clang_dir) if endswith(header, ".h")]
headers = [joinpath(@__DIR__, "gen/k.h")]
# there is also an experimental `detect_headers` function for auto-detecting top-level headers in the directory
# headers = detect_headers(clang_dir, args)

# create context
ctx = create_context(headers, args, options)

# run generator
build!(ctx)