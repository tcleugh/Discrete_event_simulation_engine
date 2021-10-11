##############################################
######### Define all processing ##############
##############################################

#This is an abstract function 
"""
It will generally be called as 
       new_timed_events = process_event(time, state, event)
It will generate 0 or more new timed events based on the current event
"""
function process_event end

function process_event(time::Float64, state::State, es_event::EndSimEvent)
    println("Ending simulation at time $time.")
    return []
end

function process_event(time::Float64, state::State, ls_event::LogStateEvent)
    println("Logging state at time $time.")
    println(state)
    return []
end;

"""
Attempts to add a job to the specified queue and handles overflow if queue is full

Returns any new events created in the process
"""
function add_to_queue(q::Int, time::Float64, state::State)
    new_timed_events = TimedEvent[]

    if state.queues[q] < state.params.K[q]
        state.queues[q] += 1  #increase number in chosen queue
    
        #if this is the only job on the server engage service
        state.queues[q] == 1 && push!(new_timed_events,
                                    TimedEvent(EndOfServiceAtQueueEvent(q), time + next_service_time(state, q)))

    # if selected queue is full sends to overflow
    else
        # Selects a new queue bases on overflow matrix
        next_q = get_next_queue(q, state.params.Q)
        if next_q > 0
            state.in_transit += 1
            push!(new_timed_events, TimedEvent(InTransitEvent(next_q), time + travel_time(state)))
        end
    end

    return new_timed_events
end

function process_event(time::Float64, state::State, arrival_event::ExternalArrivalEvent)
    new_timed_events = TimedEvent[]

    next_q = get_entry_queue(state.params.p_e)
    append!(new_timed_events, add_to_queue(next_q, time, state))

    #prepare next arrival
    push!(new_timed_events, TimedEvent(ExternalArrivalEvent(), time + next_arrival_time(state)))

    return new_timed_events
end
 
#Process an end of service event
function process_event(time::Float64, state::State, eos_event::EndOfServiceAtQueueEvent)
    q = eos_event.q
    new_timed_events = TimedEvent[]
    
    state.queues[q] -= 1
    @assert state.queues[q] ≥ 0
    
    #if another customer in the queue then start a new service
    if state.queues[q] ≥ 1
        push!(new_timed_events, TimedEvent(EndOfServiceAtQueueEvent(q), time + next_service_time(state, q))) 
    end
    
    # Finds the next queue using the routing matrix
    next_q = get_next_queue(q, state.params.P)

    if next_q > 0
        state.in_transit += 1
        push!(new_timed_events, TimedEvent(InTransitEvent(next_q), time + travel_time(state)))
    end

    return new_timed_events
end

function process_event(time::Float64, state::State, transit_event::InTransitEvent)
    state.in_transit -= 1
    return add_to_queue(transit_event.q, time, state)
end




"""
The main simulation function gets an initial state and an initial event that gets things going.
Optional arguments are the maximal time for the simulation, times for logging events, and a call back function.
"""
function simulate(params::NetworkParameters; 
                    init_queues::Vector{Int} = fill(0, params.L),
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
    state = NetworkState(init_queues, 0, params)
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
