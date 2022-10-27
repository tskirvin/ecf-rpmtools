Name:           ecf-rpmtools
Group:          System Environment/Libraries
Version:        1.0.7
Release:        0%{?dist}
Summary:        ECF RPM Tools
URL:            https://github.com/tskirvin/ecf-rpmtools

License:        Fermitools Software Legal Information (Modified BSD License)
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch

Requires:       openssl

Source:         ecf-rpmtools-%{version}-%{release}.tar.gz

%description
Installs a Makefile, rpmmacros file, and a wrapper script that are used to 
standardize building RPMs for the ECF-SSI group at Fermilab.

%prep
%setup -c -n ecf-rpmtools -q

%build
# Empty build section added per rpmlint

%install
rm -rf $RPM_BUILD_ROOT

# install the directories
install -d $RPM_BUILD_ROOT%{_bindir}
install -d $RPM_BUILD_ROOT%{_libexecdir}
install -d $RPM_BUILD_ROOT%{_libexecdir}/ecf-rpmtools

# install the wrapper script in /usr/bin
install -m 0755 make-rpm $RPM_BUILD_ROOT%{_bindir}

# install the Makefile and rpmmacros in /usr/libexec/ecf-rpmtools
install -m 0644 Makefile $RPM_BUILD_ROOT%{_libexecdir}/ecf-rpmtools
install -m 0644 rpmmacros $RPM_BUILD_ROOT%{_libexecdir}/ecf-rpmtools
install -m 0644 rpmmacros.gpg-agent $RPM_BUILD_ROOT%{_libexecdir}/ecf-rpmtools

%clean
# Adding empty clean section per rpmlint.  In this particular case, there is 
# nothing to clean up as there is no build process

%files
%attr(-, root, root) %{_bindir}/make-rpm
%attr(-, root, root) %{_libexecdir}/ecf-rpmtools/Makefile
%attr(-, root, root) %{_libexecdir}/ecf-rpmtools/rpmmacros
%attr(-, root, root) %{_libexecdir}/ecf-rpmtools/rpmmacros.gpg-agent

%changelog
* Thu Oct 27 2022  Tim Skirvin <tskirvin@fnal.gov>      1.0.7-0
- renaming cs9->el9, and centos8->el8

* Fri Apr 22 2022  Tim Skirvin <tskirvin@fnal.gov>      1.0.6-0
- CS9 support bug fixes (just small tweaks)

* Fri Feb 11 2022  Tim Skirvin <tskirvin@fnal.gov>      1.0.5-0
- CentOS Stream 9 Support (and presumably RHEL9)

* Thu Dec 17 2020  Tim Skirvin <tskirvin@fnal.gov>      1.0.4-1
- dropping SLF6 + SLF6 support for real this time

* Mon Nov 16 2020  Tim Skirvin <tskirvin@fnal.gov>      1.0.4-0
- Makefile - added per-package rpmlintrc support
- created an rpmlintrc file for ourselves
- dropping SLF6 support

* Tue Dec  3 2019  Tim Skirvin <tskirvin@fnal.gov>      1.0.3-0
- adding CentOS 8 support

* Fri Feb  5 2016  Tim Skirvin <tskirvin@fnal.gov>      1.0.2-0
- SLF5 no longer requires that RPMs be signed before confirming
- SLF5 tries to sign RPMs with '--force-v3-sigs' (not that it works)

* Wed Nov 25 2015  Tim Skirvin <tskirvin@fnal.gov>      1.0.1-1
- Makefile.local touch-ups

* Wed Nov 25 2015  Tim Skirvin <tskirvin@fnal.gov>      1.0.1-0
- tuning the Makefile to be a little bit quieter
- the 'tar5', 'tar6', and 'tar7' targets work
- general bug fixes around slf7 and slf5 targets

* Wed Nov 25 2015  Tim Skirvin <tskirvin@fnal.gov>      1.0.0-1
- initial version, forked from cms-rpmtools
