# Overview

BATS library for mocking functions.


## Getting started

Add modules as a submodule.

```shell
git submodule init
mkdir -p test/libs
git submodule add https://github.com/avisiedo/bats-mock test/libs/bats-mock
```

Create your first unit tests mocking.

```shell
load './test/libs/bats-mock/load'

@test "my-test" {
    mock stub ls
    mock_ls 0 -la
    run ls -la
    assert_mock ls
    mock unstub ls
}
```

## Knowing bugs and pending tasks

The subcommands 'stdout' and 'stderr' does not work properly. They will be
joined in 'output' subcommand as BATS join standard output and error into the
same stream.

The current library is not 100% tested, so it will be included more unit tests
to provide validation about it.

