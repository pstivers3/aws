#!/usr/bin/env ruby

# This program does the following
#   1. reads the server names from AWS tags for a given environment and application
#   2. performs a rolling restart of the servers, taking one at a time out of rotation on the elb
# This script should  auto scale to any numbler of servers on the ELB (not tested beyond 2)
# If more than 2 servers, the algorith of checking that the previous server is in service
# before taking the next server aout of rotation, should be revisited.

# Potential updates to the script
# 1. utilize functions

usage = "#{$0} <env> <server type>"
example = "#{$0} performance rdx_agentless"

env = ARGV[0]
help_state = ARGV[0]
app = ARGV[1]
# region = 'us-east-1'
elb_name = "#{env}-external-lb"

# If help_state=help, provide help information.
if ( help_state == "-h" || help_state == "--help" || help_state == "help" )
  puts "\nusage: #{usage} \nexample: #{example} \n\n"
  exit(0)
end

# set paths
## control servers
home = '/home/ubuntu'
path_to_repo = "#{home}"
## paul local
# home = '/Users/paul.stivers'
# path_to_repo = "#{home}/repos"

# set the aws profile
profile = 'cli'

puts "#{Time.now} ===> start rolling restart of #{env} #{app} servers"
# If env is not a valid environment then notify the user and exit
env_test = %x[aws ec2 describe-tags --profile #{profile} --filters "Name=key,Values=Environment" "Name=value,Values=#{env}" | grep #{env} | head -1 | awk '{ print $5 }'].chomp
if env != env_test 
  puts "\n\"#{env}\" is not a valid environment."
  puts "usage: #{usage} \nexample: #{example} \n\n"
  exit(1)
end

# If app is not a valid application then notify the user and exit
app_test = %x[aws ec2 describe-tags --profile #{profile} --filters "Name=key,Values=Application" "Name=value,Values=#{app}" | grep #{app} | head -1 | awk '{ print $5 }'].chomp
if app != app_test 
  puts "\n\"#{app}\" is not a valid app."
  puts "usage: #{usage} \nexample: #{example} \n\n"
  exit(1)
end

# create an array of server names using ec2 describe-tags with the env and app as filters
server_name = %x[aws ec2 describe-tags --profile #{profile} --filters "Name=value,Values=*#{app}*" "Name=value,Values=*#{env}*" | grep '^TAGS' | awk '{ print $5 }'].split(' ')

# create an array of instance IDs and an array of private IPs for the servers, using ec2 describe-instances with server name as a filter
instance_id = []
server_ip = []
server_name.each_with_index { |server_name, i|
  instance_id[i] = %x[aws ec2 describe-instances --profile #{profile} --filters "Name=tag:Name,Values=#{server_name}" --query Reservations[*].Instances[*].InstanceId].chomp
  server_ip[i] = %x[aws ec2 describe-instances --profile #{profile} --filters "Name=tag:Name,Values=#{server_name}" --query Reservations[*].Instances[*].PrivateIpAddress].chomp
}

# ensure the 1st instance is registered on the elb
puts "#{Time.now} register instance #{instance_id[0]} on the #{elb_name}"
%x[aws elb register-instances-with-load-balancer --profile #{profile}  --load-balancer-name #{elb_name} --instances #{instance_id[0]}]
sleep(360)

# perform rolling restarts on the servers
server_health_check = []
total_servers = server_name.size
(0...total_servers).each { |i|
  # if health check on the ith instance is "InService", perform a rolling restart on the next instance
  server_health_check[i] = %x[aws elb describe-instance-health --profile #{profile}  --load-balancer-name #{elb_name} --instances #{instance_id[i]} | grep '^INSTANCESTATES' | awk '{ print $5 }'].chomp
  puts "#{Time.now} instance #{instance_id[i]} is #{server_health_check[i]}"
  if server_health_check[i] == 'InService'
    # if the ith server is the last server in the set, set index for the rolling restart to the first server in the set
    if i+1 >= total_servers 
      i = 0
    # otherwise set the index for the rolling restart to the next server in the set 
    else 
      i = i+1
    end
    # remove the ith instance from the ELB 
    puts "#{Time.now} remove instance #{instance_id[i]} on the #{elb_name}"
    %x[aws elb deregister-instances-from-load-balancer --profile #{profile} --load-balancer-name #{elb_name} --instances #{instance_id[i]}]
    sleep(10)
    # restart application on the ith server
    puts "#{Time.now} restart instance #{instance_id[i]}, IP #{server_ip[i]}"
    # %x[echo -e 'y' | #{path_to_repo}/deploy/bin/restart #{env} -l #{server_ip[i]} -a #{app}]
    %x[ssh deploy@#{server_ip[i]} "stop rdx_agentless"]
    sleep(10)
    %x[ssh deploy@#{server_ip[i]} "start rdx_agentless"]
    sleep(300)
    # register the ith server on the ELB
    puts "#{Time.now} register instance #{instance_id[i]} on the #{elb_name}"
    %x[aws elb register-instances-with-load-balancer --profile #{profile} --load-balancer-name #{elb_name} --instances #{instance_id[i]}]
    sleep(360)
  end
}
# perform health check on the first server 
server_health_check[0] = %x[aws elb describe-instance-health --profile #{profile} --load-balancer-name #{elb_name} --instances #{instance_id[total_servers - 1]} | grep '^INSTANCESTATES' | awk '{ print $5 }'].chomp
puts "#{Time.now} instance #{instance_id[0]} is #{server_health_check[0]}"
