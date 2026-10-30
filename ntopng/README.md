# Home Assistant Add-on: ntopng

Community version of ntopng with opensource NetFlow collector netflow2ng
  - Sample packet information from your router (eg. **Using softflowd** on OpenWRT )
  - Send to netflow2ng which in-turn sends to ntopng - both are installed as Home Assistant Add-ons


## Installation


### Install the Add-On 


Install this Add-On to your Home Assitant (tested on 2026.10.x)


Sign up for the https://www.maxmind.com/ GeoLite2 service to get the GeoLite2 City and ASN databases

Add the acct# and API key to the Add-On config

### Set up a NetFlow packet sender on your router

The following is an example from /etc/config/softflowd :

```text
config softflowd
    option enabled        '1'
    option interface      'br-lan'
    option host_port      '192.168.1.99:2055' # YOUR HOME ASSISTANT IP
    option export_version '9'          # better than 5; use '10' if you want IPFIX
    option max_flows      '8192'
    option tracking_level 'full'
    option track_ipv6     '1'
    option bidirectional  '0'          # set to '1' only if export_version='10'
    option sampling_rate  '100'        # sample ONE OUT OF EVERY 100 packets!
    option timeout        ''
    option filter         ''
    option pid_file       '/var/run/softflowd.pid'
    option control_socket '/var/run/softflowd.ctl'
```

