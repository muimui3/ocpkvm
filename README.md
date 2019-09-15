# Setting OCP 4.1 using KVM

This Guide will get you up and running using KVM `libvirt`. This setup should work for both RedHat or Centos OS 7.X. The ordered bare-metal IBM Cloud will act as KVM Host.

All the OpenShift Guest VM will be deployed using the following ansible scripts. 

> **NOTE**  Before you start the install make sure ordered portable IP address in IBM Cloud for this setup


## Setup KVM Host
Before we can use ansible scripts, we have to prep the host with installing ansible rpm and python library. 

```
sudo yum update
sudo yum install ansible
sudo yum install git
sudo yum install python-pip gcc make openssl-devel python-devel
```


If you want to install Gnome desktop to setup VNC 
```
yum groupinstall "GNOME Desktop" "Graphical Administration Tools"
yum install tigervnc*
ln -sf /lib/systemd/system/runlevel5.target /etc/systemd/system/default.target
reboot
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

## Run the playbook

Run the playbook to setup your helper node (using `-e staticips=true` to flag to ansible that you won't be installing dhcp/tftp)

```
ansible-playbook -e @vars-static.yaml -e staticips=true tasks/main.yml
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

