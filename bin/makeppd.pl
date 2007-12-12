#!/usr/bin/perl -w
# Author: Ton Hospel
# Create a ppm

use strict;
use File::Temp qw(tempdir);
use File::Copy qw(move);
use File::Path qw(rmtree);
use File::Spec;
use Cwd;
use Errno qw(ENOENT ESTALE);
use Getopt::Long 2.11;

our $VERSION = "1.012"; # $Revision: 2677 $

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
               "prerequisite=f"	=> \my %prereq,
               "reinvoke"	=> \my $reinvoked,
               "min_version=s"	=> \my $min_version,
               "map=s"		=> \my %package_map,
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
    print<<"EOF";
makeppd.pl (Ton Utils) $VERSION
EOF
    exit 0;
}
if ($help) {
    require Config;
    $ENV{PATH} .= ":" unless $ENV{PATH} eq "";
    $ENV{PATH} = "$ENV{PATH}$Config::Config{'installscript'}";
    exec("perldoc", "-F", $unsafe ? "-U" : (), $0) || exit 1;
    # make parser happy
    %Config::Config = ();
}
die "This is $0 version $VERSION, but the caller wants at least version $min_version\n" if $min_version && $VERSION < $min_version;

sub exectable {
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

# Determine a good tar
$tar = $bsd_tar unless exectable($tar);
# print STDERR "tar=$tar\n";
$zip = $gnuwin_zip unless exectable($zip);
# print STDERR "zip=$zip\n";

my $ppd = shift || die "No ppm argument";

open(my $pfh, "<", $ppd) || do {
    die "$ppd does not exist yet.\n" if $! == ENOENT || $! == ESTALE;
    die "Could not open '$ppd': $!";
};
my $pkg = do { local $/; <$pfh> };
close($pfh) || die "Error closing $ppd: $!";

my ($pkg_name, $major, $minor) = $pkg =~ /\A.* NAME="([^\"]+)" VERSION="(\d+),(\d+),\d+,\d+">\s*$/m or
    die "Could not parse package header from $ppd";
if (@ARGV) {
    my $version = shift;
    $version eq "$major.$minor" || die "Package is at version $version, but the ppd is at version $major.$minor\n";
}
my ($arch) = $pkg =~
    m!^\s*<ARCHITECTURE\s+NAME="([^\"]+)"\s*/>\s*$!m or
    die "Could not parse architecture from $ppd";
my $dist = "$pkg_name-$major.$minor.tar.gz";
my $code_base = "$arch/$dist";
$pkg =~ s!^(\s*<CODEBASE\s+HREF=")[^\"]*("\s*/>\s*\n)!$1$code_base$2!m or
    die "Could not substitute codebase";
if (%prereq) {
    my $prereq = "";
    for my $pre_name (sort keys %prereq) {
        my $ver = $prereq{$pre_name};
        $ver =~ s/\./,/g;
        $ver .= ",0,0";
        $prereq .=
            qq(        <DEPENDENCY NAME="$pre_name" VERSION="$ver" />\n);
    }
    $pkg =~ s!^(\s*<IMPLEMENTATION>\s*\n)!$1$prereq!m;
}

my %replace_package =
    (
     # These are in activeperl but not in the ppm db
     "Time-HiRes"		=> "",
     "Net-SMTP"			=> "",
     "MIME-Base64"		=> "",
     "Test-More"		=> "", # Test::More is normally only for testing
     "Win32"			=> "",
     "Win32API::File"		=> "",	# Since version 1.012
     # Some info about CPAN modules
     "Date-Calendar"		=> "Date-Calc",
     "Date-Calendar-Profiles"	=> "Date-Calc",
     # Some of our own modules
     "Email::SMTP::Utils"	=> "Email::SMTP",
     "Email::SMTP::Headers"	=> "Email::SMTP",
     "Email::SMTP::Transmit"	=> "Email::SMTP",
     "Email::Time"		=> "Email::SMTP",
     # User specified mappings
     %package_map
);
my $change = join "|" => map quotemeta($_) => keys %replace_package;
$pkg =~ s!^(\s*<DEPENDENCY\s+NAME=")($change)("\s+VERSION="[^\"]+"\s+/>\s*\n)!
$replace_package{$2} ? $1 . $replace_package{$2} . $3 : ""!meg;
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
my ($pp_dir, $pp_name) = $ppd =~ m!^(.*?)([^/]+)\z!s or
    die "Could not parse $ppd";
# print STDERR "$pp_dir, $pp_name, $pkg_name, $major, $minor, $arch\n";
mkdir("$tmp_dir/$arch") || die "Could not mkdir $tmp_dir/$arch: $!";
my $new_ppd = "$tmp_dir/$pp_name";

# print $pkg;

open(my $npfh, ">", $new_ppd) || die "Could not create $new_ppd: $!";
print($npfh $pkg) || die "Error writing to $new_ppd: $!";
close($npfh) || die "Error closing $new_ppd: $!";

# Exclude man1 and man3 because windows perls don't have a mapping for these,
# and they will cause an error on ppm install
# We are currently assuming gnu tar here
# (maybe at some point generate a filelist myself and do the compress later)

print STDERR "\t$tar ", "-czf $tmp_dir/$arch/$dist --exclude \"blib/man*\"", $pp_dir eq "" ? "" : " -C $pp_dir", " blib\n";
system($tar,
       "-czf", "$tmp_dir/$arch/$dist",
       "--exclude", $^O eq "MSWin32" ? qq("blib/man*") : "blib/man*",
       ($pp_dir eq "" ? () : ("-C", $pp_dir)),
       "blib") and die "Could not tar";
my $from_dir = getcwd;
chdir($tmp_dir) || die "Could not chdir $tmp_dir: $!";
print STDERR "\t$zip -r foo .\n";
system($zip, "-r", "foo", ".") and die "Could not zip (rc $?)";
chdir($from_dir) || die "Could not chdir $from_dir: $!";
my $ppm = "$pp_dir$pkg_name-$major.$minor.ppm";
move("$tmp_dir/foo.zip", $ppm) || die "Could not move $tmp_dir/foo.zip to $ppm: $!";
__END__

=head1 NAME

makeppd.pl - Generate a ppm file from a standard perl package

=head1 SYNOPSIS

  makeppd.pl [--perl=executable] [--min_version=version_number] [--zip=executable] [--tar=executable] [--compress=executable] [--leave=directory] [--prereq name=version] [--map module=package] ppd_file [version]
  makeppd.pl --help
  makeppd.pl --version

=head1 OPTIONS

=over 4

=item X<option_perl>--perl=executable

=item X<option_min_version>--min_version=version_number

=item X<option_zip>--zip=executable

=item X<option_tar>--tar=executable

=item X<option_compress>--compress=executable

=item X<option_leave>--leave=directory

=item X<option_prereq>--prereq name=version

=item X<option_map>--map module=package

available since version 1.012

=item X<option_version>--version

=item X<option_unsafe>--unsafe, -U

=item X<option_help>--help, -h

=back

=head1 EXAMPLE

Typical use in a Makefile.PL so that you can do C<nmake ppm>:

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
	makeppd.pl --perl=\$(PERL) --min_version=1.011 --zip=\$(ZIP) --tar=\$(TAR) --compress="\$(COMPRESS)" --leave=ppm \$(DISTNAME).ppd \$(VERSION)
EOF
  }

=head1 AUTHOR

Ton Hospel, E<lt>makeppd@ton.iguana.beE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Ton Hospel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
