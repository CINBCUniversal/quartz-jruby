java_import 'org.quartz.JobKey'
java_import 'org.quartz.JobBuilder'
java_import 'org.quartz.TriggerBuilder'
java_import 'org.quartz.impl.StdSchedulerFactory'
java_import 'org.quartz.SimpleScheduleBuilder'
java_import 'org.quartz.CronScheduleBuilder'

java_import 'org.quartz.SchedulerException'

java_import 'java.lang.System'

module Quartz
  module Scheduler
    def self.included(base)
      base.class_eval do        
        include InstanceMethods
        extend ClassMethods
        include Singleton
      end
    end

    module ClassMethods
      def schedule(name, options, &block)
        instance.schedule(name, options, block)
      end

      def run_once(name, &block)
        instance.run_once(name, block)
      end

    end


    module InstanceMethods

      def scheduler_factory

        System.setProperty("org.quartz.threadPool.class", "org.quartz.simpl.SimpleThreadPool")
        System.setProperty("org.quartz.threadPool.threadCount", "50")
        System.setProperty("org.quartz.threadPool.threadPriority", "1")
        System.setProperty("org.quartz.threadPool.threadsInheritContextClassLoaderOfInitializingThread", "yes")

        @scheduler_factory ||= StdSchedulerFactory.new
      end

      def scheduler
        @scheduler ||= scheduler_factory.get_scheduler
      end

      def run
        puts scheduler.getSchedulerName
        if (scheduler.isStarted == false)
          puts "starting...."
          scheduler.start
        end
      end

      def status
        puts scheduler.getSchedulerName
        scheduler.getCurrentlyExecutingJobs
      end


      def job_code_blocks
        JobBlocksContainer.instance
      end

      def schedule(name, options, block)
        job_code_blocks.jobs[name.to_s] = block

        job_class = (options[:disallow_concurrent] ? Quartz::CronJobSingle : Quartz::CronJob)
        job = JobBuilder.new_job(job_class.java_class).with_identity("#{name}", self.class.to_s).build

        if options[:cron]
          trigger_schedule = CronScheduleBuilder.cron_schedule(options[:cron])
        else
          trigger_schedule = SimpleScheduleBuilder.simple_schedule.
                          with_interval_in_seconds(options[:every].to_i).repeat_forever
        end

        trigger = TriggerBuilder.new_trigger.with_identity("#{name}_trigger", self.class.to_s).
                          with_schedule(trigger_schedule).build

        puts scheduler.getSchedulerName
        scheduler.schedule_job(job, trigger)
      end

      def run_once(name, block)
        begin
          job_code_blocks.jobs[name.to_s] = block
          job_class = Quartz::CronJobSingle
          job = JobBuilder.new_job(job_class.java_class).with_identity("#{name}", self.class.to_s).build

          scheduler.addJob job, true

          response = scheduler.trigger_job(job.key)
        rescue SchedulerException => e
          $stderr.print "exception: #{e} "
        end
      end

      def interrupt
        scheduler.standby                                      # don't trigger new jobs
        scheduler.getCurrentlyExecutingJobs.each do |job_context|
          scheduler.interrupt(job_context.job_detail.key)      # interrupt job
        end
      end

      def stop
        interrupt
        scheduler.shutdown(true)
      end


    end
  end
end
