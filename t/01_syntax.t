#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 01_syntax.t'
#########################
# $Id: 01_syntax.t 4211 2010-09-24 23:00:32Z hospelt $
use strict;
use warnings;

our $VERSION = "1.000";

use FindBin;

BEGIN {
    $^W = 1;
    require lib;
    "lib"->import($FindBin::Bin);
};

use TestDrive qw($tmp_dir $bin_dir slurp work_area);

use Test::More tests => 3;

sub check {
    # Normally I would put the local inside the open, but this also counts as
    # the second use to avoid a warning
    local *OLDERR;
    open(*OLDERR, ">&", "STDERR") || die "Can't dup STDERR: $!";
    open(STDERR, ">", "$tmp_dir/stderr") ||
        die "Can't open $tmp_dir/stderr: $!";
    my $rc = system($^X, "-c", @_);
    open(STDERR, ">&", "OLDERR")        || die "Can't dup OLDERR: $!";
    my $errors = slurp("$tmp_dir/stderr");
    $errors =~ s/.* syntax OK\n//;
    if ($errors ne "") {
        diag($errors);
        return 1;
    }
    return $rc;
}

work_area();
for my $file qw(release_pm makeppd.pl any_to_blib) {
    ok(!check("$bin_dir/$file"), "Can compile $file");
}
