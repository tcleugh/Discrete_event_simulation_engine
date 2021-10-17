
mutable struct Job 
    entry_time::Float64
    exit_time::Float64
end

Job(exit_time::Float64) = Job(exit_time, exit_time)

""" Returns the duration of time the job has spent in the system """
duration(job::Job)::Float64 = job.exit_time - job.entry_time


isless(j1::Job, j2::Job) = j1.exit_time < j2.exit_time

function show(io::IO, job::Job)
    print(io, "Job(E: $(job.entry_time), L: $(job.exit_time))")
end