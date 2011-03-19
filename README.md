[![Build Status](http://travis-ci.org/bmarini/forker.png)](http://travis-ci.org/bmarini/forker)

# Goals

* Simplest code possible to daemonize code, redirect output and manage the
  pidfile.

## Usage

    require 'forker'
    Forker.fork(
      :log   => "/dev/null",                         # Default value
      :pid   => "/var/run/#{File.basename($0)}.pid", # Default value
      :chdir => false,                               # Default value
      :umask => false                                # Default value
    )

    # Do stuff in daemonized proc...

## Or for a simple start/stop script

    #!/usr/bin/env ruby
    # Example usage from command line:
    # ./bin/myscript start --logfile LOGFILE --pidfile PIDFILE
    # ./bin/myscript stop  --logfile LOGFILE --pidfile PIDFILE

    require 'forker'
    Forker::CLI.run(ARGV)

## Example bin/worker script for Resque

    #!/usr/bin/env ruby

    # Simulate calling rake environment
    $rails_rake_task = true

    # Load rails env
    require File.expand_path("../config/environment", File.dirname(__FILE__))

    require 'forker'
    Forker::CLI.run(ARGV)

    worker = nil
    queues = (ENV['QUEUES'] || ENV['QUEUE'] || '*').to_s.split(',')

    begin
      worker = Resque::Worker.new(*queues)
      worker.verbose = ENV['LOGGING'] || ENV['VERBOSE']
      worker.very_verbose = ENV['VVERBOSE']
    rescue Resque::NoQueueError
      abort "set QUEUE env var, e.g. $ QUEUE=critical,high,low rake resque:work"
    end

    puts "*** Starting worker in #{ENV['RAILS_ENV']} environment: #{worker}"

    worker.work(ENV['INTERVAL'] || 5) # interval, will block
