package PackageTools::Package;
our $VERSION = "1.001"; # $Revision: 2538 $

# START HISTORY
our %history = (
  'Changes' => {
    '1.000' => '1.000',
    '1.001' => '1.001'
  },
  'README' => {
    '1.001' => '1.001'
  },
  'bin/makeppd.pl' => {
    '1.011' => '1.000'
  },
  'bin/release_pm' => {
    '1.002' => '1.000',
    '1.003' => '1.001'
  },
  'lib/PackageTools/Package.pm' => {
    '1.000' => '1.000',
    '1.001' => '1.001'
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
