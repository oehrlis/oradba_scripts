# OraDBA

<!-- markdownlint-disable MD013 -->

Welcome to the *OraDBA* a collection of scripts from [www.oradba.ch](https://www.oradba.ch/). This repository contains a couple of database administration scripts in *SQL* and *bash*. Among others it also includes a set of tools to maintain *Oracle Net Service* names resolution in *OpenLDAP*, *389DS* and *Oracle Unified Directory*. The project includes the documentation as well the corresponding script framework to setup and administer *Oracle Net Service* name in a *389 Directory Server* in particular.

## Downloads and Latest Builds

The official release documents are always attached to the pipelines as artifact.
See also the [release](https://github.com/oehrlis/oradba/releases)
page of this repository.

Nightly Builds respectively builds on commit are attached as artifact to the
Azure DevOps pipeline.

## Files and Folders

- [bin](./bin/README.md) Scripts to administer and configure *Oracle Net Service* directory objects as well other *Database Administration* tasks.
- [doc](./doc/README.md) Markdown documentation files.
- [etc](./etc/README.md) Configuration files and templates for the *389 Directory Server* and the script framework.
- [images](./images/README.md) Images and logo files.
- [ldif](./ldif/README.md) *LDIF* files and templates to configure the *Oracle Context*.
- [log](./log/README.md) logfiles created by the script framework if not stored in *LOG_BASE*
- [CHANGELOG.md](./CHANGELOG.md) Change log for the *Markdown Doc Template*.
- [LICENSE](./LICENSE) License documentation.

## Releases and Versions

You find all official releases and release information on the Azure DevOps
project release page. As well documented in the [CHANGELOG.md](./CHANGELOG.md).

The versioning and release tags follow the [semantic versioning](https://semver.org/).
A version number is specified by MAJOR.MINOR.PATCH, increase the:

- *MAJOR* version when you make incompatible API changes,
- *MINOR* version when you add functionality in a backwards compatible manner, and
- *PATCH* version when you make backwards compatible bug fixes.

Additional labels for pre-release and build metadata are available as extensions
to the MAJOR.MINOR.PATCH format.

## How to Contribute

It is highly recommended to take into account [AUTHOR_GUIDE.md](./AUTHOR_GUIDE.md) when contributing to this *Markdown Documentation*. However contributing covers the following steps.

1. [Fork this respository](https://github.com/oehrlis/oradba/fork)
2. [Create a branch](https://help.github.com/articles/creating-and-deleting-branches-within-your-repository/), commit and publish your changes and enhancements
3. [Create a pull request](https://help.github.com/articles/creating-a-pull-request/)

## License

**OraDBA** is licensed under the Apache License 2.0. You may obtain a
copy of the License at <http://www.apache.org/licenses/LICENSE-2.0>.
