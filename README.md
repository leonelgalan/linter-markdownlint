# linter-markdownlint

This linter plugin for [Linter](https://github.com/AtomLinter/Linter) provides an interface to [markdownlint](https://github.com/mivok/markdownlint). It will be used with files that have the "Markdown" syntax.

## Installation

Linter package must be installed in order to use this plugin. If Linter is not installed, please follow the instructions [here](https://github.com/AtomLinter/Linter).

### mdl installation

Before using this plugin, you must ensure that `mdl` is installed on your system. To install `mdl`, do the following:

1. Install [ruby](https://www.ruby-lang.org/).

1. Install [markdownlint](https://github.com/mivok/markdownlint) by typing the following in a terminal:

```sh
gem install mdl
```

Now you can proceed to install the _linter-markdownlint_ plugin.

### Plugin installation

```sh
apm install linter-markdownlint
```

## Settings

You can configure _linter-markdownlint_ by editing ~/.atom/config.cson (choose _Config..._ in _Atom_ menu):

```cson
'linter-markdownlint':
  executablePath: 'mdl'
  severity: 'error'
```

Run `which mdl` to find the path, if you using _rbenv_ run `rbenv which mdl`
