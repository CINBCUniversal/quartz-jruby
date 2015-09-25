require 'quartz/jars/slf4j-log4j12-1.6.6'                                                                                
require 'quartz/jars/slf4j-api-1.6.6'                                                                                          
require 'quartz/jars/log4j-1.2.16'                                                                                                    
require 'quartz/jars/quartz-2.2.1'
require 'quartz/jars/quartz-jobs-2.2.1'

require 'log4jruby'
require 'concurrent'

java_import 'org.apache.log4j.Level'
java_import 'org.apache.log4j.ConsoleAppender'
java_import 'org.apache.log4j.PatternLayout'

java_import 'org.quartz.JobKey'
java_import 'org.quartz.JobBuilder'
java_import 'org.quartz.TriggerBuilder'
java_import 'org.quartz.impl.StdSchedulerFactory'
java_import 'org.quartz.SimpleScheduleBuilder'
java_import 'org.quartz.CronScheduleBuilder'
java_import 'org.quartz.SchedulerException'

java_import 'java.lang.System'

class Log4jruby::Logger
  def formatter=(formatter)
    @formatter = formatter
  end

  def formatter
    @formatter
  end
end

module Quartz
  module Scheduler
    def self.included(base)
      base.class_eval do
        include InstanceMethods
        extend ClassMethods
        include Singleton

        System.setProperty("org.quartz.threadPool.class", "org.quartz.simpl.SimpleThreadPool")
        System.setProperty("org.quartz.threadPool.threadCount", "50")
        System.setProperty("org.quartz.threadPool.threadPriority", "1")
        System.setProperty("org.quartz.threadPool.threadsInheritContextClassLoaderOfInitializingThread", "yes")
        System.setProperty("org.quartz.scheduler.instanceName", "RMXScheduler")

        console = ConsoleAppender.new
        console.setLayout(PatternLayout.new("%d [%p] %m%n"))
        console.setThreshold(Level.toLevel("INFO"))
        console.activateOptions
        org.apache.log4j.Logger.getRootLogger.addAppender(console)

      end
    end

    module ClassMethods

      def stop
        instance.stop
      end
    end


    module InstanceMethods

      def scheduler_factory
        @scheduler_factory ||= StdSchedulerFactory.new
      end

      def scheduler_name
        scheduler.getSchedulerName
      end

      def scheduler
        @scheduler ||= scheduler_factory.get_scheduler
      end

      def run
        if !scheduler.isStarted
          scheduler.start
        end
      end

      def status
        scheduler.getCurrentlyExecutingJobs
      end

      def schedule(name, options, &block)
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

        scheduler.schedule_job(job, trigger)

      rescue Java::OrgQuartz::ObjectAlreadyExistsException => e
        raise e
      end

      def run_once(name, block)

        begin
          job_code_blocks.jobs[name.to_s] = block
          job = JobBuilder.new_job(Quartz::CronJobSingle.java_class).with_identity("#{name}", self.class.to_s).build
         
          trigger = TriggerBuilder.new_trigger.with_identity("#{name}_trigger", self.class.to_s).start_now.build
          
          scheduler.schedule_job(job, trigger)
        rescue SchedulerException => e
          puts "exception: #{e} "
        end
          puts "job #{name} is scheduled at once"
      end

      def stop
        interrupt
        scheduler.shutdown(false)
        puts "scheduler was interrupted and shut down #{scheduler.isShutdown}"
      end

      private

      def interrupt
        scheduler.standby # don't trigger new jobs
        scheduler.getCurrentlyExecutingJobs.each do |job_context|
          scheduler.interrupt(job_context.job_detail.key) # interrupt job
        end
      end

      def job_code_blocks
        JobBlocksContainer.instance
      end

    end

  end
end
