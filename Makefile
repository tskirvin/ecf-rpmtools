#########################################################################
### cms-rpmtools Makefile Template ######################################
#########################################################################
##
## Provides a consistent set of tools for building RPMs according to current
## USCMS-T1 standards, using mock, rpmlint, and rpm signing.
##
## Standard Usage:
##    make rpm-nosign
##    make linti
##    make rpm-sign
##
## Test Usage:
##    make build-nomock
##
## Additional documentation is available in the cms-rpmtools git repository.

#########################################################################
### Local Configuration #################################################
#########################################################################
##
## Do not modify this file directly unless you know what you're doing!
## Instead, make changes into 'Makefile.local'.  A template for this file
## is kept in the cms-rpmtools repo.
##
## Overall, this should get you started:
##
##   mkdir -p ~/pkg/MYTOOL
##   cd ~/pkg
##   git clone git@cms-git:cms-rpmtools
##   cd ~/pkg/MYTOOL
##   ln -s ../cms-rpmtools/Makefile .
##   cp ../cms-rpmtools/Makefile.local .
##

#########################################################################
### Central Configuration - EDIT AT YOUR OWN RISK #######################
#########################################################################

## What shell will we do all of this work in?  Must be at start.
SHELL = /bin/bash

## What is the name of the package, based on our current directory?
NAME = $(shell pwd | tr '/' '\n' | tail -1)

## Build Architecture, Name, Package, etc
ARCH = $(shell egrep "^BuildArch" *.spec | cut -d':' -f2 | tr -d ' ')
PACKAGE = $(shell egrep '^Name' *spec | cut -d':' -f2 | tr -d ' ')

## A quoted release for use in SRPM
RHL = $(shell rpm -qf /etc/redhat-release | cut -d '-' -f 3 | cut -d. -f1)

## What is the name of our default work directory?
RPMDIR = $(HOME)/rpmbuild

## Package version string
REL  =  $(shell egrep ^Release *.spec | cut -d':' -f2 | tr -d ' ' | sed s/\%\{\?dist\}/.el${RHL}/)
VERS =  $(shell egrep ^Version *.spec | cut -d':' -f2 | tr -d ' ')

# The location of the SRPM
SRPM =  ${RPMDIR}/SRPMS/$(NAME)-$(VERS)-`egrep ^Release *.spec | cut -d':' -f2 | tr -d ' ' | sed s/\%\{\?dist\}/.el${RHL}/`.src.rpm

## The final name of the RPM that's being generated
RPM_BASE = $(NAME)-$(VERS)-$(REL)
RPM      = $(RPM_BASE).$(ARCH).rpm

## What is our signing key ID?
SIGN_KEY = 47AE212EA9934BB1

## Where do our RPMs go when we're done?
DEST_BASE = root@rexadmin1.fnal.gov:/var/www/html/yum-managed/RPMS
DEST_slf5_noarch = $(DEST_BASE)/noarch/5.x
DEST_slf5_x86_64 = $(DEST_BASE)/x86_64/5.x
DEST_slf6_noarch = $(DEST_BASE)/noarch/6.x
DEST_slf6_x86_64 = $(DEST_BASE)/x86_64/6.x
DEST_slf7_noarch = $(DEST_BASE)/noarch/7.x
DEST_slf7_x86_64 = $(DEST_BASE)/x86_64/7.x

## What files to track?  Will decide whether we need to re-build the .tar
FILES =  Makefile.local $(PACKAGE).spec

## Include local configuration
-include Makefile.local

#########################################################################
### main () #############################################################
#########################################################################

rpm:          rpm-6-nosign rpm-7-nosign rpm-sign
rpm-nosign:   rpm-6-nosign rpm-7-nosign

rpm-5-nosign: srpm build-slf5
rpm-6-nosign: srpm build-slf6
rpm-7-nosign: srpm build-slf7

srpm: tar
	@echo "Creating SRPM..."
	rpmbuild -bs *.spec
	@echo

tar: $(FILES) $(FILES_LOCAL)
	tar --exclude '.git' --exclude '*.tar*' --exclude '*.sw*' \
		--exclude '.gitignore' $(TAR_EXCLUDE) \
		-czpf $(PACKAGE)-$(VERS)-$(REL).tar.gz $(FILES_LOCAL)

