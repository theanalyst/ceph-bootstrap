set -x

sudo apt-get install -y apache2 libapache2-mod-fastcgi radosgw radosgw-agent

if !grep -Fq ServerName /etc/apache2/apache2.conf
then
    echo "Servername `hostname -f`" | sudo tee -a /etc/apache2/apache2.conf
fi

sudo a2enmod rewrite
sudo a2enmod fastcgi

echo "Restarting  Apache so that the foregoing changes take effect."

sudo service apache2 restart

sudo ceph-authtool --create-keyring /etc/ceph/ceph.client.radosgw.keyring
sudo chmod +r /etc/ceph/ceph.client.radosgw.keyring

sudo ceph-authtool /etc/ceph/ceph.client.radosgw.keyring -n client.radosgw.gateway --gen-key

sudo ceph-authtool -n client.radosgw.gateway --cap osd 'allow rwx' --cap mon 'allow rw' /etc/ceph/ceph.client.radosgw.keyring

sudo ceph -k /etc/ceph/ceph.client.admin.keyring auth add client.radosgw.gateway -i /etc/ceph/ceph.client.radosgw.keyring

echo "Add a Gateway Configuration to Ceph"

if !grep -Fq "client.radosgw.gateway" /etc/ceph/ceph.conf
then
    sudo tee -a /etc/ceph/ceph.conf > /dev/null <<EOF
[client.radosgw.gateway]
host = `hostname -s`
keyring = /etc/ceph/ceph.client.radosgw.keyring
rgw socket path = /var/run/ceph/ceph.radosgw.gateway.fastcgi.sock
log file = /var/log/ceph/client.radosgw.gateway.log 
EOF
fi

sudo tee /var/www/s3gw.fcgi > /dev/null <<EOF
#!/bin/sh
exec /usr/bin/radosgw -c /etc/ceph/ceph.conf -n client.radosgw.gateway
EOF

echo "Ensure that you apply execute permissions to s3gw.fcgi."

sudo chmod +x /var/www/s3gw.fcgi

echo "Creating a Data directory"

sudo mkdir -p /var/lib/ceph/radosgw/ceph-radosgw.gateway

sudo tee /etc/apache2/sites-available/rgw.conf > /dev/null <<EOF
FastCgiExternalServer /var/www/s3gw.fcgi -socket /var/run/ceph/ceph.radosgw.gateway.fastcgi.sock

<VirtualHost *:80>

	ServerName `hostname -f`
	ServerAdmin `whoami`@`hostname`
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

echo "For Debian/Ubuntu distributions, enable the site for rgw.conf."

sudo a2ensite rgw.conf

echo "Then, disable the default site."

sudo a2dissite 000-default

echo "Restarting apache"

sudo service apache2 restart

echo "start radosgw"

sudo /etc/init.d/radosgw start
