#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 00_syntax.t'
#########################
# $Id: 00_syntax.t 3298 2009-07-01 13:15:05Z hospelt $
our $VERSION = "1.002";

use strict;
use warnings;
use FindBin;

BEGIN {
    $^W = 1;
    require lib;
    "lib"->import($FindBin::Bin);
};

use TestDrive qw($tmp_dir $bin_dir slurp work_area);

use Test::More tests => 2;

sub check {
    # Normally I would put the local inside the open, but this also counts as
    # the second use to avoid a warning
    local *OLDERR;
    open(*OLDERR, ">&STDERR") || die "Can't dup STDERR: $!";
    open(STDERR, ">", "$tmp_dir/stderr") ||
        die "Can't open $tmp_dir/stderr: $!";
    my $rc = system($^X, "-c", @_);
    open(STDERR, ">&OLDERR")        || die "Can't dup OLDERR: $!";
    my $errors = slurp("$tmp_dir/stderr");
    $errors =~ s/.* syntax OK\n//;
    if ($errors ne "") {
        diag($errors);
        return 1;
    }
    return $rc;
}

work_area();
for my $file qw(release_pm makeppd.pl) {
    ok(!check("$bin_dir/$file"), "Can compile $file");
}
