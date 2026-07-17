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
| `Vagrantfile` | Consumer-facing stub with the driver self-bootstrap. Lives at a provisioner's repo root: when `driver/` is missing it fetches the release pinned in `driver.version`, verifies its `.sha256` sidecar, extracts, seeds `ssls/`, then requires the driver's `Hosts.rb` |
| `version.rb` | `CoreProvisioner::VERSION` — stamped into every provision's Ansible `extra_vars` and managed by release-please |
| `ssh_keys/` | The well-known bootstrap keypair. Insecure by design (like Vagrant's insecure key) — replaced at provision time when `vagrant_ssh_insert_key` is enabled |
| `ssls/` | Shared development CA + default-signed certificate seed. Copied into a consumer's `ssls/` non-clobbering (at build staging and by the Vagrantfile bootstrap) — a user's own certificate material always wins |
| `examples/Hosts.yml` | A complete, commented example configuration |

## Consuming the skeleton

Each release publishes fetchable archives as GitHub release assets:

- `core_provisioner-<version>.tar.gz` — the immutable, versioned archive. Pin an exact version and verify the `.sha256` sidecar after download.
- `core_provisioner.tar.gz` — a version-less copy at a stable URL (`releases/latest/download/core_provisioner.tar.gz`) for quick starts.

The archive's top-level directory is `driver/` — one untar at the consumer's repo root and the driver materializes:

```bash
sha256sum -c core_provisioner-0.2.10.tar.gz.sha256
tar -xzf core_provisioner-0.2.10.tar.gz
```

Consumers never commit `driver/`. It is gitignored and materializes two ways, both driven by the same pin:

- **At build**: the provisioner's build CI reads the repo's `driver.version` pin file (one line: the release tag, e.g. `v0.2.10`), downloads that exact archive, verifies the sidecar, and stages `driver/` into the release artifact — including the non-clobbering `ssls/` seed copy.
- **At dev time**: the shipped `Vagrantfile` self-bootstraps — when `driver/` is missing it performs the same pinned fetch, verify, and extract, seeds `ssls/`, then requires `driver/Hosts.rb`.

Released provisioners must pin an exact core version — never a floating branch — so their release artifacts stay byte-reproducible.

`Hosts.rb` resolves its own paths, so the mount directory name is free — consumers still on the legacy `submodule` branch keep mounting it as `core/` and nothing breaks. New consumers should use release archives.

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
