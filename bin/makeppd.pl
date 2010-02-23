#!/usr/bin/perl -w
# $HeadURL: http://subversion.bmsg.nl/repos/kpn/trunk/src/perl-modules/PackageTools/bin/makeppd.pl $
# $Id: makeppd.pl 3815 2010-02-23 11:08:23Z hospelt $

# Author: Ton Hospel
# Create a ppm

use strict;
use Config;
use IO::Handle;
use File::Temp qw(tempdir);
use File::Copy qw(move);
use File::Path qw(rmtree);
use File::Spec;
use Cwd;
use Errno qw(ENOENT ESTALE);
use Getopt::Long 2.11;
use ExtUtils::MM_Unix qw();

our $VERSION = "1.014";

use constant MIN_VERSION => "1.011";
my $zip = "zip";
my $tar = "tar";
my $compress = "gzip --best";

# http://gnuwin32.sourceforge.net/packages/bsdtar.htm
my $bsd_tar	= 'C:/Program Files/GnuWin32/bin/bsdtar';
# http://gnuwin32.sourceforge.net/packages/zip.htm
my $gnuwin_zip	= 'C:/Program Files/GnuWin32/bin/zip';

&Getopt::Long::config("bundling", "require_order");
my @OLD_ARGV = @ARGV;
die "Could not parse your command line (@ARGV) . Try $0 -h\n" unless
    GetOptions("zip=s"		=> \$zip,
               "tar=s"		=> \$tar,
               "perl=s"		=> \my $perl,
               "compress=s"	=> \$compress,
               "leave=s"	=> \my $leave,
               "dependency|prerequisite=f"	=> \my %prereq,
               "reinvoke"	=> \my $reinvoked,
               "min_version=s"	=> \my $min_version,
               "map=s"		=> \my %package_map,
               "objects:s"	=> \my $objects,
               "version!"	=> \my $version,
               "U|unsafe!"	=> \my $unsafe,
               "h|help!"	=> \my $help);

if ($perl && !$reinvoked) {
    # Reinvoke protects against endless recursive calls
    no warnings "once";
    require FindBin;
    my $program = File::Spec->catfile($FindBin::Bin, $FindBin::Script);
    if ($^O eq "MSWin32") {
        $_ = qq("$_") for $program, @OLD_ARGV;
    }
    my $rc = system($perl, $program, "--reinvoke", @OLD_ARGV);
    die "Could not re-exec as $perl $program --reinvoke @OLD_ARGV: $!" if $rc < 0;
    die "Signal $rc failure on re-exec of re-exec as $perl $program --reinvoke @OLD_ARGV" if $rc & 0xff;
    exit $rc >> 8;
}

if ($version) {
    require PackageTools::Package;
    print<<"EOF";
makeppd.pl $VERSION (PackageTools $PackageTools::Package::VERSION)
EOF
    exit 0;
}
if ($help) {
    $ENV{PATH} .= ":" unless $ENV{PATH} eq "";
    $ENV{PATH} = "$ENV{PATH}$Config{installscript}";
    exec("perldoc", "-F", $unsafe ? "-U" : (), $0) || exit 1;
}
die "This is $0 version $VERSION, but the caller wants at least version $min_version\n" if $min_version && $VERSION < $min_version;

sub executable {
    my ($name) = @_;
    return -x $name ? $name : undef if
        File::Spec->file_name_is_absolute($name);
    my ($volume,$directories,$file) = File::Spec->splitpath($name);
    return -x $name ? $name : undef if $volume ne "" || $directories ne "";
    for my $dir (File::Spec->path()) {
        my $try = File::Spec->catfile($dir, $tar);
        return -x $try ? $try : undef if -e $try;
    }
    return undef;
}

