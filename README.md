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

## Customizing/Options

### $DIFFE_PROGRAM

Default value: `vim -d % %`

Defines the code editor command that will open up two files for comparison. If you don't define this variable, Vim will be the default. Two `%` should be present in the command, they'll be replaced with the file names that the user chose to visualize the diff for. For example, you could choose to use `meld` as a diff visualization tool, you would then configure it as:

```
DIFFE_PROGRAM="meld % %"
```

### $DIFFE_PROGRAM_SED

Default value: `sed`

If your `sed` program is the GNU version, there's no need to define this variable. If however you're in some BSD-variant distribution, you will need to define this variable referencing the executable name to GNU's sed.

## Installation

Just source the shell script:

```
$ source <Path to where you cloned diffe>/diffe.sh
```

## Using diffe on macOS

Diffe depends on GNU's sed. The sed program that comes with macOS is the BSD version, which will result in problems while using Diffe. You can easily solve this problem installing gnu-sed on your Mac:

```
brew install gnu-sed
```

Then, when running diffe, make sure to use the `DIFFE_PROGRAM_SED` environment variable so that diffe knows to use the right sed program.

```
DIFFE_PROGRAM_SED="gsed" diffe log
```

