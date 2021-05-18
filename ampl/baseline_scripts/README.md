## Scripts

- **build_dist.sh**: script to build **dist/** after **mk dist**
- **build_ax.sh**: build ax
- **build_ubuntu.sh**: build ax and ampl on Ubuntu
- **build_manylinux.sh**: build ax and ampl on manylinux
- **download_ampl.sh**: download and extract ampl bundle
- **download_tables.sh**: download and extract table handler bundle
- **prepare_baseline.sh**: download ampl and table handlers, and prepare baseline for testing
- **basic_test.sh**: trivial test just to confirm that the executables do something
- **run_tests.sh**: run a set of tests and compare outputs
- **check_build.sh**: compare symbols
- **tladjust.py**: **tladjust.c** stuff replicated in python
- **licdecode.py**: function Decode from licmain.c implemented in python.
- **tlextend.sh**: extend expiration dates of all arguments using **tladjust.sh**
- **qemu/docker.sh**: base docker script for **qemu/lx-*** scripts (e.g., **lx-aarch64**, **lx-ubuntu20.04**)
- **escrow_decrypt.sh**: decrypt escrowYYYYMMDD.tgz.gpg.
- **escrow_update.sh**: update source from escrow directory after decrypting.
- **az-release.sh**: script to simplify releases on azure pipelines.
- **old/**: old scripts moved from the repositoy root
