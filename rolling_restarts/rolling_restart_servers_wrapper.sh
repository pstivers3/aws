#!/bin/bash -l

environment=$1
app=$2

# Make sure aws cli tool is in the PATH
aws_path=`which aws`
if [ "$aws_path" == "" ]; then
  export PATH="/usr/local/bin:$PATH"
fi

$HOME/deploy/bin/rolling_restart_servers.rb $environment $app

