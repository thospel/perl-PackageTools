#!/usr/bin/perl -wT
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl -T 03_base.t'
#########################
# $Id: 02_any_to_blib.t 4228 2010-10-04 14:58:06Z hospelt $
## no critic (ProhibitUselessNoCritic ProhibitMagicNumbers)
use strict;
use warnings;

our $VERSION = "1.000";

BEGIN {
    $^W = 1;
    use FindBin;
    use lib;
    # Untaint (otherwise some versions of Carp::croak will fail)
    $FindBin::Bin =~ m{^(.*?)/*\z}s;
    lib->import($1);	## no critic (ProhibitCaptureWithoutTest)
};

use TestDrive qw(ENOENT ESTALE 
                 $t_dir $tmp_dir $base_dir
                 work_area perl_run slurp diff);

use Test::More "no_plan";

my $test_dir = "$t_dir/any_to_blib";
eval {
    opendir(my $dh, $test_dir) || die "Could not opendir '$test_dir': $!";
    my @files = sort map /^(.*\.(?:in|tmpl)\z)/ ? $1 : (), readdir($dh);
    closedir($dh) || die "Could not closedir '$test_dir': $!";

    work_area();

    is(@files, 2, "Proper number of tests");

    my $program = "$base_dir/blib/script/any_to_blib";
    for my $file (@files) {
        my @run = ($program, "--base_dir" => $test_dir, "--to_dir" => $tmp_dir, $file);
        my $err = perl_run(@run);
        is($err,
           "filter(any_to_blib) $test_dir/$file >$tmp_dir/$file\n",
           "Expect no STDERR from '@run'");
        opendir(my $dh, $tmp_dir) || die "Could not opendir '$tmp_dir': $!";
        my @out_files = map -f "$tmp_dir/$_" ? /(.*)/s && $1 : (), readdir($dh);
        closedir($dh) || die "Could not closedir '$tmp_dir': $!";
        is(@out_files, 1, "Expect 1 output file (@out_files)");
        if (@out_files == 1) {
            my $got_out = slurp("$tmp_dir/$out_files[0]");
            my $f = $file;
            $f =~ s/\.in\z|\z/.out/;
            my $expect_out = slurp("$test_dir/$f");
            diff($got_out, $expect_out, "Ecepected output");
        }
        unlink("$tmp_dir/$_") || $! == ENOENT || $! == ESTALE || die "Could not unlink '$tmp_dir/$_': $!" for @out_files;
    }
};
chdir($base_dir) || die "Could not change back to '$base_dir': $!";
die $@ if $@;
