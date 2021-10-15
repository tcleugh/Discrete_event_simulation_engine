abstract type State end

#### Required Interfaces for State #####
""" queued_count(state)::Int

Returns the total number of jobs in all queues of the system """
function queued_count end

""" transit_count(state)::Int

Returns the total number of jobs in transit between queues in the system """
function transit_count end

""" num_in_queue(q::Int, state)::Int

Returns the number of jobs in the queue with given index """
function num_in_queue end

""" new_job(q, time, state)

Adds a new job to the system in teh given queue
"""
function new_job end

""" new_transit(time, transit_time, state)

Adds a new job to the system in transit
"""
function new_transit end

""" pop_queue(q, time, state)

Removes the first job in the given queue from the system
"""
function pop_queue end

""" queue_to_transit(q, time, transit_time, state)

Moves the first job in the given queue into transit
"""
function queue_to_transit end

""" pop_transit(time, state)

Removes the first job in transit from the system
"""
function pop_transit end

""" transit_to_queue(q, time, state)

Adds the first job in transit to the given queue
"""
function transit_to_queue end

""" update_transit(time, transit_time, state)

Changes the destination time of the first job in transit
"""
function update_transit end

""" failed_arrival(time, state)

Changes the destination time of the first job in transit
"""
function failed_arrival end


@with_kw struct NetworkParameters
    L::Int #Number of queues
    gamma_scv::Float64 #This is constant for all scenarios at 3.0
    λ::Float64 #This is undefined for the scenarios since it is varied
    η::Float64 #This is assumed constant for all scenarios at 4.0
    μ_vector::Vector{Float64} #service rates
    P::Matrix{Float64} #routing matrix
    Q::Matrix{Float64} #overflow matrix
    p_e::Vector{Float64} #external arrival distribution
    K::Vector{Int} #Queue capacity, -1 means infinity 
end

function NetworkParameters(params::NetworkParameters; λ::Float64 = NaN)::NetworkParameters
    return NetworkParameters(L = params.L, 
                             gamma_scv = params.gamma_scv, 
                             λ = convert(Float64, λ),
                             η = params.η,
                             μ_vector = copy(params.μ_vector),
                             P = copy(params.P),
                             Q = copy(params.Q),
                             p_e = copy(params.p_e),
                             K = copy(params.K))
end


"""
Returns a Gamma distribution with desired rate (inverse of shape) and SCV.
"""
rate_scv_gamma(desired_rate::Float64, desired_scv::Float64) = Gamma(1/desired_scv, desired_scv/desired_rate)

""" Generates next arrival time from state """
next_arrival_time(s::State)::Float64 = rand(rate_scv_gamma(s.params.λ, s.params.gamma_scv))

""" Generates next service time for the given queue from state """
next_service_time(s::State, q::Int)::Float64 = rand(rate_scv_gamma(s.params.μ_vector[q], s.params.gamma_scv))

""" Generates travel time between queues from state """
travel_time(s::State)::Float64 = rand(rate_scv_gamma(s.params.η, s.params.gamma_scv))

""" Randomly selects an entry queue index using the state weights """
function get_entry_queue(state::State)::Int
	prob = rand()
	for i in 1:length(state.params.p_e)
		prob -= state.params.p_e[i]
		prob <= 0 && return i
	end
    error("Entry probabilities do not sum to 1")
end

"""
Randomly selects the next queue for the job from the given routing or overflow matrix weights
Returns -1 corresponding to exiting the system.
"""
function get_next_queue(q::Int, state::State, mode::Symbol)::Int
    (mode ∉ [:routing, :overflow]) && error("$mode is not a valid mode for queue selection") 
    # Gets the probability row vector corresponding to the current queue
    next_probs = (mode == :routing) ? state.params.P[q,:] :  state.params.Q[q,:]  
    
    prob = rand()
	for i in 1:length(next_probs)
		prob -= next_probs[i]
		prob <= 0 && return i
	end
    return -1
end

""" Returns total number of jobs in the system """
total_count(state::State)::Int = queued_count(state) + transit_count(state)

""" Returns whether the number of jobs in specified queue is equal to queue capacity """
is_full(q::Int, state::State)::Bool = (state.params.K[q] != -1) && num_in_queue(q, state) == state.params.K[q] 


