require 'java'

# java quartz imports
java_import 'org.quartz.CronTrigger'
java_import 'org.quartz.impl.StdSchedulerFactory'


module Quartz
  module Scheduler
    
    def self.included(base)
      base.class_eval <<-EOF
        include InstanceMethods
        extend ClassMethods
        include Singleton
      EOF
    end

    module ClassMethods
      def schedule(name, options, &block)
        instance.schedule(name, options, block)
      end
      def log
        org.apache.log4j.Logger.get_logger(self.name)
      end
      def info(msg)
        log.log(org.apache.log4j.Level::INFO, msg)
      end
      def error(msg)
        log.log(org.apache.log4j.Level::ERROR, msg)
      end
      def warn(msg)
        log.log(org.apache.log4j.Level::WARN, msg)
      end
    end

    module InstanceMethods
      def schedule(name, options, block)
        options = defaults.merge options
        job_factory.jobs[name.to_s] = block
        cron_class = (options[:stateful] ? CronStatefulJob : CronJob)
        puts "cron class: #{cron_class}"
        job_detail = JobDetail.new(name.to_s, "cronjob", cron_class.new(name.to_s))
        
        cron_expression = options[:cron]
        unless cron_expression
          at = Time.parse(options[:at]) rescue nil || options[:at]
          cron_expression = Cronify.cronify(options[:every], at)
        end
        
        trigger = CronTrigger.new("#{name.to_s}_crontrig", "cront_trig_group", name.to_s, "cronjob", cron_expression)
        scheduler.set_job_factory(job_factory)
        scheduler.schedule_job(job_detail, trigger)
      end
      def defaults
        {
          :at=>0
        }
      end
      def scheduler_factory
        @scheduler_factor ||= StdSchedulerFactory.new
      end
      def scheduler
        scheduler_factory.get_scheduler
      end
      def job_factory
        JobFactory.instance
      end
      def run
        scheduler.start
      end
    end
  end
end
