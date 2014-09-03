Create security groups and servers in AWS VPC

Prep

  Edit the path in create_xxx.rb to match your environment.

    # paths
    home = "/home/paul"
    stack_path = "#{home}/git-repos/aws/create.stack/stack.configs"

  Edit the config files to match your AWS account and requirements

    aws/create.stack/aws.conf.global
    aws/create.stack/stack.configs/<stack name>/aws.conf
    aws/create.stack/stack.configs/<stack name>/sgs.conf
    aws/create.stack/stack.configs/<stack name>/servers.conf

Create

  Create security groups

    ./create_sgs.rb <stack name>

  Create servers

    ./create_servers.rb <stack name>

    note: assumes the server uses two security groups (version 1)

