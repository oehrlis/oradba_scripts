# OraDBA (Legacy Repository – Archived)

<!-- markdownlint-disable MD013 -->

> **⚠️ This repository is deprecated and archived.**
>
> Active development has moved to the main
> 👉 **[https://github.com/oehrlis/oradba](https://github.com/oehrlis/oradba)**
>
> All maintained scripts (including the SQL scripts from this repository) are now part of the main *oradba* project.

---

## About This Repository

This repository originally contained a collection of database administration scripts in *SQL* and *bash* from [www.oradba.ch](https://www.oradba.ch/).
It also included tools to maintain *Oracle Net Service* name resolution in *OpenLDAP*, *389DS* and *Oracle Unified Directory*, as well as documentation and framework components.

Most of this functionality has been consolidated and is now maintained in:

👉 **[https://github.com/oehrlis/oradba](https://github.com/oehrlis/oradba)**

This repository remains available for historical reference only and is no longer maintained.

---

# Where to Get the Current Version

All new development and maintained content is part of:

## 👉 [https://github.com/oehrlis/oradba](https://github.com/oehrlis/oradba)

There are two recommended ways to use *oradba* today:

---

## Option 1 – Install the Full OraDBA Environment (Recommended)

The main repository provides an installation script:

```bash
./oradba_install.sh
```

This installs the complete *OraDBA* environment, including:

* Environment setup
* Aliases
* Helper functions
* Bash tools
* SQL scripts
* Templates and configuration files

This is the recommended approach if you want the full DBA working environment.

---

## Option 2 – Use the Tarball (No Installation Required)

If you do not want to install the full environment, you can download the release tarball from:

👉 [https://github.com/oehrlis/oradba/releases](https://github.com/oehrlis/oradba/releases)

The release contains:

* `oradba-<version>.tar.gz` – full source payload

You can extract the tarball and use the SQL scripts directly:

```bash
tar -xzf oradba-<version>.tar.gz
cd oradba-<version>/sql
sqlplus / as sysdba @script.sql
```

This is useful if you only need the SQL scripts without the shell environment.

---

# Legacy Content

The original folder structure of this repository included:

* `bin/` – Scripts to administer and configure *Oracle Net Service* directory objects and other DBA tasks
* `doc/` – Markdown documentation files
* `etc/` – Configuration files and templates
* `images/` – Images and logos
* `ldif/` – *LDIF* files and templates
* `log/` – Log files created by the script framework
* `sql/` – SQL files for miscellaneous DBA and security use cases
* `CHANGELOG.md`
* `LICENSE`

All maintained and relevant components have been migrated to the main *oradba* repository.

---

# Versioning

The active project (*oradba*) follows [Semantic Versioning](https://semver.org/):

MAJOR.MINOR.PATCH

* **MAJOR** – incompatible changes
* **MINOR** – backward-compatible enhancements
* **PATCH** – backward-compatible fixes

Please refer to the `CHANGELOG.md` in the main repository for current release information.

---

# Contributing

This repository is archived and no longer accepts contributions.

If you would like to contribute, please use:

👉 [https://github.com/oehrlis/oradba](https://github.com/oehrlis/oradba)

---

# License

**OraDBA** is licensed under the Apache License 2.0.
You may obtain a copy of the License at:

[http://www.apache.org/licenses/LICENSE-2.0/](http://www.apache.org/licenses/LICENSE-2.0/)
