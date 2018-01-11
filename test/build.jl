# running test in test_beleif.jl
# POMDPs.add("FIB") <- change to this after FIB is in a registered version of POMDPs
try
    Pkg.clone("https://github.com/JuliaPOMDP/FIB.jl")
catch ex
    warn("Unable to clone FIB for testing for the following reason:")
    showerror(STDERR, ex)
end
