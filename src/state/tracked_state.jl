
mutable struct TrackedNetworkState <: State
    queues::Vector{Vector{Job}} #A vector of queues holding the jobs waiting in buffer
    in_transit::BinaryMinHeap{Job} #Jobs in transit between queues
    left_system::Vector{Job} #Jobs that have left the system
    params::NetworkParameters #The parameters of the queueing system
end

"""
Constructs an initilized tracked network state from the given parameters
"""
TrackedNetworkState(params::NetworkParameters) = TrackedNetworkState([Vector{Job}[] for _ in 1:params.L], # Initial queues
                                                                     BinaryMinHeap{Job}(),                # Intial transit
                                                                     Vector{Job}[],                       # Initial left system
                                                                     params)
"""
Constructs an initilized tracked network state from the given parameters and altered λ
"""
TrackedNetworkState(params::NetworkParameters, λ::Real) = TrackedNetworkState([Vector{Job}[] for _ in 1:params.L], # Initial queues
                                                                                 BinaryMinHeap{Job}(),                # Intial transit
                                                                                 Vector{Job}[],                       # Initial left system
                                                                                 NetworkParameters(params, λ = convert(Float64, λ)))

""" Returns the total number of jobs in all queues of the system """
queued_count(state::TrackedNetworkState)::Int = sum([length(state.queues[i]) for i in 1:length(state.queues)])
 
""" Returns the total number of in transit between queues in the system """
transit_count(state::TrackedNetworkState)::Int = length(state.in_transit)

""" Returns the number of jobs in the given queue """
num_in_queue(q::Int, state::TrackedNetworkState)::Int = length(state.queues[q])

function pop_transit(state::TrackedNetworkState)::Job
    return pop!(state.in_transit) 
end

function pop_queue(q::Int, state::TrackedNetworkState)::Job
    return popfirst!(state.queues[q])
end

function push_queue(q::Int, time::Float64, state::TrackedNetworkState, job::Job)
    push!(job, InQueue(time, q))
    push!(state.queues[q], job) 
end

function push_transit(time::Float64, transit_time::Float64, state::TrackedNetworkState, job::Job)
    push!(job, InTransit(time, transit_time))
    push!(state.in_transit, job)
end

function remove_job(time::Float64, state::TrackedNetworkState, job::Job)
    push!(job, LeaveSystem(time))
    push!(state.left_system, job)
end

default_job(state::TrackedNetworkState)::Job = Job()

""" Prints a full history of all jobs that the system processes, sorted by entry time"""
function show(io::IO, state::TrackedNetworkState)
    all_jobs = Job[]
    for queue in state.queues
        append!(all_jobs, deepcopy(queue))
    end

    in_transit = deepcopy(state.in_transit)
    append!(all_jobs, extract_all!(in_transit))

    append!(all_jobs, deepcopy(state.left_system))
    
    sort!(all_jobs, by = (job) -> entry_time(job))
    println(io, "Tracked State: ")
    for job in all_jobs
        print(io, job.history)
        print(io, "\n")
    end
end
