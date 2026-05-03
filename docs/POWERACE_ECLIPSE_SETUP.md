# Configure PowerACE To Use The Docker Database

This guide assumes the MariaDB container is already running.

## 1. Start The Container

In this repository folder:

```powershell
.\run-container.ps1
```

Check it:

```powershell
.\test-connection.ps1 -ContainerName powerace-mariadb
```

## 2. Open The Run Configuration

In Eclipse:

```text
Run -> Run Configurations...
```

Select the PowerACE Java application run configuration. It is usually called:

```text
PowerMarkets
```

If it does not exist, create one:

```text
Java Application -> New
```

Use:

```text
Project: PowerACE-main
Main class: simulations.PowerMarkets
```

## 3. Set The Working Directory

Open the `Arguments` tab.

Under `Working directory`, choose `Other` and set the PowerACE project folder,
for example:

```text
C:\workspace\powerace\PowerACE-main
```

PowerACE reads `params/userSettings.xml` relative to this folder.

## 4. Add Environment Variables

Open the `Environment` tab and add:

```text
POWERACE_DB_HOST=127.0.0.1
POWERACE_DB_PORT=3307
POWERACE_DB_USER=powerace
POWERACE_DB_PASSWORD=powerace
```

Apply the configuration.

## 5. Run PowerACE

Run the configuration.

If PowerACE is using Docker, the console should show a database connection like:

```text
Opening PowerACE database connection pool at jdbc:mysql://127.0.0.1:3307 with user 'powerace'.
```
