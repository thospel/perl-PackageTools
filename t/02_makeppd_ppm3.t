#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 02_makeppd_ppm3.t'
#########################
# $Id: 02_makeppd_ppm3.t 4213 2010-09-27 00:52:37Z hospelt $
## no critic (ProhibitUselessNoCritic ProhibitMagicNumbers)
use strict;
use warnings;

our $VERSION = "1.002";

use FindBin;

BEGIN {
    $^W = 1;
    require lib;
    "lib"->import($FindBin::Bin);
};

use TestDrive
    qw($base_dir $bin_dir $t_dir $tmp_dir $tar $zip
       work_area perl_run diff slurp);

use Test::More "no_plan";

work_area("copy", "$t_dir/makeppd/LogParse",
          programs => 1);
my $err = perl_run("$bin_dir/makeppd.pl",
                   "--root", "$tmp_dir/LogParse",
                   "--leave", "$tmp_dir/LogParse/ppm",
                   "--prerequisite", "Foo::Bloz=1.03",
                   "LogParse_ppm3.ppd");
like($err,
     qr{^\t\Q$tar -czf $tmp_dir/LogParse/ppm/Any/LogParse-1.001.tar.gz --exclude "blib/man*" -C $tmp_dir/LogParse/ blib\E\n\t\Q$zip -r foo .\E\n\z},
     "Expected output");
diff(slurp("$tmp_dir/LogParse/ppm/LogParse.ppd"),
     <<"EOF", "Expected generated ppd");
<SOFTPKG NAME="LogParse" VERSION="1,001,0,0">
    <TITLE>LogParse</TITLE>
    <ABSTRACT>Baseclass for logfile parsers</ABSTRACT>
    <AUTHOR>Ton Hospel &lt;LogParse\@ton.iguana.be&gt;</AUTHOR>
    <IMPLEMENTATION>
        <DEPENDENCY NAME="Foo-Bloz" VERSION="1,03,0,0" />
        <DEPENDENCY NAME="MURI" VERSION="1,33,0,0" />
        <DEPENDENCY NAME="Bar-Baz" VERSION="1,06,0,0" />
        <CODEBASE HREF="Any/LogParse-1.001.tar.gz" />
    </IMPLEMENTATION>
</SOFTPKG>
EOF
