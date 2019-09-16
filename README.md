# Setting OCP 4.1 using KVM

This Guide will get you up and running using KVM `libvirt`. This setup should work for both RedHat or Centos OS 7.X. The ordered bare-metal IBM Cloud will act as KVM Host.

All the OpenShift Guest VM will be deployed using the following ansible scripts. 

> **NOTE**  Openshift 4.1 has a complicated installation.  Use the following URL to access the official RedHat documentation on installing Openshift 4.1 on VMware:
https://docs.openshift.com/container-platform/4.1/installing/installing_vsphere/installing-vsphere.html 

> The information in this document is written in a condensed format. For a more verbose explanation please refer to https://docs.openshift.com/container-platform/4.1/installing/installing_vsphere/installing-vsphere.html
 
> The automation and manual steps can all be pointed back to the above URL. Before you begin, understanding your IP address is very important.  The IP addresses in the following table were obtained from IC4G.  They are listed here for illustration purpose only. Besides setting up your ESXi and vCenter server, you also need to order a minimum of 16 portable IP address which will be used to assign to the VM’s. 

> Each VM node takes up one IP address.  The recommendation minimum of 16 portable IP addresses is determined by:
> 1 helper node + 1 boot node + 3 control-plane nodes + 3 worker nodes = 8 nodes
> IC4G reserves 4 IP addresses out of every portable IP subnet.  Therefore 8 + 4 = 12.
> The extra four IP addresses are for having a cushion.  This installation provisioned the vCenter on the same portable IP subnet, thus a total of 9 IP addresses are used.

## 	Architecture Diagram 
coming soon!!!!!!!!!!!!!!!!!

## Hardware requirements

![hardware](images/hardware.png)



## Setup KVM Host
Before we can use ansible scripts, we have to prep the host with installing ansible rpm and python library. 

```
sudo yum update
sudo rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum -y install ansible
sudo yum install git
sudo yum install python-pip gcc make openssl-devel python-devel
```


If you want to install Gnome desktop to setup VNC (CentOS)
```
yum groupinstall "GNOME Desktop" "Graphical Administration Tools"
yum install tigervnc*
ln -sf /lib/systemd/system/runlevel5.target /etc/systemd/system/default.target
reboot
```
If you want to install Gnome desktop to setup VNC (RHEL)
```
yum groupinstall "Server with GUI"

```
Log back in to setup 

```
vncserver
vncpasswd
```

## Prepare the Host KVM
```
cd /opt
git clone https://github.com/fctoibm/ocpkvm.git
cd /opt/ocpkvm
```

Edit the [vars.yaml](./vars.yaml) file with the IP addresss that will be assigned to the masters/workers/boostrap. The IP addresses need to be right since they will be used to create your OpenShift servers.

Edit the [hosts](./hosts) file kvmguest section to match helper node information. This should be similar to vars.yaml file 

## Run the playbook

Run the playbook to setup your helper node (using `-e staticips=true` to flag to ansible that you won't be installing dhcp/tftp)

```
ansible-playbook -e @vars.yaml  play.yaml

```
### Playbook fail for some reason 
If the ansible scripts fail you can execute the following script to clean the environment but do it your own risk

```
ansible-playbook -e @vars.yaml  clean.yaml
```


After it is done, ssh into the helper node to run the following command to get info about your environment and some install help

```
/usr/local/bin/helpernodecheck
```

## Install VMs

Launch `virt-manager`, and boot the VMs into the boot menu; and select PXE. You'll be presented with the following picture.

![pxe](images/pxe.png)

Boot/install the VMs in the following order

* Bootstrap
* Masters
* Workers

## Wait for install

The boostrap VM actually does the install for you; you can track it with the following command by ssh into helper node guest KVM.

```
cd /opt/ocp4
openshift-install wait-for bootstrap-complete --log-level debug
```

Once you see this message below...

```
DEBUG OpenShift Installer v4.1.0-201905212232-dirty 
DEBUG Built from commit 71d8978039726046929729ad15302973e3da18ce 
INFO Waiting up to 30m0s for the Kubernetes API at https://api.ocp4.example.com:6443... 
INFO API v1.13.4+838b4fa up                       
INFO Waiting up to 30m0s for bootstrapping to complete... 
DEBUG Bootstrap status: complete                   
INFO It is now safe to remove the bootstrap resources
```

...you can continue....at this point you can delete the bootstrap server.

## Finish Install

First, ssh into helper node guest KVM

```
cd /opt/ocp4
export KUBECONFIG=/root/ocp4/auth/kubeconfig
```

Set up storage for you registry (to use PVs follow [this](https://docs.openshift.com/container-platform/4.1/installing/installing_bare_metal/installing-bare-metal.html#registry-configuring-storage-baremetal_installing-bare-metal)

```
oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"storage":{"emptyDir":{}}}}'
```

If you need to expose the registry, run this command

```
oc patch configs.imageregistry.operator.openshift.io/cluster --type merge -p '{"spec":{"defaultRoute":true}}'
```

finish up the install process
```
openshift-install wait-for install-complete 
```
Following message should be shown 
```
INFO Waiting up to 30m0s for the cluster at https://api.test.os.fisc.lab:6443 to initialize... 
INFO Waiting up to 10m0s for the openshift-console route to be created... 
INFO Install complete!                            
INFO To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=/opt/ocp4/auth/kubeconfig' 
INFO Access the OpenShift web-console here: https://console-openshift-console.apps.test.os.fisc.lab 
INFO Login to the console with user: kubeadmin, password: ###-????-@@@@-**** 
```


## Update IP tables on KVM Host to access OpenShift URL

On KVM Host run the following commands

```
iptables -I FORWARD -o openshift4 -d  <HELPER_NODE_IP> -j ACCEPT
iptables -t nat -I PREROUTING -p tcp --dport 443 -j DNAT --to <HELPER_NODE_IP>:443
```
> **HINT** change the <HELPER_NODE_IP> address in above command to match your Helper node IP address

> Add following lines to your /etc/hosts files on from where you plan to access the Opensshift URL 

> <HELPER_NODE_IP> console-openshift-console.apps.<base_domain_prefix>.<base_domain>  oauth-openshift.apps.<base_domain_prefix>.<base_domain>


