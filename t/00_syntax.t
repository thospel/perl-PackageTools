#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 00_syntax.t'
#########################
# $Id: 00_syntax.t 2678 2007-12-12 16:05:15Z hospelt $
our $VERSION = "1.000";

use strict;
use warnings;
use Carp;
use Errno qw(ENOENT ESTALE);
BEGIN { $^W = 1 };

use Test::More tests => 2;
use FindBin qw($Bin);

my $t_dir;
BEGIN {
    require lib;
    $t_dir = $FindBin::Bin;
    "lib"->import($t_dir);
}

use File::Temp qw(tempdir);
my $tmpdir = tempdir(CLEANUP => 1);

# Import a complete file and return the contents as a single string
sub slurp {
    my ($file, $may_not_exist) = @_;
    croak "filename is undefined" if !defined $file;
    open(my $fh, "<", $file) or
        $may_not_exist && ($! == ENOENT || $! == ESTALE) ?
	return undef : croak "Could not open '$file': $!";
    my $rc = read($fh, my $slurp, 1024 + -s $fh);
    croak "File '$file' is still growing" if
        $rc &&= read($fh, $slurp, 1024, length $slurp);
    croak "Error reading from '$file': $!" if !defined $rc;
    close($fh) || croak "Error while closing '$file': $!";
    return $slurp;
}

sub check {
    local *OLDERR;
    open(OLDERR, ">&STDERR") || die "Can't dup STDERR: $!";
    open(STDERR, ">", "$tmpdir/stderr") || die "Can't open $tmpdir/stderr: $!";
    my $rc = system($^X, "-c", @_);
    open(STDERR, ">&OLDERR")        || die "Can't dup OLDERR: $!";
    my $errors = slurp("$tmpdir/stderr");
    $errors =~ s/.* syntax OK\n//;
    if ($errors ne "") {
        diag($errors);
        return 1;
    }
    return $rc;
}

$Bin =~ s!/t/?\z!/bin! || die "No /t at end of $Bin";
for my $file qw(release_pm makeppd.pl) {
    ok(!check("$Bin/$file"),		"Can compile $file");
}
