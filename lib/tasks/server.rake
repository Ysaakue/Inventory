desc 'start'
task :start do
  # start server
  system("rails s -p 3001 -b 0.0.0.0 -d")
  # start delay jobs
  system("bin/delayed_job -n 10 start")
end

desc 'stop rails'
task :stop do
  #stop server
  pid_file = 'tmp/pids/server.pid'
  pid = File.read(pid_file).to_i
  Process.kill 9, pid
  File.delete pid_file
  # stop delay jobs
  system("bin/delayed_job -n 10 stop")
end
