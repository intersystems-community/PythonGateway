
# Introduction

The [Jupyter Notebook](https://jupyter.org/) is an open-source web application that allows you to create and share documents that contain live code, equations, visualizations and narrative text.

This extension allows you to browse and edit InterSystems IRIS BPL processes as jupyter notebooks. 

Note that currently default Python 3 executor is used. 

This extension assumes that annotations contain Python code and uses activities names as preceding read-only headings.

This is a direct Jupyter<->BPL bridge, at no time file representations of processes or notebooks are created.

# Screenshots

## Process Explorer 
![](https://i.imgur.com/DAW30UZ.png)

## Process Editor

![](https://i.imgur.com/43qA3B1.png)

# Installation

## Prerequisites

1. You'll need [InterSystems IRIS 2019.2+](https://wrc.intersystems.com/wrc/).
2. Install PythonGateway v0.8+ (only `isc.py.util.Jupyter` and `isc.py.ens.ProcessUtils` are required).
3. Update ObjectScript code from the repo edge.

## Automatic installation

1. Run `do ##class(isc.py.util.Jupyter).Install()` and follow the prompt.

## Manual installation

Manual installation contains all the same steps as automatic installation, but you need to execute them manually.

1. Install IRISNative for Python 3.6.7 (`cp3` **OR** `py3` should be in a finename, wheel is in `\dev\python\` folder inside InterSystems IRIS installation path):
```
pip install <IRIS>\dev\python\irisnative-*cp3*.whl
pip install <IRIS>\dev\python\*py3*.whl
```

2. Install Jupyter.
```
pip install jupyter
```
3. Check [jupyter_notebook_config.py](jupyter_notebook_config.py). It assumes the following defaults for IRIS connection:
- host: `localhost`
- port: `51773`
- namespace: `USER`
- user: `_SYSTEM`
- password: `SYS`

4. If you need other connection parameters values, modify `jupyter_notebook_config.py`. 
For example to connect to InterSystems IRIS instance on port `51776` you'll need to add this line to the bottom of `jupyter_notebook_config.py`:
```
c.MLContentsManager.port = 51776
```

You can configure all settings (host, port, namespace, user, password) this way. Completely customized config looks like this:
```
exec(open("MLContentsManager.py").read())
c.NotebookApp.contents_manager_class = MLContentsManager
c.MLContentsManager.host = 'localhost'
c.MLContentsManager.port = 51773
c.MLContentsManager.namespace = 'USER'
c.MLContentsManager.user = '_SYSTEM'
c.MLContentsManager.password = 'SYS'
```

# Docker

You can also run PythonGateway with Jupyter in Docker. To run the latest image execute:
```
docker run -d \
  -p 14558:52773 \
  -p 8888:8888 \
  --name irisj \
  intersystemsdc/irispyj:latest \
  --log $ISC_PACKAGE_INSTALLDIR/mgr/messages.log \
  --after /start.sh
```

You might be required to start jupyter manually, to do that execute: `docker exec -d irisj sh /start.sh`.

To build Docker image execute: `docker build --force-rm --tag intersystemsdc/irispyj:latest .`


# Runnning

After completing automatic or manual installation open OS bash in the folder with `jupyter_notebook_config.py` and `MLContentsManager.py` and start jupyter with:

```
jupyter notebook
```

# Notes

- Ignore `Checkpoint failed` warning on save

![](https://i.imgur.com/Vg0H4U8.png)
