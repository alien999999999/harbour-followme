Name:		harbour-followme
Version:	0.1
Release:	1
Summary:	Follow manga and/or comics
License:	GPLv2+
Group:		Qt/Qt
URL:		https://github.com/alien999999999/harbour-followme
Source0:	%name-%version.tar.bz2

%description

FollowMe is an app that allows to follow and read various manga and comics
from several sources. The app keeps record of what you have read and can
download them in the background.

%prep
%setup -q -n %{name}-%{version}

%build

%install
rm -rf %{buildroot}

pushd %{name}-%{version} >/dev/null
mkdir -p %{buildroot}%{_datadir}/icons/hicolor/86x86/apps %{buildroot}%{_datadir}/applications %{buildroot}%{_datadir}/%{name}
install %{name}.png %{buildroot}%{_datadir}/icons/hicolor/86x86/apps
install -D qml python %{name}.svg %{buildroot}%{_datadir}/%{name}
popd >/dev/null

desktop-file-install --delete-original --dir %{buildroot}%{_datadir}/applications %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_datadir}/icons/hicolor/86x86/apps/%{name}.png
%{_datadir}/applications/%{name}.desktop
%{_datadir}/%{name}
