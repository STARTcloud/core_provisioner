# Core Provisioner

[![Core Provisioner logo](https://raw.githubusercontent.com/STARTcloud/startcloud_roles/refs/heads/main/roles/startcloud_theme/files/github-header.svg)](https://github.com/STARTcloud/core_provisioner/)

The shared Vagrant driver for STARTcloud provisioners

[**Explore the docs »**](https://github.com/STARTcloud/core_provisioner/)

[Report Bug](https://github.com/STARTcloud/core_provisioner/issues) ·
[Request Feature](https://github.com/STARTcloud/core_provisioner/issues)

## Table of Contents

* [About the Project](#about-the-project)
* [What Is in the Skeleton](#what-is-in-the-skeleton)
* [Consuming the Skeleton](#consuming-the-skeleton)
* [How It Fits Together](#how-it-fits-together)
* [Provider Support](#provider-support)
* [Releases](#releases)
* [Built With](#built-with)
* [Contributing](#contributing)
* [License](#license)
* [Contact](#authors)
* [Acknowledgements](#acknowledgments)

## About the Project

Core Provisioner is the shared Vagrant driver ("the skeleton") used by every STARTcloud provisioner (for example [startcloud_generic_provisioner](https://github.com/STARTcloud/startcloud_generic_provisioner)). It reads a declarative `Hosts.yml` and turns it into a full Vagrant machine definition — providers, networking, disks, synced folders, shell/Ansible/Docker provisioning, and post-provision syncback — via a single Ruby entry point, `Hosts.rb`.

## What Is in the Skeleton

| File | Purpose |
| ---- | ------- |
| `Hosts.rb` | The driver. Parses `Hosts.yml` and configures VirtualBox, UTM, and Bhyve/zones machines end to end |
| `Vagrantfile` | Consumer-facing stub with the driver self-bootstrap. Lives at a provisioner's repo root: when `driver/` is missing it fetches the release pinned in `driver.version`, verifies its `.sha256` sidecar, extracts, then requires the driver's `Hosts.rb` |
| `version.rb` | `CoreProvisioner::VERSION` — stamped into every provision's Ansible `extra_vars` and managed by release-please |
| `ssh_keys/` | The well-known bootstrap keypair. Insecure by design (like Vagrant's insecure key) — replaced at provision time when `vagrant_ssh_insert_key` is enabled |
| `ssls/` | The canonical development CA + default-signed certificate set. Ships inside the driver; consumers sync `./driver/ssls/ → /secure/` directly via `folders[]` and drop BYO certificates into the working copy's `driver/ssls/` |
| `examples/Hosts.yml` | A complete, commented example configuration |

## Consuming the Skeleton

Each release publishes fetchable archives as GitHub release assets:

* `core_provisioner-<version>.tar.gz` — the immutable, versioned archive. Pin an exact version and verify the `.sha256` sidecar after download.
* `core_provisioner.tar.gz` — a version-less copy at a stable URL (`releases/latest/download/core_provisioner.tar.gz`) for quick starts.

The archive's top-level directory is `driver/` — one untar at the consumer's repo root and the driver materializes:

```bash
sha256sum -c core_provisioner-0.2.12.tar.gz.sha256
tar -xzf core_provisioner-0.2.12.tar.gz
```

Consumers never commit `driver/`. It is gitignored and materializes two ways, both driven by the same pin:

* **At build**: the provisioner's build CI reads the repo's `driver.version` pin file (one line: the release tag, e.g. `v0.2.12`), downloads that exact archive, verifies the sidecar, and stages `driver/` into the release artifact.
* **At dev time**: the shipped `Vagrantfile` self-bootstraps — when `driver/` is missing it performs the same pinned fetch, verify, and extract, then requires `driver/Hosts.rb`.

Released provisioners must pin an exact core version — never a floating branch — so their release artifacts stay byte-reproducible.

`Hosts.rb` resolves its own paths, so the mount directory name is free — consumers still on the legacy `submodule` branch keep mounting it as `core/` and nothing breaks. New consumers should use release archives.

## How It Fits Together

* **`Hosts.yml`** — the declarative machine description: settings, networks, disks, zones/UTM/vbox provider blocks, provisioning playbooks, synced folders, roles, and vars. See `examples/Hosts.yml`.
* **`Hosts.rb`** — interprets `Hosts.yml` inside the consumer's Vagrant run and applies every setting to the chosen provider. It also handles post-provision work: results/adapter reporting, support-bundle and SSH-key syncback, and zones post-provision boot.
* **`Vagrantfile`** — the stub a provisioner ships at its root: bootstrap the driver if missing, load `Hosts.yml`, require the driver's `Hosts.rb`, call `Hosts.configure`.

The provisioning content itself (Ansible collections, templates, scripts, installers) belongs to the consuming provisioner, not to this repo.

Vagrant caveat: `vagrant rsync` reads the folder list snapshotted in `.vagrant/machines/<name>/<provider>/synced_folders` at up/reload — not live config. A folder newly declared in `Hosts.yml` needs one `vagrant reload` before `vagrant rsync` sees it. That is Vagrant core behavior; the driver re-declares folders fresh on every run.

## Provider Support

| Provider | Supported |
| -------- | --------- |
| VirtualBox | Yes |
| UTM (macOS) | Yes |
| Bhyve/Zones (vagrant-zones) | Yes |
| KVM / QEMU | Yes |
| VMware / Hyper-V / cloud providers | No |

## Releases

Releases are cut by [release-please](https://github.com/googleapis/release-please) from Conventional Commits on `main`, tagged plain `v<version>`, with `version.rb` managed in lockstep. The build job refuses to publish if the tag and `version.rb` disagree. See [RELEASE.md](RELEASE.md).

## Built With

* [Vagrant](https://www.vagrantup.com/) - Portable Development Environment Suite.
* [VirtualBox](https://www.virtualbox.org/wiki/Downloads) - Hypervisor.
* [Ansible](https://www.ansible.com/) - Virtual Machine Automation Management.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for the process for submitting pull requests, and our [Code of Conduct](CODE_OF_CONDUCT.md).

## Authors

* **Joel Anderson** - *Initial work* - [JoelProminic](https://github.com/JoelProminic)
* **Justin Hill** - *Initial work* - [JustinProminic](https://github.com/JustinProminic)
* **Mark Gilbert** - *Refactor* - [Makr91](https://github.com/Makr91)

See also [AUTHORS.md](AUTHORS.md) and the list of [contributors](https://github.com/STARTcloud/core_provisioner/graphs/contributors) who participated in this project.

## License

This project is licensed under the GNU Affero General Public License v3 - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

See [ACKNOWLEDGMENTS.md](ACKNOWLEDGMENTS.md) for the open-source projects this driver is built on.
