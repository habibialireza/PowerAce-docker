# SQL Data File

Put the exported PowerACE SQL dump in this folder and name it:

```text
powerace-data.sql
```

The Docker build imports this file into the MariaDB image.

Recommended export rule: keep the original database names, for example
`iip-web-0002_demand`, `iip-web-0002_powerace`, and so on. If the names stay the
same, the table names in the PowerACE XML settings can stay the same too.
