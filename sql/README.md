# OraDBA SQL Tools and Reporting
<!-- markdownlint-disable MD013 -->
## General Information

A number of SQL scripts as well as SQL Developer Reports for various DBA
activities are available in this directory. The scripts focus on setup,
configuration and analysis of database security topics such as Oracle Unified
Audit, Oracle Centrally Managed Users, Advanced Security, Authentication,
Authorisation, Encryption and more.. An updated version of the scripts is
available via GitHub on [oehrli/oradba](https://github.com/oehrlis/oradba).

## Naming Concept Summary

### Script Naming Convention

The script names follow the format:
`<script_qualifier><privileges_qualifier><topic_qualifier>_<use_case>.sql`

### Script Qualifier

The script qualifier is used to determine whether a script is used to read
information or to configure, e.g. create, modify, activate, etc.

| Qualifier | Stands For | Comment                                  |
|-----------|------------|------------------------------------------|
| s         | Show       | Output only on screen                    |
| d         | Delete     | Delete any objects, configuration etc    |
| i         | Initialize | Initializes or enable a configuration    |
| c         | Create     | Create any objects, configuration etc.   |
| u         | Update     | Update any object                        |
| g         | Grant      | Grants some objects or system privileges |

### Privileges Qualifier

The privilege qualifier is used to determine what privileges are required by a
script.

| Qualifier | Stands For | Comment                                                                |
|-----------|------------|------------------------------------------------------------------------|
| s         | SYS        | SYS, SYSDBA or Internal                                                |
| d         | DBA        | SYSTEM or any other user with DBA role                                 |
| o         | Owner      | Object owner                                                           |
| p         | Create     | Needs some special privileges according to the scripts inline comments |
| a         | Audit      | Audit roles like AUDIT_ADMIN or AUDIT_VIEWER                           |

### Topic Qualifier

Topic Qualifier is used to assign the different scripts to a certain topic and
thus to be able to sort them better.

| Qualifier | Stands For        | Comment                                        |
|-----------|-------------------|------------------------------------------------|
| ua        | Unified Audit     | Everything related to Oracle Unified Audit     |
| ta        | Traditional Audit | Everything related to Oracle traditional Audit |
| sec       | Security          | Oracle security related stuff                  |
| enc       | Encryption        | Oracle Transparent DataEncryption              |
| a         | Admin             | Database Administration                        |

## Generic DBA Activities

The following SQL scripts are available.

| Script                     | Alias              | Purpose                                      |
|----------------------------|--------------------|----------------------------------------------|
| [ssa_hip.sql](ssa_hip.sql) | [hip.sql](hip.sql) | Show all (hidden and regular) init parameter |

## Oracle Unified Audit

### SQL Script Use Cases and Filenames

The following SQL scripts are available.

| Script                                               | Purpose                                                                                              |
|------------------------------------------------------|------------------------------------------------------------------------------------------------------|
| [saua_info.sql](saua_info.sql)                       | Show information about the audit trails                                                              |
| [daua_pol.sql](daua_pol.sql)                         | Disable all audit policies and drop all non-Oracle maintained policies                               |
| [cdua_init.sql](cdua_init.sql)                       | Initialize Audit environment (create tablespace, reorganize tables, create jobs)                     |
| [caua_pol.sql](caua_pol.sql)                         | Create custom local audit policies policies                                                          |
| [iaua_pol.sql](iaua_pol.sql)                         | Enable custom local audit policies policies                                                          |
| [saua_pol.sql](saua_pol.sql)                         | Show local audit policies policies                                                                   |
| [saua_teact.sql](saua_teact.sql)                     | Show top unified audit events by action for current DBID                                             |
| [saua_tecli.sql](saua_tecli.sql)                     | Show top unified audit events by client_program_name for current DBID                                |
| [saua_tedbid.sql](saua_tedbid.sql)                   | Show top unified audit events by DBID                                                                |
| [saua_teusr.sql](saua_teusr.sql)                     | Show top unified audit events by dbusername for current DBID                                         |
| [saua_teobj.sql](saua_teobj.sql)                     | Show top unified audit events by object_name for current DBID                                        |
| [saua_teobjusr.sql](saua_teobjusr.sql)               | Show top unified audit events by Object Name without Oracle maintained schemas for current DBID      |
| [saua_teown.sql](saua_teown.sql)                     | Show top unified audit events by object_schema for current DBID                                      |
| [saua_teosusr.sql](saua_teosusr.sql)                 | Show top unified audit events by os_username for current DBID                                        |
| [saua_tepol.sql](saua_tepol.sql)                     | Show top unified audit events by unified_audit_policies for current DBID                             |
| [saua_tepoldet.sql](saua_tepoldet.sql)               | Show top unified audit events by unified_audit_policies, dbusername, action for current DBID         |
| [saua_tehost.sql](saua_tehost.sql)                   | Show top unified audit events by userhost for current DBID                                           |
| [saua_asdbv.sql](saua_asdbv.sql)                     | Show audit sessions for audit type Database Vault                                                    |
| [saua_asdp.sql](saua_asdp.sql)                       | Show audit sessions for audit type Datapump                                                          |
| [saua_asfga.sql](saua_asfga.sql)                     | Show audit sessions for audit type Fine Grained Audit                                                |
| [saua_asbck.sql](saua_asbck.sql)                     | Show audit sessions for audit type RMAN                                                              |
| [saua_asstd.sql](saua_asstd.sql)                     | Show audit sessions for audit type Standard                                                          |
| [saua_as.sql](saua_as.sql)                           | Show audit sessions for audit any type                                                               |
| [saua_asdet.sql](saua_asdet.sql)                     | Show entries of a particular audit session with unified_audit_policies                               |
| [saua_asdetsql.sql](saua_asdetsql.sql)               | Show entries of a particular audit session with SQL_TEXT                                             |
| [sdua_usage.sql](sdua_usage.sql)                     | Show Unified Audit trail storage usage                                                               |
| [saua_tabsize.sql](saua_tabsize.sql)                 | Show Unified Audit trail table and partition size                                                    |
| [sdua_enpolstm.sql](sdua_enpolstm.sql)               | Generate statements to enable all audit policies as currently set in AUDIT_UNIFIED_ENABLED_POLICIES  |
| [sdua_crpolstm.sql](sdua_crpolstm.sql)               | Generate statements to create all audit policies as currently set in AUDIT_UNIFIED_ENABLED_POLICIES  |
| [sdua_drpolstm.sql](sdua_drpolstm.sql)               | Generate statements to drop all audit policies as currently set in AUDIT_UNIFIED_ENABLED_POLICIES    |
| [sdua_dipolstm.sql](sdua_dipolstm.sql)               | Generate statements to disable all audit policies as currently set in AUDIT_UNIFIED_ENABLED_POLICIES |
| [sdua_prgstm.sql](sdua_prgstm.sql)                   | Generate Unified Audit trail storage purge statements                                                |
| [sdua_stostm.sql](sdua_stostm.sql)                   | Generate Unified Audit trail storage usage modification statements                                   |
| [cdsec_credbarestrole.sql](cdsec_credbarestrole.sql) | Script to create a restricted DBA role including re-grant to existing users.                         |

### SQL Developer Reports

Predefined reports for Unified Audit Assessment available via
[unified_audit_reports.xml](https://github.com/oehrlis/oradba/blob/b4bc6e713405e8836e21532b6e0cd4075a576848/sql/unified_audit_reports.xml)

The scripts are divided into the following categories for easier organisation.

- **Generic Audit**
- **Audit Configuration**
- **Audit Sessions**
- **Generate Statements**
- **Top Audit Events**

| Folder              | Report                                      | Purpose                                                                                                                                |
|---------------------|---------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------|
| Generic             | Audit Events by Day                         | Chart with number of Audit events by days with a couple of subqueries for history, by hour or DB Info                                  |
| Generic             | Audit Events by User                        | Chart with number of Audit events by user with a couple of subqueries for history, by hour or DB Info                                  |
| Generic             | Audit Events by User                        | Show of Audit Events by Users with a couple of subqueries for audit policies, actions, clients and Policy                              |
| Audit Configuration | Audit Storage Usage                         | Information about the Audit storage usage and configuration.                                                                           |
| Audit Configuration | Clean Up Events                             | Displays the audit cleanup event history                                                                                               |
| Audit Configuration | Clean Up Jobs                               | Displays the currently configured audit trail purge jobs                                                                               |
| Audit Configuration | Configuration                               | Show current audit configuration parameter                                                                                             |
| Audit Configuration | Last Archive Timestamp                      | Displays the last archive timestamps set for the audit trails                                                                          |
| Audit Configuration | Unified Audit Policies                      | Display overview about unified audit policies based on the views AUDIT_UNIFIED_POLICIES and AUDIT_UNIFIED_ENABLED_POLICIES.            |
| Audit Sessions      | Proxy Sessions                              | Show information about proxy sessions for audit type Standard based on UNIFIED_AUDIT_TRAIL                                             |
| Audit Sessions      | Session by Audit Type Standard              | Show information about sessions for audit type Standard based on UNIFIED_AUDIT_TRAIL                                                   |
| Audit Sessions      | Session Details                             | Show details of a particular session                                                                                                   |
| Audit Sessions      | Session Overview                            | Overview of standard audit session                                                                                                     |
| Audit Sessions      | Sessions by any Audit Type                  | Show information about sessions any audit type based on UNIFIED_AUDIT_TRAIL                                                            |
| Audit Sessions      | Sessions by Audit Type Database Vault       | Show information about sessions for audit type Database Vault based on UNIFIED_AUDIT_TRAIL                                             |
| Audit Sessions      | Sessions by Audit Type Datapump             | Show information about sessions for audit type Datapump based on UNIFIED_AUDIT_TRAIL                                                   |
| Audit Sessions      | Sessions by Audit Type Direct path API      | Show information about sessions for audit type Direct path API based on UNIFIED_AUDIT_TRAIL                                            |
| Audit Sessions      | Sessions by Audit Type Fine Grained Audit   | Show information about sessions for audit type Fine Grained Audit based on UNIFIED_AUDIT_TRAIL                                         |
| Audit Sessions      | Sessions by Audit Type Protocol             | Show information about sessions for audit type Protocol based on UNIFIED_AUDIT_TRAIL                                                   |
| Audit Sessions      | Sessions by Audit Type RMAN_AUDIT           | Show information about sessions for audit type RMAN_AUDIT based on UNIFIED_AUDIT_TRAIL                                                 |
| Generate Statements | Create all Audit Policy                     | Generate statements to create all audit policies as they are currently set in AUDIT_UNIFIED_ENABLED_POLICIES. Requires DBA privileges. |
| Generate Statements | Disable all Audit Policy                    | Generate statements to disable all audit policies as they are currently set in AUDIT_UNIFIED_ENABLED_POLICIES.                         |
| Generate Statements | Drop all Audit Policy                       | Generate statements to drop all audit policies as they are currently set in AUDIT_UNIFIED_ENABLED_POLICIES.                            |
| Generate Statements | Enable all Audit Policy                     | Generate statements to enable all audit policies as they are currently set in AUDIT_UNIFIED_ENABLED_POLICIES.                          |
| Top Audit Events    | Top Audit Events by Action                  | Show top unified audit events by Action Name                                                                                           |
| Top Audit Events    | Top Audit Events by Application Context     | Show top unified audit events by Application Context                                                                                   |
| Top Audit Events    | Top Audit Events by Audit Type              | Show top unified audit events by Audit Type                                                                                            |
| Top Audit Events    | Top Audit Events by Client                  | Show top unified audit events by Client                                                                                                |
| Top Audit Events    | Top Audit Events by Client Program name     | Show top unified audit events by Client Program                                                                                        |
| Top Audit Events    | Top Audit Events by DBID                    | Show top unified audit events by Database ID                                                                                           |
| Top Audit Events    | Top Audit Events by External User ID        | Show top unified audit events by External User ID                                                                                      |
| Top Audit Events    | Top Audit Events by Global User ID          | Show top unified audit events by Global User ID                                                                                        |
| Top Audit Events    | Top Audit Events by Object Name             | Show top unified audit events by Object Name                                                                                           |
| Top Audit Events    | Top Audit Events by none Oracle Object Name | Show top unified audit events by Object Name without Oracle maintained schemas                                                         |
| Top Audit Events    | Top Audit Events by Object Schema           | Show top unified audit events by Object Schema                                                                                         |
| Top Audit Events    | Top Audit Events by OS User                 | Show top unified audit events by OS User                                                                                               |
| Top Audit Events    | Top Audit Events by Unified Policy          | Show top unified audit events by Unified Audit Policy                                                                                  |
| Top Audit Events    | Top Audit Events by SQL Text                | Show top unified audit events by SQL Text                                                                                              |
| Top Audit Events    | Top Audit Events by User                    | Show top unified audit events by User                                                                                                  |
