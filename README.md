# diffe

Visualize diffs between git revisions, easily.

## Usage

CD into a git repository folder, and then:

```
$ diffe branch
```

Choose two branches you want to compare against and visualize the diff.

Or if you want to diff against two commits:

```
$ diffe log
```

## Customizing/Options

### $DIFFE_PROGRAM

Default value: `vim -d % %`

Defines the code editor command that will open up two files for comparison. If you don't define this variable, Vim will be the default. Two `%` should be present in the command, they'll be replaced with the file names that the user chose to visualize the diff for. For example, you could choose to use `meld` as a diff visualization tool, you would then configure it as:

`DIFFE_PROGRAM="meld % %"`

## Installation

Just source the shell script:

```
$ source <Path to where you cloned diffe>/diffe.sh
```


