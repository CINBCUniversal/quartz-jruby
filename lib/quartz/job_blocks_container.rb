module Quartz
  class JobBlocksContainer
    include Singleton

    attr_accessor :jobs
    def initialize
      @jobs ||= Concurrent::Hash.new
    end
  end
end