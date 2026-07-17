## Description

Brief description of the changes in this pull request.

## Type of Change

Please delete options that are not relevant:

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Code refactoring (no functional changes)

## Testing

Please describe how you verified your changes:

- [ ] `vagrant up` tested with a real `Hosts.yml`
- [ ] Tested on VirtualBox
- [ ] Tested on UTM
- [ ] Tested on Bhyve/zones (vagrant-zones)
- [ ] `ruby -c` passes on changed Ruby files

**Test Configuration:**

- Host OS:
- Vagrant Version:
- Provider + Version:

## Impact Assessment

- [ ] No breaking changes
- [ ] Requires a `Hosts.yml` schema change (call it out below)
- [ ] Changes behavior for downstream provisioners consuming the released skeleton

**Areas Affected:**

- [ ] Hosts.rb provider configuration (VirtualBox / UTM / zones)
- [ ] Networking
- [ ] Disks
- [ ] Provisioning (shell / ansible / docker)
- [ ] Post-provision triggers / syncback
- [ ] Release / CI

## Additional Context

Any additional information that reviewers should know.

## Checklist

- [ ] I have read the [Contributing Guidelines](../CONTRIBUTING.md)
- [ ] Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/) (release-please relies on them)
- [ ] I have updated documentation as needed
- [ ] I have considered the impact on downstream provisioners
