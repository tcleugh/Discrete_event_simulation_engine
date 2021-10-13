import Base: push!, isless

abstract type PositionRecord end

struct InTransit <: PositionRecord
    time::Float64
end

struct InQueue <: PositionRecord
    time::Float64
    queue::Int
end

struct LeaveSystem <: PositionRecord
    time::Float64
end

mutable struct JobPath 
    history::Vector{PositionRecord}
end

JobPath(entry::PositionRecord) = JobPath([entry])

duration(job::JobPath)::Float64 = last(job.history).time - first(job.history).time

function push!(job::JobPath, pos::PositionRecord)
    push!(job.history, pos)
end

isless(j1::JobPath, j2::JobPath) = last(j1.history).time < last(j2.history).time

mutable struct FullTrackedNetworkState <: State
    queues::Vector{Vector{JobPath}} #A vector of queues holding the jobs waiting in buffer
    in_transit::BinaryMinHeap{JobPath} #Jobs in transit between queues
    left_system::Vector{JobPath} #Jobs that have left the system
    params::NetworkParameters #The parameters of the queueing system
end









""" Adds a new job to the system """
function process_event(time::Float64, state::State, arrival_event::ExternalArrivalEvent)
    new_timed_events = TimedEvent[]

    next_q = get_entry_queue(state.params.p_e)
    append!(new_timed_events, add_to_queue(next_q, time, state))

    #prepare next arrival
    push!(new_timed_events, TimedEvent(ExternalArrivalEvent(), time + next_arrival_time(state)))

    return new_timed_events
end

"""
Randomly selects the next queue for the job from the given routing or overflow matrix weights
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

""" 
Finds the next queue for the job and moves it into transit to that queue 
Returns any new events created in the process
"""
function add_to_transit(q::Int, M::Matrix{Float64}, time::Float64, state::State)
    new_timed_events = []
    
    next_q = get_next_queue(q, M)
    if next_q > 0
        state.in_transit += 1
        push!(new_timed_events, TimedEvent(InTransitEvent(next_q), time + travel_time(state)))
    end

    return new_timed_events
end

""" 
Finds the next queue for the job and moves it into transit to that queue  
Returns any new events created in the process
With job Tracking
"""
function add_to_transit(q::Int, M::Matrix{Float64}, time::Float64, state::TrackedNetworkState, job::Job)
    new_timed_events = []
    
    next_q = get_next_queue(q, M)
    if next_q > 0
        transit_time = time + travel_time(state)
        job.event_time = transit_time
        push!(state.in_transit, job)
        push!(new_timed_events, TimedEvent(InTransitEvent(next_q), transit_time))
    else
        job.exit_time = time
        push!(state.left_system, job)
    end

    return new_timed_events
end

"""
Attempts to add a job to the specified queue and handles overflow if queue is full 
Returns any new events created in the process
"""
function add_to_queue(q::Int, time::Float64, state::State)
    new_timed_events = TimedEvent[]

    capacity = state.params.K[q]
    if capacity == -1 || state.queues[q] < capacity
        state.queues[q] += 1  #increase number in chosen queue
    
        #if this is the only job on the server engage service
        state.queues[q] == 1 && push!(new_timed_events,
                                    TimedEvent(EndOfServiceAtQueueEvent(q), time + next_service_time(state, q)))
    else
        #Finds new queue using overflow matrix
        append!(new_timed_events, add_to_transit(q, state.params.Q, time, state))
    end

    return new_timed_events
end

"""
Attempts to add a job to the specified queue and handles overflow if queue is full 
Returns any new events created in the process
With job tracking
"""
function add_to_queue(q::Int, time::Float64, state::TrackedNetworkState; job::Job = Job(time, time, -1))
    new_timed_events = TimedEvent[]

    capacity = state.params.K[q]
    if capacity == -1 || length(state.queues[q]) < capacity
        push!(state.queues[q], job) # adds job to selected queue
    
        #if this is the only job on the server engage service
        length(state.queues[q]) == 1 && push!(new_timed_events,
                                              TimedEvent(EndOfServiceAtQueueEvent(q), time + next_service_time(state, q)))
    else
        #Finds new queue using overflow matrix
        append!(new_timed_events, add_to_transit(q, state.params.Q, time, state, job))
    end

    return new_timed_events
end

 
""" Process an end of service event """
function process_event(time::Float64, state::State, eos_event::EndOfServiceAtQueueEvent)
    q = eos_event.q
    new_timed_events = TimedEvent[]
    
    state.queues[q] -= 1
    @assert state.queues[q] ≥ 0
    
    #if another customer in the queue then start a new service
    if state.queues[q] ≥ 1
        push!(new_timed_events, TimedEvent(EndOfServiceAtQueueEvent(q), time + next_service_time(state, q))) 
    end
    
    #Finds new queue using routing matrix
    append!(new_timed_events, add_to_transit(q, state.params.P, time, state))

    return new_timed_events
end

""" Process an end of service event with job tracking """
function process_event(time::Float64, state::TrackedNetworkState, eos_event::EndOfServiceAtQueueEvent)
    q = eos_event.q
    new_timed_events = TimedEvent[]
    
    job = popfirst!(state.queues[q])
    
    #if another customer in the queue then start a new service
    if length(state.queues[q]) ≥ 1
        push!(new_timed_events, TimedEvent(EndOfServiceAtQueueEvent(q), time + next_service_time(state, q))) 
    end
    
    #Finds new queue using routing matrix
    append!(new_timed_events, add_to_transit(q, state.params.P, time, state, job))

    return new_timed_events
end

""" Process a transit event """
function process_event(time::Float64, state::State, transit_event::InTransitEvent)
    state.in_transit -= 1
    return add_to_queue(transit_event.q, time, state)
end

""" Process a transit event with job tracking """
function process_event(time::Float64, state::TrackedNetworkState, transit_event::InTransitEvent)
    job = pop!(state.in_transit)
    return add_to_queue(transit_event.q, time, state, job = job)
end


"""
The main simulation function gets an initial state and an initial event that gets things going.
Optional arguments are the maximal time for the simulation, times for logging events, and a call back function.
"""
function simulate(init_state::State; 
                    init_timed_event::TimedEvent = TimedEvent(ExternalArrivalEvent(), 0.0), 
                    max_time::Float64 = 10.0, 
                    log_times::Vector{Float64} = Float64[],
                    call_back = (time,state) -> nothing)

    #The event queue
    priority_queue = BinaryMinHeap{TimedEvent}()

    #Put the standard events in the queue
    push!(priority_queue, init_timed_event)
    push!(priority_queue, TimedEvent(EndSimEvent(), max_time))
    for lt in log_times
        push!(priority_queue,TimedEvent(LogStateEvent(), lt))
    end

    #initilize the state
    state = deepcopy(init_state)
    time = 0.0

    call_back(time, state)

    #The main discrete event simulation loop - SIMPLE!
    while true
        #Get the next event
        timed_event = pop!(priority_queue)

        #advance the time
        time = timed_event.time

        #Act on the event
        new_timed_events = process_event(time, state, timed_event.event) 

        #if the event was an end of simulation then stop
        isa(timed_event.event, EndSimEvent) && break 

        #The event may spawn 0 or more events which we put in the priority queue 
        for new_event in new_timed_events
            push!(priority_queue, new_event)
        end

        call_back(time, state)
    end
end