sub provides {
    my $provides = "";
    my @dirs = "blib/lib";
    while (defined(my $dir = shift @dirs)) {
        opendir(my $dh, $dir) || die "Could not opendir '$dir': $!";
        my @files = sort readdir($dh);
        closedir($dh) || die "Could not closedir '$dir': $!";
        for my $f (@files) {
            next if $f eq "." || $f eq "..";
            my $file = "$dir/$f";
            my @stat = lstat($file) or die "Could not lstat $file: $!";
            if (-d _) {
                unshift @dirs, $file;
            } elsif (-f _) {
                next unless $f =~ /\.pm\z/i;
                my $v = ExtUtils::MM_Unix->parse_version($file);
                if (defined $v) {
                    $file =~ s!^blib/lib/!! ||
                        die "Assertion: File '$file' does not start with blib/lib/";
                    $file =~ s!\.pm\z!!i ||
                        die "Assertion: File '$file' does not end on .pm";
                    $file =~ s!/!::!g;
                    $provides .= qq(        <PROVIDE NAME="$file" VERSION="$v" />\n);
                }
            } else {
                die "Unhandled filetype for '$file'";
            }
        }
    }
    return $provides;
}

# Determine a good tar
$tar = $bsd_tar unless executable($tar);
# print STDERR "tar=$tar\n";
$zip = $gnuwin_zip unless executable($zip);
# print STDERR "zip=$zip\n";

my $ppd = shift || die "No ppd argument";

my $provides = provides();

open(my $pfh, "<", $ppd) || do {
    die "$ppd does not exist yet.\n" if $! == ENOENT || $! == ESTALE;
    die "Could not open '$ppd': $!";
};
my $pkg = do { local $/; <$pfh> };
close($pfh) || die "Error closing $ppd: $!";

my ($pkg_name, $v) = $pkg =~ /\A\s*<SOFTPKG\s+NAME="([^\"]+)" VERSION="([^\"]+)"(?:\s+DATE="([^\"]+)")?>\s*$/m or
    die "Could not parse package header from $ppd";
my $ppm_version = 4;
if ($v =~ /^\d+,\d+,\d+,\d+\z/) {
    $ppm_version = 3;
    $v =~ tr/,/./;
    $v =~ s/(?:.0){1,2}\z//;
}
my ($major, $minor) = $v =~ /^(\d+)\.(\d+)\z/  or
    die "Could not parse version '$v'";
if (@ARGV) {
    my $version = shift;
    $version eq "$major.$minor" || die "Package is at version $version, but the ppd is at version $major.$minor\n";
}
my ($arch) = $pkg =~
    m{^[^\S\n]*<ARCHITECTURE\s+NAME="([^\"]+)"\s*/>[^\S\n]*$}m or
    die "Could not parse architecture from $ppd";

if ($objects) {
    # Fixup for a perl 5.10 bug where
    # ARCHITECTURE NAME is MSWin32-x86-multi-thread-5.1
    my $wrong_version = substr($Config{version},0,3);
    if ($arch =~ s/-\Q$wrong_version\E\z//) {
        my ($major, $minor, $sub) =
            $Config{version} =~ /^(\d+)\.(\d+)\.(\d+)\z/ or
            die "Could not parse perl version '$Config{version}'";
        $arch = "$arch-$major.$minor";
        $pkg =~ s{^([^\S\n]*<ARCHITECTURE\s+NAME=")[^\"]+("\s*/>[^\S\n]*)$}{$1$arch$2}m || die "Could not fixup ARCHITECTURE NAME";
        print STDERR "Fixing ARCHITECTURE NAME to $arch\n";
    }
} else {
    $pkg =~ s{^[^\S\n]*<ARCHITECTURE\s+NAME="[^\"]+"\s*/>[^\S\n]*\n}{}m ||
        die "Could not remove ARCHITECTURE NAME";
    $pkg =~ s{^[^\S\n]*<OS\s+NAME="[^\"]+"\s*/>[^\S\n]*\n}{}m;
    $arch = "Any";
}

my $dist = "$pkg_name-$major.$minor.tar.gz";
my $code_base = "$arch/$dist";
$pkg =~ s{^(\s*<CODEBASE\s+HREF=")[^\"]*("\s*/>\s*\n)}{$1$code_base$2}m or
    die "Could not substitute codebase";
