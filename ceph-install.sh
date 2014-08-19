# A very minimal ceph install script, using ceph-deploy
set -e
set -x

PKG_OK=$(dpkg-query -W --showformat='${Status}\n' ceph-deploy |grep "install ok installed")
if [ "" == "$PKG_OK" ]; then
    wget -q -O- 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc' | sudo apt-key add -
    echo deb http://ceph.com/packages/ceph-extras/debian $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph-extras.list
    sudo apt-add-repository 'deb http://ceph.com/debian-firefly/ $(lsb_release -sc)  main'
    sudo apt-get update
    sudo apt-get --yes install ceph-deploy
fi

HOST=$(hostname)
ceph-deploy purge $HOST
ceph-deploy new $HOST

cat <<EOF >> ceph.conf
osd pool default size=2
osd crush chooseleaf type = 0
EOF

ceph-deploy install $HOST
ceph-deploy mon create-initial $HOST

sudo mkdir /var/local/osd0
sudo mkdir /var/local/osd1
sudo mkdir /var/local/osd2

ceph-deploy osd prepare $host:/var/local/osd0 $host:/var/local/osd1 $host:/var/local/osd2
ceph-deploy osd activate  $host:/var/local/osd0 $host:/var/local/osd1 $host:/var/local/osd2
sleep 30 # Give some time for ceph to work its magic
sudo ceph health

