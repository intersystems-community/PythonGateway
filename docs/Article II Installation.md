# Python Gateway: Installation

This series of articles would cover [Python Gateway](https://openexchange.intersystems.com/package/PythonGateway) for InterSystems Data Platforms. Execute Python code and more from InterSystems IRIS. This project brings you the power of Python right into your InterSystems IRIS environment:

- Execute arbitrary Python code
- Seamlessly transfer data from InterSystems IRIS into Python
- Build intelligent Interoperability business processes with Python Interoperability Adapter
- Save, examine, modify and restore Python context from InterSystems IRIS

# Other articles

The plan for the series so far (subject to change).

- [Part I: Overview, Landscape and Introduction](https://community.intersystems.com/post/python-gateway-part-i-introduction) 
- Part II: Installation and Troubleshooting <-- you're here
- Part III: Basic functionality
- Part IV: Interoperability Adapter
- Part V: Execute function
- Part VI: Dynamic Gateway
- Part VII: Proxy Gateway
- Part VIII: Use cases and ML Toolkit

# Installation

The are several ways to install and use Python Gateway:

- Host
  - Windows
  - Linux
  - Mac
- Docker
  - Pull prebuilt image
  - Build your own image
  
Regardless of installation method, you'll need the code. The only place to download the code is [releases page](https://github.com/intersystems-community/PythonGateway/releases). It contains tested stable releases, just get the latest one. Currently it's 0.7 but there would be newer ones in time. Don't clone/download the repository, download latest release.
  
# Host
  
If you're installing Python Gateway on your host operating system, first (regardless of operating system) you need to install Python.
  
1. [Install Python 3.6.7 64 bit](https://www.python.org/downloads/release/python-367/). It's recommended to install Python into default suggested location.
2. Install `dill` module: `pip install dill`.
3. Load ObjectScript code (i.e. `do $system.OBJ.ImportDir("C:\InterSystems\Repos\Python\isc\py\","*.cls","c",,1)`) into Production (Ensemble-enabled) namespace. In case you want to Production-enable existing namespace call: `write ##class(%EnsembleMgr).EnableNamespace($Namespace, 1)`.
4. Place [callout DLL/SO/DYLIB](https://github.com/intersystems-community/PythonGateway/releases) in the `bin` folder of your InterSystems IRIS installation. Library file should be placed into a path returned by `write ##class(isc.py.Callout).GetLib()`. 

## Windows 

5. Check that your `PYTHONHOME` environment variable points to Python 3.6.7.
6. Check that your SYSTEM `PATH` environment variable has `PYTHONHOME` variable (or directory it points to).

## Linux 

5. Check that your SYSTEM `PATH` environment variable has `/usr/lib` and `/usr/lib/x86_64-linux-gnu`, preferably at the beginning. Use `/etc/environment` file to set environment variables.
6. In cause of errors check Troubleshooting section `undefined symbol: _Py_TrueStruct` and specify `PythonLib` property.

## Mac

5. Only python 3.6.7 from [Python.org](https://www.python.org/downloads/release/python-367/) is currently supported. Check `PATH` variable.

If you modified environment variables restart your InterSystems product.


# Docker

There are many advantages to using containers: 
- Portability
- Efficiency
- Isolation
- Lightweight
- Immutability

Check [this](https://community.intersystems.com/post/continuous-delivery-your-intersystems-solution-using-gitlab-part-v-why-containers) series of articles for more info on Docker. 

All Python Gateway docker builds are based on `2019.1` containers.

## Pull prebuilt image

Execute: `docker run -d -p 52773:52773 --name irispy intersystemscommunity/irispy-community:latest` to pull and run Python Gateway on top of InterSystems IRIS Community Edition. That's it.

## Build your own image

To build docker image execute in the repository root: `docker build --force-rm --tag intersystemscommunity/irispy:latest .` 
By default the image is built upon `intersystems/iris:2019.1.0.510.0-1` image, however you can change that by providing `IMAGE` variable.
To build from InterSystems IRIS Community Edition execute: `docker build  --build-arg IMAGE=store/intersystems/iris:2019.1.0.510.0-community --force-rm --tag intersystemscommunity/irispy-community:latest .`

After that you can run your docker image: 

```
docker run -d \
  -p 52773:52773 \
  -v /<HOST-DIR-WITH-iris.key>/:/mount \
  --name irispy \
  intersystemscommunity/irispy:latest \
  --key /mount/iris.key
```

If you are running InterSystems IRIS Community Edition based image you can skip providing the key.

## Docker notes

Some information about docker:

- Test process `isc.py.test.Process` saves image artifact into temp directory. You might want to change that path to a mounted directory. To do that edit annotation for `Correlation Matrix: Graph` call, specifying valid filepath for `f.savefig` function.
- For terminal access execute: `docker exec -it irispy sh`.
- Access SMP with SuperUser/SYS or Admin/SYS user/password.
- To stop container execute: `docker stop irispy && docker rm --force irispy`.

# Validating your installation

After you've installed Python Gateway time to check that it works. Execute this code:
```
set sc = ##class(isc.py.Callout).Setup() 
set sc = ##class(isc.py.Main).SimpleString("x='HELLO'", "x", , .var)
write var
```

It should output `HELLO` - value of Python variable `x`. If returned status is an error or `var` is empty, check [readme troubleshooting section](https://github.com/intersystems-community/PythonGateway).

# Conclusion

Installing Python Gateway is fast and easy. If you're familiar with Docker get the latest image, otherwise there are kits for the main InterSystems IRIS operating systems: Windows, Linux and Mac. In the next article we would start using Python Gateway.

# Illustrated guide

There's also illustrated installation guide in ML Toolkit user group. ML Toolkit user group is a private GitHub repository set up as part of InterSystems corporate GitHub organization. It is addressed to the external users that are installing, learning or are already using ML Toolkit components. To join ML Toolkit user group, please send a short e-mail at the following address: [MLToolkit@intersystems.com](mailto:MLToolkit@intersystems.com?subject=MLToolkit%20user%20group&body=Hello.%0A%0APlease%20add%20me%20to%20ML%20Toolkit%20user%20group%3A%0A%0A-%20GitHub%20username%3A%20%0A%0A-%20Name%3A%20%0A%0A-%20Company%3A%20%0A%0A-%20Position%3A%0A-%20Country%3A%20%0A%0A) and indicate in your e-mail the following details (needed for the group members to get to know and identify you during discussions):

- GitHub username
-	Full Name (your first name followed by your last name in Latin script)
-	Organization (you are working for, or you study at, or your home office)
-	Position (your actual position in your organization, or “Student”, or “Independent”)
-	Country (you are based in)
