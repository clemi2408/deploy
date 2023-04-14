# Manual connect juju to maas

## Install Juju 
### Ubuntu

#### Install

```bash
snap install juju --classic
```

#### Remove

```bash
snap remove juju --purge
```

### Mac

#### Install

```bash
brew install juju
```

## Juju cloud configuration
### Create cloud configuration

```bash
cat << EOF > juju-cloud-region01-maas-srv-lan-bru-cloud.yaml
clouds:
  cloud-region01-maas-srv-lan-bru:
    type: maas
    auth-types: [oauth1]
    endpoint: http://10.0.0.20:5240/MAAS
EOF
```
   
### Create cloud credentials configuration

#### Get API Key

```bash

/snap/bin/maas apikey --username "admin"

```

#### Create cloud credential file

```bash
cat << EOF > juju-cloud-region01-maas-srv-lan-bru-cloud-creds.yaml
credentials:
  cloud-region01-maas-srv-lan-bru:
    anyuser:
      auth-type: oauth1
      maas-oauth: LxXTkPVgtYUsfJav3G:g8z7ep2Wb3qhLN4RZE:9kBYnC33vQPexeYcsEdJvdET7UKpZ62P
EOF
```

### Import cloud configuration

```bash
juju add-cloud --client -f juju-cloud-region01-maas-srv-lan-bru-cloud.yaml cloud-region01-maas-srv-lan-bru
```

### Import cloud credentials configuration

```bash
juju add-credential --client -f juju-cloud-region01-maas-srv-lan-bru-cloud-creds.yaml cloud-region01-maas-srv-lan-bru
```

## Juju cloud controller Dashboard

### Bootstrap controller

```bash
juju bootstrap -v --debug --config bootstrap-timeout=5000 --bootstrap-series=focal --constraints "mem=4.0G cores=2 arch=arm64" cloud-region01-maas-srv-lan-bru juju01
```

to remove a failed controller

```bash
juju unregister cloud-region01-maas-srv-lan-bru juju01
```

If you do have machines/pods running, then using the following might help (don’t run this on a production setup, tread carefully!):

```bash
juju kill-controller cloud-region01-maas-srv-lan-bru juju01
```

### Check Status

```bash
watch juju status
```

### Set Dashboard Login

```bash
juju change-user-password admin
```

```bash
juju change-user-password --reset admin
```

### Upgrade Dashboard

```bash
juju upgrade-dashboard --list
```

```bash
juju upgrade-dashboard
```

### Access Dashboard

```bash
https://juju01:17070/dashboard/controllers
```

### Destroy controller

```bash
juju destroy-controller jujucontroller01 --destroy-all-models
```


