
mutable struct FullTrackedState <: State
    queues::Vector{Vector{FullJob}} #A vector of queues holding the jobs waiting in buffer
    in_transit::BinaryMinHeap{FullJob} #Jobs in transit between queues
    left_system::Vector{FullJob} #Jobs that have left the system
    params::NetworkParameters #The parameters of the queueing system
end

"""
Constructs an initilized tracked network state from the given parameters
"""
FullTrackedState(params::NetworkParameters) = FullTrackedState([Vector{FullJob}[] for _ in 1:params.L], # Initial queues
                                                                     BinaryMinHeap{FullJob}(),                # Intial transit
                                                                     Vector{FullJob}[],                       # Initial left system
                                                                     params)
"""
Constructs an initilized tracked network state from the given parameters and altered λ
"""
FullTrackedState(params::NetworkParameters, λ::Float64) = FullTrackedState([Vector{FullJob}[] for _ in 1:params.L], # Initial queues
                                                                                 BinaryMinHeap{FullJob}(),                # Intial transit
                                                                                 Vector{FullJob}[],                       # Initial left system
                                                                                 NetworkParameters(params, λ = λ))

queued_count(state::FullTrackedState)::Int = sum([length(state.queues[i]) for i in 1:length(state.queues)])
 
transit_count(state::FullTrackedState)::Int = length(state.in_transit)

num_in_queue(q::Int, state::FullTrackedState)::Int = length(state.queues[q])

function clear_left(state::FullTrackedState)
    empty!(state.left_system)
end

""" Prints a full history of all jobs that the system processes, sorted by entry time"""
function show(io::IO, state::FullTrackedState)
    all_jobs = FullJob[]
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

function new_job(q::Int, time::Float64, state::FullTrackedState)
    push!(state.queues[q], FullJob(InQueue(time, q))) 
end

function new_transit(time::Float64, transit_time::Float64, state::FullTrackedState)
    push!(state.in_transit, FullJob(InTransit(time, transit_time)))
end

function pop_queue(q::Int, time::Float64, state::FullTrackedState)
    job = popfirst!(state.queues[q])
    push!(job, LeaveSystem(time))
    push!(state.left_system, job)
end

function queue_to_transit(q::Int, time::Float64, transit_time::Float64, state::FullTrackedState)
    job = popfirst!(state.queues[q])
    push!(job, InTransit(time, transit_time))
    push!(state.in_transit, job)
end

function pop_transit(time::Float64, state::FullTrackedState)
    job = pop!(state.in_transit)
    push!(job, LeaveSystem(time))
    push!(state.left_system, job)
end

function transit_to_queue(q::Int, time::Float64, state::FullTrackedState)
    job = pop!(state.in_transit)
    push!(job, InQueue(time, q))
    push!(state.queues[q], job)
end

function update_transit(time::Float64, transit_time::Float64, state::FullTrackedState)
    job = pop!(state.in_transit)
    push!(job, InTransit(time, transit_time))
    push!(state.in_transit, job)
end

function failed_arrival(time::Float64, state::FullTrackedState) 
    push!(state.left_system, FullJob(LeaveSystem(time)))
end