# KVM

## Host Network
### Disable IPv6
[see more](disable-ipv6.md)

### Setup bridged Interface
[see more](bridged-network.md)


## Install KVM

```bash
apt full-upgrade -y
```

```bash
apt install -y uvtool virtinst
```

## Sync image

```bash
uvt-simplestreams-libvirt --verbose sync release=focal arch=arm64
```

## List VMs

```bash
virsh net-list --all
```

## Configure Network

```bash
virsh net-destroy default                                                    
```

```bash
virsh net-undefine default
```                             

### Define Internal Network

```bash
cat << EOF > net-internal.xml
<network>                                                                       
  <name>internal</name>                                                         
  <uuid>790274ec-2590-4854-b432-ea7d22deb668</uuid>                             
  <forward mode='nat'>                                                          
    <nat>                                                                       
      <port start='1024' end='65535'/>                                          
    </nat>                                                                      
  </forward>                                                                    
  <bridge name='virbr1' stp='on' delay='0'/>                                    
  <mac address='52:54:00:c9:86:41'/>                                            
  <ip address='10.0.0.1' netmask='255.255.255.0'>                               
  </ip>                                                                         
</network>
EOF
```

```bash                                                                         
virsh net-define net-internal.xml                                               
```

```bash
virsh net-start internal                                                        
```

```bash
virsh net-autostart internal
```

### Define External  Network

```bash
cat << EOF > net-external.xml
<network>                                                                       
  <name>external</name>                                                         
  <uuid>790274ec-2590-4854-b432-ea7d22deb667</uuid>                             
  <forward mode="bridge"/>
  <bridge name="br0"/>
</network> 
EOF
```

```bash
virsh net-define net-external.xml                                               
```

```bash
virsh net-start external                                                        
```

```bash
virsh net-autostart external                                                    
```

## VM Template
### Create template

```bash
cat << EOF > vm-template.xml
<domain type='kvm'>                                                             
  <os>                                                                          
    <type>hvm</type>                                                            
    <boot dev='hd'/>                                                            
  </os>                                                                         
  <features>   
    <apic/>                                                                     
    <pae/>                                                                      
  </features>                                                                   
  <devices>                                                                     
    <interface type='network'>                                                  
      <source network='external'/>                                              
      <model type='virtio'/>                                                    
      <mac address='52:54:00:01:01:01'/>                                        
    </interface>                                                                
    <interface type='network'>                                                  
      <source network='internal'/>                                              
      <model type='virtio'/>                                                    
      <mac address='52:54:00:01:01:02'/>                                        
    </interface>                                                                
    <serial type='pty'>                                                         
      <source path='/dev/pts/3'/>                                               
      <target port='0'/>                                                        
    </serial>                                                                   
    <graphics type='vnc' autoport='yes' listen='127.0.0.1'>                     
      <listen type='address' address='127.0.0.1'/>                              
    </graphics>                                                                 
    <video/>                                                                    
  </devices>                                                                    
</domain>
EOF
```

### Template Test

```bash
uvt-kvm create --template ./vm-template.xml iptest release=focal
```

```bash
uvt-kvm ssh iptest ip a
```

```bash
uvt-kvm destroy iptest
```