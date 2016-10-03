require 'spec_helper'

module Quartz
  describe Schedule do

    describe '#running_jobs' do
      it 'will return an array of running job details' do
        allow(Schedule.instance).to receive(:status) { [double(:job_context, job_detail: 'JobID')] }
        expect(Schedule.running.size).to eql(1)
      end
    end

    describe '#find_running_job' do
      it 'will find a job based on its group name' do
        job_detail = double(:job_detail, group: 'JobClass')
        allow(Schedule.instance).to receive(:status) { [double(:job_context, job_detail: job_detail)] }
        expect(Schedule.find_running_job('JobClass')).to eql([job_detail])
      end
    end
  end
end
