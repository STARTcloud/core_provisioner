# Contributing to Core Provisioner

Thank you for your interest in contributing to Core Provisioner! Community contributions directly impact the pace of feature development and bug fixes.

## How to Contribute

### Reporting Issues

Before creating an issue, please:

1. **Search existing issues** to avoid duplicates
2. **Use the appropriate issue template** (bug report, feature request, question)
3. **Provide detailed information** — the relevant `Hosts.yml` portion (redact secrets), steps to reproduce, expected vs. actual behavior
4. **Include environment details** (host OS, Vagrant version, provider + version)

### Submitting Pull Requests

1. **Fork the repository** and create your feature branch from `main`
2. **Keep changes focused** and write commit messages using [Conventional Commits](https://www.conventionalcommits.org/) — release-please builds the changelog and version bumps from them (`fix:` = patch, `feat:` = minor)
3. **Make sure CI passes**: `ruby -c Hosts.rb version.rb Vagrantfile` must be clean, and no legacy `::TOKEN::` markers may appear anywhere
4. **Fill out the pull request template** completely

### Testing Changes

There is no unit test suite — the driver is exercised by real `vagrant up` runs. Before submitting:

1. Test with a real `Hosts.yml` (start from `examples/Hosts.yml`)
2. State in the PR which providers you tested (VirtualBox, UTM, Bhyve/zones)
3. Call out anything that changes the `Hosts.yml` schema or affects downstream provisioners consuming the released skeleton

### What We're Looking For

- Bug fixes, especially provider-specific ones
- Provider support improvements (VirtualBox, UTM, vagrant-zones)
- Better error handling and clearer provisioning output
- Documentation improvements

## Response Times and Review Process

Due to limited development resources:

- **Issue responses**: we aim to acknowledge new issues within a few days
- **Pull request reviews**: may take time depending on complexity and workload
- **Documentation updates**: generally reviewed quickly as they're high-impact, low-risk

## Recognition

All contributors are recognized in our [AUTHORS.md](AUTHORS.md) file.

## Code of Conduct

This project follows our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to abide by its terms.

## License

By contributing to Core Provisioner, you agree that your contributions will be licensed under the [GNU AGPL v3](LICENSE.md).
