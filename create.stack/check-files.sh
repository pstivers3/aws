#!/bin/bash

usage="usage: $0 <stack folder> <stack path>"
example="example: $0 stg ~/hs-git/aws/create.stack/stack.configs"

stack_folder=$1
help_state=$1
stack_path=$2

# If help_state=help, provide help information.
if [ "$help_state" = help ]; then
    echo 
    echo "$usage"
    echo "$example"
    echo
    exit 0
fi

# uncomment this line if chose not to use the 2nd argument on the command line 
# stack_path=~/aws/create.stack/stack.configs

# If the env folder or any of the stack files do not exist, notify the user and exit.

# If stack stack folder does not exist, notify the user and exit.
if [ ! -d $stack_path/$stack_folder ]; then
    echo
    echo "The stack folder \"$stack_path/$stack_folder\" does not exist."
    echo
    exit 1
fi

# If the aws.conf file does not exist, notify the user and exit.
if [ ! -f $stack_path/$stack_folder/aws.conf ]; then
    echo
    echo "The aws.conf file does not exist in the \"$stack_path/$stack_folder\" directory."
    echo 
    exit 1
fi

# If the aws.conf.global file does not exist, notify the user and exit.
if [ ! -f aws.conf.global ]; then
    echo
    echo "The aws.conf.global file does not exist in the \"$stack_path\" directory."
    echo 
    exit 1
fi

# If the sgs.conf file does not exist, notify the user and exit.
if [ ! -f $stack_path/$stack_folder/sgs.conf ]; then
    echo
    echo "The sgs.conf file does not exist in the \"$stack_path/$stack_folder\" directory."
    echo 
    exit 1
fi

# If the servers.conf file does not exist, notify the user and exit.
if [ ! -f $stack_path/$stack_folder/servers.conf ]; then
    echo
    echo "The servers.conf file does not exist in the \"$stack_path/$stack_folder\" directory."
    echo 
    exit 1
fi

exit 0

