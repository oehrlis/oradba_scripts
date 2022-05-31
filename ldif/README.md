# LDIF Data Files

This folder contains various *LDIF* data files used to initialize and configure
the OpenLDAP directory server. In particular the Oracle TNS schema, basis data
and more.

- [90orclNet.ldif](./90orclNet.ldif) *LDAP* schema definition for *Oracle Context*
  required to store *Oracle Net Service* objects in *LDAP*.
- [ACI.ldif_template](./ACI.ldif_template) *LDIF* template to define the ACIs for
  anonymous access of the *Oracle Net Service* objects.
- [OracleContext.ldif_template](./OracleContext.ldif_template) *LDIF* template
  for a basic *Oracle Context* used to store *Oracle Net Service* objects.
