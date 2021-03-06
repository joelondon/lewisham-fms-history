# lewisham id from mapit.mysociety
mapitID=2492 \

# oldest lewisham date in fms is 2007-03-05

# use this old date to collect everything
# first_request_date=`date -j -f "%F" 2007-03-05 +"%s"` \

# use this date to upsert recent stuff only, updating/inserting records from last week
first_request_date=`date -v-8d +"%s"` \

# setup counter
(( c=1 ))

from=`date -v-"${c}"w +"%s"`
to=`date +"%s"`


while [[ $from > $first_request_date ]]; do
  start_date=`date -j -f "%s" $from "+%Y-%m-%d"`
  end_date=`date -j -f "%s" $to "+%Y-%m-%d"`
  echo $start_date - $end_date

    curl "https://www.fixmystreet.com/open311/v2/requests.json?jurisdiction_id=fixmystreet&agency_responsible=$mapitID&start_date=$start_date&end_date=$end_date" | \
    # flatten json
    jq .service_requests | jq '
        [.[] | 
        [leaf_paths as $path | {"key": $path | join("_"), "value": getpath($path)}]
        | from_entries]
    ' | \
    sqlite-utils upsert ./fms-history.db requests - --pk=service_request_id
  # move back in time week-by-week
  to=`date -v-"${c}"w +"%s"`
  (( c=c+1 ))
  from=`date -v-"${c}"w +"%s"`
done
