# Maintained by Max Egorov and Zach Sunberg

"""
A weight vector to be used as a belief or state distribution.

sum(b)=1 is not enforced at all times, but during the update it is normalized to sum to one.

pdf(b, i) calculates the sum every time it is called. To access the weight directly (for example if you are sure that the sum is 1), use weight(b, i). 
"""
type DiscreteBelief
    b::Vector{Float64}
end

# Constructor with uniform belief
DiscreteBelief(n::Int64) = DiscreteBelief(zeros(n) + 1.0/n)

type DiscreteUpdater <: Updater{DiscreteBelief}
    pomdp::POMDP
end

vec(b::DiscreteBelief) = b.b

Base.length(b::DiscreteBelief) = length(b.b)
index(b::DiscreteBelief, i::Int64) = i
weight(b::DiscreteBelief, i::Int64) = b.b[i]
iterator(b::DiscreteBelief) = filter(i->b[i]>0.0, 1:length(b))
rand(rng::AbstractRNG, b::DiscreteBelief) = sample(rng, WeightVec(b.b)) # This will return an integer - seems like it should actually return an object of the state type of the problem
pdf(b::DiscreteBelief, s::Int) = b.b[s]/sum(b.b) # only works when the state type is integer

function Base.fill!(b::DiscreteBelief, x::Float64)
    fill!(b.b, x)
    return b
end

function Base.fill!(b::DiscreteBelief, idxs::Vector{Int64}, vals::Vector{Float64})
    fill!(b.b, 0.0)
    for i = 1:length(idxs)
        index = idxs[i]
        index > 0 ? (b[index] = vals[i]) : nothing 
    end
    b
end

function Base.setindex!(b::DiscreteBelief, x::Float64, i::Int64) 
    b.b[i] = x
    b
end

Base.getindex(b::DiscreteBelief, i::Int64) = b.b[i]

function Base.copy!(b1::DiscreteBelief, b2::DiscreteBelief)
    copy!(b1.b, b2.b)
    return b1
end

Base.sum(b::DiscreteBelief) = sum(b.b)

create_belief(bu::DiscreteUpdater) = DiscreteBelief(n_states(bu.pomdp))

function initialize_belief(bu::DiscreteUpdater, dist::Any, belief::DiscreteBelief = create_belief(bu))
    belief = fill!(belief, 0.0)
    for s in iterator(dist)
        sidx = state_index(bu.pomdp, s) 
        belief[sidx] = pdf(dist, s)  
    end
    return belief
end


# Updates the belief given the current action and observation
function update{A,O}(bu::DiscreteUpdater, bold::DiscreteBelief, a::A, o::O)
    bnew = create_belief(bu)
    pomdp = bu.pomdp
    # initialize spaces
    pomdp_states = ordered_states(pomdp)
    # ensure belief state sizes match 
    @assert length(bold) == length(bnew)
    # initialize belief 
    fill!(bnew, 0.0)
    # iterate through each state in belief vector
    for (i, sp) in enumerate(pomdp_states)
        # get the distributions
        od = observation(pomdp, a, sp)
        # get prob of observation o from current distribution
        probo = pdf(od, o)
        # if observation prob is 0.0, then skip rest of update b/c bnew[i] is zero
        probo == 0.0 ? (continue) : (nothing)
        b_sum = 0.0 # belief for state sp
        for (j, s) in enumerate(pomdp_states)
            td = transition(pomdp, s, a)
            pp = pdf(td, sp)
            b_sum += pp * bold[j]
        end
        bnew[i] = probo * b_sum
    end
    norm = sum(bnew)
    # if norm is zero, the update was invalid - reset to uniform
    if norm == 0.0
        println("Invalid update for: ", bold, " ", a, " ", o)
        u = 1.0/length(bnew)
        fill!(bnew, u)
    else
        for i = 1:length(bnew); bnew[i] /= norm; end
    end
    bnew
end


# alphas are |A|x|S|
# computes dot product of alpha vectors and belief
# util is array with utility of each alpha vecotr for belief b
function product(alphas::Matrix{Float64}, b::DiscreteBelief)
    @assert size(alphas, 1) == length(b) "Alpha and belief sizes not equal"
    n = size(alphas, 2) 
    util = zeros(n)
    for i = 1:n
        s = 0.0
        for j = 1:length(b)
            s += alphas[j,i]*b[j]
        end
        util[i] = s
    end
    return util
end

# function Base.convert(t::Type{DiscreteBelief}, b::Any)
#     db = DiscreteBelief(zeros(length(b))) # b must support length
#     for s in iterator(b)
#         db[index(b,s)] = pdf(b, s)
#     end
# end
