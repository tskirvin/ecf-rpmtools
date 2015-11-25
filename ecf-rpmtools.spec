Name:           ecf-rpmtools
Group:          System Environment/Libraries
Version:        1.0.0
Release:        0
Summary:        ECF RPM Tools
URL:            https://ecf-git.fnal.gov/ecf-rpmtools

License:        Fermitools Software Legal Information (Modified BSD License)
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch

Requires:       openssl

Provides:       ecf-rpmtools = %{version}-%{release}

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
install -m 0500 make-rpm $RPM_BUILD_ROOT%{_bindir}

# install the Makefile and rpmmacros in /usr/libexec/ecf-rpmtools
install -m 0500 Makefile $RPM_BUILD_ROOT%{_libexecdir}/ecf-rpmtools
install -m 0500 rpmmacros $RPM_BUILD_ROOT%{_libexecdir}/ecf-rpmtools

%clean
# Adding empty clean section per rpmlint.  In this particular case, there is 
# nothing to clean up as there is no build process

%files
%attr(-, root, root) %{_bindir}/make-rpm
%attr(-, root, root) %{_libexecdir}/ecf-rpmtools/Makefile
%attr(-, root, root) %{_libexecdir}/ecf-rpmtools/rpmmacros

%changelog
* Tue Nov 24 2015  Tim Skirvin <tskirvin@fnal.gov>      1.0.0
- initial version, forked from cms-rpmtools