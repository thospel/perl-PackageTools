#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 02_makeppd_ppm3.t'
#########################
# $Id: 02_makeppd_ppm3_4.t 4156 2010-06-23 14:27:34Z hospelt $
our $VERSION = "1.002";

use strict;
use warnings;
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
                   "--ppm_version=4",
                   "--prerequisite", "Foo::Bloz=1.03",
                   "LogParse_ppm3.ppd");
like($err,
     qr{^\t\Q$tar -czf $tmp_dir/LogParse/ppm/Any/LogParse-1.001.tar.gz --exclude "blib/man*" -C $tmp_dir/LogParse/ blib\E\n\t\Q$zip -r foo .\E\n\z},
     "Expected output");
diff(slurp("$tmp_dir/LogParse/ppm/LogParse_ppm3.ppd"),
     <<"EOF", "Expected generated ppd");
<SOFTPKG NAME="LogParse" VERSION="1,001,0,0">
    <TITLE>LogParse</TITLE>
    <ABSTRACT>Baseclass for logfile parsers</ABSTRACT>
    <AUTHOR>Ton Hospel &lt;LogParse\@ton.iguana.be&gt;</AUTHOR>
    <IMPLEMENTATION>
        <PROVIDE NAME="LogParse" VERSION="1.002" />
        <PROVIDE NAME="LogParse::Attributes" VERSION="1.000" />
        <PROVIDE NAME="LogParse::Info" VERSION="1.000" />
        <PROVIDE NAME="LogParse::Package" VERSION="1.006" />
        <PROVIDE NAME="LogParse::Record" VERSION="1.001" />
        <PROVIDE NAME="LogParse::State" VERSION="1.000" />
        <PROVIDE NAME="LogParse::Transaction" VERSION="1.001" />
        <PROVIDE NAME="LogParse::Transaction::Record" VERSION="1.001" />
        <PROVIDE NAME="LogParse::Info::Record" VERSION="1.000" />
        <REQUIRE NAME="Foo::Bloz" VERSION="1.03" />
        <REQUIRE NAME="MURI" VERSION="1.33" />
        <REQUIRE NAME="Bar::Baz" VERSION="1.06" />
        <CODEBASE HREF="Any/LogParse-1.001.tar.gz" />
    </IMPLEMENTATION>
</SOFTPKG>
EOF
