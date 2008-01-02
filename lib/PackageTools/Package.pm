package PackageTools::Package;
# $HeadURL: http://prodbs1.bmsg.nl/repos/kpn/trunk/src/perl-modules/PackageTools/lib/PackageTools/Package.pm $
# $Id: Package.pm 2693 2008-01-02 09:54:19Z hospelt $
our $VERSION = "1.004";

# START HISTORY
our %history = (
  'Changes' => {
    '1.000' => '1.000',
    '1.001' => '1.001',
    '1.002' => '1.002',
    '1.003' => '1.003',
    '1.004' => '1.004'
  },
  'MANIFEST' => {
    '1.000' => '1.000',
    '1.001' => '1.004'
  },
  'MANIFEST.SKIP' => {
    '1.000' => '1.004'
  },
  'Makefile.PL' => {
    '1.000' => '1.001',
    '1.001' => '1.004'
  },
  'README' => {
    '1.000' => '1.000',
    '1.001' => '1.001',
    '1.002' => '1.002',
    '1.003' => '1.003',
    '1.004' => '1.004'
  },
  'bin/makeppd.pl' => {
    '1.011' => '1.000',
    '1.012' => '1.002',
    '1.013' => '1.004'
  },
  'bin/release_pm' => {
    '1.002' => '1.000',
    '1.003' => '1.001',
    '1.004' => '1.002',
    '1.005' => '1.003',
    '1.006' => '1.004'
  },
  'lib/PackageTools/Package.pm' => {
    '1.000' => '1.000',
    '1.001' => '1.001',
    '1.002' => '1.002',
    '1.003' => '1.003',
    '1.004' => '1.004'
  },
  't/00_syntax.t' => {
    '1.000' => '1.001',
    '1.001' => '1.004'
  }
);

use Carp;

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
