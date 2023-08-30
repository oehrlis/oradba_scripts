# Changelog
<!-- markdownlint-disable MD013 -->
<!-- markdownlint-configure-file { "MD024":{"allow_different_nesting": true }} -->
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] -

### Added

### Changed

### Fixed

### Removed

## [1.3.0] - 2023-08-30

### Added

- add script *isenc_tde_pdbiso_prepare.sql* to prepare a PDB environment for isolated mode
- add script *isenc_tde_pdbiso_syskm.sql* to configure PDB software keystore as SYSKM

### Changed

- update documentation for new scripts

## [1.2.0] - 2023-08-30

### Added

- add delete TDE script *dsenc_tde.sql*
- add a force TDE setup script *isenc_tde_force.sql* which explicitly discard
  lost master key handles.
- add a force TDE setup script *isenc_tde_pdbiso_force.sql* which explicitly
  discard lost master key handles.
- add a force TDE setup script *isenc_tde_pdbuni_force.sql* which explicitly
  discard lost master key handles.

### Changed

- remove prompt *csenc_master.sql*
- simplify commands and remove one db *startup force* in *csenc_swkeystore.sql*
- simplify commands and remove one db *startup force* in *isenc_tde.sql*
- simplify commands and remove one db *startup force* in *isenc_tde_pdbiso.sql*
- move legacy scripts back to *sql* folder

## [1.1.1] - 2023-08-30

### Fixed

- fix name for the files from *idenc_tde.sql*, *idenc_tde_pdbuni.sql*,
  *idenc_tde_pdbiso.sql* to *isenc_tde.sql*, *isenc_tde_pdbuni.sql*,
  *isenc_tde_pdbiso.sql*

## [1.1.0] - 2023-08-30

### Added

- add script *idenc_wroot.sql* to initialize init.ora parameter WALLET_ROOT for
  TDE with software keystore.
- add script *csenc_master.sql* to create master encryption key for TDE.
  Configured keystore must be set before hand e.g., with *csenc_swkeystore.sql*.
  Works for CDB as well PDB.
- add script *csenc_swkeystore.sql* to create TDE software keystore and master
  encryption key in CDB$ROOT in the WALLET_ROOT directory.
- add script *ddenc_wroot.sql* to reset init.ora parameter WALLET_ROOT for TDE.
  This script should run in CDB$ROOT. A manual restart of the database is
  mandatory to activate WALLET_ROOT
- add script *idenc_lostkey.sql* to set hidden parameter *_db_discard_lost_masterkey*
  to force discard of lost master keys
- add script *isenc_tde_pdbiso.sql* to initialize TDE in a PDB in isolation mode
  i.e., with a dedicated wallet in WALLET_ROOT for this pdb. The CDB must be
  configured for TDE beforehand. This scripts does use several other scripts to
  enable TDE and it also includes **restart** of the pdb.
- add script *isenc_tde_pdbuni.sql* to initialize TDE in a PDB in united mode
  i.e., with a common wallet of the CDB in WALLET_ROOT. The CDB must be
  configured for TDE beforehand. This scripts does use several other scripts to
  enable TDE and it also includes **restart** of the pdb.
- add script *isenc_tde.sql* to initialize TDE for a single tenant or container
  database. This scripts does use several other scripts to enable TDE and it
  also includes **restart** of the database.
- add script *ssenc_info* to show information about the TDE Configuration.

### Changed

- update [README.md](sql/README.md) with information for latest scripts.

## [1.0.0] - 2023-08-29

### Added

- Readme for SQL Toolbox for simplified Oracle Unified Audit Data Analysis
- add latest version (v3.4.8) of TNS scripts

### Changed

- Adjust script names according naming convention
- Clean up file headers

## [0.1.1] - 2022-05-31

### Fixed

- Fix missing ETC_BASE variable in *tns_functions.sh*
- Rename config files

## [0.1.0] - 2022-05-31

### Added

- initial release of *OraDBA* documentation, tools and scripts.

### Changed

### Fixed

### Removed

[unreleased]: https://github.com/oehrlis/oradba
[0.1.0]: https://github.com/oehrlis/oradba/releases/tag/v0.1.0
[0.1.1]: https://github.com/oehrlis/oradba/releases/tag/v0.1.1
