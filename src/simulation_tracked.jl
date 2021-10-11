##############################################
######### Define all processing ##############
##############################################


"""
Attempts to add a job to the specified queue and handles overflow if queue is full

Returns any new events created in the process
"""
function add_to_queue(q::Int, time::Float64, state::TrackedNetworkState; job::Job = Job(time, time, -1))
    new_timed_events = TimedEvent[]

    capacity = state.params.K[q]
    if capacity == -1 || length(state.queues[q]) < capacity
        push!(state.queues[q], job) # adds job to selected queue
    
        #if this is the only job on the server engage service
        length(state.queues[q]) == 1 && push!(new_timed_events,
                                              TimedEvent(EndOfServiceAtQueueEvent(q), time + next_service_time(state, q)))

    # if selected queue is full sends to overflow
    else
        # Selects a new queue bases on overflow matrix
        next_q = get_next_queue(q, state.params.Q)
        if next_q > 0
            transit_time = time + travel_time(state)
            job.event_time = transit_time
            push!(state.in_transit, job)
            push!(new_timed_events, TimedEvent(InTransitEvent(next_q), transit_time))
        else
            job.exit_time = time
            push!(state.left_system, job)
        end
    end

    return new_timed_events
end
 
#Process an end of service event
function process_event(time::Float64, state::TrackedNetworkState, eos_event::EndOfServiceAtQueueEvent)
    q = eos_event.q
    new_timed_events = TimedEvent[]
    
    job = popfirst!(state.queues[q])
    
    #if another customer in the queue then start a new service
    if length(state.queues[q]) ≥ 1
        push!(new_timed_events, TimedEvent(EndOfServiceAtQueueEvent(q), time + next_service_time(state, q))) 
    end
    
    # Finds the next queue using the routing matrix
    next_q = get_next_queue(q, state.params.P)

    if next_q > 0
        job.event_time = time
        push!(state.in_transit, job)
        push!(new_timed_events, TimedEvent(InTransitEvent(next_q), time + travel_time(state)))

    else
        job.exit_time = time
        push!(state.left_system, job)
    end

    return new_timed_events
end

function process_event(time::Float64, state::TrackedNetworkState, transit_event::InTransitEvent)
    job = pop!(state.in_transit)
    return add_to_queue(transit_event.q, time, state, job = job)
end




"""
The main simulation function gets an initial state and an initial event that gets things going.
Optional arguments are the maximal time for the simulation, times for logging events, and a call back function.
"""
function simulate_tracked(params::NetworkParameters; 
                    max_time::Float64 = 10.0, 
                    init_timed_event::TimedEvent = TimedEvent(ExternalArrivalEvent(), 0.0),
                    log_times::Vector{Float64} = Float64[],
                    call_back = (time, state) -> nothing)

    #The event queue
    priority_queue = BinaryMinHeap{TimedEvent}()

    #Put the standard events in the queue
    push!(priority_queue, init_timed_event)
    push!(priority_queue, TimedEvent(EndSimEvent(), max_time))
    for lt in log_times
        push!(priority_queue,TimedEvent(LogStateEvent(), lt))
    end

    #initilize the state
    state = TrackedNetworkState([Vector{Job}[] for _ in 1:params.L], # Initial queues
                                BinaryMinHeap{Job}(),                # Intial transit
                                Vector{Job}[],                       # Initial left system
                                params
                                )
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
