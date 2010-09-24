#!/usr/bin/perl -w
# $HeadURL: http://subversion.bmsg.nl/repos/kpn/trunk/src/perl-modules/PackageTools/bin/makeppd.pl $
# $Id: makeppd.pl 4211 2010-09-24 23:00:32Z hospelt $

# Author: Ton Hospel
# Create a ppm

use strict;
use warnings;

our $VERSION = "1.015";

use FindBin qw($Bin $Script);
# If the program runs as /foobar/bin/program, find libraries in /foobar/lib
BEGIN {
    # Even on windows FindBin uses / in the reported path
    $Bin =~ s{/+\z}{};
    $Bin =~
        ($^O eq "MSWin32" ?
         qr{^((?:[A-Z]:)?(?:/[a-zA-Z0-9_:.~ -]+)*)/[a-zA-Z0-9_.-]+/*\z} :
         qr{^((?:/[a-zA-Z0-9_:.-]+)*)/[a-zA-Z0-9_.-]+/*\z}) ||
         die "Could not parse bin directory '$Bin'";
    # Use untainted version of lib
    require lib;
    # Support a simple --blib option for pre-install testing
    "lib"->import(@ARGV && $ARGV[0] eq "--blib" ? shift && "$1/blib/lib" : "$1/lib");
}

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

use constant MIN_VERSION => "1.011";
my $zip = "zip";
my $tar = "tar";
my $compress = "gzip --best";

# http://gnuwin32.sourceforge.net/packages/bsdtar.htm
my $bsd_tar	= 'C:/Program Files/GnuWin32/bin/bsdtar';
# http://gnuwin32.sourceforge.net/packages/zip.htm
my $gnuwin_zip	= 'C:/Program Files/GnuWin32/bin/zip';

Getopt::Long::config("bundling", "require_order");
my @OLD_ARGV = @ARGV;
die "Could not parse your command line (@ARGV) . Try $Bin/$Script -h\n" unless
    GetOptions("zip=s"		=> \$zip,
               "tar=s"		=> \$tar,
               "perl=s"		=> \my $perl,
               "compress=s"	=> \$compress,
               "leave=s"	=> \my $leave,
               "root=s"		=> \my $prefix_dir,
               "dependency|prerequisite=f"	=> \my %prereq,
               "ppm_version=i"	=> \my $ppm_out_version,
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
    my $program = File::Spec->catfile($Bin, $Script);
    if ($^O eq "MSWin32") {
        $_ = qq("$_") for $program, @OLD_ARGV;
    }
    # Should also propagate cover options
    my $rc = system($perl, $INC{"Devel/Cover.pm"} ? "-MDevel::Cover" : (),
                    $program, "--reinvoke", @OLD_ARGV);
    die "Could not re-exec as $perl $program --reinvoke @OLD_ARGV: $!" if $rc < 0;
    die "Signal $rc failure on re-exec of re-exec as $perl $program --reinvoke @OLD_ARGV" if $rc & 0xff;
    exit $rc >> 8;
}

die "This is $Bin/$Script version $VERSION, but the caller wants at least version $min_version\n" if $min_version && $VERSION < $min_version;

if ($version) {
    require PackageTools::Package;
    ## no critic (RequireCheckedSyscalls)
    print<<"EOF";
makeppd.pl $VERSION (PackageTools $PackageTools::Package::VERSION)
EOF
    exit 0;
}
if ($help) {
    $ENV{PATH} .= ":" unless $ENV{PATH} eq "";
    $ENV{PATH} = "$ENV{PATH}$Config{installscript}";
    exec("perldoc", "-F", $unsafe ? "-U" : (), "$Bin/$Script") || exit 1;
}

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
    my (%seen, @stat);
    while (defined(my $dir = shift @dirs)) {
        my $dh;
        if (defined $prefix_dir) {
            opendir($dh, "$prefix_dir/$dir") ||
                die "Could not opendir '$prefix_dir/$dir': $!";
        } else {
            opendir($dh, $dir) ||
                die "Could not opendir '$dir': $!";
        }
        my @files = sort readdir($dh);
        closedir($dh) || die "Could not closedir '$dir': $!";
        for my $f (@files) {
            next if $f eq "." || $f eq "..";
            my $file = "$dir/$f";
            if (defined $prefix_dir) {
                @stat = lstat("$prefix_dir/$file") or
                    die "Could not lstat '$prefix_dir/$file': $!";
            } else {
                @stat = lstat($file) or
                    die "Could not lstat '$file': $!";
            }
            if (-d _) {
                unshift @dirs, $file;
            } elsif (-f _) {
                next unless $f =~ /\.pm\z/i;
                my $v = ExtUtils::MM_Unix->parse_version
                    (defined $prefix_dir ? "$prefix_dir/$file" : $file);
                if (defined $v) {
                    $file =~ s{^blib/lib/}{} ||
                        die "Assertion: File '$file' does not start with blib/lib/";
                    $file =~ s{\.pm\z}{}i ||
                        die "Assertion: File '$file' does not end on .pm";
                    # if ($ppm_out_version == 3) {
                    #    $v =~ s/\./,/g;
                    #    $v .= ",0" x (3 - $v =~ tr/,//);
                    #    $file =~ s!/!-!g;
                    #} else {
                    # ppm version 4
                    $file =~ s{/}{::}g;
                    #}
                    my $provide = qq(        <PROVIDE NAME="$file" VERSION="$v" />\n);
                    $provides .= $provide unless $seen{$provide}++;
                }
            } else {
                die "Unhandled filetype for '$file'";
            }
        }
    }
    return $provides;
}

my $ppm_in_version = 4;
my (%seen_dep, $demand_version, %replace_package);
sub depend {
    # warn "Replace $name\n";
    my ($pre, $name, $version, $post) = @_;
    if ($ppm_in_version == 3) {
        $name =~ s{-}{::}g;
        if (defined $version) {
            $version =~ tr/,/./;
            $version =~ s/(?:.0){1,2}\z//;
        }
    }
    if ($replace_package{$name}) {
        $demand_version = $replace_package{$name}[1] if
            $replace_package{$name}[1] > $demand_version;
        defined($name = $replace_package{$name}[0]) || return "";
    }
    my $dep;
    if ($ppm_out_version == 3) {
        $name =~ s{::\z}{};
        $name =~ s{::}{-}g;
        if (defined $version) {
            $version =~ s/\./,/g;
            $version .= ",0" x (3 - $version =~ tr/,//);
            $dep = qq(DEPENDENCY NAME="$name" VERSION="$version");
        } else {
            $dep = qq(DEPENDENCY NAME="$name");
        }
    } elsif (defined $version) {
        $dep = qq(REQUIRE NAME="$name" VERSION="$version");
    } else {
        $dep = qq(REQUIRE NAME="$name");
    }
    return $seen_dep{$dep}++ ? "" : $pre . $dep . $post;
}

# Determine a good tar
$tar = $bsd_tar unless executable($tar);
# warn "tar=$tar\n";
$zip = $gnuwin_zip unless executable($zip);
# warn "zip=$zip\n";

my $ppd = shift || die "No ppd argument";
$ppd = "$prefix_dir/$ppd" if
    defined $prefix_dir && !File::Spec->file_name_is_absolute($ppd);

open(my $pfh, "<", $ppd) || do {
    die "$ppd does not exist yet.\n" if $! == ENOENT || $! == ESTALE;
    die "Could not open '$ppd': $!";
};
my $pkg = do { local $/; <$pfh> };
close($pfh) || die "Error closing '$ppd': $!";

my ($pkg_name, $pkg_version) =
    $pkg =~ /\A\s*<SOFTPKG\s+NAME="([^\"]+)" VERSION="([^\"]+)"(?:\s+DATE="([^\"]+)")?>\s*$/m or
    die "Could not parse package header from $ppd";
if ($pkg_version =~ /^\d+,\d+,\d+,\d+\z/) {
    $ppm_in_version = 3;
    $pkg_version =~ tr/,/./;
    $pkg_version =~ s/(?:.0){1,2}\z//;
}
$ppm_out_version ||= $ppm_in_version;
if (@ARGV) {
    my $version = shift;
    $version eq $pkg_version || die "Package is at version $version, but the ppd is at version $pkg_version\n";
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
        warn "Fixing ARCHITECTURE NAME to $arch\n";
    }
} else {
    $pkg =~ s{^[^\S\n]*<ARCHITECTURE\s+NAME="[^\"]+"\s*/>[^\S\n]*\n}{}m ||
        die "Could not remove ARCHITECTURE NAME";
    $pkg =~ s{^[^\S\n]*<OS\s+NAME="[^\"]+"\s*/>[^\S\n]*\n}{}m;
    $arch = "Any";
}

my $dist = "$pkg_name-$pkg_version.tar.gz";
my $code_base = "$arch/$dist";
$pkg =~ s{^(\s*<CODEBASE\s+HREF=")[^\"]*("\s*/>\s*\n)}{$1$code_base$2}m or
    die "Could not substitute codebase";
if (%prereq) {
    my $prereq = "";
    for my $pre_name (sort keys %prereq) {
        my $ver = $prereq{$pre_name};
        if ($ppm_out_version == 3) {
            $ver =~ s/\./,/g;
            $ver .= ",0" x (3 - $ver =~ tr/,//);
            $pre_name =~ s{::}{-}g;
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
if ($ppm_out_version != 3) {
    my $provides = provides();
    $pkg =~ s{^([^\S\n]*<IMPLEMENTATION>[^\S\n]*\n)}{$1$provides}gm ||
        die "Assertion: No IMPLEMENTATION";
}

$_ = [$_, "0"] for values %package_map;

# Map from module name to package name and
# the first version of this program that had the mapping
# Name undef means the dependency is dropped
%replace_package =
    (
     # Activestate builtins
     "Time::HiRes"		=> [undef, "1.011"],
     "Net::SMTP"		=> [undef, "1.011"],
     "MIME::Base64"		=> [undef, "1.011"],
     "Storable"			=> [undef, "1.013"],
     "Carp"			=> [undef, "1.015"],
     "Errno"			=> [undef, "1.015"],
     "Exporter"			=> [undef, "1.015"],
     "File::Spec"		=> [undef, "1.015"],
     "IO::Handle"		=> [undef, "1.015"],
     "POSIX"			=> [undef, "1.015"],
     "Socket"			=> [undef, "1.015"],
     "Test::Harness"		=> [undef, "1.015"],
     "URI"			=> [undef, "1.015"],
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
if ($ppm_out_version == 3) {
    for my $replace_package (values %replace_package) {
        $replace_package->[0] =~ s{::}{-}g if defined $replace_package->[0];
    }
}
$demand_version = MIN_VERSION;
%seen_dep = ();
$pkg =~ s{^(\s*<)(?:DEPENDENCY|REQUIRE)\s+NAME="([^\"]+)"(?:\s+VERSION="([^\"]+)"|)(\s*/>\s*\n)}{depend($1, $2, $3, $4)}meg;
warn("Warning: minimum needed version is $demand_version, not $min_version") if
    $min_version && $demand_version > $min_version;
$pkg =~ s{^(\s*<DEPENDENCY\s+NAME=")([^\"]*)-Package("\s+VERSION="[^\"]+"\s*/>\s*\n)}{$1$2$3}mg;

my $tmp_dir = $leave || tempdir(CLEANUP => 1);
if ($leave) {
    -d $leave || mkdir($leave) || die "Could not mkdir '$leave': $!";
    opendir(my $dh, $leave) || die "Could not opendir '$leave': $!";
    for my $f (readdir($dh)) {
        next if $f eq "." || $f eq "..";
        rmtree("$leave/$f");
    }
}
my ($pp_dir, $pp_name) = $ppd =~ m{^(.*?)([^/]+)\z}s or
    die "Could not parse $ppd";
# warn "$pp_dir, $pp_name, $pkg_name, $pkg_version, $arch\n";
mkdir("$tmp_dir/$arch") || die "Could not mkdir '$tmp_dir/$arch': $!";
my $new_ppd = "$tmp_dir/$pkg_name.ppd";

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

warn "\t$tar ", "-czf $tmp_dir/$arch/$dist --exclude \"blib/man*\"", $pp_dir eq "" ? "" : " -C $pp_dir", " blib\n";
system($tar,
       "-czf", "$tmp_dir/$arch/$dist",
       "--exclude", $^O eq "MSWin32" ? qq("blib/man*") : "blib/man*",
       $pp_dir eq "" ? () : ("-C", $pp_dir),
       "blib") and do {
           warn("If you don't have bsd tar, you can get it from http://gnuwin32.sourceforge.net/packages/bsdtar.htm\n") if $? == -1 || $? == 256;
           die "Could not tar (rc $?)";
};
my $from_dir = getcwd();
chdir($tmp_dir) || die "Could not chdir $tmp_dir: $!";
warn "\t$zip -r foo .\n";
system($zip, "-r", "foo", ".") and do {
    warn("If you don't have a command-line zip, you can get it from http://gnuwin32.sourceforge.net/packages/zip.htm\n") if $? == -1 || $? == 256;
    die "Could not zip (rc $?)";
};
chdir($from_dir) || die "Could not chdir $from_dir: $!";
my $ppm = "$pp_dir$pkg_name-$pkg_version.ppm";
move("$tmp_dir/foo.zip", $ppm) || die "Could not move $tmp_dir/foo.zip to $ppm: $!";
__END__

=for stopwords dmake ppd makeppd makeppd.pl

=head1 NAME

makeppd.pl - Generate a ppm file from a standard perl package

=head1 SYNOPSIS

  makeppd.pl [--perl=executable] [--min_version=version_number] [--zip=executable] [--tar=executable] [--compress=executable] [--leave=directory] [--root=directory] [--ppm_version] {--prerequisite name=version} {--dependency name=version} {--map module=package} {--objects=object} ppd_file [version]
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
The program will restart itself with the same arguments and the appropriate
perl executable.

=item X<option_min_version>--min_version=version_number

The minimum version of the makeppd program itself that is acceptable. The
program will do a version check and error out if the version number is too low.

=item X<option_zip>--zip=executable

The name of the command-line zip program to use. Defaults to just C<zip>. An
appropriate zip executable for windows can be found on
L<http://gnuwin32.sourceforge.net/packages/zip.htm>.

=item X<option_tar>--tar=executable

The name of the command-line tar program to use. Defaults to just C<tar>. An
appropriate tar executable for windows can be found on
L<http://gnuwin32.sourceforge.net/packages/bsdtar.htm>.

=item X<option_compress>--compress=executable

The name of the command-line compress program to use. Defaults to just
C<gzip --best>.

=item X<option_leave>--leave=directory

By default the working directory where the distribution file is constructed
is cleaned up after running the program. By giving a directory argument to this
option that directory will be used as the working directory to create the ppm
package and this directory then does not get cleaned up afterward.

=item X<option_dir>--root=directory

The package base directory. If not given the current directory is used

=item X<option_prerequisite>--prerequisite name=version

=item X<option_prerequisite>--dependency name=version

Allows you to add explicit prerequisites that will get added to the ppd file.
You can give this option as often as required.

The name should always use :: to separate module parts,even for ppm3 where in
the output a - will be used).

The version should always be a plain version number, even for ppm3 where the
version will be split into digits separated by commas.

=item X<ppm_version>--ppm_version

available since version 1.015

Determines ppm version of the ppd output file that will be generated. If not
given it will be the same as the version of the ppd input file.

=item X<option_map>--map module=package

available since version 1.012

Most Makefile.PL prerequisites are of modules instead of packages but ppd
prerequisites (for ppm3) are in terms of packages. makeppd has a number of
often occurring mappings from modules to packages built in, but the majority are
not known.
You can use this option to declare that a given module comes with a given
package.

Even with this it still won't know how to convert required module versions to
required package version though.

You can give this option as often as required.

=item X<option_objects>--objects object

This indicates that it is a binary package and the architecture will not be
removed from the result ppd.

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
  ppm: \$(DISTNAME).ppm
	makeppd.pl "--perl=\$(PERL)" --min_version=1.014 "--zip=\$(ZIP)" "--tar=\$(TAR)" "--compress="\$(COMPRESS)" --leave=ppm \$(DISTNAME).ppd \$(VERSION)

  \$(DISTNAME).ppd: all ppd
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
