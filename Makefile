#########################################################################
### ecf-rpmtools Makefile Template ######################################
#########################################################################
##
## Provides a consistent set of tools for building RPMs according to current
## ECF-SSI standards, using mock, rpmlint, and rpm signing.
##
## Standard Usage:
##    make rpm-nosign
##    make linti
##    make rpm-sign
##
## Test Usage:
##    make build-nomock
##
## Additional documentation is available in the ecf-rpmtools git repository.

#########################################################################
### Local Configuration #################################################
#########################################################################
##
## Do not modify this file directly unless you know what you're doing!
## Instead, make changes into 'Makefile.local'.  A template for this file
## is kept in the ecf-rpmtools repo.
##
## Overall, this should get you started:
##
##   mkdir -p ~/pkg/MYTOOL
##   cd ~/pkg
##   git clone ssh://git@rexadmin1.fnal.gov:2222/ssi/ecf-rpmtools
##   cp ~/pkg/ecf-rpmtools/rpmmacros ~/.rpmmacros
##   cd ~/pkg/MYTOOL
##   ln -s ../ecf-rpmtools/Makefile .
##   cp ../ecf-rpmtools/Makefile.local .
##

#########################################################################
### Central Configuration - EDIT AT YOUR OWN RISK #######################
#########################################################################

## What shell will we do all of this work in?  Must be at start.
SHELL = /bin/bash

## What is the name of the package, based on our current directory?
NAME = $(shell egrep '^Name' *spec | cut -d':' -f2 | tr -d ' ')

## Build Architecture, Name, Package, etc
ARCH    := $(shell egrep "^BuildArch" *.spec | cut -d':' -f2 | tr -d ' ')
PACKAGE := $(shell egrep '^Name' *spec | cut -d':' -f2 | tr -d ' ')

## A quoted release for use in SRPM
RHL = $(shell rpm -qf /etc/redhat-release | cut -d '-' -f 3 | cut -d. -f1)

## What is the name of our default work directory?
RPMDIR = $(HOME)/rpmbuild

