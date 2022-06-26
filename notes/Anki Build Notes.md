# Anki Build Notes

These notes are based on dev work/experimentation that I did on 2021-12-12.  Note that this development work was all done on a Mac.  See [this page](https://github.com/ankitects/anki/blob/main/docs/development.md) from the Anki documentation for their description of the Anki build process.

## Build Steps for Anki

```bash
  git clone git@github.com:ankitects/anki.git
  cd anki
  brew unlink bazel   # conflicts with bazelisk
  brew install bazelisk
```

To build and launch Anki (this takes a while):

```bash
  ./run
```

## Running Anki Tests

To run tests in a directory:

```bash
  cd pylib/tests
  bazel test //...
```

To run a specific test, e.g., test_schedv2 (the main Anki scheduling test):

```bash
  cd anki
  PYTEST=test_schedv2 bazel run //pylib:pytest
```


## Debugging Anki Code

To print out an object from Python:

```python
  from pprint import pprint

  pprint(vars(my_object))
```
