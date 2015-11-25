# ecf-rpmtools

ecf-rpmtools provides a set of wrappers for building RPMs using mock,
rpmlint, and rpm signing.  A standard build might look like:

    make rpm-nosign
    make linti
    make rpm-sign
    make copy
    make deploy

## Local Configuation

This should get you started (assuming you've installed everything into
/usr/libexec/ecf-rpmtools):

    ln -s /usr/libexec/ecf-rpmtools/rpmmacros ~/.rpmmacros

    mkdir -p ~/pkg/MYTOOL
    cd ~/pkg/MYTOOL
    ln -s /usr/libexec/ecf-rpmtools/Makefile ~/pkg/MYTOOL
    cp /usr/libexec/ecf-rpmtools/Makefile.local ~/pkg/MYTOOL

...then modify Makefile.local.