#########################################################################
### Per-Architecture Builds #############################################
#########################################################################

build-slf5: build-slf5-x86_64 build-slf5-noarch
build-slf5-noarch: build-slf5-noarch-local
build-slf5-x86_64: build-slf5-x86_64-local

build-slf6: build-slf6-x86_64 build-slf6-noarch
build-slf6-noarch: build-slf6-noarch-local
build-slf6-x86_64: build-slf6-x86_64-local

build-slf7: build-slf7-x86_64 build-slf7-noarch
build-slf7-noarch: build-slf7-noarch-local
build-slf7-x86_64: build-slf7-x86_64-local

build-nomock: tar
	rpmbuild -ba *spec

build-mock-verbose: srpm
	@if [[ $(ARCH) == 'noarch' ]]; then \
		mock -r slf6-x86_64 --arch noarch --uniqueext=$(USER) \
			--resultdir $(RPMDIR)/slf6-x86_64 $(SRPM) -v ; \
		mock -r slf6-x86_64 --arch noarch --uniqueext=$(USER) clean ; \
	fi

build-slf5-x86_64-local: srpm
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		mock -r slf5-x86_64 --arch x86_64 --uniqueext=$(USER) \
			--resultdir $(RPMDIR)/slf5-x86_64 $(SRPM) ; \
		mock -r slf5-x86_64 --arch x86_64 --uniqueext=$(USER) clean ; \
	fi

build-slf5-noarch-local: srpm
	@if [[ $(ARCH) == 'noarch' ]]; then \
		mock -r slf5-x86_64 --arch noarch --uniqueext=$(USER) \
			--resultdir $(RPMDIR)/slf5-x86_64 $(SRPM) ; \
		mock -r slf5-x86_64 --arch noarch --uniqueext=$(USER) clean ; \
	fi

build-slf6-x86_64-local: srpm
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		mock -r slf6-x86_64 --arch x86_64 --uniqueext=$(USER) \
			--resultdir $(RPMDIR)/slf6-x86_64 $(SRPM) ; \
		mock -r slf6-x86_64 --arch x86_64 --uniqueext=$(USER) clean ; \
	fi

build-slf6-noarch-local: srpm
	@if [[ $(ARCH) == 'noarch' ]]; then \
		mock -r slf6-x86_64 --arch noarch --uniqueext=$(USER) \
			--resultdir $(RPMDIR)/slf6-x86_64 $(SRPM) ; \
		mock -r slf6-x86_64 --arch noarch --uniqueext=$(USER) clean ; \
	fi

build-slf7-x86_64-local: srpm
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		mock -r slf7-x86_64 --arch x86_64 --uniqueext=$(USER) \
			--resultdir $(RPMDIR)/slf7-x86_64 $(SRPM) ; \
		mock -r slf7-x86_64 --arch x86_64 --uniqueext=$(USER) clean ; \
	fi

build-slf7-noarch-local: srpm
	@if [[ $(ARCH) == 'noarch' ]]; then \
		mock -r slf7-x86_64 --arch noarch --uniqueext=$(USER) \
			--resultdir $(RPMDIR)/slf7-x86_64 $(SRPM) ; \
		mock -r slf7-x86_64 --arch noarch --uniqueext=$(USER) clean ; \
	fi

#########################################################################
### Per-Architecture Copying ############################################
#########################################################################

copy-slf5: copy-slf5-x86_64 copy-slf5-noarch
copy-slf6: copy-slf6-x86_64 copy-slf6-noarch
copy-slf7: copy-slf7-x86_64 copy-slf7-noarch

copy-slf5-x86_64: confirm-slf5-x86_64
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		for i in $(DEST_slf5_x86_64); do \
			echo "scp $(RPMDIR)/slf5-x86_64/$(RPM_BASE).x86_64.rpm $$i" ; \
			echo "Press enter to continue..."; \
			read ; \
			scp $(RPMDIR)/slf5-x86_64/$(RPM_BASE).x86_64.rpm $$i ; \
		done ; \
	fi

