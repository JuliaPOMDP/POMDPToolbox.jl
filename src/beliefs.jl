type DiscreteBelief <: Belief
    b::Vector{Float64}
    bp::Vector{Float64}
    n::Int64
    valid::Bool
end
# Constructor with uniform belief
function DiscreteBelief(n::Int64)
    b = zeros(n) + 1.0/n
    bp = zeros(n) + 1.0/n
    return DiscreteBelief(b, bp, n)
end
# Constructor for user defined initial belief
function DiscreteBelief(b::Vector{Float64})
    n = length(b)
    bp = deepcopy(b)
    bpp = deepcopy(b)
    return DiscreteBelief(bpp, bp, n)
end

vec(b::DiscreteBelief) = b.b

Base.length(b::DiscreteBelief) = b.n
POMDPs.index(b::DiscreteBelief, i::Int64) = i
POMDPs.weight(b::DiscreteBelief, i::Int64) = b.b[i]
valid(b::DiscreteBelief) = b.valid

function Base.fill!(b::DiscreteBelief, x::Float64)
    fill!(b.b, x)
    fill!(b.bp, x)
    b
end

function Base.fill!(b::DiscreteBelief, idxs::Vector{Int64}, vals::Vector{Float64})
    fill!(b.b, 0.0)
    fill!(b.bp, 0.0)
    for i = 1:length(idxs)
        index = idxs[i]
        index > 0 ? (b[index] = vals[i]) : nothing 
    end
    b
end

function Base.setindex!(b::DiscreteBelief, x::Float64, i::Int64) 
    b.b[i] = x
    b.bp[i] = x
    b
end

# TODO(max): Support for non-integer actions/observations? Will need mapping functions
# Updates the belief given the current action and observation
function update_belief!(b::DiscreteBelief, pomdp::POMDP, a::Int64, o::Int64)
    sspace = space(pomdp)
    pomdp_states = domain(sspace)
    @assert length(collect(pomdp_states)) == b.n

    od = create_observation(pomdp)
    td1 = create_transition(pomdp)
    td2 = create_transition(pomdp)

    belief = b.b
    new_belief = b.bp
    fill!(new_belief, 0.0)
    
    for (i, sp) in enumerate(pomdp_states)
        b_sum = 0.0
        transition!(td1, pomdp, sp, a) 
        observation!(od, pomdp, sp, a)
        for is = 1:length(td)
            p = weight(td1, is)
            if p > 0.0
                s = index(td1, is)
                transition!(td2, pomdp, s, a) 
                for js = 1:length(td2) 
                    pp = weight(td2, js) 
                    if pp > 0.0
                        spidx = index(td2, js)
                        if spidx == sp
                            b_sum += pp*belief[s] 
                        end
                    end
                end
            end
        end
        for io = 1:length(od)
            idx = index(od, io)
            if idx == o
                new_belief[i] = weight(od, io)*b_sum
                break
            end
        end
    end
    norm = sum(new_belief)
    # if norm is zero, the update was invalid - reset to uniform
    if norm == 0.0
        u = 1.0/length(b)
        fill!(b, u)
    else
        for i = 1:length(new_belief) new_belief[i] /= norm end
        belief[1:end] = new_belief[1:end]
    end
    b
end

# a belief that just stores the previous observation
# policies based on the previous observation only are often pretty good
# e.g. for the crying baby problem
type PreviousObservation <: Belief
    observation
end
function update_belief!(b::PreviousObservation, p::POMDP, action::Any, obs::Any)
    b.observation = deepcopy(obs)
end

# an empty belief
# for use with e.g. a random policy
type EmptyBelief <: Belief
end
function update_belief!(b::EmptyBelief, p::POMDP, a, o)
end


