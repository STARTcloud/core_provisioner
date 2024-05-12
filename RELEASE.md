# Release process

This is Core Provisioner current release process

## Prepare the release

Github Actions now handles the release cycle. We are using SemVer Verision and Convential Commits to ensure that we can use our Commits in our CI/CD Workflow

To push a fix and have it automatically publish, ie a the Patch digit in Version string, prefix your commit header with "fix:  Some Commit Message"

To push a feature, ie a the feature digit in Version string, prefix your commit header with "feat:  Some Commit Message"

Doing so will cause GitHub Actions to perform the following
* Update the version in "core/version.rb"
* Update the version in CHANGELOG.md
* Create a Release and Corresponding tag
* Push the package to the GPR and Ruby Gems

If you are project maintainer, you may also run a manual build if you want to build an artifact without releasing a production publication.

The CHANGELOG.md will be automatically maintained in a similar format to Vagrant by the Github Action Release-Please:

https://github.com/mitchellh/vagrant/blob/master/CHANGELOG.md

