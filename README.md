# winjs-dependency-ls

A dependency manager for WinJS ([danielrippa/winjs](https://github.com/danielrippa/winjs)).

It is used both in the command line and in the javascript code in the form of a function.

A dependency is a .js file referenced as a qualified namespace resource like `some.namespace.Dependency` where `some.namespace` is the qualified namespace and `Dependency` is the resource name.

The qualified namespace resource resolves to the full path of a .js file.

The qualified namespace can be either an actual filesystem folder hierarchy or can be a virtual namespace configured via an optional `namespaces.conf` configuration file.

Each resolved dependency is cached so after being referenced for the first time, further references are accessed from the cache instead of being read again from the filesystem.

## Usage

In the command line:
```
  winjs.exe dependency.js some.namespace.Dependency
```

In JavaScript code:
```
  some-dependency = dependency 'some.namespace.Dependency'
  
  // or more commonly used with de-structuring:
  
  { some-method, some-property } = dependency 'some.namespace.Dependency'
```

Where `some.namespace` can either be:

  * an actual filesystem folder hierarchy starting from the current working folder, or 
  * a folder mapped via the optional `namespaces.conf` configuration file.

## Configuration file Syntax

The `namespaces.conf` configuration file is optional.

Each line can:

  * be empty
  * include a comment preceded by a '#'
  * declare a 

namespaces.conf
```
some.namespace folder
```
