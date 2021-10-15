abstract type State end

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
    # will override the lambda value without having to make it mutable 
    return NetworkParameters(L = params.L, 
                             gamma_scv = params.gamma_scv, 
                             λ = λ,
                             η = params.η,
                             μ_vector = copy(params.μ_vector),
                             P = copy(params.P),
                             Q = copy(params.Q),
                             p_e = copy(params.p_e),
                             K = copy(params.K))
end

mutable struct NetworkState <: State
    queues::Vector{Int} #A vector which indicates the number of customers in each queue
    in_transit::Int
    params::NetworkParameters #The parameters of the tandem queueing system
end

"""
Constructs an initilized network state from the given parameters
"""
NetworkState(params::NetworkParameters) = NetworkState(fill(0, params.L), # Initial queues
                                                      0,                 # Intial transit
                                                      params)

"""
Constructs an initilized network state from the given parameters and altered λ
"""
NetworkState(params::NetworkParameters, λ::Float64) = NetworkState(fill(0, params.L), # Initial queues
                                                                       0,            # Intial transit
                                                                       NetworkParameters(params, λ = λ))

"""
The structure 'FullTrackedState' allows jobs to be tracked based on 'location' (in the queue, transit, or system)
"""
mutable struct FullTrackedState <: State
    queues::Vector{Vector{Job}} #A vector of queues holding the jobs waiting in buffer
    in_transit::BinaryMinHeap{Job} #Jobs in transit between queues
    left_system::Vector{Job} #Jobs that have left the system
    params::NetworkParameters #The parameters of the tandem queueing system
end

"""
Constructs an initilized tracked network state from the given parameters
"""
FullTrackedState(params::NetworkParameters) = FullTrackedState([Vector{Job}[] for _ in 1:params.L], # Initial queues -> empty vectors based on servers
                                                                     BinaryMinHeap{Job}(),                # Intial transit
                                                                     Vector{Job}[],                       # Initial left system
                                                                     params
                                                                    )

"""
Constructs an initilized tracked network state from the given parameters and altered λ
"""
FullTrackedState(params::NetworkParameters, λ::Float64) = FullTrackedState([Vector{Job}[] for _ in 1:params.L], # Initial queues
                                                                                 BinaryMinHeap{Job}(),                # Intial transit
                                                                                 Vector{Job}[],                       # Initial left system
                                                                                 NetworkParameters(params, λ = λ)
                                                                                )


####################
# Helper Functions #
####################

""" Generates next arrival time from state """
next_arrival_time(s::State)::Float64 = rand(Exponential(1/s.params.λ))

""" Generates next service time for the given queue from state """
next_service_time(s::State, q::Int)::Float64 = rand(rate_scv_gamma(s.params.μ_vector[q], s.params.gamma_scv))

""" Generates travel time between queues from state """
travel_time(s::State)::Float64 = rand(rate_scv_gamma(s.params.η, s.params.gamma_scv))

"""
Returns a Gamma distribution with desired rate (inverse of shape) and SCV.
"""
rate_scv_gamma(desired_rate::Float64, desired_scv::Float64) = Gamma(1/desired_scv, desired_scv/desired_rate)