copy-slf5-noarch: confirm-slf5-noarch
	@if [[ $(ARCH) == 'noarch' ]]; then \
		for i in $(DEST_slf5_noarch); do \
			echo "scp $(RPMDIR)/slf5-x86_64/$(RPM_BASE).noarch.rpm $$i" ; \
			echo "Press enter to continue..."; \
			read ; \
			scp $(RPMDIR)/slf5-x86_64/$(RPM_BASE).noarch.rpm $$i ; \
		done ; \
	fi

copy-slf6-x86_64: confirm-slf6-x86_64
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		for i in $(DEST_slf6_x86_64); do \
			echo "scp $(RPMDIR)/slf6-x86_64/$(RPM_BASE).x86_64.rpm $$i" ; \
			echo "Press enter to continue..."; \
			read ; \
			scp $(RPMDIR)/slf6-x86_64/$(RPM_BASE).x86_64.rpm $$i ; \
		done ; \
	fi


copy-slf6-noarch: confirm-slf6-noarch
	@if [[ $(ARCH) == 'noarch' ]]; then \
		for i in $(DEST_slf6_noarch); do \
			echo "scp $(RPMDIR)/slf6-x86_64/$(RPM_BASE).noarch.rpm $$i" ; \
			echo "Press enter to continue..."; \
			read ; \
			scp $(RPMDIR)/slf6-x86_64/$(RPM_BASE).noarch.rpm $$i ; \
		done ; \
	fi

copy-slf7-x86_64: confirm-slf7-x86_64
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		for i in $(DEST_slf7_x86_64); do \
			echo "scp $(RPMDIR)/slf7-x86_64/$(RPM_BASE).x86_64.rpm $$i" ; \
			echo "Press enter to continue..."; \
			read ; \
			scp $(RPMDIR)/slf7-x86_64/$(RPM_BASE).x86_64.rpm $$i ; \
		done ; \
	fi


copy-slf7-noarch: confirm-slf7-noarch
	@if [[ $(ARCH) == 'noarch' ]]; then \
		for i in $(DEST_slf7_noarch); do \
			echo "scp $(RPMDIR)/slf7-x86_64/$(RPM_BASE).noarch.rpm $$i" ; \
			echo "Press enter to continue..."; \
			read ; \
			scp $(RPMDIR)/slf7-x86_64/$(RPM_BASE).noarch.rpm $$i ; \
		done ; \
	fi


#########################################################################
### Per-Architecture RPM Confirmation ###################################
#########################################################################

confirm-slf5: confirm-slf5-x86_64 confirm-slf5-noarch
confirm-slf6: confirm-slf6-x86_64 confirm-slf6-noarch
confirm-slf7: confirm-slf7-x86_64 confirm-slf7-noarch

confirm-slf5-x86_64:
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		echo "rpm -qpi $(RPMDIR)/slf5-x86_64/$(RPM_BASE).*86*rpm" ; \
		rpm -qpi $(RPMDIR)/slf-5-x86_64/$(RPM_BASE).*86*rpm \
			2>&1 | egrep ^Signature | grep -i $(SIGN_KEY) ; \
	fi

confirm-slf5-noarch:
	@if [[ $(ARCH) == 'noarch' ]]; then \
		echo "rpm -qpi $(RPMDIR)/slf5-x86_64/$(RPM_BASE).noarch.rpm" ; \
		rpm -qpi $(RPMDIR)/slf-5-x86_64/$(RPM_BASE).noarch.rpm \
			2>&1 | egrep ^Signature | grep -i $(SIGN_KEY) ; \
	fi

confirm-slf6-x86_64:
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		echo "rpm -qpi $(RPMDIR)/slf6-x86_64/$(RPM_BASE).*86*rpm" ; \
		rpm -qpi $(RPMDIR)/slf6-x86_64/$(RPM_BASE).*86*rpm \
			2>&1 | egrep ^Signature | grep -i $(SIGN_KEY) ; \
	fi

