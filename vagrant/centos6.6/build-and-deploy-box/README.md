CentOS 6.6 OZP Build and Deploy Box
========================================
This Vagrant box will build, package, and deploy the following OZP applications
(note that you may need to replace `localhost` with your host's IP address,
depending on your setup):

* [REST service](https://localhost:7799/marketplace/api)
* [Center](https://localhost:7799/center)
* [HUD](https://localhost:7799/hud)
* [Webtop](https://localhost:7799/webtop)
* [IWC (debugger)](https://localhost:7799/iwc/debugger/index.html)
* [Demo Apps](https://localhost:7799/demo_apps)
* [HAL Browser](https://localhost:7799/iwc/debugger/index.html/#hal-browser/https://localhost:5443/marketplace/api)
* [Tomcat web UI](http://localhost:5808/manager/html/) (username: tomcat, password: password)

Basic Authentication is used to access the OZP applications above. Use any of
the following credentials to log in:

* testUser1, password (role: USER)
* testAdmin1, password (role: ADMIN)
* testOrgSteward1, password (role: ORG_STEWARD)

## Usage
First, install VirtualBox and Vagrant on your host, which are all available for
Windows, OS X, and Linux. Make sure you have a current version of vagrant, at
least v1.6 (check this with `vagrant -v`). If not, head over to the Vagrant
homepage to download the latest version for your OS.

You may also wish to install the `vagrant-vbguest` plugin which keeps your
Guest Additions up to date: `vagrant plugin install vagrant-vbguest` (this may
not work on a Windows host)

In most cases, you'll want to use your host's IP address to access the apps (
instead of simply localhost, which would only work from your local machine).
Enter your host's IP in `deploy.sh` (the HOST_IP variable at the top of the
file). Note that if your host's IP changes in the future (after you've gone
through the steps below), update the `HOST_IP` variable accordingly and just
re-reun `/vagrant/deploy.sh` on the VM.

Now, run `vagrant up` in this directory and, after provisioning
is complete (**typically 35-55 minutes**), access the OZP applications from your
host at the URLs listed above. Alternateively, it may be helpful to catpure
a log output to assist with any problems: `vagrant up 2>&1 | tee vagrant.log` (
assuming you are running on Linux or OS X host)

By default, the contents of `~/ozp` on your host are rsynced with the vagrant
box. This is useful for development purposes, where the code you're editing
lives on your host and needs to get to the VM for execution. Run `vagrant rsync`
to update the contents of `/home/vagrant/ozp` in the VM

**Windows Users**: If things don't go well, try re-running (from the host):
`vagrant ssh -c "/vagrant/build.sh; /vagrant/package.sh; /vagrant/deploy.sh;"`

## Details
ozp-rest is run under Tomcat, using an actual MySQL database and Elasticsearch
instance (as opposed to the in-memory versions often used in development). The
front-end resources are hosted via nginx, and nginx is also used as a reverse
proxy, such that all resources (front and back end) are served from the same
domain.

When this box is initially provisioned, `bootstrap.sh` is executed, which in
turn runs four scripts:

* `initial_provisioning.sh`: installs dependencies (Java, Grails, MySQL, etc),
configures dependencies, and copies **insecure** SSL keys for use by nginx and
Tomcat. Unlike the other three scripts, this one should only be run once
* `build.sh`: clones the ozp applications from GitHub and builds them
* `package.sh`: tars and compresses the compiled output from the previous step
* `deploy.sh`: move the previously created artifacts to the right places, and
perform any configuration required for deployment

## Potential Issues/Troubleshooting
1. Firewalls sometimes cause problems - if so, `sudo service iptables stop`
2. `deploy.sh` will wait 2 minutes for ozp-rest to start up. On very slow
or resource-starved machines, that might not be long enough
3. If you change the rsync directory in the Vagrantfile, do NOT rsync a
directory that includes this one

## Developers
This VM has also been designed to be ozp-developer friendly. The anticipated
workflow goes like this:

1. Clone this repo and run `vagrant up`, getting this VM up and running
2. Edit OZP application code on the host box, somewhere inside the directory
that is rsynced with the VM (by default, this is ~/ozp on the host - this can be
changed in the Vagrantfile if desired)
3. After making code changes on the host, the code needs to be
redeployed on the VM for testing. At a high level, this means 1) running
`vagrant rsync` to get the code to the VM, and 2) running some script on the
VM to copy that code to the right place, build it (if not pre-built), restart
servers, etc.

## Helpful Hints:
    * If prompted for a password after running "vagrant up" the password should be "vagrant"
    * rsync will not work on windows.  the command will have to be comment out from the VagrantFile
    * nginx error log:  `/var/log/nginx/error.log`
    * nginx access log:  `/var/log/nginx/access.log`
    * restart nginx: `nginx -s reload` or `sudo service nginx restart`
    * Logs (backend): /var/log/tomcat/, /usr/share/tomcat/logs/
    * verify that elasticsearch is running: `sudo netstat -lnp | grep 9300`
    * sudo multitail -i /usr/share/tomcat/logs/marketplace.log -i /usr/share/tomcat/logs/stacktrace.log -i /var/log/tomcat/localhost_access_log.2015-04-04.txt -i /var/log/tomcat/catalina.out -i /var/log/tomcat/localhost.2015-04-04.log  -i /var/log/nginx/error.log -i /var/log/nginx/access.log  -s 2 -sn 4
    # multitail: F1 for help, O to clear all windows, o to clear specific window, 0..9 to set a marker in the correspond window to easily see what's changed, B to merge all into one
    * from Modern IE VMs, http://10.0.2.2 to get to host box. This means we need to adjust the paths in OzoneConfig.js to use 10.0.2.2 instead of localhost
    * IE testing: Always enable Cache->Always Refresh From Server option in F12 dev tools
    * clear the elasticsearch data: curl -XDELETE 'http://localhost:9200/marketplace' (done on local box, not from host (would need port fwd))
    # elasticsearch data at /var/lib/elasticsearch

