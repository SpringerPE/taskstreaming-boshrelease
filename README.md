# A `task` streaming release for BOSH

A Bosh release to stream the output of a task (or other commands) as a web
application. Also useful to provide a web terminal to work on.

Powered by https://github.com/yudai/gotty

This project was reated as hack day project with the aim of promoting Bosh and
do live retransmission showing how it updates a CloudFoundry (or any other)
deployment.


# Development

After cloning this repository, run:

```
./bosh_prepare
```

It will download all sources specified in the spec file (commented out) of
each job, then you can create the final release with:
```
./bosh_final_release
```
It will push all changes to git upstream repository, create a tag, upload the
'.tgz' release to Github releases section. Then you can go there and update the
description.


and upload to BOSH director:

```
bosh upload release
```


# Author

Springer Nature Platform Engineering, Jose Riguera Lopez (jose.riguera@springer.com)

Copyright 2017 Springer Nature



# License

Apache 2.0 License
