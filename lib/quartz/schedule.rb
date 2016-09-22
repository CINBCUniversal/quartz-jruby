# Internal Quartz Schedule
module Quartz
  class Schedule
    include Scheduler

    class << self
      def find_running_job(job_name)
        instance.status.map(&:job_detail).select { |detail| detail.group == job_name }
      end
    end

    def schedule; end
    def stop; end
  end
end
