# SSL Material — Seeded from the Driver; Your Files Always Win

This directory is the **BYO-SSL drop zone**. Nothing in it is committed except this README and the `.gitkeep` placeholders.

The shared development CA and the `default-signed` key/cert pair are **seeded from the pinned core_provisioner driver** (see `driver.version` at the repo root), non-clobbering:

- at build, by the provisioner's CI when it stages the release artifact, and
- at first `vagrant up`, by the Vagrantfile's driver bootstrap.

Anyone who installs the seeded `ca/ca-certificate.crt` on their machine can trust the SSLs this provisioner mints for its services.

**Seeding never overwrites** — a file you place here always beats the seed. For real deployments, drop your own key/cert material into the machine's working copy of this tree before provisioning and disable the self-signed default in the machine's configuration.

The subdirectories (`ca/`, `combined/`, `crt/`, `csr/`, `jks/`, `key/`, `kyr/`, `pfx/`) are the working locations the ssl role populates per machine; this whole tree syncs to `/secure/` on the guest (see `folders:` in the rendered `Hosts.yml`), where the ssl role consumes it.
