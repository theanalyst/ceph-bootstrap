#!/bin/bash
set -x
sudo apt-get install -y radosgw radosgw-agent

zone=${1:-us-west}
zone2=${2:-us-east}
region=$(echo $zone | awk -F '-' '{print $1}')
fqdn=$(hostname -f)

sudo ceph osd pool create .$zone.rgw.root 8 8
sudo ceph osd pool create .$zone.rgw.control 8 8
sudo ceph osd pool create .$zone.rgw.gc 8 8
sudo ceph osd pool create .$zone.rgw.buckets 8 8
sudo ceph osd pool create .$zone.rgw.buckets.index 8 8
sudo ceph osd pool create .$zone.rgw.buckets.extra 8 8
sudo ceph osd pool create .$zone.log 8 8
sudo ceph osd pool create .$zone.intent-log 8 8
sudo ceph osd pool create .$zone.usage 8 8
sudo ceph osd pool create .$zone.users 8 8
sudo ceph osd pool create .$zone.users.email 8 8
sudo ceph osd pool create .$zone.users.swift 8 8
sudo ceph osd pool create .$zone.users.uid 8 8

if sudo ceph auth list | grep -q client.radosgw.$zone
then
    sudo ceph auth del client.radosgw.$zone
fi


sudo ceph-authtool --create-keyring /etc/ceph/ceph.client.radosgw.keyring
sudo chmod +r /etc/ceph/ceph.client.radosgw.keyring

sudo ceph-authtool /etc/ceph/ceph.client.radosgw.keyring -n client.radosgw.$zone --gen-key

sudo ceph-authtool -n client.radosgw.$zone --cap osd 'allow rwx' --cap mon 'allow rwx' /etc/ceph/ceph.client.radosgw.keyring


sudo ceph -k /etc/ceph/ceph.client.admin.keyring auth add client.radosgw.$zone -i /etc/ceph/ceph.client.radosgw.keyring

sudo mkdir -p /var/lib/ceph/radosgw/ceph-radosgw.$zone

sudo tee /etc/apache2/sites-available/rgw-$zone.conf > /dev/null <<EOF
FastCgiExternalServer /var/www/s3gw.fcgi -socket /var/run/ceph/ceph.radosgw.$zone.sock


<VirtualHost *:80>

	ServerName `hostname -f`
	ServerAdmin {email.address}
	DocumentRoot /var/www
	RewriteEngine On
	RewriteRule  ^/(.*) /s3gw.fcgi?%{QUERY_STRING} [E=HTTP_AUTHORIZATION:%{HTTP:Authorization},L]

	<IfModule mod_fastcgi.c>
   	<Directory /var/www>
			Options +ExecCGI
			AllowOverride All
			SetHandler fastcgi-script
			Order allow,deny
			Allow from all
			AuthBasicAuthoritative Off
		</Directory>
	</IfModule>

	AllowEncodedSlashes On
	ErrorLog /var/log/apache2/error.log
	CustomLog /var/log/apache2/access.log combined
	ServerSignature Off

</VirtualHost>
EOF

sudo a2ensite rgw-$zone.conf
sudo a2dissite 000-default


sudo tee /var/www/s3gw.fcgi > /dev/null <<EOF
#!/bin/sh
exec /usr/bin/radosgw -c /etc/ceph/ceph.conf -n client.radosgw.$zone
EOF


if ! grep -Fq "client.radosgw.$zone" /etc/ceph/ceph.conf
then
    sudo tee -a /etc/ceph/ceph.conf > /dev/null <<EOF
[client.radosgw.$zone]
rgw region = $region
rgw region root pool = .$region.rgw.root
rgw zone = $zone
rgw zone root pool = .$zone.rgw.root
keyring = /etc/ceph/ceph.client.radosgw.keyring
rgw dns name = $(hostname -s)
rgw socket path = /var/run/ceph/$name.sock
host = $(hostname -s)

[client.radosgw.$zone2]
rgw region = $region
rgw region root pool = .$region.rgw.root
rgw zone = $zone2
rgw zone root pool = .$zone2.rgw.root
keyring = /etc/ceph/ceph.client.radosgw.keyring
rgw dns name = $(hostname-s)
rgw socket path = /var/run/ceph/$name.sock
host = $(hostname -s)
EOF
fi

cat <<EOF > ind.json
{ "name": "$region",
  "api_name": "$region",
  "is_master": "true",
  "endpoints": [
        "http:\/\/$fqdn:80\/"],
  "master_zone": "$zone",
  "zones": [
        { "name": "$zone",
          "endpoints": [
                "http:\/\/$fqdn:80\/"],
          "log_meta": "true",
          "log_data": "true"},
        { "name": "$zone2",
          "endpoints": [
                "http:\/\/$fqdn:80\/"],
          "log_meta": "true",
          "log_data": "true"}],
  "placement_targets": [
   {
     "name": "default-placement",
     "tags": []
   }
  ],
  "default_placement": "default-placement"}

EOF

sudo radosgw-admin region set --infile ind.json --name client.radosgw.$zone

sudo radosgw-admin region default --rgw-region=$region --name client.radosgw.$zone

sudo radosgw-admin regionmap update --name client.radosgw.$zone

cat <<EOF > $zone.json
	{ "domain_root": ".$zone.domain.rgw",
	  "control_pool": ".$zone.rgw.control",
	  "gc_pool": ".$zone.rgw.gc",
	  "log_pool": ".$zone.log",
	  "intent_log_pool": ".$zone.intent-log",
	  "usage_log_pool": ".$zone.usage",
	  "user_keys_pool": ".$zone.users",
	  "user_email_pool": ".$zone.users.email",
	  "user_swift_pool": ".$zone.users.swift",
	  "user_uid_pool": ".$zone.users.uid",
	  "system_key": { "access_key": "", "secret_key": ""},
	  "placement_pools": [
	    { "key": "default-placement",
	      "val": { "index_pool": ".$zone.rgw.buckets.index",
	               "data_pool": ".$zone.rgw.buckets"}
	    }
	  ]
	}
 
EOF

cat <<EOF > $zone2.json
	{ "domain_root": ".$zone2.domain.rgw",
	  "control_pool": ".$zone2.rgw.control",
	  "gc_pool": ".$zone2.rgw.gc",
	  "log_pool": ".$zone2.log",
	  "intent_log_pool": ".$zone2.intent-log",
	  "usage_log_pool": ".$zone2.usage",
	  "user_keys_pool": ".$zone2.users",
	  "user_email_pool": ".$zone2.users.email",
	  "user_swift_pool": ".$zone2.users.swift",
	  "user_uid_pool": ".$zone2.users.uid",
	  "system_key": { "access_key": "", "secret_key": ""},
	  "placement_pools": [
	    { "key": "default-placement",
	      "val": { "index_pool": ".$zone2.rgw.buckets.index",
	               "data_pool": ".$zone2.rgw.buckets"}
	    }
	  ]
	}
 
EOF


sudo radosgw-admin zone set --rgw-zone=$zone --infile $zone.json --name client.radosgw.$zone
sudo radosgw-admin zone set --rgw-zone=$zone --infile $zone.json --name client.radosgw.$zone2

sudo radosgw-admin regionmap update --name client.radosgw.$zone

radosgw-admin user create --uid="$zone" --display-name="Region-$zone" --name client.radosgw.$zone --system
radosgw-admin user create --uid="$zone2" --display-name="Region-$zone2" --name client.radosgw.$zone2 --system
