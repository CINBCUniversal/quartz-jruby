# Expose the internal Quartz Schedule
module Quartz
  class Schedule
    include Scheduler

    def find_running_job(job_name)
      running_jobs.map(&:get_job_detail).select { |detail| detail.get_name == job_name }
    end

    alias_method :running_jobs, :status

    # this class cannot be scheduled
    def schedule; end
    # this class cannot stop the scheduler
    def stop; end
  end
end
