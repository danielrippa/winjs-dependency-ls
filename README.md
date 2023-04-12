# winjs-dependency-ls

A dependency manager for WinJS ([danielrippa/winjs](https://github.com/danielrippa/winjs)).

It is used both in the command line and in the javascript code as a function.

A dependency is a .js file referenced as a qualified namespace resource like `some.namespace.Dependency` where `some.namespace` is the qualified namespace and `Dependency` is the resource name.

The qualified namespace resource resolves to the full path of a .js file.

The qualified namespace can be either an actual filesystem folder hierarchy or can be a virtual namespace configured via an optional `namespaces.conf` configuration file.

Once resolved each dependency is cached so further references are accessed from the cache instead of being read again from the filesystem.

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

Each line can either:

  * be empty
  * include a comment preceded by a '#'
  * declare a 

namespaces.conf
```
# A comment that will be ignored 

some.namespace a:\folder\somewhere
another.namespace another-folder
```

In the previous example assuming the current working folder is `C:\Users\DanielR`:

```
  { some-method } = dependency 'folder.FileA'
  // Resolves to: C:\Users\DanielR\folder\FileA.js  
  
  { some-other-method } = dependency 'some.namespace.FileB'
  // Resolves to: a:\folder\somewhere\FileB.js
```
