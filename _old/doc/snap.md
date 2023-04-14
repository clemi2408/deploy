# SNAP

## Install SNAP

```bash
apt update
```

```bash
apt install snapd
```

```bash
echo 'export PATH=$PATH:/snap/bin' >> ~/.bashrc
```

```bash
snap version
```

## Snap Commands

```bash
snap refresh
```

```bash
snap find $snapname
```

```bash
snap info $snapname
```

```bash
sudo snap install $snapname
```

```bash
sudo snap install --channel=edge $snapname
```

```bash
sudo snap switch --channel=stable $snapname
```

```bash
sudo snap refresh --channel=beta $snapname
```

```bash
snap list
```

```bash
snap list --all $snapname
```

```bash
sudo snap refresh $snapname
```

```bash
sudo snap disable $snapname
```

```bash
sudo snap enable $snapname
```

```bash
sudo snap remove $snapname
```

```bash
sudo snap remove $snapname --purge
```

## Remove Snap

```bash
sudo apt purge snapd
```

```bash
rm -rf ~/snap
```


```bash
sudo rm -rf /var/cache/snapd 
```