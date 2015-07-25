type DiscreteBelief <: Belief
    b::Vector{Float64}
    bp::Vector{Float64}
    n::Int64
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
    return DiscreteBelief(b, bp, n)
end

vec(b::DiscreteBelief) = b.b

Base.length(b::DiscreteBelief) = b.n
POMDPs.index(b::DiscreteBelief, i::Int64) = i
POMDPs.weight(b::DiscreteBelief, i::Int64) = b[i]



function update_belief(pomdp::POMDP, a::Int64, o::Int64)
    ns = n_states(pomdp)
    b = DiscreteBelief(ns)
    update_belief!(b, pomdp, a, o)
    return b
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
    for i = 1:length(new_belief) new_belief[i] /= norm end
    belief[1:end] = new_belief[1:end]
    b
end

