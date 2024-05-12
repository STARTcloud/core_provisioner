<!-- PROJECT LOGO -->
<br />
<p align="center">
  <a href="https://github.com/STARTcloud/core_provisioner/">
    <img src="https://startcloud.com/assets/images/logos/startcloud-logo40.png" alt="Logo" width="200" height="100">
  </a>

  <h3 align="center">Core Provisioner</h3>

  <p align="center">
    Documentation for Core Provisioner
    <br />
    <a href="https://github.com/STARTcloud/core_provisioner/"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/STARTcloud/core_provisioner/">View Demo</a>
    ·
    <a href="https://github.com/STARTcloud/core_provisioner/issues">Report Bug</a>
    ·
    <a href="https://github.com/STARTcloud/core_provisioner/issues">Request Feature</a>
  </p>
</p>

<!-- TABLE OF CONTENTS -->
## Table of Contents

* [About the Project](#core-provisioner)
* [Key Features](#key-features)
* [Vagrantfile Explained](#vagrantfile-explained)
* [Roadmap](#roadmap)
* [Contributing](#contributing)
* [License](#license)
* [Contact](#authors)
* [Acknowledgements](#acknowledgments)


## Core Provisioner
Core Provisioner is a modular framework designed to simplify the provisioning of virtual machines using Vagrant, with a focus on flexibility and extensibility. It leverages a YAML configuration file (`Hosts.yml`) and a Ruby interpreter (`Hosts.rb`) to dynamically generate Vagrant configurations, allowing for a more declarative approach to setting up virtual environments. This project aims to streamline the provisioning process by integrating default SSH keys for STARTcloud Vagrant projects and adding support for Ansible, enhancing automation and consistency across deployments.

## Key Features

- **Declarative Configuration**: Utilizes `Hosts.rb` to parse `Hosts.yml`, a YAML file that contains all necessary configurations for setting up and running virtual machines.
- **Default SSH Keys**: Provides default SSH keys for all STARTcloud Vagrant projects, simplifying the authentication process.
- **Ansible Support**: Integrates Ansible support into the provisioning process, allowing for automated configuration management and deployment.

## Vagrantfile Explained
The Vagrantfile acts as the orchestrator that sets up and configures the virtual machines (VMs) based on the specifications found in the `Hosts.yml` file. It does this by requiring and executing the `Hosts.rb` script, which interprets the `Hosts.yml` file and generates the necessary Vagrant configurations. Here's a breakdown of what the Vagrantfile is doing:

- **Integration with `Hosts.rb`**: The Vagrantfile requires the `Hosts.rb` script, which is responsible for interpreting the `Hosts.yml` file. This integration allows the Vagrantfile to leverage the configurations defined in `Hosts.yml` to dynamically generate Vagrant configurations for the VMs.

- **Loading `Hosts.yml` Configurations**: The Vagrantfile reads the `Hosts.yml` file using Ruby's YAML library. This file contains all the necessary configurations for setting up and running the VMs, such as provider settings, network configurations, disk setups, and provisioning scripts.

- **Configuring Vagrant**: After loading the configurations from `Hosts.yml`, the Vagrantfile uses the `Hosts.configure` method from `Hosts.rb` to apply these configurations to the Vagrant environment. This method dynamically generates Vagrant configurations based on the specifications provided in `Hosts.yml`.

- **Provider Configuration**: The Vagrantfile specifies the version of Vagrant being used ("2") and delegates the actual configuration of the VMs to `Hosts.rb` through the `Hosts.configure` method. This allows for a flexible and provider-agnostic setup process, as `Hosts.rb` can handle different VM providers based on the configurations in `Hosts.yml`.

In essence, the Vagrantfile is a bridge between the declarative `Hosts.yml` file and the Vagrant environment, utilizing `Hosts.rb` to interpret and apply the configurations defined in `Hosts.yml`. This approach allows for a highly customizable and scalable setup process, making it easier to manage complex VM configurations.

## Roadmap
See the [open issues](https://github.com/STARTcloud/core_provisioner/issues) for a list of proposed features (and known issues).

## Provider Support

| Provider       | Supported by Core Provisioner |
|----------------|--------------------------------|
| VirtualBox     | Yes                            |
| Bhyve/Zones    | Yes                            |
| VMware Fusion  | No                             |
| Hyper-V        | No                             |
| Parallels      | No                             |
| AWS EC2        | Yes                            |
| Google Cloud   | No                             |
| Azure          | No                             |
| DigitalOcean   | No                             |
| Linode         | No                             |
| Vultr          | No                             |
| Oracle Cloud   | No                             |
| OpenStack      | No                             |
| Rackspace      | No                             |
| Alibaba Cloud  | No                             |
| Aiven          | No                             |
| Packet         | No                             |
| Scaleway       | No                             |
| OVH            | No                             |
| Exoscale       | No                             |
| Hetzner Cloud  | No                             |
| KVM            | Yes                            |
| QEMU           | Yes                            |
| Docker Desktop | No                             |
| HyperKit       | No                             |
| WSL2           | No                             |

## Built With
* [Vagrant](https://www.vagrantup.com/) - Portable Development Environment Suite.
* [VirtualBox](https://www.virtualbox.org/wiki/Downloads) - Hypervisor.
* [Ansible](https://www.ansible.com/) - Virtual Machine Automation Management.

## Contributing

Please read [CONTRIBUTING.md](https://www.prominic.net) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors
* **Joel Anderson** - *Initial work* - [JoelProminic](https://github.com/JoelProminic)
* **Justin Hill** - *Initial work* - [JustinProminic](https://github.com/JustinProminic)
* **Mark Gilbert** - *Refactor* - [MarkProminic](https://github.com/MarkProminic)

See also the list of [contributors](https://github.com/STARTcloud/core_provisioner/graphs/contributors) who participated in this project.

## License

This project is licensed under the SSLP v3 License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Hat tip to anyone whose code was used
