# Originally borrowed from ceph/qa licensed under LGPL
# remove the ceph directories
sudo rm -rf /var/log/ceph
sudo rm -rf /var/lib/ceph
sudo rm -rf /etc/ceph
sudo rm -rf /var/run/ceph

# remove the osds
for i in 0 1 2
do
    sudo rm -rf /var/local/osd$i
done

# remove rgw related confs
sudo rm /var/www/s3gw.fcgi
sudo a2dissite rgw && sudo rm /etc/apache/sites-available/rgw.conf

# remove the ceph packages
sudo apt-get -y  purge ceph
sudo apt-get -y  purge ceph-dbg
sudo apt-get -y  purge ceph-mds
sudo apt-get -y  purge ceph-mds-dbg
sudo apt-get -y  purge ceph-fuse
sudo apt-get -y  purge ceph-fuse-dbg
sudo apt-get -y  purge ceph-common
sudo apt-get -y  purge ceph-common-dbg
sudo apt-get -y  purge ceph-fs-common
sudo apt-get -y  purge ceph-fs-common-dbg
sudo apt-get -y  purge ceph-resource-agents
sudo apt-get -y  purge librados2
sudo apt-get -y  purge librados2-dbg
sudo apt-get -y  purge librados-dev
sudo apt-get -y  purge librbd1
sudo apt-get -y  purge librbd1-dbg
sudo apt-get -y  purge librbd-dev
sudo apt-get -y  purge libcephfs1
sudo apt-get -y  purge libcephfs1-dbg
sudo apt-get -y  purge libcephfs-dev
sudo apt-get -y  purge radosgw
sudo apt-get -y  purge radosgw-dbg
sudo apt-get -y  purge rest-bench
sudo apt-get -y  purge rest-bench-dbg
sudo apt-get -y  purge obsync
sudo apt-get -y  purge python-ceph
