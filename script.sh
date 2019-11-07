#!/usr/bin/env bash

# set this variable to a string that will search the log groups.
# Returns all Cloudwarch log groups with a name that contains this string.
# Use this to limit the deletion to groups with names that contain this string.
group_string_selector='Yada'

# Set some dates based on epoch
epoch_secs=`date +%s`
current_time=`expr ${epoch_secs} \* 1000` # converts epoch seconds into miliseconds to match AWS api output
seven_days_ago=`expr ${current_time} - 604800` # 10080 is 7 days in seconds

echo Current Time is = ${current_time}
echo Epoch Seven Days Ago is = ${seven_days_ago}

# Pull the list of log groups and parse with jq.
# returned list is ONLY matched based on name with string above.
log_groups=`aws logs describe-log-groups | \
    jq "[.logGroups[] | select(.logGroupName | contains (\"${group_string_selector}\"))]"`

# Iterate over the list of dictionaries that the above cli command returns.
# jq breaks the list into newlines.
echo ${log_groups} | jq -c '.[]' | while read i; do
    creation_time=`echo ${i} | jq -r '.creationTime'` # When the group was created
    group_name=`echo ${i} | jq -r '.logGroupName'` # Name of this log group
    if (( creation_time >= seven_days_ago )); then
      echo "deleting ${group_name}"
      # uncomment below line to enable deletion
      # aws logs delete-log-group --log-group-name ${group_name}
    else
      echo "NOT DELETING ${group_name} because its not old enough..."
    fi
done