confirm-slf6-noarch:
	@if [[ $(ARCH) == 'noarch' ]]; then \
		echo "rpm -qpi $(RPMDIR)/slf6-x86_64/$(RPM_BASE).noarch.rpm" ; \
		rpm -qpi $(RPMDIR)/slf6-x86_64/$(RPM_BASE).noarch.rpm \
			2>&1 | egrep ^Signature | grep -i $(SIGN_KEY) ; \
	fi

confirm-slf7-x86_64:
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		echo "rpm -qpi $(RPMDIR)/slf7-x86_64/$(RPM_BASE).*86*rpm" ; \
		rpm -qpi $(RPMDIR)/slf7-x86_64/$(RPM_BASE).*86*rpm \
			2>&1 | egrep ^Signature | grep -i $(SIGN_KEY) ; \
	fi

confirm-slf7-noarch:
	@if [[ $(ARCH) == 'noarch' ]]; then \
		echo "rpm -qpi $(RPMDIR)/slf7-x86_64/$(RPM_BASE).noarch.rpm" ; \
		rpm -qpi $(RPMDIR)/slf7-x86_64/$(RPM_BASE).noarch.rpm \
			2>&1 | egrep ^Signature | grep $(SIGN_KEY) ; \
	fi

#########################################################################
### Per-Architecture RPM Signing ########################################
#########################################################################

rpm-sign: sign-slf6 sign-slf7

sign-slf5: sign-slf5-x86_64 sign-slf5-noarch
sign-slf6: sign-slf6-x86_64 sign-slf6-noarch
sign-slf7: sign-slf7-x86_64 sign-slf7-noarch

sign-slf5-x86_64:
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		echo "rpm --resign $(RPMDIR)/slf-5-x86_64/$(RPM_BASE).*86*rpm" ; \
		rpm --resign $(RPMDIR)/slf-5-x86_64/$(RPM_BASE).*86*rpm \
			2>&1 | grep -v "input reopened" ; \
	fi

sign-slf5-noarch:
	@if [[ $(ARCH) == 'noarch' ]]; then \
		echo "rpm --resign $(RPMDIR)/slf-5-x86_64/$(RPM_BASE).noarch.rpm" ; \
		rpm --resign $(RPMDIR)/slf-5-x86_64/$(RPM_BASE).noarch.rpm \
			2>&1 | grep -v "input reopened" ; \
	fi

sign-slf6-x86_64:
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		echo "rpm --resign $(RPMDIR)/slf6-x86_64/$(RPM_BASE).*86*rpm" ; \
		rpm --resign $(RPMDIR)/slf6-x86_64/$(RPM_BASE).*86*rpm \
			2>&1 | grep -v "input reopened" ; \
	fi

sign-slf6-noarch:
	@if [[ $(ARCH) == 'noarch' ]]; then \
		echo "rpm --resign $(RPMDIR)/slf6-x86_64/$(RPM_BASE).noarch.rpm" ; \
		rpm --resign $(RPMDIR)/slf6-x86_64/$(RPM_BASE).noarch.rpm \
			2>&1 | grep -v "input reopened" ; \
	fi

sign-slf7-x86_64:
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		echo "rpm --resign $(RPMDIR)/slf7-x86_64/$(RPM_BASE).*86*rpm" ; \
		rpm --resign $(RPMDIR)/slf7-x86_64/$(RPM_BASE).*86*rpm \
			2>&1 | grep -v "input reopened" ; \
	fi

sign-slf7-noarch:
	@if [[ $(ARCH) == 'noarch' ]]; then \
		echo "rpm --resign $(RPMDIR)/slf7-x86_64/$(RPM_BASE).noarch.rpm" ; \
		rpm --resign $(RPMDIR)/slf7-x86_64/$(RPM_BASE).noarch.rpm \
			2>&1 | grep -v "input reopened" ; \
	fi

#########################################################################
### rpmlint #############################################################
#########################################################################
## Verify that the RPMs match the standard 'rpmlint' checks.

lint:
	find $(RPMDIR) -name "$(NAME)-$(VERS)-$(REL).*.rpm" \
		! -name '*src.rpm*' | xargs rpmlint

# Add warnings to the lint output
linti:
	find $(RPMDIR) -name "$(NAME)-$(VERS)-$(REL).*.rpm" \
		! -name '*src.rpm*' | xargs rpmlint -i
