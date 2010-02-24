package LogParse::Package;
# $HeadURL: http://subversion.bmsg.nl/repos/kpn/trunk/src/perl-modules/PackageTools/t/makeppd/LogParse/blib/lib/LogParse/Package.pm $
# $Id: Package.pm 3820 2010-02-23 17:00:11Z hospelt $

# START HISTORY
# autogenerated by release_pm
use vars qw($VERSION $release_time %history);
$VERSION = "1.005";
$release_time = 1266965259;
%history = (
  'Changes' => {
    '1.000' => '1.000',
    '1.001' => '1.001',
    '1.002' => '1.002',
    '1.003' => '1.003',
    '1.004' => '1.004',
    '1.005' => '1.005'
  },
  'MANIFEST' => {
    '1.000' => '1.000',
    '1.001' => '1.004',
    '1.002' => '1.005'
  },
  'MANIFEST.SKIP' => {
    '1.000' => '1.004'
  },
  'Makefile.PL' => {
    '1.000' => '1.001',
    '1.001' => '1.004',
    '1.002' => '1.005'
  },
  'README' => {
    '1.000' => '1.000',
    '1.001' => '1.001',
    '1.002' => '1.002',
    '1.003' => '1.003',
    '1.004' => '1.004',
    '1.005' => '1.005'
  },
  'bin/any_to_blib' => {
    '1.000' => '1.005'
  },
  'bin/makeppd.pl' => {
    '1.011' => '1.000',
    '1.012' => '1.002',
    '1.013' => '1.004',
    '1.014' => '1.005'
  },
  'bin/release_pm' => {
    '1.002' => '1.000',
    '1.003' => '1.001',
    '1.004' => '1.002',
    '1.005' => '1.003',
    '1.006' => '1.004',
    '1.007' => '1.005'
  },
  'lib/PackageTools/Package.pm' => {
    '1.000' => '1.000',
    '1.001' => '1.001',
    '1.002' => '1.002',
    '1.003' => '1.003',
    '1.004' => '1.004',
    '1.005' => '1.005'
  },
  't/00_syntax.t' => {
    '1.000' => '1.001',
    '1.001' => '1.004',
    '1.002' => '1.005'
  },
  't/02_makeppd.t' => {
    '1.000' => '1.005'
  },
  't/02_makeppd_ppm3.t' => {
    '1.000' => '1.005'
  },
  't/TestDrive.pm' => {
    '1.000' => '1.005'
  },
  't/makeppd/LogParse/LogParse.ppd' => {
    '1.000' => '1.005'
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
    '1.005' => '1.005'
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

sub release_time {
    return $release_time;
}

sub released {
    my ($package, $version) = @_;
    my $p = $package;
    $p =~ s!::!/!g;
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
# END HISTORY

1;