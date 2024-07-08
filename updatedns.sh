#!/bin/bash

# Cloudflare account details
ZONE_IDS=("12345678910abcde" "12345678910abcde" "12345678910abcde")
API_TOKEN="12345678910abcde"

# Check if at least one BASE_NAME is provided as an argument
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <BASE_NAME1> [<BASE_NAME2> ... <BASE_NAMEN>]"
  exit 1
fi

# Get your current public IP address
IP=$(curl -s https://api.ipify.org)
echo "Current IP: $IP"

# Function to get domain name from zone ID
get_domain_name() {
  ZONE_ID=$1
  DOMAIN_NAME=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}" \
      -H "Authorization: Bearer ${API_TOKEN}" \
      -H "Content-Type: application/json" | jq -r '.result.name')
  echo $DOMAIN_NAME
}

# Function to update DNS record
update_dns_record() {
  ZONE_ID=$1
  BASE_NAME=$2

  # Get domain name from zone ID
  DOMAIN_NAME=$(get_domain_name $ZONE_ID)
  echo "DOMAIN_NAME of ZONE_ID=$ZONE_ID IS $DOMAIN_NAME"
  if [ -z "$DOMAIN_NAME" ]; then
    echo "Failed to get domain name for zone ${ZONE_ID}"
    return
  fi

  # Construct fully qualified domain name (FQDN)
  DNS_RECORD="${BASE_NAME}.${DOMAIN_NAME}" 
  echo "Updating DNS record for: ${DNS_RECORD}"

  # Get the DNS record ID by querying the current DNS record
  RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?name=${DNS_RECORD}" \
      -H "Authorization: Bearer ${API_TOKEN}" \
      -H "Content-Type: application/json" | jq -r '.result[0].id')

  # Check if we got a valid RECORD_ID
  if [ -z "$RECORD_ID" ]; then
      echo "Failed to get DNS record ID for ${DNS_RECORD} in zone ${ZONE_ID}"
      return
  fi

  # Fetch current DNS record details
  RECORD=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${RECORD_ID}" \
      -H "Authorization: Bearer ${API_TOKEN}" \
      -H "Content-Type: application/json")

  # Extract existing IP from the current DNS record
  EXISTING_IP=$(echo $RECORD | jq -r '.result.content')
  echo "Existing IP for ${DNS_RECORD} in zone ${ZONE_ID}: $EXISTING_IP"

  # Check if the IP has changed
  if [ "$IP" != "$EXISTING_IP" ]; then
    # Update the DNS record if the IP has changed
    RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${RECORD_ID}" \
        -H "Authorization: Bearer ${API_TOKEN}" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"A\",\"name\":\"${DNS_RECORD}\",\"content\":\"${IP}\",\"ttl\":120,\"proxied\":false}")

    # Check if the update was successful
    if echo "${RESPONSE}" | grep -q '"success":true'; then
        echo "DNS record for ${DNS_RECORD} in zone ${ZONE_ID} updated successfully."
    else
        echo "Failed to update DNS record for ${DNS_RECORD} in zone ${ZONE_ID}:"
        echo "${RESPONSE}"
    fi
  else
    echo "IP address for ${DNS_RECORD} in zone ${ZONE_ID} has not changed. No update needed."
  fi
}
# Iterate over provided BASE_NAMEs and predefined ZONE_IDs
for ZONE_ID in "${ZONE_IDS[@]}"; do
  for BASE_NAME in "$@"; do
    update_dns_record $ZONE_ID $BASE_NAME
  done
done