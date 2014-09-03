#!/usr/bin/env ruby

# uses AWS CLI 1.4.2 API definition

usage = "#{$0} <stack folder name>"
example = "#{$0} stg"

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

File.readlines("#{stack_path}/#{stack_folder}/servers.conf").each do |line| # read one line at a time
  # skip blank or commented lines
  next if line.match(/^\s*(#|$)/)
  data=line.split(/\s+/) # split the line into an array

  tier_name = data[0]
  instance_type = data[1]
  ami_name = data[2]
  sg_name_1 = data[3]
  sg_name_2 = data[4]
  public_ip = data[5]
  count = data[6].to_i

  puts "\n==> Getting the base AMI for the #{tier_name} server"
  ami_id = %x[aws ec2 describe-images --region #{REGION} --output text --filters "Name=name,Values=#{ami_name}"].match(/ami-\S+/)

  # if the server AMI can not be found, notify the user and exit.
  if ami_id.nil?
    puts "\nThe #{tier_name} server AMI could not be found."
    puts "Please double check the AMI name in servers.conf\n\n"
    exit(1)
  end

  # get the security group IDs)
  sg_id_1 = %x[aws ec2 describe-security-groups --region #{REGION} --output text --filter "Name=group-name,Values=#{sg_name_1}"].match(/sg-\S+/)
  sg_id_2 = %x[aws ec2 describe-security-groups --region #{REGION} --output text --filter "Name=group-name,Values=#{sg_name_2}"].match(/sg-\S+/)
    
  # set the public IP option
  public_ip_option = '--associate-public-ip-address' if public_ip == 'yes'
  
  
# Create the server/s and make name tags
  puts "==> Creating the #{tier_name} servers and name tags"

  puts "\nAMI name:  #{ami_name}"
  puts "#AMI ID:   #{ami_id}"
  puts "type:      #{instance_type}"
  puts "zone:      #{AZ}\n\n"

  1.upto(count) do |i|
    server_name = "#{STACK}-#{tier_name}-0#{i}"
    # create the server
    instance_id = %x[aws ec2 run-instances --region #{REGION} --subnet-id #{SUBNET} --output text --image-id #{ami_id} --key-name #{RSA_KEY} --security-group-ids #{sg_id_1} #{sg_id_2} --instance-type #{instance_type} --placement AvailabilityZone=#{AZ} #{public_ip_option}].match(/\s(i-\S+)/).to_s.sub(' ','')
    # create the name tag
    %x[aws ec2 create-tags --region #{REGION} --resources #{instance_id} --tags Key=Name,Value="#{server_name}"]
    puts "#{server_name}"
  end
end

puts "\n===== The #{STACK} servers have been created in #{AZ} and #{SUBNET} =====\n\n"

exit(0)

