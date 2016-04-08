# Moai Plugin Manager
This is a simple plugin manager for **Moai SDK**. It is still in early alpha stages. To learn how to make new plugins, take a look at: `plugins/plugin.lua.sample`. Define your plugins in `util/apply-plugin/config.lua`.

## Requirements
Right now **Moai Plugin Manger** requires **moaiutil**. Support for **pito** is a priority for future updates. Works best with **Moai 1.6 Stable**.

## Installation
### Linux / OS X:
Run the following in your shell:
```bash
git clone https://github.com/btatarov/moai-plugin-mgr.git
cd moai-plugin-mgr
./install
```
You **must** have your **$MOAI_ROOT** environment variable set in order to use the automatic installer. If you are not sure, run this line from inside your Moai root directory:
```bash
export MOAI_ROOT=$(pwd)
```

### Windows:
Windows is not supported, yet. To use the tool you have to install Cygwin or some other application that supports bash scripting. Any help in bringing **Moai Plugin Manager** to Windows will be highly appreciated.

## Usage
Execute from your Moai root:
```bash
./bin/apply-plugin.sh <plugin-name>
```
