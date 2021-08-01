#!/usr/bin/env bash

# Check if AWS in installed
{ 
  hash aws || pip install awscli 
} >/dev/null 2>&1

# Listing all zones
ALL_ZONES=$(aws route53 list-hosted-zones-by-name)

# Excluding important zones
# Define SKIP_ZONES as domain.com. <-don't forget the dot in the end
if [[ -v SKIP_ZONES ]]
then
  EXCLUDE_DOMAINS='select ('
    for SKIP_ZONE in $SKIP_ZONES
    do
      EXCLUDE_DOMAINS+="$ADD_AND.Name!=\"${SKIP_ZONE}\""
      ADD_AND=" and "
    done
  EXCLUDE_DOMAINS+=")"
fi

# Get hosted zones ids
ZONES=$(echo ${ALL_ZONES} | jq -r ".HostedZones[] | $EXCLUDE_DOMAINS | .Id")

EXCLUDE_TYPES='select (.Type!="SOA" and .Type!="NS")'

for ZONE in ${ZONES}
do
  ALL_RECORDS=$(aws route53 list-resource-record-sets --hosted-zone-id ${ZONE})
  # Excluding SOA and NS entries
  aws route53 change-resource-record-sets \
    --hosted-zone-id ${ZONE} \
    --change-batch file://<(echo ${ALL_RECORDS} | \
  jq ".ResourceRecordSets[] | 
  $EXCLUDE_TYPES |
  {
    \"Changes\": 
    [
      {
        \"Action\": \"DELETE\",
        \"ResourceRecordSet\":
          {
            Name,
            Type,
            TTL,
            ResourceRecords
          }
      }
    ]
  } ")
done
