#!/usr/bin/env bash

#!/bin/bash
while getopts r:i:b:a: option
do
case "${option}"
in
r) REPO=${OPTARG};;
i) BUILD_INSTANCE_ID=${OPTARG};;
b) BUCKET=${OPTARG};;
a) ROBOT_APP_ARN=${OPTARG};;
esac
done
echo "Adding changes..."
if ![ -d "$REPO" ]; then
  echo "Repo could not be found."
  exit 0
fi  
cd $REPO
git add .
git commit -m "auto build"
git push
cd ../
timeToComplete=0
echo "Starting build..."
output=$(aws ssm send-command --document-name "AWS-RunShellScript" --document-version "1" --targets "Key=instanceids,Values=$BUILD_INSTANCE_ID" --parameters '{"workingDirectory":["/home/ubuntu/"],"executionTimeout":["3600"],"commands":["./build.sh -b rootfs-nano/"]}' --timeout-seconds 600 --max-concurrency "50" --max-errors "0" --output-s3-bucket-name "$BUCKET" --output-s3-key-prefix "build-logs" --region us-west-2)
commandId=$(echo $output | jq -r .Command.CommandId)
instanceId=$BUILD_INSTANCE_ID
echo "Build ID: "$commandId
echo "Build Server Instance ID: "$instanceId
while [ : ]
do
  echo "Waiting for build to complete.. sleeping for 10 seconds..."
  timeToComplete=$((timeToComplete+10))
  sleep 10
  status=$(aws ssm get-command-invocation --command-id $commandId --instance-id $instanceId)
  echo $status | jq -r '.Status'
  if [ "$(echo $status | jq -r '.Status')" == "Success" ];
  then
     echo "Build finished!"
     if ![ -d "build-log" ]; then
        mkdir build-log
     fi
     mkdir build-log/$commandId
     aws s3 cp --recursive s3://$BUCKET/build-logs/$commandId/$instanceId/awsrunShellScript/0.awsrunShellScript/ build-log/$commandId/
     file=$(aws s3 ls s3://$BUCKET/dinobot/aarm64/ | tail -1)
     fileArr=($file)
     echo "Updating robot app with new tar: "${fileArr[3]}
     aws robomaker update-robot-application --application $ROBOT_APP_ARN --sources s3Bucket=$BUCKET,s3Key=dinobot/aarm64/${fileArr[3]},architecture=ARM64 --robot-software-suite name=ROS,version=Melodic
     echo "Total time in seconds was around..."$timeToComplete
     exit 0
  elif [ "$(echo $status | jq -r '.Status')" == "Error" ];
  then
     echo "There was an error. Copying logs..."
     aws s3 cp --recursive s3://$BUCKET/build-logs/$commandId/$instanceId/awsrunShellScript/0.awsrunShellScript/ build-log/$commandId/
     exit 0
  fi
done
