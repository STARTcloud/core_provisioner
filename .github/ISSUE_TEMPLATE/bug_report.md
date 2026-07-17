---
name: Bug report
about: Create a report to help us improve
title: '[BUG] '
labels: 'bug'
assignees: ''
---

## Bug Description

A clear and concise description of what the bug is.

## Environment

**System Information:**

- Host OS: [e.g., Windows 11, macOS 15, OmniOS r151052]
- Vagrant Version: [e.g., 2.4.3]
- Provider: [e.g., VirtualBox 7.1, UTM, vagrant-zones/bhyve]
- Core Provisioner Version: [e.g., 0.2.8]
- Consumed via: [release archive / git checkout / downstream provisioner]

## Hosts.yml

The relevant portion of your `Hosts.yml` (redact secrets):

```yaml
# Paste here
```

## Steps to Reproduce

1. ...
2. ...
3. See error

## Expected Behavior

What you expected to happen.

## Actual Behavior

What actually happened.

## Error Messages

```text
Paste vagrant/ansible output here
```

## Additional Context

Add any other context about the problem here.

## Impact Assessment

- [ ] Critical (provisioning impossible, security issue)
- [ ] High (major functionality broken)
- [ ] Medium (functionality impaired)
- [ ] Low (minor issue, workaround available)

**Affected Functionality:**

- [ ] VirtualBox provider
- [ ] UTM provider
- [ ] Bhyve/zones provider
- [ ] Networking
- [ ] Disks
- [ ] Provisioning (shell / ansible / docker)
- [ ] Post-provision / syncback
- [ ] Documentation

## Resource Understanding

I understand that this project is maintained with limited development resources and that:

- Response times may vary based on current workload and severity
- Critical and high-impact issues receive priority attention
- Detailed bug reports help prioritize and resolve issues more efficiently
