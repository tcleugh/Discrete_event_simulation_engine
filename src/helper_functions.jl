####################################################################
##### Functions to assist with various parts of the simulation #####
####################################################################

"""
Returns a Gamma distribution with desired rate (inverse of shape) and SCV.
"""
rate_scv_gamma(desired_rate::Float64, desired_scv::Float64) = Gamma(1/desired_scv, desired_scv/desired_rate)

"""
Randomly selects an entry queue index using the given weights

Requires: ∑ p_i = 1
"""
function get_entry_queue(entry_probs::Vector{Float64})::Integer
	prob = rand()
	for i in 1:length(entry_probs)
		prob -= entry_probs[i]
		prob <= 0 && return i
	end
    error("Entry probabilities do not sum to 1")
end

"""
Randomly selects the next queue for the job from the given routing matrix weights

Returns -1 corresponding to exiting the system.
"""
function get_next_queue(current::Integer, P::Matrix{Float64})::Integer
    next_probs = P[current,:] # Gets the probability row vector corresponding to the current queue 

    prob = rand()
	for i in 1:length(next_probs)
		prob -= next_probs[i]
		prob <= 0 && return i
	end
    return -1
end


next_arrival_time(s::State)::Float64 = rand(Exponential(1/s.params.λ))

next_service_time(s::State, q::Int)::Float64 = rand(rate_scv_gamma(s.params.μ_vector[q], s.params.gamma_scv))

travel_time(s::State)::Float64 = rand(rate_scv_gamma(s.params.η, s.params.gamma_scv))
