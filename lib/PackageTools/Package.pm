package PackageTools::Package;
# $HeadURL: http://subversion.bmsg.nl/repos/kpn/trunk/src/perl-modules/PackageTools/lib/PackageTools/Package.pm $
# $Id: Package.pm 4256 2010-10-21 13:28:13Z hospelt $

# START HISTORY
# autogenerated by release_pm
use strict;
use warnings;
use vars qw($VERSION $release_time %history);
$VERSION = "1.008";
$release_time = 1287666440;	## no critic (ProhibitUselessNoCritic ProhibitMagicNumbers)
%history = (
  'Changes' => {
    '1.000' => '1.000',
    '1.001' => '1.001',
    '1.002' => '1.002',
    '1.003' => '1.003',
    '1.004' => '1.004',
    '1.005' => '1.005',
    '1.006' => '1.006',
    '1.007' => '1.007',
    '1.008' => '1.008'
  },
  'MANIFEST' => {
    '1.000' => '1.000',
    '1.001' => '1.004',
    '1.002' => '1.005',
    '1.003' => '1.007'
  },
  'MANIFEST.SKIP' => {
    '1.000' => '1.004'
  },
  'Makefile.PL' => {
    '1.000' => '1.001',
    '1.001' => '1.004',
    '1.002' => '1.005',
    '1.003' => '1.006',
    '1.004' => '1.007'
  },
  'README' => {
    '1.000' => '1.000',
    '1.001' => '1.001',
    '1.002' => '1.002',
    '1.003' => '1.003',
    '1.004' => '1.004',
    '1.005' => '1.005',
    '1.006' => '1.006',
    '1.007' => '1.007',
    '1.008' => '1.008'
  },
  'bin/any_to_blib' => {
    '1.000' => '1.005',
    '1.001' => '1.007'
  },
  'bin/makeppd.pl' => {
    '1.011' => '1.000',
    '1.012' => '1.002',
    '1.013' => '1.004',
    '1.014' => '1.005',
    '1.015' => '1.007'
  },
  'bin/release_pm' => {
    '1.002' => '1.000',
    '1.003' => '1.001',
    '1.004' => '1.002',
    '1.005' => '1.003',
    '1.006' => '1.004',
    '1.007' => '1.005',
    '1.008' => '1.005',
    '1.009' => '1.006',
    '1.010' => '1.007'
  },
  'lib/PackageTools/Package.pm' => {
    '1.000' => '1.000',
    '1.001' => '1.001',
    '1.002' => '1.002',
    '1.003' => '1.003',
    '1.004' => '1.004',
    '1.005' => '1.005',
    '1.006' => '1.006',
    '1.007' => '1.007',
    '1.008' => '1.008'
  },
  't/00_load.t' => {
    '1.000' => '1.007'
  },
  't/00_syntax.t' => {
    '1.000' => '1.001',
    '1.001' => '1.004',
    '1.002' => '1.005'
  },
  't/01_syntax.t' => {
    '1.000' => '1.007'
  },
  't/02_any_to_blib.t' => {
    '1.000' => '1.007'
  },
  't/02_makeppd.t' => {
    '1.000' => '1.005',
    '1.001' => '1.006',
    '1.002' => '1.007'
  },
  't/02_makeppd_ppm3.t' => {
    '1.000' => '1.005',
    '1.001' => '1.006',
    '1.002' => '1.007'
  },
  't/02_makeppd_ppm3_4.t' => {
    '1.000' => '1.007'
  },
  't/02_makeppd_ppm4_3.t' => {
    '1.000' => '1.007'
  },
  't/TestDrive.pm' => {
    '1.000' => '1.005',
    '1.001' => '1.007'
  },
  't/any_to_blib/01_basic.in' => {
    '1.000' => '1.007'
  },
  't/any_to_blib/01_basic.out' => {
    '1.000' => '1.007'
  },
  't/any_to_blib/02_filter.tmpl' => {
    '1.000' => '1.007'
  },
  't/any_to_blib/02_filter.tmpl.out' => {
    '1.000' => '1.007'
  },
  't/makeppd/LogParse/LogParse.ppd' => {
    '1.000' => '1.005',
    '1.001' => '1.007'
  },
  't/makeppd/LogParse/LogParse_ppm3.ppd' => {
    '1.000' => '1.005',
    '1.001' => '1.007'
  },
  't/makeppd/LogParse/blib/lib/LogParse.pm' => {
    '1.002' => '1.005'
  },
  't/makeppd/LogParse/blib/lib/LogParse/Attributes.pm' => {
    '1.000' => '1.005'
  },
  't/makeppd/LogParse/blib/lib/LogParse/Info.pm' => {
    '1.000' => '1.005'
  },
  't/makeppd/LogParse/blib/lib/LogParse/Info/Record.pm' => {
    '1.000' => '1.005'
  },
  't/makeppd/LogParse/blib/lib/LogParse/Package.pm' => {
    '1.003' => '1.005',
    '1.005' => '1.005',
    '1.006' => '1.006'
  },
  't/makeppd/LogParse/blib/lib/LogParse/Record.pm' => {
    '1.001' => '1.005'
  },
  't/makeppd/LogParse/blib/lib/LogParse/State.pm' => {
    '1.000' => '1.005'
  },
  't/makeppd/LogParse/blib/lib/LogParse/Transaction.pm' => {
    '1.001' => '1.005'
  },
  't/makeppd/LogParse/blib/lib/LogParse/Transaction/Record.pm' => {
    '1.001' => '1.005'
  },
  't/ppm3/LogParse.ppd' => {
    '1.000' => '1.005'
  }
);

