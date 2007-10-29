package PackageTools::Package;
our $VERSION = "1.000"; # $Revision: 2526 $

# START HISTORY
our %history = (
  'lib/PackageTools/Package.pm' => {
    '1.000' => '1.000'
  },
  'bin/release_pm' => {
    '1.000' => '1.000'
  },
  'Changes' => {
    '1.000' => '1.000'
  },
  'MANIFEST' => {
    '1.000' => '1.000'
  },
  'bin/makeppd.pl' => {
    '1.000' => '1.000'
  },
  't/00_syntax.t' => {
    '1.000' => '1.000'
  },
  'Makefile.PL' => {
    '1.000' => '1.000'
  },
  'README' => {
    '1.000' => '1.000'
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
