module POMDPToolbox

using POMDPs

export 
    Interpolants,
    interpolants!

type Interpolants
    indeces::Vector{Int}
    weights::Vector{Float64}
    length::Int

    function Interpolants(nentries::Int=100)
        new(Array(Int, nentries), Array(Float64, nentries), 0)
    end
end

Base.length(interpolants::Interpolants) = interpolants.length
function Base.push!(interpolants::Interpolants, stateindex::Int, val::Float64)
    interpolants.length += 1
    if interpolants.length ≤ length(interpolants.indeces)
        interpolants.indeces[interpolants.length] = stateindex
        interpolants.weights[interpolants.length] = val
    else
        push!(interpolants.indeces, stateindex)
        push!(interpolants.weights, val)
    end
    interpolants
end
function Base.empty!(interpolants::Interpolants)

    interpolants.length = 0
end
function Base.show(io::IO, interpolants::Interpolants)
    println(io, "Interpolant:")
    println(io, "indeces: ", interpolants.indeces[1:interpolants.length])
    println(io, "weightes: ", interpolants.weights[1:interpolants.length])
end

interpolants!(interps::Interpolants, d::AbstractDistribution) = error("$(typeof(d)) does not implement interpolants!")

end # module
