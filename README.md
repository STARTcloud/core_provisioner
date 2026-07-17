<!-- PROJECT LOGO -->
<br />
<p align="center">
  <a href="https://github.com/STARTcloud/core_provisioner/">
    <img src="https://startcloud.com/assets/images/logos/startcloud-logo40.png" alt="Logo" width="200" height="100">
  </a>

  <h3 align="center">Core Provisioner</h3>

  <p align="center">
    The shared Vagrant driver for STARTcloud provisioners
    <br />
    <br />
    <a href="https://github.com/STARTcloud/core_provisioner/issues">Report Bug</a>
    ·
    <a href="https://github.com/STARTcloud/core_provisioner/issues">Request Feature</a>
  </p>
</p>

## Core Provisioner

Core Provisioner is the shared Vagrant driver ("the skeleton") used by every STARTcloud provisioner (for example [startcloud_generic_provisioner](https://github.com/STARTcloud/startcloud_generic_provisioner)). It reads a declarative `Hosts.yml` and turns it into a full Vagrant machine definition — providers, networking, disks, synced folders, shell/Ansible/Docker provisioning, and post-provision syncback — via a single Ruby entry point, `Hosts.rb`.

## What's in the skeleton

| File | Purpose |
| ---- | ------- |
| `Hosts.rb` | The driver. Parses `Hosts.yml` and configures VirtualBox, UTM, and Bhyve/zones machines end to end |
| `Vagrantfile` | Consumer-facing stub. Lives at a provisioner's repo root and requires the skeleton's `Hosts.rb` from `core/` |
| `version.rb` | `CoreProvisioner::VERSION` — stamped into every provision's Ansible `extra_vars` and managed by release-please |
| `ssh_keys/` | The well-known bootstrap keypair. Insecure by design (like Vagrant's insecure key) — replaced at provision time when `vagrant_ssh_insert_key` is enabled |
| `examples/Hosts.yml` | A complete, commented example configuration |

## Consuming the skeleton

Each release publishes fetchable archives as GitHub release assets:

- `core_provisioner-<version>.tar.gz` — the immutable, versioned archive. Pin an exact version and verify the `.sha256` sidecar after download.
- `core_provisioner.tar.gz` — a version-less copy at a stable URL (`releases/latest/download/core_provisioner.tar.gz`) for quick starts.

The archive carries the skeleton files at its root, so a consumer stages it straight into its driver directory (today `core/`):

```bash
curl -fsSL -o core_provisioner-0.2.8.tar.gz \
  https://github.com/STARTcloud/core_provisioner/releases/download/v0.2.8/core_provisioner-0.2.8.tar.gz
curl -fsSL -o core_provisioner-0.2.8.tar.gz.sha256 \
  https://github.com/STARTcloud/core_provisioner/releases/download/v0.2.8/core_provisioner-0.2.8.tar.gz.sha256
sha256sum -c core_provisioner-0.2.8.tar.gz.sha256
mkdir -p core && tar -xzf core_provisioner-0.2.8.tar.gz -C core
```

Released provisioners must pin an exact core version — never a floating branch — so their release artifacts stay byte-reproducible.

> The legacy `submodule` branch still exists for consumers that haven't cut over from `git submodule` consumption yet. New consumers should use release archives.

## How it fits together

- **`Hosts.yml`** — the declarative machine description: settings, networks, disks, zones/UTM/vbox provider blocks, provisioning playbooks, synced folders, roles, and vars. See `examples/Hosts.yml`.
- **`Hosts.rb`** — interprets `Hosts.yml` inside the consumer's Vagrant run and applies every setting to the chosen provider. It also handles post-provision work: results/adapter reporting, support-bundle and SSH-key syncback, and zones post-provision boot.
- **`Vagrantfile`** — the stub a provisioner ships at its root: load `Hosts.yml`, require the skeleton's `Hosts.rb`, call `Hosts.configure`.

The provisioning content itself (Ansible collections, templates, scripts, installers) belongs to the consuming provisioner, not to this repo.

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

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for the process for submitting pull requests, and our [Code of Conduct](CODE_OF_CONDUCT.md).

## Authors

- **Joel Anderson** - *Initial work* - [JoelProminic](https://github.com/JoelProminic)
- **Justin Hill** - *Initial work* - [JustinProminic](https://github.com/JustinProminic)
- **Mark Gilbert** - *Refactor* - [Makr91](https://github.com/Makr91)

See also [AUTHORS.md](AUTHORS.md) and the list of [contributors](https://github.com/STARTcloud/core_provisioner/graphs/contributors).

## License

This project is licensed under the GNU Affero General Public License v3 - see the [LICENSE.md](LICENSE.md) file for details.

## Acknowledgments

See [ACKNOWLEDGMENTS.md](ACKNOWLEDGMENTS.md).
