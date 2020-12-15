## Domino NVIDIA Starter Kit

Domino NVIDIA Starter Kit provides a fast and simple installation of Kubernetes, [Domino](https://www.dominodatalab.com/), and all other dependencies on a single node for
use in demos of Domino software on [DGX hardware](https://www.nvidia.com/en-us/data-center/dgx-systems/) with [Multi-Instance GPU A100 modules](https://www.nvidia.com/en-us/technologies/multi-instance-gpu/).

For this project, we're using the [NVIDIA DeepOps](https://github.com/NVIDIA/deepops) tooling to install hardware
drivers, the NVIDIA container runtime, and Kubernetes 1.18.

Domino 4.3.3+ can then be installed from official release channels via the [fleetcommand-agent](https://admin.dominodatalab.com/en/4.3.2/installation/install.html).

### How to use Domino NVIDIA Starter Kit

- Quickly stand up Domino as an ML development and deployment layer on a single DGX machine
- Demo Domino on a variety of DGX hardware
- Demo Multi-Instance GPU capabilities on a machine with A100 Tensor Core modules, such as a p4.24xlarge EC2 instance

### How NOT to use Domino NVIDIA Starter Kit

- Since Domino NVIDIA Starter Kit deployments have no redundancy or backups, they should not be treated as durable production data science platforms
- Domino NVIDIA Starter Kit deployments can not currently be used to build multi-node clusters

<br />
<br />


**Contents**

* [Installation prerequisites](#installation-prerequisites)
* [Kubernetes and dependency installation](#kubernetes-and-dependency-installation)
* [Domino installation](#domino-installation)

<br />
<br />


### Installation prerequisites

- **Infrastructure**

  This process is only suitable for installing Domino on a **single NVIDIA GPU node**. The node should be running a
  DeepOps-compatible OS (Ubuntu 18.04 recommended) with Git installed, have unencumbered access to Domino release
  channels over the Internet, and have at least one
  [NVIDIA A100 Tensor Core GPU](https://www.nvidia.com/en-us/data-center/a100/) module installed.

  Record the IP address or hostname of this machine. You'll need it when configuring DNS for the Domino application.

- **DNS**

  Domino is a web application with multiple interlinked UI components, and must accordingly have a fully qualified domain
  name with which to self-reference. The installation process will generate a self-signed certificate for this name and
  configure Domino to serve it. Ideally, this would be a name for which you can control DNS for your organization,
  however you can use any name and override DNS in your `/etc/hosts` file if preferred.

  Record the FQDN you want to use to access Domino. You'll need it when running the Domino software installer.

- **Credentials**

  In order to download Domino component images from quay.io release channels, you will need a username and password
  provided by Domino. If you do not know your username and password, contact Domino at support@dominodatalab.com.

  Record these credentials. You'll need them when running the Domino software installer.




<br />
<br />


### Kubernetes and dependency installation

This command installs Kubernetes 1.18 plus NVIDIA GPU drivers and utilities on the node. The machine will restart twice during this installation.

`git clone https://github.com/dominodatalab/nvidia-starter-kit.git && cd nvidia-starter-kit/ && ./domino-nvidia-starter-kit-1.sh`

Once this completes, you are ready to install Domino.


<br />
<br />


### Domino installation

Run this script with the arguments shown from the `nvidia-starter-kit` directory to install Domino 4.3.3 into the local node Kubernetes environment.

`./install-domino.sh <FQDN_HOSTNAME> <QUAY_USERNAME> <QUAY_PASSWORD>`

Once the installation completes, you can access Domino by creating DNS records (or /etc/hosts entries) that
resolve the Domino FQDN to the IP address of your node. To get started, browse to a path of `/auth/`
(the trailing `/` is important) on your Domino FQDN to open the authentication service. Then follow
[these instructions in the Domino administrator's guide](https://admin.dominodatalab.com/en/4.3.2/keycloak.html) to
retrieve credentials and log in to the auth service, from which you can create users or enable independent signups.
