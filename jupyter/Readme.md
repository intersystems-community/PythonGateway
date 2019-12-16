
# Introduction

The [Jupyter Notebook](https://jupyter.org/) is an open-source web application that allows you to create and share documents that contain live code, equations, visualizations and narrative text.

This extension allows you to browse and edit InterSystems IRIS BPL processes as jupyter notebooks. 

Note that currently default Python 3 executor is used. 

This extension assumes that annotations contain Python code and uses activities names as preceding read-only headings.

# Screenshots

## Process Explorer 
![](https://i.imgur.com/DAW30UZ.png)

## Process Editor

![](https://i.imgur.com/43qA3B1.png)

# Installation

1. You'll need [InterSystems IRIS 2019.2+](https://wrc.intersystems.com/wrc/).
2. Install PythonGateway v0.8+ (only `isc.py.util.Jupyter` and `isc.py.ens.ProcessUtils` are required).
3. Install IRISNative for Python 3.6.7 (`cp36` should be in a finename, wheel is in `\dev\python\` folder inside InterSystems IRIS installation path):
```
pip install <IRIS>\dev\python\irisnative-*cp36*.whl
```

4. Install Jupyter.
```
pip install jupyter
```
5. Check [jupyter_notebook_config.py](jupyter_notebook_config.py). It assumes the following defaults for IRIS connection:
- host: `localhost`
- port: `51773`
- namespace: `USER`
- user: `_SYSTEM`
- password: `SYS`

6. If you need other connection parameters values, modify `jupyter_notebook_config.py`. 
For example to connect to InterSystems IRIS instance on port `51776` you'll need to add this line to the bottom of `jupyter_notebook_config.py`:
```
c.MLContentsManager.port = 51776
```

You can configure all settings (host, port, namespace, user, password) this way.

7. Open OS bash in the folder with `jupyter_notebook_config.py` and `MLContentsManager.py` and start jupyter with:

```
jupyter notebook
```

# Notes

- Ignore `Checkpoint failed` warning on save

![](https://i.imgur.com/Vg0H4U8.png)
