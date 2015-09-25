require 'java'
$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'singleton'

# require jars                                                                                                                 
require 'quartz/jars/slf4j-log4j12-1.6.6'                                                                                
require 'quartz/jars/slf4j-api-1.6.6'                                                                                          
require 'quartz/jars/log4j-1.2.16'                                                                                                    
require 'quartz/jars/quartz-2.2.1'
require 'quartz/jars/quartz-jobs-2.2.1'

require 'quartz/cron_job'
require 'quartz/job_blocks_container'
require 'quartz/scheduler'
