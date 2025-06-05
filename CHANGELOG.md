# Changelog
<!-- markdownlint-disable MD013 -->
<!-- markdownlint-disable MD024 -->
<!-- markdownlint-configure-file { "MD024":{"allow_different_nesting": true }} -->
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] -

### Added

### Changed

### Fixed

### Removed

## [1.8.1] - 2025-06-05

### Fixed

- execute permission for *get_seps_pwd.sh*

## [1.8.0] - 2025-06-05

### Added

- add script *get_seps_pwd.sh* to extract password from oracle wallet
  
### Changed

- Update file header for SQL files
- rework *cdua_init.sql* to handle OMF files

### Fixed

- Fix issue with line wrap in ldapsearch of *tns_function.sh*

## [1.7.0] - 2024-08-21

### Added

- Add script [spsec_usrinf.sql](https://github.com/oehrlis/oradba/blob/master/sql/spsec_usrinf.sql) to show session information of current user
- Add alias script [whoami.sql](https://github.com/oehrlis/oradba/blob/master/sql/whoami.sql) for script [spsec_usrinf.sql](https://github.com/oehrlis/oradba/blob/master/sql/spsec_usrinf.sql)

## [1.6.0] - 2024-03-21

### Added

- Add script [sdenc_dbf_off_enc.sql](https://github.com/oehrlis/oradba/blob/master/sql/sdenc_dbf_off_enc.sql) to generate chunks of *alter database* commands for offline encrypt datafiles
- Add script [sdenc_dbf_off_dec.sql](https://github.com/oehrlis/oradba/blob/master/sql/sdenc_dbf_off_dec.sql) to generate chunks of *alter database* commands for offline decrypt datafiles
- Add script [saua_logon.sql](https://github.com/oehrlis/oradba/blob/master/sql/saua_logon.sql) to show audit logon events
- Add script [senc_tde_ops.sql](https://github.com/oehrlis/oradba/blob/master/sql/senc_tde_ops.sql) to show TDE operation from *V$SESSION_LONGOPS*.
- Add script [senc_tde_ops_run.sql](https://github.com/oehrlis/oradba/blob/master/sql/senc_tde_ops_run.sql) to show running TDE operation from *V$SESSION_LONGOPS*.
- Add script [senc_tde_ops_csv.sql](https://github.com/oehrlis/oradba/blob/master/sql/senc_tde_ops_csv.sql) to show TDE operation from *V$SESSION_LONGOPS* as CSV


### Fixed

- uncomment *oradba_loc_all_act_named_usr* in *iaua_pol.sql*.

## [1.5.1] - 2023-12-13

### Added

- Add a script [saua_report.sql](https://github.com/oehrlis/oradba/blob/master/sql/saua_report.sql) to run all show / report queries for unified audit in one script. Depending on the amount of audit data, this script can run for a relatively long time.

### Changed

- add *SPOOL* to all show script for Oracle Unified Audit

## [1.5.0] - 2023-12-13

### Added

- add a generic password verify function [cssec_pwverify.sql](https://github.com/oehrlis/oradba/blob/master/sql/cssec_pwverify.sql) The password strength and complexity can be configured by the internal variables at create time
- Script [sssec_pwverify_test.sql](https://github.com/oehrlis/oradba/blob/master/sql/sssec_pwverify_test.sql) to verify the custom password verify function. List of passwords to be tested have to added to the script / varchar2 array

## [1.4.0] - 2023-12-11

### Added

- add script *csenc_swkeystore_backup.sql* to create a TDE software keystore backup using *DBMS_SCHEDULER*
- add script *ssenc_swkeystore_backup.sql* to show TDE software keystore backup schedules created with *csenc_swkeystore_backup.sql*
- add script *dsenc_swkeystore_backup.sql* to delete TDE software keystore backup schedules created with *csenc_swkeystore_backup.sql*

### Changed

- rename file *isenc_tde_pdbiso_syskm.sql* to *isenc_tde_pdbiso_keyadmin.sql*
- add add grant privileges for key management to *isenc_tde_pdbiso_prepare.sql*

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
