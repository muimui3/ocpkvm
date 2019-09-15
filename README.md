# Setting OCP 4.1 using KVM

This Guide will get you up and running using KVM `libvirt`. This setup should work for both RedHat or Centos OS 7.X. The ordered bare-metal IBM Cloud will act as KVM Host.

All the OpenShift Guest VM will be deployed using the following ansible scripts. 

> **NOTE**  Before you start the install make sure ordered portable IP address in IBM Cloud for this setup


## Setup KVM Host
Before we can use ansible scripts, we have to prep the host with installing ansible rpm and python library. 

```
sudo yum update
sudo yum install ansible
yum install python-pip gcc make openssl-devel python-devel
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
