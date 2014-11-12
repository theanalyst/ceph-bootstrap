akey='0555b35654ad1656d804'
skey='h7GhxuBLTrlhVUyxSPUKUV8r/2EI4ngqJxD7iBdBYLhwluN30JaT3Q=='
conf_fn='/etc/ceph/ceph.conf'
echo "setting up user testid"
sudo radosgw-admin user create --uid testid --access-key $akey --secret $skey --display-name 'M. Tester' --email tester@ceph.c\
om -c $conf_fn

akey='1555b35654ad1656d804'
skey='17GhxuBLTrlhVUyxSPUKUV8r/2EI4ngqJxD7iBdBYLhwluN30JaT3Q=='
sudo radosgw-admin user create --uid testid2 --access-key $akey --secret $skey --display-name 'N. Tester' --email tester2@ceph.c\
om -c $conf_fn

cat <<EOF > s3.conf
[DEFAULT]

## replace with e.g. "localhost" to run against local software
host = 127.0.0.1

## uncomment the port to use something other than 80
port = 8080

## say "no" to disable TLS
is_secure = no

[fixtures]
## all the buckets created will start with this prefix;
## {random} will be filled with random characters to pad
## the prefix to 30 characters long, and avoid collisions
bucket prefix = sometestbucket-{random}-

[s3 main]
## the tests assume two accounts are defined, "main" and "alt".

## user_id is a 64-character hexstring
user_id = testid

## display name typically looks more like a unix login, "jdoe" etc
display_name = M. Tester

## replace these with your access keys
access_key = 0555b35654ad1656d804
secret_key = h7GhxuBLTrlhVUyxSPUKUV8r/2EI4ngqJxD7iBdBYLhwluN30JaT3Q==
email = tester@ceph.com
[s3 alt]
## another user account, used for ACL-related tests
user_id = testid2
display_name = N. Tester
## the "alt" user needs to have email set, too
email = tester2@ceph.com
access_key = 1555b35654ad1656d804
secret_key = 17GhxuBLTrlhVUyxSPUKUV8r/2EI4ngqJxD7iBdBYLhwluN30JaT3Q==
EOF

