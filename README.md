# fuzzminator

This is a framework for input guided fuzzing using afl for network and docker.
The idea behind this envornment setup is to be able to parallelize
multiple instances of a target server in separate docker images.

## Network based afl
https://github.com/liangdzou/afl/tree/afl-2.39b

### Port binding problem
In the readme of network afl the chapter "12) Fuzzing network services"
introduce a problem that this environment aims to solve.

> It is not possible to run two processes under a single operating
> system kernel that bind to (listen to) the same port on the same
> address. Thus, either a special wrapper (such as could be implemented
> using LD_PRELOAD) can be used to remap each target's port to a
> different value, or only one target process can be executed per kernel
> (not per core). Parallel fuzzing of network services can be done using
> several independent hosts (a cluster), or by reconfiguring the code
> running on each core to use a different port.

We aim to build a generic aproach that does not require code changes
or configuration changes and thus the independent host cluster
approach is what we are going for using docker as a tennant
for each cpu core.

### Delay time guidlines
Delay before write and timeout delay are two values that need to be
found using debugging. The timeout_delay is a time in milliseconds that
the entire fuzz run should take before a crash should have occured.

The delay_before_write value is the time it takes for the server to start
and be ready to receive input.

From the documentation:

> A rule of
> thumb is the timeout_delay value should be slightly longer than three
> times the delay_before_write value, and the delay_before_write value
> should be as small as possible while consistent with an acceptable
> fraction of target process executions that time out (for example,
> around 0.1%).

The afl-fuzz command argument for `timeout_delay` is `-D ms` and
`delay_before_write` is `-t ms`.

### Network setup
Afl-net only support fuzzing of localhost. Using the
`-N network_specification` option we can specify what connection
type and destination to use.
Here is an example of a `network_specification`:
```
afl-fuzz -i /input -o /output -N tcp://127.0.0.1:80 ./target
```

## Process thread paralellization
To deal with the port binding problem we utilize a separation between
each proces susing Linux namespaces through docker.

https://github.com/liangdzou/afl/blob/afl-2.39b/docs/parallel_fuzzing.txt

*Note!*
We utilize a experimental feature called multi-system paralellization.
The feature we used was introduced in afl-2.39b this specific combination of network
and paralellization features are only available in this repo
https://github.com/liangdzou/afl/tree/afl-2.39b

As of March 2020 the 2.39b experimental feature set for deterministic multi masters
was not yet added to the unoficcial repository of github.com/jdbirdwell/afl see:
https://github.com/jdbirdwell/afl/pull/4

> The difference between the -M and -S modes is that the master instance will
> still perform deterministic checks; while the secondary instances will
> proceed straight to random tweaks. If you don't want to do deterministic
> fuzzing at all, it's OK to run all instances with -S. With very slow or complex
> targets, or when running heavily parallelized jobs, this is usually a good plan.

> Note that running multiple -M instances is wasteful, although there is an
> experimental support for parallelizing the deterministic checks. To leverage
> that, you need to create -M instances like so:

```
$ ./afl-fuzz -i testcase_dir -o sync_dir -M masterA:1/3 [...]
$ ./afl-fuzz -i testcase_dir -o sync_dir -M masterB:2/3 [...]
$ ./afl-fuzz -i testcase_dir -o sync_dir -M masterC:3/3 [...]
```

> ...where the first value after ':' is the sequential ID of a particular master
> instance (starting at 1), and the second value is the total number of fuzzers to
> distribute the deterministic fuzzing across. Note that if you boot up fewer
> fuzzers than indicated by the second number passed to -M, you may end up with
> poor coverage.

### Intercommunication
The processes communicate using a sync directory and a shared master-job.
Set up a shared volume for docker using tmpfs (so we dont ruin our SSD disks with writes).
```
$ docker volume create --driver local \
    --opt type=tmpfs \
    --opt device=tmpfs \
    --opt o=size=100m,uid=1000 \
    output
$ docker run -v output:/output --detach fuzzminator:1.0
```
Find the shared output directory using the `-o /output` option to `afl-fuzz`.
