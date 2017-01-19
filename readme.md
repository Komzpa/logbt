logbt
-----

Short for "Log Backtrace", this is a bash wrapper for displaying a backtrace when a program crashes.

[![Build Status](https://travis-ci.org/mapbox/logbt.svg?branch=master)](https://travis-ci.org/mapbox/logbt)

Without logbt if a program crashes it will show only an unhelpful error:

```sh
$ ./program
Segmentation fault
```

After logbt you will see logs with the program exit code and beautiful backtrace if the program crashed:

```sh
$ sudo logbt --setup
$ logbt --watch ./program
program exited with code:139
Found core at /tmp/logbt-coredumps/core.15425

Core was generated by `program     '.
Program terminated with signal 11, Segmentation fault.
#0  0x00007f51f7452317 in kill () from /lib/x86_64-linux-gnu/libc.so.6

Thread 5 (Thread 0x7f51f5c18700 (LWP 15429)):
#0  0x00007f51f77e7fd0 in sem_wait () from /lib/x86_64-linux-gnu/libpthread.so.0
#1  0x0000000000fa97d8 in v8::base::Semaphore::Wait() ()
#2  0x0000000000e46f99 in v8::platform::TaskQueue::GetNext() ()
#3  0x0000000000e470ec in v8::platform::WorkerThread::Run() ()
#4  0x0000000000faa790 in v8::base::ThreadEntry(void*) ()
#5  0x00007f51f77e1e9a in start_thread () from /lib/x86_64-linux-gnu/libpthread.so.0
#6  0x00007f51f750f36d in clone () from /lib/x86_64-linux-gnu/libc.so.6
#7  0x0000000000000000 in ?? ()

[... snip ...]
```

### Supports

 - Linux and OS X
 - Docker (see [Docker](#Docker-considerations) below)

### Depends

Requires `gdb` on linux and `lldb` on OS X.

Recommended install of gdb on linux:

```
mkdir mason && curl -sSfL https://github.com/mapbox/mason/archive/v0.5.0.tar.gz | tar --gunzip --extract --strip-components=1 --directory=./mason
./mason/mason install gdb 7.12
export PATH=$(./mason/mason prefix gdb 7.12)/bin:${PATH}
which gdb
```

Recommended install of lldb on OS X is to get latest XCode.

### Installing

To install `logbt` to `/usr/local/bin`:

```sh
curl -sSfL https://github.com/mapbox/logbt/archive/v1.6.0.tar.gz | tar --gunzip --extract --strip-components=1 --exclude="*md" --exclude="test*" --directory=/usr/local
which logbt
/usr/local/bin/logbt
logbt --version
```

Locally (perhaps if your user cannot write to `/usr/local`):

```sh
curl -sSfL https://github.com/mapbox/logbt/archive/v1.6.0.tar.gz | tar --gunzip --extract --strip-components=2 --exclude="*md" --exclude="test*" --directory=.
./logbt --version
```

### Usage

There are two main modes to using `logbt`. First you run `--setup` and second you run `--watch` to launch your program with it.

#### logbt --setup

You must setup `logbt` before use:

```bash
sudo logbt --setup
```

This command sets the system `core_pattern` to ensure it is ready for `logbt` to use.

This is required on Linux (modifies `/proc/sys/kernel/core_pattern`). Running `logbt --setup` is optional on OS X if the system default for `kern.corefile` is intact (This means on OS X that `$(sysctl -n kern.corefile) == '/cores/core.%P'`)

Common default values for `core_pattern` on linux (which do not work with `logbt`) are:

  - `|/usr/libexec/abrt-hook-ccpp %s %c %p %u %g %t e` Seen on Centos 6
  - `|/usr/share/apport/apport %p %s %c` Seen on Ubuntu Precise
  - `|/usr/share/apport/apport %p %s %c %P` Seen on Ubuntu Trusty

#### logbt --watch

### Additional options

 - `logbt --test`: tests that logbt is functioning correctly. Should be run after `logbt --setup`
 - `logbt --current-pattern`: displays the current `core_pattern` value on the system (`/proc/sys/kernel/core_pattern` on linux and `sysctl -n kern.corefile` on OS X)
 - `logbt --target-pattern`: displays the target `core_pattern` value that `logbt --setup` will apply to the system which is `/tmp/logbt-coredumps/core.%p.%e` on linux and `/tmp/logbt-coredumps/core.%P` on OS X)
 - `logbt --version`: Prints the `logbt` version
 - `logbt --help`: Prints the `logbt` usage help

### Docker considerations

Docker linux containers inherit their kernel settings from the linux host. Because the `core_pattern` modified by [`logbt --setup`](#Logbt-setup) is kernel-level the `--setup` command must be either be run as root on the linux host (recommended) or within a container run with the `--privileged` flag.

If you try to run `logbt --setup` in a container without the `--privileged` flag you will see an error like: `/proc/sys/kernel/core_pattern: Read-only file system`

Beware that running `logbt --setup` in a `privileged` container will change the value for the host (when the host is linux).

The `--privileged` only applies to `docker run` and not `docker build` (refs https://github.com/docker/docker/issues/1916)

With AWS, the ECS [container definition](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#container_definition_security) is how you ask for `privileged` runs.

The `logbt --setup` command does not work on some CI systems like https://circleci.com (neither on the host or in the container). This is because on circleci `/proc/sys/kernel/core_pattern` is read-only on the host (perhaps because the host machine is actually a docker container). It appears that to run in `--privileged` you need to be an [enterprise customer](https://github.com/circleci/image-builder/#ubuntu-1404-xxl-enterprise).

Running `logbt` on travis works great with ["sudo-enabled" machines](https://docs.travis-ci.com/user/ci-environment/#Virtualization-environments). These machines allow you to run `sudo logbt --setup` on the host or run `logbt --setup` in a `privileged` container. However similar to circleci the `logbt --setup` command does not work on https://travis-ci.org "container-based" (aka `sudo:false`) machines.

One other alternative to running `--privileged` is mounting a writable /proc directory like:

    docker run --volume /proc:/writable-proc <image name> bash

Then within that container you can write to `writable-proc` and it will be reflected in `/proc`:

    cat $(./bin/logbt --target-pattern) > /writable-proc/sys/kernel/core_pattern

After that command both `/writable-proc/sys/kernel/core_pattern` and `/proc/sys/kernel/core_pattern` will be equivalent and `logbt --test` should work.

But surprisingly this still modifies the host `core_pattern` so there is no major advantage to this method over running `logbt --setup` directly on the host.
