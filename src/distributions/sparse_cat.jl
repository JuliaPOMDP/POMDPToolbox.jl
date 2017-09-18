struct SparseCat{V, P}
    vals::V
    probs::P
end

function rand(rng::AbstractRNG, d::SparseCat)
    r = sum(d.probs)*rand(rng)
    tot = first(d.probs)
    for (v, p) in d
        if r < tot
            return v
        end
        tot += p
    end
    return v
end

# slow linear search :(
function pdf(d::SparseCat, s)
    for (v, p) in d
        if v == s
            return p
        end
    end
    return zero(eltype(d.probs))
end

iterator(d::SparseCat) = d.vals

weighted_iterator(d::SparseCat) = d

Base.start(d::SparseCat) = (start(d.vals), start(d.probs))
function Base.next(d::SparseCat, state::Tuple)
    val, vstate = next(d.vals, first(state))
    prob, pstate = next(d.probs, last(state))
    return (val=>prob, (vstate, pstate))
end
Base.done(d::SparseCat, state::Tuple) = done(d.vals, first(state)) || done(d.vals, last(state))
Base.length(d::SparseCat) = min(length(d.vals), length(d.probs))
Base.eltype(D::Type{SparseCat{V,P}}) where {V, P} = Pair{eltype(V), eltype(P)}

function Base.mean(d::SparseCat)
    vsum = zero(eltype(d.vals))
    for (v, p) in d
        vsum += v*p
    end
    return vsum/sum(d.probs)
end

function mode(d::SparseCat)
    bestp = zero(eltype(d.probs))
    bestv = first(d.vals)
    for (v, p) in d
        if p >= bestp
            bestp = p
            bestv = v
        end 
    end
    return bestv
end
