
# JUJU
## Bootstrap Juju Controller

### Check available regions
juju bootstrap --regions maas-cloud

### Bootstrap Controller VM
juju bootstrap maas-cloud/default juju01 \
--constraints "mem=1.5G cores=1 arch=arm64" \
--bootstrap-series=jammy \
--config bootstrap-timeout=10000 \
--to zone=local-lxd-zone \
--verbose --debug --keep-broken

### Setup Controller
juju change-user-password admin
juju upgrade-dashboard --list
juju dashboard

--> https://10.0.0.1:17070/dashboard








