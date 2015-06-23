module POMDPToolbox

using POMDPs

export 
    Interpolants,
    interpolants!,
    interpolants_gaussian_1d!,
    interpolants_uniform_1d!

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
function Base.getindex(interpolants::Interpolants, index::Int)
    @assert(0 < index ≤ interpolants.length)
    (interpolants.indeces[index], interpolants.weights[index])
end
function Base.show(io::IO, interpolants::Interpolants)
    println(io, "Interpolant:")
    println(io, "indeces: ", interpolants.indeces[1:interpolants.length])
    println(io, "weightes: ", interpolants.weights[1:interpolants.length])
end

interpolants!(interps::Interpolants, d::AbstractDistribution) = error("$(typeof(d)) does not implement interpolants!")

Φ(z::Real) = 0.5*erfc(-z/√2)
zval(x::Real, μ::Real, σ::Real) = (x - μ) / σ
cdf(x::Real, μ::Real, σ::Real) = Φ(zval(x, μ, σ))

function interpolants_gaussian_1d!{F<:Real}(
    interps::Interpolants,
    orderedstates::AbstractVector{F}, # list of discrete states, ordered from smallest to largest
    stateindeces::AbstractVector{Int}, # list of state indeces corresponding to the ordered states
    μ::Real, # Gaussian mean
    σ::Real; # Gaussian standard deviation
    threshold_probability_too_small::Float64=1e-10 # will not add interpolant if the weighting is too low
    )

    # assigns all weight to the bins defined by the midpoints between states
    # ie, if orderedstates is [-1,0,1], then the bin edges are [-∞,-0.5,0.5,∞]

    n = length(orderedstates)

    cdf_prev = 0.0
    for i = 1 : n-1
        bin_now = 0.5*(orderedstates[i+1] + orderedstates[i])
        cdf_now = cdf(bin_now, μ, σ)
        weight = cdf_now - cdf_prev
        if weight > threshold_probability_too_small
            push!(interps, stateindeces[i], weight)
        end
        cdf_prev = cdf_now
    end

    weight = 1.0 - cdf_prev
    if weight > threshold_probability_too_small
        push!(interps, stateindeces[n], weight)
    end

    interps
end
function interpolants_uniform_1d!{F<:Real}(
    interps::Interpolants,
    binedges::AbstractVector{F}, # list of discrete states bin edges, ordered from smallest to largest
    stateindeces::AbstractVector{Int}, # list of state indeces corresponding to the ordered states
    threshold_probability_too_small::Float64=1e-10 # will not add interpolant if the weighting is too low
    )

    n = length(stateindeces)
    @assert(length(binedges) == n + 1)

    total_width = binedges[end] - binedges[1]

    for i = 1 : n
        width = binedges[i+1] - binedges[i]
        weight = width / total_width
        if weight > threshold_probability_too_small
            push!(interps, stateindeces[i], weight)
        end
    end

    interps
end

end # module
