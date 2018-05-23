# obs_weight is a shortcut function for getting the relative likelihood of an observation without having to construct the observation distribution. Useful for particle filtering
# maintained by @zsunberg

"""
    obs_weight(pomdp, sp, o)
    obs_weight(pomdp, a, sp, o)
    obs_weight(pomdp, s, a, sp, o)

Return a weight proportional to the likelihood of receiving observation o from state sp (and a and s if they are present).

This is a useful shortcut for particle filtering so that the observation distribution does not have to be represented.
"""
function obs_weight end

@generated function obs_weight(p, s, a, sp, o)
    ow_impl = :(obs_weight(p, a, sp, o))
    o_impl = :(pdf(observation(p, s, a, sp), o))
    if implemented(obs_weight, Tuple{p, a, sp, o})
        return ow_impl
    elseif implemented(observation, Tuple{p, s, a, sp})
        return o_impl
    else
        return quote
            try # trick to get the compiler to put the right backedges in
                $ow_impl
                $o_impl
            catch
                throw(MethodError(obs_weight, (p,s,a,sp,o)))
            end
        end
    end
end

@generated function obs_weight(p, a, sp, o)
    ow_impl = :(obs_weight(p, sp, o))
    o_impl = :(pdf(observation(p, a, sp), o))
    if implemented(obs_weight, Tuple{p, sp, o})
        return ow_impl
    elseif implemented(observation, Tuple{p, a, sp})
        return o_impl
    else
        return quote
            try # trick to get the compiler to put the right backedges in
                $ow_impl
                $o_impl
            catch
                throw(MethodError(obs_weight, (p, a, sp, o)))
            end
        end
    end
end

@generated function obs_weight(p, sp, o)
    impl = :(pdf(observation(p, sp), o))
    if implemented(observation, Tuple{p, sp})
        return impl
    else
         return quote
            try # trick to get the compiler to put the right backedges in
                $impl
            catch
                return :(throw(MethodError(obs_weight, (p, sp, o))))
            end
        end
    end
end

function implemented(f::typeof(obs_weight), TT::Type)
    m = which(f, TT)
    if length(TT.parameters) == 5
        P, S, A, _, O = TT.parameters
        reqs_met = implemented(observation, Tuple{P,S,A,S}) || implemented(obs_weight, Tuple{P,A,S,O})
    elseif length(TT.parameters) == 4
        P, A, S, O = TT.parameters
        reqs_met = implemented(observation, Tuple{P,A,S}) || implemented(obs_weight, Tuple{P,S,O})
    elseif length(TT.parameters) == 3
        P, S, O = TT.parameters
        reqs_met = implemented(observation, Tuple{P,S})
    else
        return method_exists(f, TT)
    end
    if m.module == POMDPToolbox && !reqs_met
        return false
    else
        true
    end
end
