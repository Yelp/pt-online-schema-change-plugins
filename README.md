# Yelp pt-online-schema-change-plugins 

## Introduction
These are some sample pt-online-schema-change plugins based off of the ones we use at Yelp when running pt-online-schema-change. Also included is a sample pt-online-schema-change.cnf, which you can deploy in /etc/percona-toolkit alongside the plugin.

## The Plugins

### init
An example of using the local database connection to obtain the database name, and using it in a command to announce the start of the pt-online-schema-change run in the dba IRC channel.

### before\_exit
Like init, this plugin announces the finish of a pt-online-schema-change run.

### get\_slave\_lag
This plugin is more complicated because it returns a subroutine. You can do your setup before defining $lag. This sample plugin currently *always returns a lag of 3*.

### before\_create\_new\_table
Because pt-online-schema-change requires a user with the SUPER privilege, it's worth it to verify that it's running against a master withi ``read_only=0``, and not, a replica with ```read_only=1```. 

### before\_swap\_tables
We run pt-online-schema-change with ``--no-drop-old-table`` so that we can revert the change in case of an emergency. Having the master binary log coordinates is useful to examine changes from just before the point of swapping the new table in place.

## Using
To use just a plugin file like this one, add:

```
--plugin /your/path/here/pt-online-schema-change-plugin.pl
```
to your ``pt-online-schema-change`` command. 

Or, use an pt-online-schema-change.cnf like the one provided, which includes a reference to the plugin file. We use the default location of ``/etc/percona-toolkit`` for both.