if (%prereq) {
    my $prereq = "";
    for my $pre_name (sort keys %prereq) {
        my $ver = $prereq{$pre_name};
        if ($ppm_version == 3) {
            $ver =~ s/\./,/g;
            $ver .= ",0" x (4 - $ver =~ tr/,//);
            $prereq .=
                qq(        <DEPENDENCY NAME="$pre_name" VERSION="$ver" />\n);
        } else {
            # Version 4
            $prereq .=
                qq(        <REQUIRE NAME="$pre_name" VERSION="$ver" />\n);
        }
    }
    $pkg =~ s{^([^\S\n]*<IMPLEMENTATION>[^\S\n]*\n)}{$1$prereq}gm ||
        die "Assertion: No IMPLEMENTATION";
}
$pkg =~ s{^([^\S\n]*<IMPLEMENTATION>[^\S\n]*\n)}{$1$provides}gm ||
    die "Assertion: No IMPLEMENTATION";

$_ = [$_, "0"] for values %package_map;

# Map from module name to package name and
# the first version of this program that had the mapping
# Name undef means the dependency is dropped
my %replace_package =
    (
     # Activestate builtins
     "Time::HiRes"		=> [undef, "1.011"],
     "Net::SMTP"		=> [undef, "1.011"],
     "MIME::Base64"		=> [undef, "1.011"],
     "Storable"			=> [undef, "1.013"],
     # Test::More is normally only for testing
     "Test::More"		=> [undef, "1.011"],
     "Win32"			=> [undef, "1.011"],
     "Win32::ChangeNotify"	=> [undef, "1.013"],
     "Win32::Clipboard"		=> [undef, "1.013"],
     "Win32::Console"		=> [undef, "1.013"],
     "Win32::Event"		=> [undef, "1.013"],
     "Win32::EventLog"		=> [undef, "1.013"],
     "Win32::File"		=> [undef, "1.013"],
     "Win32::FileSecurity"	=> [undef, "1.013"],
     "Win32::IPC"		=> [undef, "1.013"],
     "Win32::Internet"		=> [undef, "1.013"],
     "Win32::Job"		=> [undef, "1.013"],
     "Win32::Mutex"		=> [undef, "1.013"],
     "Win32::NetAdmin"		=> [undef, "1.013"],
     "Win32::NetResource"	=> [undef, "1.013"],
     "Win32::ODBC"		=> [undef, "1.013"],
     "Win32::OLE"		=> [undef, "1.013"],
     "Win32::OLE::Const"	=> [undef, "1.013"],
     "Win32::OLE::Enum"		=> [undef, "1.013"],
     "Win32::OLE::NLS"		=> [undef, "1.013"],
     "Win32::OLE::TypeInfo"	=> [undef, "1.013"],
     "Win32::OLE::Variant"	=> [undef, "1.013"],
     "Win32::PerfLib"		=> [undef, "1.013"],
     "Win32::Pipe"		=> [undef, "1.013"],
     "Win32::Process"		=> [undef, "1.013"],
     "Win32::Registry"		=> [undef, "1.013"],
     "Win32::Semaphore"		=> [undef, "1.013"],
     "Win32::Service"		=> [undef, "1.013"],
     "Win32::Shortcut"		=> [undef, "1.013"],
     "Win32::Sound"		=> [undef, "1.013"],
     "Win32::TieRegistry"	=> [undef, "1.013"],
     "Win32::WinError"		=> [undef, "1.013"],
     "Win32API::File"		=> [undef, "1.012"],
     "Win32API::Net"		=> [undef, "1.013"],
     "Win32API::Registry"	=> [undef, "1.013"],
     # Some info about CPAN modules
     "Date::Calendar"		=> ["Date::Calc", "1.011"],
     "Date::Calendar::Profiles"	=> ["Date::Calc", "1.011"],
     # Some of our own modules
     "Email::SMTP::Utils"	=> ["Email::SMTP", "1.013"],
     "Email::SMTP::Headers"	=> ["Email::SMTP", "1.013"],
     "Email::SMTP::Transmit"	=> ["Email::SMTP", "1.013"],
     "Email::Time"		=> ["Email::SMTP", "1.013"],
     # PackageTools: Only for make install
     "PackageTools"		=> [undef, "1.014"],
     # User specified mappings
     %package_map
    );
if ($ppm_version == 3) {
    %replace_package = map { my $a = $_; $a =~ s/::/-/g; $a } %replace_package;
}
my $change = join "|" => map quotemeta($_) => keys %replace_package;
my $demand_version = MIN_VERSION;
$pkg =~ s{^(\s*<(?:DEPENDENCY|REQUIRE)\s+NAME=")($change)("\s+VERSION="[^\"]+"\s+/>\s*\n)}{
    if ($replace_package{$2}) {
        $demand_version = $replace_package{$2}[1] if
            $replace_package{$2}[1] > $demand_version;
        defined $replace_package{$2}[0] ? "$1$replace_package{$2}[0]$3" : "";
    } else {
        "";
    }
}meg;
warn("Warning: minimum needed version is $demand_version, not $min_version") if
    $min_version && $demand_version > $min_version;
$pkg =~ s!^(\s*<DEPENDENCY\s+NAME=")([^\"]*)-Package("\s+VERSION="[^\"]+"\s+/>\s*\n)!$1$2$3!mg;

my $tmp_dir = $leave || tempdir(CLEANUP => 1);
if ($leave) {
    -d $leave || mkdir($leave) || die "Could not create $leave: $!";
    opendir(my $dh, $leave) || die "Could not opendir $leave: $!";
    for my $f (readdir($dh)) {
        next if $f eq "." || $f eq "..";
        rmtree("$leave/$f");
    }
}
my ($pp_dir, $pp_name) = $ppd =~ m{^(.*?)([^/]+)\z}s or
    die "Could not parse $ppd";
# print STDERR "$pp_dir, $pp_name, $pkg_name, $major, $minor, $arch\n";
mkdir("$tmp_dir/$arch") || die "Could not mkdir $tmp_dir/$arch: $!";
my $new_ppd = "$tmp_dir/$pp_name";

# print $pkg;

open(my $npfh, ">", $new_ppd) || die "Could not create '$new_ppd': $!";
print($npfh $pkg) || die "Error writing to '$new_ppd': $!";
$npfh->flush	|| die "Error flushing '$new_ppd': $!";
$^O eq "MSWin32" || $npfh->sync	|| die "Error syncing '$new_ppd': $!";
close($npfh)	|| die "Error closing '$new_ppd': $!";

# Exclude man1 and man3 because windows perls don't have a mapping for these,
# and they will cause an error on ppm install
# We are currently assuming gnu tar here
# (maybe at some point generate a filelist myself and do the compress later)

print STDERR "\t$tar ", "-czf $tmp_dir/$arch/$dist --exclude \"blib/man*\"", $pp_dir eq "" ? "" : " -C $pp_dir", " blib\n";
system($tar,
       "-czf", "$tmp_dir/$arch/$dist",
       "--exclude", $^O eq "MSWin32" ? qq("blib/man*") : "blib/man*",
       ($pp_dir eq "" ? () : ("-C", $pp_dir)),
       "blib") and do {
           warn("If you don't have bsd tar, you can get it from http://gnuwin32.sourceforge.net/packages/bsdtar.htm\n") if $? == -1 || $? == 256;
           die "Could not tar (rc $?)";
};
my $from_dir = getcwd;
chdir($tmp_dir) || die "Could not chdir $tmp_dir: $!";
print STDERR "\t$zip -r foo .\n";
system($zip, "-r", "foo", ".") and do {
    warn("If you don't have a commandline zip, you can get it from http://gnuwin32.sourceforge.net/packages/zip.htm\n") if $? == -1 || $? == 256;
    die "Could not zip (rc $?)";
};
chdir($from_dir) || die "Could not chdir $from_dir: $!";
my $ppm = "$pp_dir$pkg_name-$major.$minor.ppm";
move("$tmp_dir/foo.zip", $ppm) || die "Could not move $tmp_dir/foo.zip to $ppm: $!";
__END__

=head1 NAME

makeppd.pl - Generate a ppm file from a standard perl package

=head1 SYNOPSIS

  makeppd.pl [--perl=executable] [--min_version=version_number] [--zip=executable] [--tar=executable] [--compress=executable] [--leave=directory] [--prerequisite name=version] [--dependency name=version] [--map module=package] ppd_file [version]
  makeppd.pl [-U] [--unsafe] --help
  makeppd.pl --version

=head1 DESCRIPTION

....

If the version argument is given it's checked against the package version in
the ppd file. They must be the same.

=head1 OPTIONS

=over 4

=item X<option_perl>--perl=executable

The name of the perl executable to use to execute makeppd.pl. This obviously
only gets checked once makeppd is already running under some perl executable.
The program will restart itself with the same arguments and the appropiate
perl executable.

=item X<option_min_version>--min_version=version_number

The minimum version of the makeppd program itself that is acceptable. The
program will do a version check and error out if the version number is too low.

=item X<option_zip>--zip=executable

The name of the commandline zip program to use. Defaults to just C<zip>. An
appropiate zip executable for windows can be found on
L<http://gnuwin32.sourceforge.net/packages/zip.htm>.

=item X<option_tar>--tar=executable

The name of the commandline tar program to use. Defaults to just C<tar>. An
appropiate tar executable for windows can be found on
L<http://gnuwin32.sourceforge.net/packages/bsdtar.htm>.

=item X<option_compress>--compress=executable

The name of the commandline compress program to use. Defaults to just
C<gzip --best>.

=item X<option_leave>--leave=directory

By default the working directory where the distribution file is constructed
is cleaned up after running the program. By giving a directory argument to this
option that directory will be used as the working directory to create the ppm
package and this directory then does not get cleaned up afterward.

=item X<option_prerequisite>--prerequisite name=version

=item X<option_prerequisite>--dependency name=version

Allows you to add explicite prerequisites that will get added to the ppd file.
You can give this option as often as required.

=item X<option_map>--map module=package

available since version 1.012

Most Makefile.PL prerequisites are of modules instead of packages but ppd
prerequisites are in terms of packages. makeppd has a number of often occuring
mappings from modules to packages built in, but the majority are not known.
You can use this option to declare that a given module comes with a given
package.

Even with this it still won't know how to convert required module versions to
required package version though.

You can give this option as often as required.

=item X<option_version>--version

Show the the program version.

=item X<option_unsafe>--unsafe, -U

Allows you to run L<--help|"option_help"> even as root. Notice that this implies
you are trusting this program and the perl installation.

=item X<option_help>--help, -h

Show this help.

=back

=head1 EXAMPLE

Typical use in a Makefile.PL so that you can do L<name|nmake> or L<dmake|dmake>
on targets like C<ppm> or C<ppm_install>:

  ...
  WriteMakefile
  (
     ...
     clean		=> {
         FILES => '$(DISTVNAME).ppm',
     },
     ...
  );
  ...
  package MY;
  sub postamble {
    return shift->SUPER::postamble() . <<"EOF";
  ppm: \$(DISTVNAME).ppm

  \$(DISTVNAME).ppm: all ppd
	makeppd.pl "--perl=\$(PERL)" --min_version=1.014 "--zip=\$(ZIP)" "--tar=\$(TAR)" "--compress="\$(COMPRESS)" --leave=ppm \$(DISTNAME).ppd \$(VERSION)
EOF
  }

You can use L<release_pm|"release_pm"> to insert such a section automatically.

=head1 SEE ALSO

L<release_pm|release_pm>

=head1 AUTHOR

Ton Hospel, E<lt>makeppd@ton.iguana.beE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Ton Hospel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
