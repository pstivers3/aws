#!/usr/bin/env ruby

usage = "usage: #{$0} <stack folder name>"
example = "example: #{$0} paul"

stack_folder = ARGV[0]
help_state = ARGV[0]

# If help_state=help, provide help information.
if help_state == 'help' 
    puts "\n usage: #{usage} \n example: #{example} \n\n"
    exit 0
end

# paths
home = "/home/paul"
stack_path = "#{home}/git-repos/aws/create.stack/stack.configs"

# if no stack folder name is given, notify the user and exit
if stack_folder.nil?
  puts "\nerror: no stack folder name\n#{usage}\n#{example}\n\n"
  exit(1)
end

# Check that all the config files exist.
system("./check-files.sh #{stack_folder} #{stack_path}")
# If the called script exits with non-zero exit status, then also exit this script.
exit($?.to_i) if $?.exitstatus != 0

# source configuration constants
eval File.read("#{stack_path}/#{stack_folder}/aws.conf")
eval File.read("aws.conf.global")
system("source #{home}/ec2.env")

sg_name_last = ''
# create security groups and rules
File.readlines("#{stack_path}/#{stack_folder}/sgs.conf").each do |line| # read one line at a time from sgs.conf
  next if line.match(/^\s*(#|$)/) # skip blank or commented lines
  data=line.split(/\s+/) # split the line into an array
  sg_name=data[0]
  protocol=data[1]
  port=data[2]
  source=data[3]
  xgress=data[4]

  # get the sg_id
  sg_id = %x[aws ec2 describe-security-groups --region #{REGION} --output text --filter "Name=group-name,Values=#{sg_name}"].match(/sg-\S+/)

  # if the first time the sg_name is encounterd
  if sg_name != sg_name_last
    # if the security group doesn't exist, create it 
    if sg_id.nil?
      puts "\n= Creating the #{sg_name} security group =\n\n"
      sg_id = %x[aws ec2 create-security-group --region #{REGION} --vpc-id #{VPC_ID} --output text --group-name #{sg_name} --description "Security_group_for_#{sg_name}"].match(/sg-\S+/)
      puts "sg_id  = #{sg_id}\n"
    else
      puts "\n= The #{sg_name} security group already exists =\n\n"
      puts "sg_id  = #{sg_id}\n"
    end
  end
  sg_name_last = sg_name

  # get the ID of the default security group
  default_sg_id = sg_id if default_sg_id.nil?  
  if source == 'dsg'  
    source = default_sg_id
    source_option = '--source-group'
  else
    source_option = '--cidr'
  end

  # output the sg_name and the aws CLI command
  puts "#{sg_name}: aws ec2 authorize-security-group-#{xgress} --region #{REGION} --group-id #{sg_id} --protocol #{protocol} --port #{port} #{source_option} #{source}"
  # create the security rule
  puts %x[aws ec2 authorize-security-group-#{xgress} --region #{REGION} --group-id #{sg_id} --protocol #{protocol} --port #{port} #{source_option} #{source}]
end
puts ""

exit(0)

