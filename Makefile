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
NAME = $(shell pwd | tr '/' '\n' | tail -1)

## Build Architecture, Name, Package, etc
ARCH    := $(shell egrep "^BuildArch" *.spec | cut -d':' -f2 | tr -d ' ')
PACKAGE := $(shell egrep '^Name' *spec | cut -d':' -f2 | tr -d ' ')

## A quoted release for use in SRPM
RHL = $(shell rpm -qf /etc/redhat-release | cut -d '-' -f 3 | cut -d. -f1)

## What is the name of our default work directory?
RPMDIR = $(HOME)/rpmbuild

## Package version and release strings
REL  :=  $(shell egrep ^Release *.spec | cut -d':' -f2 | tr -d ' ' | sed s/\%\{\?dist\}/.el${RHL}/)
REL5 :=  $(shell egrep ^Release *.spec | cut -d':' -f2 | tr -d ' ' | sed s/\%\{\?dist\}/.el5/)
REL6 :=  $(shell egrep ^Release *.spec | cut -d':' -f2 | tr -d ' ' | sed s/\%\{\?dist\}/.el6/)
REL7 :=  $(shell egrep ^Release *.spec | cut -d':' -f2 | tr -d ' ' | sed s/\%\{\?dist\}/.el7/)
RELx :=  $(shell egrep ^Release *.spec | cut -d':' -f2 | tr -d ' ' | sed s/\%\{\?dist\}//)
VERS :=  $(shell egrep ^Version *.spec | cut -d':' -f2 | tr -d ' ')

# The location of the SRPMs
SRPM :=  $(shell echo "${RPMDIR}/SRPMS/$(NAME)-$(VERS)-$(REL).src.rpm")
SRPM5 :=  $(shell echo "${RPMDIR}/SRPMS/$(NAME)-$(VERS)-$(REL5).src.rpm")
SRPM6 :=  $(shell echo "${RPMDIR}/SRPMS/$(NAME)-$(VERS)-$(REL6).src.rpm")
SRPM7 :=  $(shell echo "${RPMDIR}/SRPMS/$(NAME)-$(VERS)-$(REL7).src.rpm")

## The final name of the RPM that's being generated
RPM_BASE = $(NAME)-$(VERS)-$(REL)
RPM_BASE_5 = $(NAME)-$(VERS)-$(REL5)
RPM_BASE_6 = $(NAME)-$(VERS)-$(REL6)
RPM_BASE_7 = $(NAME)-$(VERS)-$(REL7)
RPM      = $(RPM_BASE).$(ARCH).rpm

## What is our signing key ID?
SIGN_KEY = 47ae212ea9934bb1

SPEC_FILE := $(shell echo *.spec)

## Where do our RPMs go when we're done?
DEST = root@rexadmin1.fnal.gov:/var/www/html/yum-managed/RPMS
DEST_slf5_noarch = $(DEST)/noarch/5.x
DEST_slf5_x86_64 = $(DEST)/x86_64/5.x
DEST_slf6_noarch = $(DEST)/noarch/6.x
DEST_slf6_x86_64 = $(DEST)/x86_64/6.x
DEST_slf7_noarch = $(DEST)/noarch/7.x
DEST_slf7_x86_64 = $(DEST)/x86_64/7.x

DEPLOY_MAKE = ssh root@rexadmin1 make -f /var/www/html/yum-managed/Makefile

## What files to track?  Will decide whether we need to re-build the .tar
FILES =  Makefile.local $(PACKAGE).spec

## Include local configuration
-include Makefile.local

MOCK5 := mock -r slf5-x86_64 --uniqueext=$(USER) --resultdir $(RPMDIR)/slf5-x86_64
MOCK6 := mock -r slf6-x86_64 --uniqueext=$(USER) --resultdir $(RPMDIR)/slf6-x86_64
MOCK7 := mock -r slf7-x86_64 --uniqueext=$(USER) --resultdir $(RPMDIR)/slf7-x86_64

#########################################################################
### main () #############################################################
#########################################################################

rpm:          rpm-6-nosign rpm-7-nosign rpm-sign
rpm-nosign:   rpm-6-nosign rpm-7-nosign

rpm-5-nosign: build-slf5 
rpm-6-nosign: build-slf6
rpm-7-nosign: build-slf7

#########################################################################
## .tar Files ###########################################################
#########################################################################

tar: $(FILES) $(FILES_LOCAL)
	tar --exclude '.git' --exclude '*.tar*' --exclude '*.sw*' \
		--exclude '.gitignore' $(TAR_EXCLUDE) \
		-czpf $(PACKAGE)-$(VERS)-$(REL).tar.gz $(FILES_LOCAL)

tar5: tar
    if [[ "$(REL)" != "$(REL5)" ]]; then \
	    cp $(PACKAGE)-$(VERS)-$(REL).tar.gz $(PACKAGE)-$(VERS)-$(REL5).tar.gz \
    fi

tar6: tar
    if [[ "$(REL)" != "$(REL6)" ]]; then \
	    cp $(PACKAGE)-$(VERS)-$(REL).tar.gz $(PACKAGE)-$(VERS)-$(REL6).tar.gz \
    fi

tar7: tar
    if [[ "$(REL)" != "$(REL7)" ]]; then \
	    cp $(PACKAGE)-$(VERS)-$(REL).tar.gz $(PACKAGE)-$(VERS)-$(REL7).tar.gz \
    fi

#########################################################################
### SRPMs ###############################################################
#########################################################################

srpm5: tar5
	@echo "Creating SLF5 SRPM..."
	mock -r slf5-x86_64 -D 'dist .el5' \
		--spec=$(PWD)/$(SPEC_FILE) --sources=$(PWD) \
		--resultdir=$(RPMDIR)/SRPMS \
		--buildsrpm

srpm6: tar6
	@echo "Creating SLF6 SRPM..."
	mock -r slf6-x86_64 -D 'dist .el6' \
		--spec=$(PWD)/$(SPEC_FILE) --sources=$(PWD) \
		--resultdir=$(RPMDIR)/SRPMS \
		--buildsrpm

srpm7: tar7
	@echo "Creating SLF7 SRPM..."
	mock -r slf7-x86_64 -D 'dist .el7' \
		--spec=$(PWD)/$(SPEC_FILE) --sources=$(PWD) \
		--resultdir=$(RPMDIR)/SRPMS \
		--buildsrpm

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

build-mock-verbose-slf5: srpm5
	$(MOCK5) -D 'dist .el5' --arch noarch $(SRPM5) -v
	$(MOCK5) clean

build-mock-verbose-slf6: srpm6
	$(MOCK6) -D 'dist .el6' --arch noarch $(SRPM6) -v
	$(MOCK6) clean

build-mock-verbose-slf7: srpm7
	$(MOCK7) -D 'dist .el7' --arch noarch $(SRPM7) -v
	$(MOCK7) clean

build-slf5-x86_64-local: srpm5
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		$(MOCK5) -D 'dist .el5' --arch x86_64 $(SRPM5) ; \
		$(MOCK5) clean ; \
	fi

build-slf5-noarch-local: srpm5
	@if [[ $(ARCH) == 'noarch' ]]; then \
		$(MOCK5) -D 'dist .el5' --arch noarch $(SRPM5) ; \
		$(MOCK5) clean ; \
	fi

build-slf6-x86_64-local: srpm6
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		$(MOCK6) -D 'dist .el6' --arch x86_64 $(SRPM6) ; \
		$(MOCK6) clean ; \
	fi

build-slf6-noarch-local: srpm6
	@if [[ $(ARCH) == 'noarch' ]]; then \
		$(MOCK6) -D 'dist .el6' --arch noarch $(SRPM6) ; \
		$(MOCK6) clean ; \
	fi

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

#########################################################################
### Per-Architecture Copying ############################################
#########################################################################

copy-slf5: copy-slf5-x86_64 copy-slf5-noarch
copy-slf6: copy-slf6-x86_64 copy-slf6-noarch
copy-slf7: copy-slf6-x86_64 copy-slf6-noarch

copy-slf5-x86_64: confirm-slf5-x86_64
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		for i in $(DEST_slf5_x86_64); do \
			echo "scp $(RPMDIR)/slf5-x86_64/$(RPM_BASE_5).x86_64.rpm $$i" ; \
			echo "Press enter to continue..."; \
			read ; \
			scp $(RPMDIR)/slf5-x86_64/$(RPM_BASE_5).x86_64.rpm $$i ; \
		done ; \
	fi

copy-slf5-noarch: confirm-slf5-noarch
	@if [[ $(ARCH) == 'noarch' ]]; then \
		for i in $(DEST_slf5_noarch); do \
			echo "scp $(RPMDIR)/slf5-x86_64/$(RPM_BASE_5).noarch.rpm $$i" ; \
			echo "Press enter to continue..."; \
			read ; \
			scp $(RPMDIR)/slf5-x86_64/$(RPM_BASE_5).noarch.rpm $$i ; \
		done ; \
	fi

copy-slf6-x86_64: confirm-slf6-x86_64
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		for i in $(DEST_slf6_x86_64); do \
			echo "scp $(RPMDIR)/slf6-x86_64/$(RPM_BASE_6).x86_64.rpm $$i" ; \
			echo "Press enter to continue..."; \
			read ; \
			scp $(RPMDIR)/slf6-x86_64/$(RPM_BASE_6).x86_64.rpm $$i ; \
		done ; \
	fi


copy-slf6-noarch: confirm-slf6-noarch
	@if [[ $(ARCH) == 'noarch' ]]; then \
		for i in $(DEST_slf6_noarch); do \
			echo "scp $(RPMDIR)/slf6-x86_64/$(RPM_BASE_6).noarch.rpm $$i" ; \
			echo "Press enter to continue..."; \
			read ; \
			scp $(RPMDIR)/slf6-x86_64/$(RPM_BASE_6).noarch.rpm $$i ; \
		done ; \
	fi

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

#########################################################################
### Per-Architecture RPM Confirmation ###################################
#########################################################################

confirm-slf5: confirm-slf5-x86_64 confirm-slf5-noarch
confirm-slf6: confirm-slf6-x86_64 confirm-slf6-noarch
confirm-slf7: confirm-slf7-x86_64 confirm-slf7-noarch

confirm-slf5-x86_64:
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		echo "rpm -qpi $(RPMDIR)/slf5-x86_64/$(RPM_BASE_5).*86*rpm" ; \
		rpm -qpi $(RPMDIR)/slf-5-x86_64/$(RPM_BASE_5).*86*rpm \
			2>&1 | egrep ^Signature | grep $(SIGN_KEY) ; \
	fi

confirm-slf5-noarch:
	@if [[ $(ARCH) == 'noarch' ]]; then \
		echo "rpm -qpi $(RPMDIR)/slf5-x86_64/$(RPM_BASE_5).noarch.rpm" ; \
		rpm -qpi $(RPMDIR)/slf-5-x86_64/$(RPM_BASE_5).noarch.rpm \
			2>&1 | egrep ^Signature | grep $(SIGN_KEY) ; \
	fi

confirm-slf6-x86_64:
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		echo "rpm -qpi $(RPMDIR)/slf6-x86_64/$(RPM_BASE_6).*86*rpm" ; \
		rpm -qpi $(RPMDIR)/slf6-x86_64/$(RPM_BASE_6).*86*rpm \
			2>&1 | egrep ^Signature | grep $(SIGN_KEY) ; \
	fi

confirm-slf6-noarch:
	@if [[ $(ARCH) == 'noarch' ]]; then \
		echo "rpm -qpi $(RPMDIR)/slf6-x86_64/$(RPM_BASE_6).noarch.rpm" ; \
		rpm -qpi $(RPMDIR)/slf6-x86_64/$(RPM_BASE_6).noarch.rpm \
			2>&1 | egrep ^Signature | grep $(SIGN_KEY) ; \
	fi

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

#########################################################################
### Per-Architecture RPM Signing ########################################
#########################################################################

sign-slf5: sign-slf5-x86_64 sign-slf5-noarch
sign-slf6: sign-slf6-x86_64 sign-slf6-noarch
sign-slf7: sign-slf7-x86_64 sign-slf7-noarch

sign-slf5-x86_64:
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		echo "rpm --resign $(RPMDIR)/slf-5-x86_64/$(RPM_BASE_5).*86*rpm" ; \
		rpm --resign $(RPMDIR)/slf-5-x86_64/$(RPM_BASE_5).*86*rpm \
			2>&1 | grep -v "input reopened" ; \
	fi

sign-slf5-noarch:
	@if [[ $(ARCH) == 'noarch' ]]; then \
		echo "rpm --resign $(RPMDIR)/slf-5-x86_64/$(RPM_BASE_5).noarch.rpm" ; \
		rpm --resign $(RPMDIR)/slf-5-x86_64/$(RPM_BASE_5).noarch.rpm \
			2>&1 | grep -v "input reopened" ; \
	fi

sign-slf6-x86_64:
	@if [[ $(ARCH) == 'x86_64' ]]; then \
		echo "rpm --resign $(RPMDIR)/slf6-x86_64/$(RPM_BASE_6).*86*rpm" ; \
		rpm --resign $(RPMDIR)/slf6-x86_64/$(RPM_BASE_6).*86*rpm \
			2>&1 | grep -v "input reopened" ; \
	fi

sign-slf6-noarch:
	@if [[ $(ARCH) == 'noarch' ]]; then \
		echo "rpm --resign $(RPMDIR)/slf6-x86_64/$(RPM_BASE_6).noarch.rpm" ; \
		rpm --resign $(RPMDIR)/slf6-x86_64/$(RPM_BASE_6).noarch.rpm \
			2>&1 | grep -v "input reopened" ; \
	fi

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

#########################################################################
### rpmlint #############################################################
#########################################################################
## Verify that the RPMs match the standard 'rpmlint' checks.

lint:
	find $(RPMDIR) -name "$(NAME)-$(VERS)-$(RELx).*.rpm" \
		! -name '*src.rpm*' | xargs rpmlint

# Add warnings to the lint output
linti:
	find $(RPMDIR) -name "$(NAME)-$(VERS)-$(RELx).*.rpm" \
		! -name '*src.rpm*' | xargs rpmlint -i

#########################################################################
### Deploy ##############################################################
#########################################################################
## Run the Makefile on the 

deploy-5:
	$(DEPLOY_MAKE) 5

deploy-6:
	$(DEPLOY_MAKE) 6

deploy-7:
	$(DEPLOY_MAKE) 7
