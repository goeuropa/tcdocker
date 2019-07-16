#!/usr/bin/env bash
echo 'Starting agency looper'

# This should generate the basic TC.PROPERTIES files
# and fill in the agency id + gtfs realtime data,
# then later substitute.sh is called to replace
# the POSTGRES variables at runtime. 

__CONFIGPATH="/usr/local/transitclock/agencies"
__GENERIC="/usr/local/transitclock/agencies/__generic.properties"


for filename in /usr/local/transitclock/agencies/*.env; do
  [ -e "$filename" ] || continue
  source $filename
  NEW_CONFIG_PATH="${__CONFIGPATH}/${ID}.properties"

  # Copy generic props file to new one
  cp -n "${__GENERIC}" "${NEW_CONFIG_PATH}"
  chmod 777 "${NEW_CONFIG_PATH}"

  # Replace new props file with data
  sed -i "s|*AGENCYID|${ID}|g" "${NEW_CONFIG_PATH}"
  sed -i "s|*GTFSRT|${GTFSRT}|g" "${NEW_CONFIG_PATH}"
  sed -i "s|*AGENCYNAME|${NAME}|g" "${NEW_CONFIG_PATH}"
done

# Delete the generic template since it's no longer needed
rm -f "${__GENERIC}"

echo 'Finished agency looper'