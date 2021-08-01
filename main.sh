#!/usr/bin/env bash

# Check if AWS in installed
hash aws >/dev/null 2>&1 || pip install awscli

# Listing all zones
ALL_ZONES=$(aws route53 list-hosted-zones-by-name)


EXCLUDE_DOMAINS='| select (
[ -v $EXCLUDE_DOMAINS ] || {
  for EXCLUDED_DOMAIN in $EXCLUDED_DOMAINS
  do

  done
}

# Excluding important zones
ZONES=$(echo ${ALL_ZONES} | jq -r '.HostedZones[] | 
select(
.Name!="" 
and 
.Name!="") 
| .Id')

for ZONE in ${ZONES}
do
  ALL_RECORDS=$(aws route53 list-resource-record-sets --hosted-zone-id ${ZONE})
  # Excluding SOA and NS entries
  RECORDS=$(echo ${ALL_RECORDS} |  jq -r '.ResourceRecordSets[]| select(.Type!="SOA" and .Type!="NS")')
  echo $RECORDS | jq '.| legth'
  read pn
done

