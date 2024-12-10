# diffe

Visualize diffs between git revisions, easily.

## Usage

CD into a git repository folder, and then:

```
$ diffe branch
```

You will then be prompted to choose two branches you want to compare against and visualize the diff for.

Or if you want to diff against two commits:

```
$ diffe log
```

If you prefer to just type the revisions or branches you want to compare instead of being prompted to select:

```
$ diffe branch_one branch_two
```

You may also provide a single Git revision, and then *diffe* will compare that revision to the previous one:

```
$ diffe some_revision
```

## Customizing/Options

### $DIFFE_PROGRAM

Default value: `vim -d % %`

Defines the code editor command that will open up two files for comparison. If you don't define this variable, Vim will be the default. Two `%` should be present in the command, they'll be replaced with the file names that the user chose to visualize the diff for. For example, you could choose to use `meld` as a diff visualization tool, you would then configure it as:

```
DIFFE_PROGRAM="meld % %"
```

## Installation

Just source the shell script:

```
$ source <Path to where you cloned diffe>/diffe.sh
```

## Integrate it with tig

[tig is a text-mode interface for git.](https://github.com/jonas/tig)

```sh
# ~/.tigrc:

bind generic ; !sh -c '. ~/.bashrc && diffe %(commit)'
```

## LICENSE

The MIT License (MIT)

Copyright (c) 2024 Dhuan Oliveira

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


