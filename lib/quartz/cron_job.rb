require 'jruby/core_ext'
java_import 'org.quartz.InterruptableJob'
java_import 'org.quartz.JobExecutionContext'
java_import 'org.quartz.DisallowConcurrentExecution'

module Quartz
  class CronJob
    include org.quartz.InterruptableJob

    attr_accessor :interrupted

    def interrupted?
      !!interrupted
    end

    add_method_signature('execute', [java.lang.Void::TYPE, JobExecutionContext])
    def execute(context)
      job_block = JobBlocksContainer.instance.jobs[context.job_detail.name]      
      job_block.call(self)
    end
    
    add_method_signature('interrupt', [java.lang.Void::TYPE])
    def interrupt
      # Simple interrupting - code needs to check job.interrupted? periodically
      # Using Java's thread.interrupt() doesn't make sense currently, b/c JRuby
      # ignores InterruptedException (http://jira.codehaus.org/browse/JRUBY-4135)
      self.interrupted = true
    end    
  end
  
  class CronJobSingle < CronJob
    add_class_annotations({ DisallowConcurrentExecution => {} }) 
  end
  
  CronJob.become_java!
  CronJobSingle.become_java!  
end
