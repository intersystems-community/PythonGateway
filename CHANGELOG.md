# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.7] - 2019-03-21
### Added
- Docker support.
- (Experimental) `ExecuteFunction` support.
- (Experimental) Proxyless Gateway support. 
- `ExecuteQuery` support for types and namespaces.
- JSON serialization for interoperability (also Repr, Pickle and Dill).
- Saving context now saves user functions.
- Python datatypes escaper: string, bool, date, time, timestamp.
- Initializer interface.
- Python shell: `do ##class(isc.py.util.Shell).Shell()`
- Business Process emulator.
- Sample %ZLANGC00 and %ZSTART routines.

### Changed
- Dill is now a required module.
- `GetVariableInfo` now returns FQCN as type.
- `GetVariableInfo` support for attributes (methods and the like).
- Test process now uses non-interactive GUI for test business process
- Test process: new data, simplified code.
- Log trace events enabled by default.

### Removed
- Test methods GetRandom, GetRandomSimple, SimpleStringFull from callout API


## [0.6] - 2019-01-22
### Added
- Mac OS X support.
- Linux - ability to load Python library explicitly.
- ExcuteQuery - load data from query without xDBC.
- Exception handling to Callout interface.

### Changed
- Test process now works in 3 modes: RAW, ODBC, JDBC.
- Completed Main interface utility methods.

## [0.5] - 2019-01-18
### Added
- Streams up to 2,147,483,647 bytes (~2Gb) now can be passed inside to python context and retrieved (up to IRIS limit) from it.
- Mask and MaxLength conditions added to context persistence.
- New class `isc.py.Main` as a main public interface.

### Changed
- Context persistence uses streams.

## [0.4.2] - 2019-01-17
### Changed
- Pass/retrieve limit raised to 3 641 144 characters.

## [0.4] - 2018-12-28
### Added
- Context persistence.
- Serialization options.
- Unit tests.
- Error management.

## [0.3] - 2018-12-24
### Changed
- Transfer limit raised to 3 641 144 characters.

### Removed
- Explicit initialization (now it's done implicitly).

## [0.2] - 2018-12-20
### Removed
- Debugging.

## [0.1.1] - 2018-12-18
### Changed
- Retrieving undefined variable does not crash the process now.

## [0.1] - 2018-12-18
### Added
- Initial version.