use Carp;

my $epoch_base;

sub release_time {
    if (!defined $epoch_base) {
        require Time::Local;
        $epoch_base = Time::Local::timegm(0,0,0,1,0,70);	## no critic (ProhibitUselessNoCritic ProhibitMagicNumbers)
    }
    return $release_time + $epoch_base;
}

sub released {
    my ($package, $version) = @_;
    my $p = $package;
    $p =~ s{::}{/}g;
    my $history = $history{"lib/$p.pm"} ||
        croak "Could not find a history for package '$package'";
    my $lowest = 9**9**9;
    for my $v (keys %$history) {
        $lowest = $v if $v >= $version && $v < $lowest;
    }
    croak "No known version '$version' of package '$package'" if
        $lowest == 9**9**9;
    return $history->{$lowest};
}
1;
__END__

=for stopwords PackageTools globals

=head1 NAME

PackageTools::Package - Version and history of PackageTools

=head1 SYNOPSIS

  use PackageTools::Package;

  $epoch_time = PackageTools::Package->release_time();

  $package_version = PackageTools::Package->VERSION;

  $min_package_version = PackageTools::Package::released($module, $module_version);

=head1 DESCRIPTION

In the context of this documentation a C<package> is a set of files that
together make up a perl extension, not to be confused with the more normal
perl concept of a namespace for globals.

A package release with a certain package version number contains a number of
modules and other files with their own version numbers. This module contains a
history of which files with which versions where in which package release and
also knows when the current package was released.

This module contains a few simple methods to query this.

The version number of this Package.pm module is always equal to the version
number of the package release. This means you can use this to query this
release number and also makes it a convenient target for Makefile.PL
dependencies.

=head1 METHODS

=over

=item X<release_time>$epoch_time = PackageTools::Package->release_time()

Returns the the number of non-leap seconds since whatever time the system that
calls this function considers to be the epoch the last time
L<release_pm|release_pm(1)> was run (even if that was on another system with a
different epoch). Since the idea is to run L<release_pm|release_pm(1)> just
before releasing the package this is therefore the value of
L<time()|perlfunc/time> on the system calling this function at the moment the
package was released. This number is suitable for feeding to
L<gmtime()|perlfunc/gmtime> and L<local_time()|perlfunc/local_time>

=item X<VERSION>$package_version = PackageTools::Package->VERSION

This is the normal L<UNIVERSAL::VERSION|UNIVERSAL/VERSION> method you can use
on all modules, but this particular module is guaranteed to have a version
number that is the same as that of the package

=item X<released>$min_package_version = PackageTools::Package::released($module, $module_version)

Given a module name (e.g. Foo::Bar) and a module version number (e.g. 1.023)
returns the lowest package version in which that module (as the file
F<Foo/Bar.pm>) had at least that module version

=back

=head1 EXPORTS

None.

=head1 SEE ALSO

L<release_pm|release_pm(1)> which can be used to keep Package.pm files up to
date.

=cut

# END HISTORY
