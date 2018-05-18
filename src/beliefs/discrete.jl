# Goals: minimize calls to ordered_states (allocates memory)

# needs pomdp for state_index in pdf(b, s)
# needs list of ordered_states for rand(b)

"""
    DiscreteBelief

A belief specified by a probability vector.

Normalization of `b` is NOT enforced at all times, but the `DiscreteBeleif(pomdp, b)` constructor will warn, and `update(...)` always returns a belief with normalized `b`.
"""
struct DiscreteBelief{P<:POMDP, S}
    pomdp::P
    state_list::Vector{S}       # vector of ordered states
    b::Vector{Float64}
end

function DiscreteBelief(pomdp::POMDP, state_list::AbstractVector, b::AbstractVector{Float64}, check::Bool=true)
    if check
        if !isapprox(sum(b), 1.0, atol=0.001)
            warn("""
                 b in DiscreteBelief(pomdp, b) does not sum to 1.

                 To suppress this warning use `DiscreteBelief(pomdp, b, check=false)`
                 """)
        end
        if !all(0.0 <= p <= 1.0 for p in b)
            warn("""
                 b in DiscreteBelief(pomdp, b) contains entries outside [0,1].

                 To suppress this warning use `DiscreteBelief(pomdp, b, check=false)`
                 """)
        end
    end
    return DiscreteBelief(pomdp, state_list, b)
end

function DiscreteBelief(pomdp::POMDP, b::Vector{Float64}; check::Bool=true)
    return DiscreteBelief(pomdp, ordered_states(pomdp), b, check)
end

function DiscreteBelief(pomdp::POMDP, b; check::Bool=true)
    # convert b to a vector representation 
    state_list = ordered_states(pomdp)
    bv = Vector{Float64}(n_states(pomdp))
    for (i, s) in enumerate(state_list)
        bv[i] = pdf(b, s)
    end
    return DiscreteBelief(pomdp, state_list, bv, check)
end


"""
Return a DiscreteBelief with equal probability for each state.
"""
function uniform_belief(pomdp)
    state_list = ordered_states(pomdp)
    ns = length(state_list)
    return DiscreteBelief(pomdp, state_list, ones(ns) / ns)
end

pdf(b::DiscreteBelief, s) = b.b[state_index(b.pomdp, s)]

function rand(rng::AbstractRNG, b::DiscreteBelief)
    i = sample(rng, Weights(b.b))
    return b.state_list[i]
end

function Base.fill!(b::DiscreteBelief, x::Float64)
    fill!(b.b, x)
    return b
end

Base.length(b::DiscreteBelief) = length(b.b)

iterator(b::DiscreteBelief) = b.state_list

==(b1::DiscreteBelief, b2::DiscreteBelief) = b1.state_list == b2.state_list && b1.b == b2.b

Base.hash(b::DiscreteBelief, h::UInt) = hash(b.b, hash(b.state_list, h))

mutable struct DiscreteUpdater{P<:POMDP} <: Updater
    pomdp::P
end

uniform_belief(up::DiscreteUpdater) = uniform_belief(up.pomdp)

function initialize_belief(bu::DiscreteUpdater, dist::Any)
    state_list = ordered_states(bu.pomdp)
    ns = length(state_list)
    b = zeros(ns)
    belief = DiscreteBelief(bu.pomdp, state_list, b)
    for s in iterator(dist)
        sidx = state_index(bu.pomdp, s)
        belief.b[sidx] = pdf(dist, s)
    end
    return belief
end

function update(bu::DiscreteUpdater, b::DiscreteBelief, a, o)
    pomdp = b.pomdp
    state_space = b.state_list
    bp = zeros(length(state_space))

    bp_sum = 0.0   # to normalize the distribution

    for (spi, sp) in enumerate(state_space)

        # po = O(a, sp, o)
        od = observation(pomdp, a, sp)
        po = pdf(od, o)

        if po == 0.0
            continue
        end

        b_sum = 0.0
        for (si, s) in enumerate(state_space)
            td = transition(pomdp, s, a)
            pp = pdf(td, sp)
            b_sum += pp * b.b[si]
        end

        bp[spi] = po * b_sum
        bp_sum += bp[spi]
    end

    if bp_sum == 0.0
        error("""
              Failed discrete belief update: new probabilities sum to zero.

              b = $b
              a = $a
              o = $o

              Failed discrete belief update: new probabilities sum to zero.
              """)
    else
        bp ./= bp_sum
    end

    return DiscreteBelief(pomdp, b.state_list, bp)
end

update(bu::DiscreteUpdater, b::Any, a, o) = update(bu, initialize_belief(bu, b), a, o)


# DEPRECATED
@generated function create_belief(bu::DiscreteUpdater)
    Core.println("WARNING: create_belief(up::DiscreteUpdater) is deprecated. Use uniform_belief(up) instead.")
    return :(uniform_belief(bu))
end

# alphas are |A|x|S|
# computes dot product of alpha vectors and belief
# util is array with utility of each alpha vecotr for belief b
@generated function product(alphas::Matrix{Float64}, b::DiscreteBelief)
    Core.println("WARNING: product(alphas, b::DiscreteBelief) is deprecated.")
    quote
        @assert size(alphas, 1) == length(b) "Alpha and belief sizes not equal"
        n = size(alphas, 2) 
        util = zeros(n)
        for i = 1:n
            s = 0.0
            for j = 1:length(b)
                s += alphas[j,i]*b.b[j]
            end
            util[i] = s
        end
        return util
    end
end