## Package version and release strings
REL  :=  $(shell egrep ^Release *.spec | cut -d':' -f2 | tr -d ' ' | sed s/\%\{\?dist\}/.el${RHL}/)
REL7 :=  $(shell egrep ^Release *.spec | cut -d':' -f2 | tr -d ' ' | sed s/\%\{\?dist\}/.el7/)
REL8 :=  $(shell egrep ^Release *.spec | cut -d':' -f2 | tr -d ' ' | sed s/\%\{\?dist\}/.el8/)
REL9 :=  $(shell egrep ^Release *.spec | cut -d':' -f2 | tr -d ' ' | sed s/\%\{\?dist\}/.el9/)
RELx :=  $(shell egrep ^Release *.spec | cut -d':' -f2 | tr -d ' ' | sed s/\%\{\?dist\}//)
VERS :=  $(shell egrep ^Version *.spec | cut -d':' -f2 | tr -d ' ')

# The location of the SRPMs
SRPM :=  $(shell echo "${RPMDIR}/SRPMS/$(NAME)-$(VERS)-$(REL).src.rpm")
SRPM7 :=  $(shell echo "${RPMDIR}/SRPMS/$(NAME)-$(VERS)-$(REL7).src.rpm")
SRPM8 :=  $(shell echo "${RPMDIR}/SRPMS/$(NAME)-$(VERS)-$(REL8).src.rpm")
SRPM9 :=  $(shell echo "${RPMDIR}/SRPMS/$(NAME)-$(VERS)-$(REL9).src.rpm")

## The final name of the RPM that's being generated
RPM_BASE = $(NAME)-$(VERS)-$(REL)
RPM_BASE_7 = $(NAME)-$(VERS)-$(REL7)
RPM_BASE_8 = $(NAME)-$(VERS)-$(REL8)
RPM_BASE_9 = $(NAME)-$(VERS)-$(REL9)
RPM      = $(RPM_BASE).$(ARCH).rpm

## What is our signing key ID?
SIGN_KEY = 602df50e15142ea3

SPEC_FILE := $(shell echo *.spec)

## Where do our RPMs go when we're done?
DEST = root@ssi-rpm.fnal.gov:/var/www/html/ssi/yum-managed/RPMS
DEST_slf7_noarch = $(DEST)/noarch/7.x
DEST_slf7_x86_64 = $(DEST)/x86_64/7.x
DEST_el8_noarch = $(DEST)/noarch/8.x
DEST_el8_x86_64 = $(DEST)/x86_64/8.x
DEST_el9_noarch = $(DEST)/noarch/9.x
DEST_el9_x86_64 = $(DEST)/x86_64/9.x

DEPLOY_MAKE = ssh root@ssi-rpm.fnal.gov make -f /var/www/html/ssi/yum-managed/Makefile

## What files to track?  Will decide whether we need to re-build the .tar
FILES =  Makefile.local $(PACKAGE).spec

## Include local configuration
-include Makefile.local

MOCK7 := mock -r slf7-x86_64 --uniqueext=$(USER) --resultdir $(RPMDIR)/slf7-x86_64 -D 'dist .el7'
MOCK8 := mock -r centos8-x86_64 --uniqueext=$(USER) --resultdir $(RPMDIR)/el8-x86_64 -D 'dist .el8' --disable-plugin=package_state
MOCK9 := mock -r centos-stream-9-x86_64 --uniqueext=$(USER) --resultdir $(RPMDIR)/el9-x86_64 -D 'dist .el9'

#########################################################################
### main () #############################################################
#########################################################################

rpm:          rpm-7-nosign rpm-8-nosign rpm-9-nosign rpm-sign
rpm-nosign:   rpm-7-nosign rpm-8-nosign rpm-9-nosign

rpm-7-nosign: build-slf7
rpm-8-nosign: build-el8
rpm-9-nosign: build-el9

#########################################################################
## .tar Files ###########################################################
#########################################################################

tar: $(FILES) $(FILES_LOCAL)
	@tar --exclude '.git' --exclude '*.tar*' --exclude '*.sw*' \
		--exclude '.gitignore' $(TAR_EXCLUDE) \
		-czpf $(PACKAGE)-$(VERS)-$(REL).tar.gz $(FILES_LOCAL)

tar7: tar
	@if [[ "$(REL)" != "$(REL7)" ]]; then \
	    cp $(PACKAGE)-$(VERS)-$(REL).tar.gz $(PACKAGE)-$(VERS)-$(REL7).tar.gz ; \
	fi

tar8: tar
	@if [[ "$(REL)" != "$(REL8)" ]]; then \
	    cp $(PACKAGE)-$(VERS)-$(REL).tar.gz $(PACKAGE)-$(VERS)-$(REL8).tar.gz ; \
	fi

tar9: tar
	@if [[ "$(REL)" != "$(REL9)" ]]; then \
	    cp $(PACKAGE)-$(VERS)-$(REL).tar.gz $(PACKAGE)-$(VERS)-$(REL9).tar.gz ; \
	fi

#########################################################################
### SRPMs ###############################################################
#########################################################################

srpm7: tar7
	@echo "Creating SLF7 SRPM..."
	@mock -r slf7-x86_64 -D 'dist .el7' \
		--spec=$(PWD)/$(SPEC_FILE) --sources=$(PWD) \
		--resultdir=$(RPMDIR)/SRPMS \
		--buildsrpm

srpm8: tar8
	@echo "Creating CentOS 8 SRPM..."
	@mock -r centos8-x86_64 -D 'dist .el8' \
		--spec=$(PWD)/$(SPEC_FILE) --sources=$(PWD) \
		--resultdir=$(RPMDIR)/SRPMS \
		--buildsrpm

srpm9: tar9
	@echo "Creating EL9 SRPM..."
	@mock -r centos-stream-9-x86_64 -D 'dist .el9' \
		--spec=$(PWD)/$(SPEC_FILE) --sources=$(PWD) \
		--resultdir=$(RPMDIR)/SRPMS \
		--buildsrpm

#########################################################################
### Per-Architecture Builds #############################################
#########################################################################

build-slf7: build-slf7-x86_64 build-slf7-noarch
build-slf7-noarch: build-slf7-noarch-local
build-slf7-x86_64: build-slf7-x86_64-local

build-el8: build-el8-x86_64 build-el8-noarch
build-el8-noarch: srpm8 build-el8-noarch-local
build-el8-x86_64: srpm8 build-el8-x86_64-local

build-el9: build-el9-x86_64 build-el9-noarch
build-el9-noarch: srpm9 build-el9-noarch-local
build-el9-x86_64: srpm9 build-el9-x86_64-local

build-nomock: tar
	rpmbuild -ba *spec

build-mock-verbose-slf7: srpm7
	$(MOCK7) -D 'dist .el7' --arch noarch $(SRPM7) -v
	$(MOCK7) clean

build-mock-verbose-el8: srpm8
	$(MOCK8) -D 'dist .el8' --arch noarch $(SRPM8) -v
	$(MOCK8) clean

build-mock-verbose-el9: srpm9
	$(MOCK9) -D 'dist .el9' --arch noarch $(SRPM9) -v
	$(MOCK9) clean

build-slf7-x86_64-local: srpm7
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		$(MOCK7) -D 'dist .el7' --arch x86_64 $(SRPM7) ; \
		$(MOCK7) clean ; \
	fi

build-slf7-noarch-local: srpm7
	@if [[ $(ARCH) == 'noarch' ]]; then \
		$(MOCK7) -D 'dist .el7' --arch noarch $(SRPM7) ; \
		$(MOCK7) clean ; \
	fi

build-el8-x86_64-local:
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		$(MOCK8) --arch x86_64 $(SRPM8) ; \
	fi

build-el8-noarch-local:
	@if [[ $(ARCH) == 'noarch' ]]; then \
		$(MOCK8) --arch noarch $(SRPM8) ; \
	fi

build-el9-x86_64-local:
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		$(MOCK9) --arch x86_64 $(SRPM9) ; \
	fi

build-el9-noarch-local:
	@if [[ $(ARCH) == 'noarch' ]]; then \
		$(MOCK9) --arch noarch $(SRPM9) ; \
	fi

mock7-clean:
	$(MOCK7) clean

mock8-clean:
	$(MOCK8) clean

mock9-clean:
	$(MOCK9) clean

#########################################################################
### Per-Architecture Copying ############################################
#########################################################################

copy-slf7: copy-slf7-x86_64 copy-slf7-noarch
copy-el8: copy-el8-x86_64 copy-el8-noarch
copy-el9: copy-el9-x86_64 copy-el9-noarch

copy-slf7-x86_64: confirm-slf7-x86_64
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		for i in $(DEST_slf7_x86_64); do \
			echo "scp $(RPMDIR)/slf7-x86_64/$(RPM_BASE_7).x86_64.rpm $$i" ; \
			echo "Press enter to continue..."; \
			read ; \
			scp $(RPMDIR)/slf7-x86_64/$(RPM_BASE_7).x86_64.rpm $$i ; \
		done ; \
	fi

copy-slf7-noarch: confirm-slf7-noarch
	@if [[ $(ARCH) == 'noarch' ]]; then \
		for i in $(DEST_slf7_noarch); do \
			echo "scp $(RPMDIR)/slf7-x86_64/$(RPM_BASE_7).noarch.rpm $$i" ; \
			echo "Press enter to continue..."; \
			read ; \
			scp $(RPMDIR)/slf7-x86_64/$(RPM_BASE_7).noarch.rpm $$i ; \
		done ; \
	fi

copy-el8-x86_64: confirm-el8-x86_64
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		for i in $(DEST_el8_x86_64); do \
			echo "scp $(RPMDIR)/el8-x86_64/$(RPM_BASE_8).x86_64.rpm $$i" ; \
			echo "Press enter to continue..."; \
			read ; \
			scp $(RPMDIR)/el8-x86_64/$(RPM_BASE_8).x86_64.rpm $$i ; \
		done ; \
	fi

copy-el8-noarch: confirm-el8-noarch
	@if [[ $(ARCH) == 'noarch' ]]; then \
		for i in $(DEST_el8_noarch); do \
			echo "scp $(RPMDIR)/el8-x86_64/$(RPM_BASE_8).noarch.rpm $$i" ; \
			echo "Press enter to continue..."; \
			read ; \
			scp $(RPMDIR)/el8-x86_64/$(RPM_BASE_8).noarch.rpm $$i ; \
		done ; \
	fi

copy-el9-x86_64: confirm-el9-x86_64
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		for i in $(DEST_el9_x86_64); do \
			echo "scp $(RPMDIR)/el9-x86_64/$(RPM_BASE_9).x86_64.rpm $$i" ; \
			echo "Press enter to continue..."; \
			read ; \
			scp $(RPMDIR)/el9-x86_64/$(RPM_BASE_9).x86_64.rpm $$i ; \
		done ; \
	fi

copy-el9-noarch: confirm-el9-noarch
	@if [[ $(ARCH) == 'noarch' ]]; then \
		for i in $(DEST_el9_noarch); do \
			echo "scp $(RPMDIR)/el9-x86_64/$(RPM_BASE_9).noarch.rpm $$i" ; \
			echo "Press enter to continue..."; \
			read ; \
			scp $(RPMDIR)/el9-x86_64/$(RPM_BASE_9).noarch.rpm $$i ; \
		done ; \
	fi

#########################################################################
### Per-Architecture RPM Confirmation ###################################
#########################################################################

confirm-slf7: confirm-slf7-x86_64 confirm-slf7-noarch
confirm-el8: confirm-el8-x86_64 confirm-el8-noarch
confirm-el9: confirm-el9-x86_64 confirm-el9-noarch

confirm-slf7-x86_64:
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		echo "rpm -qpi $(RPMDIR)/slf7-x86_64/$(RPM_BASE_7).*86*rpm" ; \
		rpm -qpi $(RPMDIR)/slf7-x86_64/$(RPM_BASE_7).*86*rpm \
			2>&1 | egrep ^Signature | grep $(SIGN_KEY) ; \
	fi

confirm-slf7-noarch:
	@if [[ $(ARCH) == 'noarch' ]]; then \
		echo "rpm -qpi $(RPMDIR)/slf7-x86_64/$(RPM_BASE_7).noarch.rpm" ; \
		rpm -qpi $(RPMDIR)/slf7-x86_64/$(RPM_BASE_7).noarch.rpm \
			2>&1 | egrep ^Signature | grep $(SIGN_KEY) ; \
	fi

confirm-el8-x86_64:
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		echo "rpm -qpi $(RPMDIR)/el8-x86_64/$(RPM_BASE_8).*86*rpm" ; \
		rpm -qpi $(RPMDIR)/el8-x86_64/$(RPM_BASE_8).*86*rpm \
			2>&1 | egrep ^Signature | grep $(SIGN_KEY) ; \
	fi

confirm-el8-noarch:
	@if [[ $(ARCH) == 'noarch' ]]; then \
		echo "rpm -qpi $(RPMDIR)/el8-x86_64/$(RPM_BASE_8).noarch.rpm" ; \
		rpm -qpi $(RPMDIR)/el8-x86_64/$(RPM_BASE_8).noarch.rpm \
			2>&1 | egrep ^Signature | grep $(SIGN_KEY) ; \
	fi

confirm-el9-x86_64:
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		echo "rpm -qpi $(RPMDIR)/el9-x86_64/$(RPM_BASE_9).*86*rpm" ; \
		rpm -qpi $(RPMDIR)/el9-x86_64/$(RPM_BASE_9).*86*rpm \
			2>&1 | egrep ^Signature | grep $(SIGN_KEY) ; \
	fi

confirm-el9-noarch:
	@if [[ $(ARCH) == 'noarch' ]]; then \
		echo "rpm -qpi $(RPMDIR)/el9-x86_64/$(RPM_BASE_9).noarch.rpm" ; \
		rpm -qpi $(RPMDIR)/el9-x86_64/$(RPM_BASE_9).noarch.rpm \
			2>&1 | egrep ^Signature | grep $(SIGN_KEY) ; \
	fi

#########################################################################
### Per-Architecture RPM Signing ########################################
#########################################################################

sign-slf7: sign-slf7-x86_64 sign-slf7-noarch
sign-el8: sign-el8-x86_64 sign-el8-noarch
sign-el9: sign-el9-x86_64 sign-el9-noarch

sign-slf7-x86_64:
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		echo "rpm --resign $(RPMDIR)/slf7-x86_64/$(RPM_BASE_7).*86*rpm" ; \
		rpm --resign $(RPMDIR)/slf7-x86_64/$(RPM_BASE_7).*86*rpm \
			2>&1 | grep -v "input reopened" ; \
	fi

sign-slf7-noarch:
	@if [[ $(ARCH) == 'noarch' ]]; then \
		echo "rpm --resign $(RPMDIR)/slf7-x86_64/$(RPM_BASE_7).noarch.rpm" ; \
		rpm --resign $(RPMDIR)/slf7-x86_64/$(RPM_BASE_7).noarch.rpm \
			2>&1 | grep -v "input reopened" ; \
	fi

sign-el8-x86_64:
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		echo "rpm --resign $(RPMDIR)/el8-x86_64/$(RPM_BASE_8).*86*rpm" ; \
		rpm --resign $(RPMDIR)/el8-x86_64/$(RPM_BASE_8).*86*rpm \
			2>&1 | grep -v "input reopened" ; \
	fi

sign-el8-noarch:
	@if [[ $(ARCH) == 'noarch' ]]; then \
		echo "rpm --resign $(RPMDIR)/el8-x86_64/$(RPM_BASE_8).noarch.rpm" ; \
		rpm --resign $(RPMDIR)/el8-x86_64/$(RPM_BASE_8).noarch.rpm \
			2>&1 | grep -v "input reopened" ; \
	fi

sign-el9-x86_64:
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		echo "rpm --resign $(RPMDIR)/el9-x86_64/$(RPM_BASE_9).*86*rpm" ; \
		rpm --resign $(RPMDIR)/el9-x86_64/$(RPM_BASE_9).*86*rpm \
			2>&1 | grep -v "input reopened" ; \
	fi

sign-el9-noarch:
	@if [[ $(ARCH) == 'noarch' ]]; then \
		echo "rpm --resign $(RPMDIR)/el9-x86_64/$(RPM_BASE_9).noarch.rpm" ; \
		rpm --resign $(RPMDIR)/el9-x86_64/$(RPM_BASE_9).noarch.rpm \
			2>&1 | grep -v "input reopened" ; \
	fi

#########################################################################
### rpmlint #############################################################
#########################################################################
## Verify that the RPMs match the standard 'rpmlint' checks.  rpmlintrc
## is a file with local rpmlint exemptions.

lint:
	find $(RPMDIR) -name "$(NAME)-$(VERS)-$(RELx).*.rpm" \
		! -name '*src.rpm*' | xargs rpmlint -f rpmlintrc

# Add warnings to the lint output
linti:
	find $(RPMDIR) -name "$(NAME)-$(VERS)-$(RELx).*.rpm" \
		! -name '*src.rpm*' | xargs rpmlint -i -f rpmlintrc

#########################################################################
### Deploy ##############################################################
#########################################################################
## Run the Makefile on the upstream host to deploy the RPMs into the main 
## yum repository.

deploy-7:
	$(DEPLOY_MAKE) 7

deploy-8:
	$(DEPLOY_MAKE) 8

deploy-9:
	$(DEPLOY_MAKE) 9
