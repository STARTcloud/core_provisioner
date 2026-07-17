# Changelog

## [0.2.12](https://github.com/STARTcloud/core_provisioner/compare/v0.2.11...v0.2.12) (2026-07-17)


### Features

* drop the ssls seeding design - driver/ssls is synced directly to /secure ([247f463](https://github.com/STARTcloud/core_provisioner/commit/247f4632a3222d4dd27cc0ef376490d13519a4d0))


### Bug Fixes

* new dev root CA (key offline) and scheduled SSH/SSL credential rotation ([b675dad](https://github.com/STARTcloud/core_provisioner/commit/b675dad35fa35ababfe5e1ab2a3fd3174de08683))
* rotate bootstrap SSH keypair and dev PKI material ([acea463](https://github.com/STARTcloud/core_provisioner/commit/acea463c227d1e20712e9f7d9b06b93c0e021dca))
* rotate bootstrap SSH keypair and dev PKI material ([64dc52b](https://github.com/STARTcloud/core_provisioner/commit/64dc52b06738592dae790486fc4afbf894ffd4f6))

## [0.2.11](https://github.com/STARTcloud/core_provisioner/compare/v0.2.10...v0.2.11) (2026-07-17)


### Features

* adding the default SSLs ([66efff4](https://github.com/STARTcloud/core_provisioner/commit/66efff4ea62a1222305da4ccf7f02c3ca7336d93))

## [0.2.10](https://github.com/STARTcloud/core_provisioner/compare/v0.2.9...v0.2.10) (2026-07-17)


### Features

* driver-shaped releases with self-bootstrapping Vagrantfile and ssls seed ([62d7f7e](https://github.com/STARTcloud/core_provisioner/commit/62d7f7ed3acd484a387a400686b039f95b1803cf))
* driver-shaped releases with self-bootstrapping Vagrantfile and ssls seed ([284fd6c](https://github.com/STARTcloud/core_provisioner/commit/284fd6cb522a2d8cf049a6dccb9a3530805b1a00))

## [0.2.9](https://github.com/STARTcloud/core_provisioner/compare/v0.2.8...v0.2.9) (2026-07-17)


### Features

* add QGA support for bhyve zones ([244defa](https://github.com/STARTcloud/core_provisioner/commit/244defa808003dbd9a36e38b286c6fcc7dbe1240))
* UTM Support ([e479c7b](https://github.com/STARTcloud/core_provisioner/commit/e479c7b6f99cdfd654d4c8550966ad2bb40201fe))


### Bug Fixes

* actions ([6912deb](https://github.com/STARTcloud/core_provisioner/commit/6912deb0fcba0ad9e589ca495ef8899928574dae))
* actions can't go in submodule, pollutes directory ([72b2f49](https://github.com/STARTcloud/core_provisioner/commit/72b2f495cf2499fb27245cdd66feeef9576d3fc6))
* adding etherstub ([00f635f](https://github.com/STARTcloud/core_provisioner/commit/00f635fa1743a9c004252bfa6fb8fb997fb9b65f))
* adding etherstub ([74f26b2](https://github.com/STARTcloud/core_provisioner/commit/74f26b26ee9235c1ab1136d44fd5acc7551c8124))
* adding UTM support ([dae95ee](https://github.com/STARTcloud/core_provisioner/commit/dae95ee63a79b7f779fe39feba42dee30e9b0032))
* allow different zonename than domain name ([2a177b1](https://github.com/STARTcloud/core_provisioner/commit/2a177b1072b0fa43da830f58046fc95c7c98f948))
* Box URL ([de2f6d5](https://github.com/STARTcloud/core_provisioner/commit/de2f6d516413b425ce25c51d4dd5f2a966ce24f8))
* build workflow ([52e9e99](https://github.com/STARTcloud/core_provisioner/commit/52e9e999df36e733ca7a73155f87655be7447e10))
* core ([308a22a](https://github.com/STARTcloud/core_provisioner/commit/308a22abd58907a48ce1a16ed9896ceeb750da59))
* core ([1ded475](https://github.com/STARTcloud/core_provisioner/commit/1ded475a5b2ac546cb345661515cd3c420e1c4f2))
* do not scp if no support bundle included- security ([7e96497](https://github.com/STARTcloud/core_provisioner/commit/7e96497f5a65862044e76a33d9c5bad86e887a33))
* first build ([617f331](https://github.com/STARTcloud/core_provisioner/commit/617f33127d2994b57ecf6495940d6190d0263551))
* Hosts.rb ansible provisioner galaxy role ([8d29a70](https://github.com/STARTcloud/core_provisioner/commit/8d29a705796fdcb9c6c62bc83d635cab77d2df8d))
* include ansible galaxy requirements ([568c67b](https://github.com/STARTcloud/core_provisioner/commit/568c67bca08f899f8998c30161b70f528353fde0))
* Include Customizable Box Repo URL (hashicorp acquisition) ([47edc25](https://github.com/STARTcloud/core_provisioner/commit/47edc2573e3a52440d02eabfb4cfda8f4f43434b))
* include github actions ([4aa941e](https://github.com/STARTcloud/core_provisioner/commit/4aa941ef684d1d7f00b1ceb1c381781d8ad95e0c))
* include remote galaxy role installation capability ([9fd7a62](https://github.com/STARTcloud/core_provisioner/commit/9fd7a6255445ae983ef09944dd809b89e1288d29))
* move github actions back to main ([4efe55d](https://github.com/STARTcloud/core_provisioner/commit/4efe55d40485e0dce9191fc2bcac372f19d6ef9a))
* password for bhyve using shi provisioner ([2bda688](https://github.com/STARTcloud/core_provisioner/commit/2bda6883bd30367819a7c7e636934bfe3222ffc7))
* password for bhyve using shi provisioner ([fd518fb](https://github.com/STARTcloud/core_provisioner/commit/fd518fb8542dc42afc780319441098fee920ab5e))
* Provisioning Options, Always, Never, Once, not_first ([79f0fa6](https://github.com/STARTcloud/core_provisioner/commit/79f0fa6ec750b158ac55d1cd36436116d8783f80))
* releases ([04dff26](https://github.com/STARTcloud/core_provisioner/commit/04dff26814109043b7c04777b25e5bc52805a4e5))
* releases ([ac775b8](https://github.com/STARTcloud/core_provisioner/commit/ac775b8c86678d031745e5f987cbb40ff7ca6d3c))
* releases ([fe97457](https://github.com/STARTcloud/core_provisioner/commit/fe97457853c3111c7bed7106d3d801a3d184297e))
* releases ([4df1daf](https://github.com/STARTcloud/core_provisioner/commit/4df1dafb72f056d954c84252bce04121c187cf22))
* releases ([cfb43c8](https://github.com/STARTcloud/core_provisioner/commit/cfb43c82bf58eb3cd1c00608242e3dc9c5f88130))
* releases ([1067a87](https://github.com/STARTcloud/core_provisioner/commit/1067a87a2de3f2cdc7763d3e70f3514554eda92e))
* remove dead add-role provisioning block ([2370ba4](https://github.com/STARTcloud/core_provisioner/commit/2370ba4ebc5decbcc7bd598e81379f1c7ce4b746))
* submodule workflow ([3061157](https://github.com/STARTcloud/core_provisioner/commit/3061157bb284ff44b15e289ccec13557f5ec0ec6))
* test auto workflow ([3d3f9d9](https://github.com/STARTcloud/core_provisioner/commit/3d3f9d9905dcf4bc0b1c1d296581ef7ad9e52d9c))
* Testing Submodule Merge ([59a62ef](https://github.com/STARTcloud/core_provisioner/commit/59a62ef8ae3b507a0c4c1bb7f543aecd7b8e6ea5))
* testing workflows ([a609391](https://github.com/STARTcloud/core_provisioner/commit/a60939171d09ac4ea7c745cc435bf86517b82af5))
* testing workflows ([273d07f](https://github.com/STARTcloud/core_provisioner/commit/273d07f46c6dab341d8ad7b2e69d5c537347d8f0))
* testing workflows ([07a3fbd](https://github.com/STARTcloud/core_provisioner/commit/07a3fbd6bd47548a803a6cc010eb47f94305f408))
* testing workflows ([b460dc2](https://github.com/STARTcloud/core_provisioner/commit/b460dc262e1242b0d6797139fe3958039023ea86))
* testing workflows ([bed5ea5](https://github.com/STARTcloud/core_provisioner/commit/bed5ea54cfb59ec0ddf7e20e8bbd488d70bfca24))
* testing workflows ([d1c4c14](https://github.com/STARTcloud/core_provisioner/commit/d1c4c1454c403222cce16a6e3dbc44a593325fbe))
* testing workflows ([eca2103](https://github.com/STARTcloud/core_provisioner/commit/eca2103718ed7f19dab678a448a119b078220ee4))
* typos, update readme, adjust documentation ([edbd9be](https://github.com/STARTcloud/core_provisioner/commit/edbd9be17a3054c2c486eb579ca63ca10417879a))
* update ([6d4c19e](https://github.com/STARTcloud/core_provisioner/commit/6d4c19eaaa12405d5f658da94b91966cfea0597e))
* update galaxy role file path ([9840de9](https://github.com/STARTcloud/core_provisioner/commit/9840de931ccf13e33c91f51e68456b84b963f0d9))
* update vagrant ssh key regen/replace ([30b2856](https://github.com/STARTcloud/core_provisioner/commit/30b2856e58c0b297877114fdd06dc75a85716499))
* use vagrant_user for SSH key syncback and drop the debug template transfer ([512b3c5](https://github.com/STARTcloud/core_provisioner/commit/512b3c52b0f18f94617313f34a03884e7a4bc322))
* use vagrant_user for SSH key syncback and drop the debug template transfer ([c681ec8](https://github.com/STARTcloud/core_provisioner/commit/c681ec899378b37cf6124c5920a188d6064ec04c))
* use vagrant_user for SSH key syncback and drop the debug template transfer ([8874858](https://github.com/STARTcloud/core_provisioner/commit/887485867279285d9090cb8e96cebb612f019056))
* when vars are nil for packer builder ([d0cfe3d](https://github.com/STARTcloud/core_provisioner/commit/d0cfe3d4a3e6085ecdbeab8d2f160e7cfc9bb8f9))
* windows ([1eac299](https://github.com/STARTcloud/core_provisioner/commit/1eac299bf9fcf10d15f2830b5381158762e5f227))
* windows ([dd3fcee](https://github.com/STARTcloud/core_provisioner/commit/dd3fcee02f7856fad4675f79f8ef3a45cf233f10))
* windows ([65794c8](https://github.com/STARTcloud/core_provisioner/commit/65794c8765ed7a6c733fdab34f213a1296825b61))
* windows ([df21c18](https://github.com/STARTcloud/core_provisioner/commit/df21c18cf59025ff04d2f26f5554f6207252918a))
* windows ([0094432](https://github.com/STARTcloud/core_provisioner/commit/0094432d10e955586dd6fd980da9d0c8ed9539f9))
* windows ([12e7c53](https://github.com/STARTcloud/core_provisioner/commit/12e7c53fc00486b1713e401757150a65eaa83fb3))
* WSL2 Vagrant compatability ([c3de1f7](https://github.com/STARTcloud/core_provisioner/commit/c3de1f74b58bfdf8ed7b0c5f40365fb9e5a16f43))
* zone defintions ([4a5009f](https://github.com/STARTcloud/core_provisioner/commit/4a5009f6decf3cba0f7a950acc30d5d91b2948c9))

## [0.2.8](https://github.com/STARTcloud/core_provisioner/compare/core_provisioner/v0.2.7...core_provisioner/v0.2.8) (2024-05-15)


### Bug Fixes

* Hosts.rb ansible provisioner galaxy role ([8d29a70](https://github.com/STARTcloud/core_provisioner/commit/8d29a705796fdcb9c6c62bc83d635cab77d2df8d))

## [0.2.7](https://github.com/STARTcloud/core_provisioner/compare/core_provisioner/v0.2.6...core_provisioner/v0.2.7) (2024-05-15)


### Bug Fixes

* update galaxy role file path ([9840de9](https://github.com/STARTcloud/core_provisioner/commit/9840de931ccf13e33c91f51e68456b84b963f0d9))

## [0.2.6](https://github.com/STARTcloud/core_provisioner/compare/core_provisioner/v0.2.5...core_provisioner/v0.2.6) (2024-05-15)


### Bug Fixes

* testing workflows ([a609391](https://github.com/STARTcloud/core_provisioner/commit/a60939171d09ac4ea7c745cc435bf86517b82af5))
* testing workflows ([273d07f](https://github.com/STARTcloud/core_provisioner/commit/273d07f46c6dab341d8ad7b2e69d5c537347d8f0))
* update ([6d4c19e](https://github.com/STARTcloud/core_provisioner/commit/6d4c19eaaa12405d5f658da94b91966cfea0597e))

## [0.2.5](https://github.com/STARTcloud/core_provisioner/compare/core_provisioner/v0.2.4...core_provisioner/v0.2.5) (2024-05-15)


### Bug Fixes

* actions can't go in submodule, pollutes directory ([72b2f49](https://github.com/STARTcloud/core_provisioner/commit/72b2f495cf2499fb27245cdd66feeef9576d3fc6))
* Box URL ([de2f6d5](https://github.com/STARTcloud/core_provisioner/commit/de2f6d516413b425ce25c51d4dd5f2a966ce24f8))
* build workflow ([52e9e99](https://github.com/STARTcloud/core_provisioner/commit/52e9e999df36e733ca7a73155f87655be7447e10))
* include ansible galaxy requirements ([568c67b](https://github.com/STARTcloud/core_provisioner/commit/568c67bca08f899f8998c30161b70f528353fde0))
* include github actions ([4aa941e](https://github.com/STARTcloud/core_provisioner/commit/4aa941ef684d1d7f00b1ceb1c381781d8ad95e0c))
* include remote galaxy role installation capability ([9fd7a62](https://github.com/STARTcloud/core_provisioner/commit/9fd7a6255445ae983ef09944dd809b89e1288d29))
* move github actions back to main ([4efe55d](https://github.com/STARTcloud/core_provisioner/commit/4efe55d40485e0dce9191fc2bcac372f19d6ef9a))
* submodule workflow ([3061157](https://github.com/STARTcloud/core_provisioner/commit/3061157bb284ff44b15e289ccec13557f5ec0ec6))
* test auto workflow ([3d3f9d9](https://github.com/STARTcloud/core_provisioner/commit/3d3f9d9905dcf4bc0b1c1d296581ef7ad9e52d9c))
* Testing Submodule Merge ([59a62ef](https://github.com/STARTcloud/core_provisioner/commit/59a62ef8ae3b507a0c4c1bb7f543aecd7b8e6ea5))
* testing workflows ([07a3fbd](https://github.com/STARTcloud/core_provisioner/commit/07a3fbd6bd47548a803a6cc010eb47f94305f408))
* testing workflows ([b460dc2](https://github.com/STARTcloud/core_provisioner/commit/b460dc262e1242b0d6797139fe3958039023ea86))
* testing workflows ([bed5ea5](https://github.com/STARTcloud/core_provisioner/commit/bed5ea54cfb59ec0ddf7e20e8bbd488d70bfca24))
* testing workflows ([d1c4c14](https://github.com/STARTcloud/core_provisioner/commit/d1c4c1454c403222cce16a6e3dbc44a593325fbe))
* testing workflows ([eca2103](https://github.com/STARTcloud/core_provisioner/commit/eca2103718ed7f19dab678a448a119b078220ee4))

## [0.2.4](https://github.com/STARTcloud/core_provisioner/compare/core_provisioner/v0.2.3...core_provisioner/v0.2.4) (2024-05-12)


### Bug Fixes

* actions ([6912deb](https://github.com/STARTcloud/core_provisioner/commit/6912deb0fcba0ad9e589ca495ef8899928574dae))
* core ([308a22a](https://github.com/STARTcloud/core_provisioner/commit/308a22abd58907a48ce1a16ed9896ceeb750da59))
* core ([1ded475](https://github.com/STARTcloud/core_provisioner/commit/1ded475a5b2ac546cb345661515cd3c420e1c4f2))
* Include Customizable Box Repo URL (hashicorp acquisition) ([47edc25](https://github.com/STARTcloud/core_provisioner/commit/47edc2573e3a52440d02eabfb4cfda8f4f43434b))
* releases ([04dff26](https://github.com/STARTcloud/core_provisioner/commit/04dff26814109043b7c04777b25e5bc52805a4e5))
* releases ([ac775b8](https://github.com/STARTcloud/core_provisioner/commit/ac775b8c86678d031745e5f987cbb40ff7ca6d3c))
* releases ([fe97457](https://github.com/STARTcloud/core_provisioner/commit/fe97457853c3111c7bed7106d3d801a3d184297e))
* releases ([4df1daf](https://github.com/STARTcloud/core_provisioner/commit/4df1dafb72f056d954c84252bce04121c187cf22))
* typos, update readme, adjust documentation ([edbd9be](https://github.com/STARTcloud/core_provisioner/commit/edbd9be17a3054c2c486eb579ca63ca10417879a))

## [0.2.3](https://github.com/STARTcloud/core_provisioner/compare/core_provisioner/v0.2.2...core_provisioner/v0.2.3) (2023-09-20)


### Bug Fixes

* releases ([cfb43c8](https://github.com/STARTcloud/core_provisioner/commit/cfb43c82bf58eb3cd1c00608242e3dc9c5f88130))

## [0.2.2](https://github.com/STARTcloud/core_provisioner/compare/core_provisioner/v0.2.1...core_provisioner/v0.2.2) (2023-09-20)


### Bug Fixes

* releases ([1067a87](https://github.com/STARTcloud/core_provisioner/commit/1067a87a2de3f2cdc7763d3e70f3514554eda92e))

## [0.2.1](https://github.com/STARTcloud/core_provisioner/compare/core_provisioner-v0.2.0...core_provisioner/v0.2.1) (2023-08-02)


### Bug Fixes

* first build ([617f331](https://github.com/STARTcloud/core_provisioner/commit/617f33127d2994b57ecf6495940d6190d0263551))
