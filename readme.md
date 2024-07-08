## cloudflare ddns updater

### prerequite

#### cloudflare account
#### cloudflare api token
#### cloudflare dns zone IDs and domain names
#### cloudflare dns records

The script can be run any home linux based VM as a scheduled crontab job.

`
./update_dns.sh <BASE_NAME1> [<BASE_NAME2> ... <BASE_NAMEN>]
`

This script will update the DNS records for BASE_NAME1.example1.com, BASE_NAME2.example3.com, and BASE_NAME3.example3.com (assuming corresponding zone IDs are in ZONE_IDS array) if the public IP address has changed. It dynamically constructs the full domain name (FQDN) for each base name by fetching the domain from the Cloudflare zone ID.

This is an homemade way to replace the no-ip.com DDNS, to avoid annoying 2 weeks renewal notice from DDNS.


Cloudflare can host dns and email and simple website permanently free, with many addon services like CDN/WAF etc.