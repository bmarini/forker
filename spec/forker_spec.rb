require 'rubygems'
require 'bundler/setup'
require 'minitest/autorun'
require 'minitest/spec'
require 'fileutils'
require 'forker'

class Harness
  attr_accessor :output

  def run(args="")
    @output = `spec/harness #{args}`
  end

  def start(args="")
    run("start #{args}")
  end

  def stop(args="")
    run("stop #{args}")
  end

  def pid
    @output[/forked process is (\d+)/, 1]
  end

  def lsof
    `lsof -p #{pid} | awk '{print $4, $9}'`.split("\n").grep(/^(0r|1w|2w) /)
  end

  FD = Struct.new(:name, :path)
  def open_file_descriptors
    @open_file_descriptors = lsof.map { |l| FD.new(*l.split) }
  end
end

class ForkerSpec < MiniTest::Spec

  describe "Forker::CLI" do
    before { @harness = Harness.new }

    it "should provide a helpful usage banner" do
      @harness.run

      @harness.output.must_equal <<-EOS.lstrip
Usage: harness [start|stop] -p /path/to/pidfile.pid
    -l, --logfile LOGFILE            redirect output to this location
    -p, --pidfile PIDFILE            save pidfile to this location
      EOS
    end
  end

  describe "forking" do
    before do
      @harness = Harness.new
    end

    after do
      @harness.stop "-p spec/harness.pid"
      FileUtils.rm_f "spec/harness.log"
    end

    it "should announce the pid and logfile location" do
      @harness.start "-p spec/harness.pid"

      line1, line2 = @harness.output.split("\n")
      line1.must_match /forked process is (\d+)/
      line2.must_equal "output redirected to /dev/null"
    end

    it "should redirect stdin, stdout and stderr to dev/null by default" do
      @harness.start "-p spec/harness.pid"

      @harness.open_file_descriptors.each do |fd|
        fd.path.must_equal "/dev/null"
      end
    end

    it "should allow you to specify a logfile" do
      @harness.start "-l spec/harness.log -p spec/harness.pid"

      sleep 0.1
      File.exist?("spec/harness.log").must_equal true
      File.read("spec/harness.log").must_match /I love tests/
    end

    it "should allow you to specify a pidfile" do
      @harness.start "-p spec/harness.pid"
      File.exist?("spec/harness.pid").must_equal true
      @harness.pid.must_equal File.read("spec/harness.pid")
    end
  end
end