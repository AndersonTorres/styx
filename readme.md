[![Build Status](https://travis-ci.org/styx-static/styx.svg?branch=master)](https://travis-ci.org/styx-static/styx)

# Styx

The purely functional static site generator in Nix expression language.


## Features

Among others, styx have the following features:

## Easy to install

Styx has no other depency than nix, if nix is installed `nix-env -iA styx` is all that is required to install.

## Multiple content support

Styx support content in markdown, asciidoc and nix.  
Styx also provides some special tags that can be used in markup language to add an introduction or to split a markup file in multiple html pages.

## Embedded nix

Nix can be embedded in markup files!  
For example a youtube video can be embedded in a mardown file like this:

## Handling of sass/scss

Upon site rendering, styx will automatically convert sass and scss files.

## Template framework

The generic-template theme provide a template framework that can be leveraged to easily create new themes or sites.
Thank to this a theme like hyde consists only in about 120 lines of nix templates.

## Configuration interface

Styx sites use a configuration interface a la NixOS modules.  
Every configuration declaration is type-checked, and documentation can be generated from that interface.

## Linkcheck

Linkcheck functionality is available out of the box, just run `styx linkcheck` to run linkcheker on a site.

## Themes

Styx support themes. Multiple themes can be used, mixed and extended at the same time.  
This make it very easy to adapt an existing theme.  
Official themes can also be used without any implicit installation, declaring the used theme(s) in `site.nix` is enough!

## Documentation

Styx fetaure complete documentation that can be viewed at any time by running `styx doc`.  
A very unique feature of styx is that it can generate the documentation for a particuliar site with the `styx site-doc`,
this documentation consists of used themes documentations, rendered pages list url and more.


## Install

Use nix-env to install styx, or nix-shell to just test without installing it:

```sh
$ nix-env -iA styx
$ styx --help
```

```sh
$ nix-shell -p styx
$ styx --help
```

The version you will get will depend on the version of nixpkgs used, to get the latest stable release without relying on nixpkgs:

```
$ nix-env -i $(nix-build https://github.com/styx-static/styx/archive/latest.tar.gz)
$ styx --help
```

or

```
$ nix-shell -p $(nix-build https://github.com/styx-static/styx/archive/latest.tar.gz)
$ styx --help
```

Note: When using a version of styx that is different of the one in the system active nixpkgs, call to `pkgs.styx-themes.*` might not work as versions will differ.  
In this case themes should be fetched directly with `fetchGit` or similar.


## Examples

The official styx site is an example of a basic software site with release news. It have some interesting features like:

- generating the documentation for every version of styx
- generating a page for every official theme

Please check [site.nix](https://github.com/styx-static/styx-site/blob/master/site.nix) for implementation details.


## As a Nix laboratory

This repository is also a playground for more exotic nix usages and experiments:

- [derivation.nix](./derivation.nix) is the main builder for styx, it builds the command line interface, the library and the documentation.

- [nixpkgs/default.nix](./nixpkgs/default.nix) extend the system nixpkgs with the styx related packages making it easy to build or install dev versions with the correct set of dependencies:

    ```
    $ nix-build nixpkgs -A styx
    $ nix-build nixpkgs -A styx-themes.showcase
    ```

- [script/run-tests](./scripts/run-tests) is a thin wrapper to `nix-build` that will run [library](./tests/lib.nix) and [functionality tests](./tests/default.nix).

- Library functions and themes templates use special functions (`documentedFunction` and `documentedTemplate`) that allow to automatically generate documentation and tests.  
The code used to generate tests from `documentedFunctions` can be found in [tests/lib.nix](./tests/lib.nix).  
Library function tests can print a coverage or a report (with pretty printing):

    ```
    $ cat $(nix-build --no-out-link -A coverage tests/lib.nix)
    $ cat $(nix-build --no-out-link -A report tests/lib.nix)
    ```

- [scripts/library-doc.nix](./scripts/library-doc.nix) is a nix expression that generate an asciidoc documentation from the library `documentedFunction`s ([example](https://styx-static.github.io/styx-site/documentation/library.html)).

- [scripts/update-themes-screens](./scripts/update-themes-screens) is a shell script using a `nix-shell` shebang that automatically take care of external dependencies (PhantomJS and image magick) that build every theme site, run it on a local server and take a screenshot with PhantomJS. neat!

- [scripts/themes-doc.nix](./scripts/themes-doc.nix) and [src/nix/site-doc.nix](./src/nix/site-doc.nix) are nix expressions that automatically generate documentation for styx themes, including configuration interface and templates ([example](https://styx-static.github.io/styx-site/documentation/styx-themes.html)). This feature is leveraged in the `styx site-doc` command to dynamically generate the documentation for a site according to used themes.

- `lib.prettyNix` is a pure nix function that pretty print nix expressions.

- [parsimonious](https://github.com/erikrose/parsimonious) is used to do some [voodoo](src/tools/parser.py) on markup files to turn them into valid nix expressions, so nix expressions can be embedded in markdown or asciidoc.

- styx `propagatedBuildInputs` are taken advantage in `lib.data` conversion functions like `markupToHtml`.


## Links

- [Official site](https://styx-static.github.io/styx-site/)
- [Documentation](https://styx-static.github.io/styx-site/documentation/)


## Contributing

Read [contributing.md](./contributing.md) for details.


## Feedback

Any question or issue should go in the github issue tracker.  
Themes requests are also welcome.
And please let me know if you happen to run a site on styx!
