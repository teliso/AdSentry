## Description

A DNS filtering module based on KernelSU and AdGuardHome.

If you want to build the module yourself, you need to place the AdGuardHome binary and the AdGuardHome.yaml configuration file into the `agh_work` directory. **The filenames must remain unchanged.**

The toggle switch can be used to start or stop AdSentry.

The default web interface for AdGuardHome in this module is: `http://127.0.0.1:3000/`

Username: `admin`

Password: `admin`

## Features

* Uses the module configuration system provided by KernelSU to manage settings.
  To modify the configuration, edit the `config.sh` file in the module directory.
  Saving changes will automatically trigger a configuration update and restart AdSentry.

* Dynamically updates the module description to display runtime information, including:
  - Module logs
  - Whether firewall rules are applied
  - AdGuardHome version and PID
  - Loaded firewall rules

* More flexible module configuration and more detailed logging output.

* Module information output supports automatic system language detection, but currently only supports Chinese and English.

## Acknowledgements

Idea inspired by: [twoone-3/AdGuardHomeForRoot](https://github.com/twoone-3/AdGuardHomeForRoot)

Powered by: [AdguardTeam/AdGuardHome](https://github.com/AdguardTeam/AdGuardHome)