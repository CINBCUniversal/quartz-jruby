require File.dirname(__FILE__) + '/spec_helper.rb'

class TestScheduler

  describe 'get the scheduler' do

    subject { SchedulerProxy.instance }

    before '#scheduler_factory' do
      subject.scheduler
      subject.run
    end

    it '#scheduler_factory has made one scheduler and its name is RMXScheduler' do
      schedulers = subject.scheduler_factory.getAllSchedulers
      expect(schedulers.size).to eq (1)
      expect(schedulers.iterator.next.getSchedulerName).to eq "RMXScheduler"
    end

    it '#the scheduler we are using is called RMXScheduler' do
      expect(subject.scheduler_name).to eq "RMXScheduler"
    end

    it '#run' do
      expect(subject).to receive(:run).exactly(1).times
      subject.run
    end

    it '#status' do
      expect(subject).to receive(:status).exactly(1).times
      subject.status
    end

    it '#stop' do
      expect(subject).to receive(:stop).exactly(1).times
      subject.stop
    end

    it '#run_once' do
      veggie_count = Concurrent::AtomicFixnum.new
      #run asap
      subject.run_once("eat your veggies", Proc.new { veggie_count.increment })

      sleep 4

      expect(veggie_count.value).to eq 1
    end

    it '#schedule_every second and sleep main thread for 10' do
      brush_teeth_count = Concurrent::AtomicFixnum.new
      #run now and then every 1 secs after
      subject.schedule("brush your teeth", :every => 1) do
        brush_teeth_count.increment
      end

      sleep 10

      expect(brush_teeth_count.value).to be_between(9, 11)
    end

    it '#schedule every 3 seconds and sleep for twelve seconds' do
      dessert_count = Concurrent::AtomicFixnum.new
      reference = subject.schedule "dessert", :cron => "0/3 0/1 * 1/1 * ? *" do
        dessert_count.increment
      end
      sleep 12
      expect(dessert_count.value).to be_between(3, 5)
    end

    it "#schedule naming conflict" do

      begin
        brush_teeth_count = Concurrent::AtomicFixnum.new


        subject.schedule("brush your teeth", :every => 10) do
          brush_teeth_count.increment
        end

        subject.schedule("brush your teeth", :every => 10) do
          brush_teeth_count.increment
        end

      rescue Java::OrgQuartz::ObjectAlreadyExistsException => e
        expect(e).to be_instance_of(Java::OrgQuartz::ObjectAlreadyExistsException)
      end

    end

    it "#scheduling with no naming conflict" do

      # Removes all the jobs from the scheduler from the previous tests
      subject.scheduler.clear

      brush_teeth_count = Concurrent::AtomicFixnum.new

      subject.schedule("brush my teeth", :every => 10) do
        brush_teeth_count.increment
      end

      subject.schedule("brush your teeth", :every => 10) do
        brush_teeth_count.increment
      end

    end

    it '#disallow concurrent jobs schedule every 1 seconds' do
      dessert_count = Concurrent::AtomicFixnum.new

      #cron says do it every 1 secs, but we disallow concurrent and the job sleeps for 5 secs
      subject.schedule "dessert", :disallow_concurrent => true, :cron => "0/1 0/1 * 1/1 * ? *" do
        dessert_count.increment
        sleep 5
      end

      sleep 5
      expect(dessert_count.value).to eq(1)
    end

    it '#allow concurrent jobs schedule every 1 seconds' do
      dessert_count = Concurrent::AtomicFixnum.new

      #cron says do it every 1 secs and the job sleeps for 5 secs, so jobs are just gonna pile up
      subject.schedule "concurrent dessert", :disallow_concurrent => false, :cron => "0/1 0/1 * 1/1 * ? *" do
        sleep 5
        dessert_count.increment
      end

      sleep 10
      expect(dessert_count.value).to be_between(5, 7)
    end

    #clean up the resources
    after(:all) do
      SchedulerProxy.stop
    end

  end

end