#!/usr/bin/perl -w
# $Id: Makefile.PL 2792 2008-01-15 14:07:42Z hospelt $
use 5.008000;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config qw(%Config);

our $VERSION = '1.001';

# Allows to suppress all program installation with -n (library only)
use Getopt::Std;
our ($opt_n, $opt_y);
getopts("ny") || die "Usage: $0 [-n] [-y]\n";

my @programs_to_install;

if (!$opt_n || $opt_y) {
    print <<EOT

This package comes with a programs that I can try
to install in $Config{installscript}.

   Note that you can avoid this question by passing
   the '-n' or '-y' option to 'Makefile.PL'.

EOT
if !$opt_y;
    push @programs_to_install, "bin/release_pm" if
        $opt_y ||
        prompt("Install release_pm, a simple version manager ?", "y") =~ /^y/i;
    push @programs_to_install, "bin/makeppd.pl" if
        $opt_y ||
        prompt("Install makeppd.pl, a simple ppd generator ?", "y") =~ /^y/i;
}

WriteMakefile
    (NAME		=> 'PackageTools',
     VERSION_FROM	=> 'lib/PackageTools/Package.pm', # finds $VERSION
     PREREQ_PM		=> {
	 "Test::More"		=> "0.01",	# Only for the tests
     },
     ABSTRACT		=> 'lib/PackageTools.pm',
     AUTHOR		=> 'Ton Hospel <PackageTools@ton.iguana.be>',
     EXE_FILES		=> \@programs_to_install,
     $^O eq "MSWin32" ? (
         PM_FILTER	=> '$(PERL) -p -e1',
     ) : (),
     clean		=> {
         FILES => '$(DISTNAME).ppd ppm',
     },
     );

# Not generated through release_pm since we want to force the local makeppd.pl
package MY;
sub postamble {
    return shift->SUPER::postamble() . <<"EOF";
ppm: \$(DISTNAME).ppd

\$(DISTNAME).ppd: all ppd
	\$(PERL) bin/makeppd.pl "--zip=\$(ZIP)" "--tar=\$(TAR)" "--compress=\$(COMPRESS)" --leave=ppm \$(DISTNAME).ppd \$(VERSION)

ppm_install: \$(DISTNAME).ppd
	ppm install ppm/\$(DISTNAME).ppd

ppm_uninstall:
	ppm uninstall \$(DISTNAME)
EOF
}
