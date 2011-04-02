# This gem follows best practices for daemonizing processes in a UNIX
# environment with as little fluff as possible. Forks once, calls `setsid`,
# and forks again. STDIN, STDOUT, STDERR are all redirected to /dev/null by
# default. We'll manage the pidfile also.
#
# `chdir` and `umask` are optional precautions:
#
# * `chdir` is a safeguard against problems that would occur is you tried to
#   launch a daemon process on a mounted filesystem
# * `umask` gives your daemon process more control over file creation
#   permissions
#
# Notes
# $$ = Process.pid

require 'thread'

if RUBY_VERSION < '1.9'
  require 'system_timer'
  module Forker; Timeout = SystemTimer; end
else
  require 'timeout'
end

module Forker
  module CLI
    # You can use this if your daemon is simple enough or write your own and
    # use Forker#fork! directly
    def self.run(argv)
      require 'optparse'
      options = {}
      opts = OptionParser.new do |opts|
        opts.banner = "Usage: #{File.basename($0)} [start|stop] -p /path/to/pidfile.pid"

        opts.on("-l", "--logfile LOGFILE", "redirect output to this location") do |logfile|
          options[:log] = logfile
        end

        opts.on("-p", "--pidfile PIDFILE", "save pidfile to this location") do |pidfile|
          options[:pid] = pidfile
        end
      end
      opts.parse!(argv)

      if options[:pid].nil?
        puts opts
        exit
      end

      case argv.first
      when "start"
        Forker.fork!(options)
      when "stop"
        Forker.kill(options)
        exit
      else
        puts opts
        exit
      end
    end
  end

  def self.fork!(opts={})
    opts = { :log => "/dev/null", :pid => "/var/run/#{File.basename($0)}.pid" }.merge(opts)

    $stdout.sync = $stderr.sync = true
    $stdin.reopen("/dev/null")

    exit if fork

    Process.setsid

    exit if fork

    Dir.chdir("/")   if opts[:chdir]
    File.umask(0000) if opts[:umask]

    if File.exist?(opts[:pid])
      begin
        existing_pid = File.read(opts[:pid]).to_i
        Process.kill(0, existing_pid) # See if proc exists
        abort "error: existing process #{existing_pid} using this pidfile, exiting"
      rescue Errno::ESRCH
        puts "warning: removing stale pidfile with pid #{existing_pid}"
      end
    end

    File.open(opts[:pid], 'w') { |f| f.write($$) }

    at_exit do
      ( File.read(opts[:pid]).to_i == $$ and File.unlink(opts[:pid]) ) rescue nil
    end

    puts "forked process is #{$$}"
    puts "output redirected to #{opts[:log]}"

    $stdout.reopen(opts[:log], 'a')
    $stderr.reopen(opts[:log], 'a')
    $stdout.sync = $stderr.sync = true
  end

  def self.kill(opts={})
    begin
      pid = File.read(opts[:pid]).to_i
      sec = 60 # Seconds to wait before force killing
      Process.kill("TERM", pid)

      begin
        Timeout.timeout(sec) do
          loop do
            puts "waiting #{sec} seconds for #{pid} before sending KILL"
            Process.kill(0, pid) # See if proc exists

            sec -= 1
            sleep 1
          end
        end
      rescue Errno::ESRCH
        puts "killed process #{pid}"
      rescue Timeout::Error
        Process.kill("KILL", pid)
        puts "force killed process #{pid}"
      end

    rescue Errno::ENOENT
      puts "warning: pidfile #{opts[:pid]} does not exist"
    rescue Errno::ESRCH
      puts "warning: process #{pid} does not exist"
    end
  end
end
