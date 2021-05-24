# NAME

release\_pm - Automatically update version information on files and packages

# SYNOPSIS

```
release_pm --initial [version] [--digits natural] [--import_version] [--import_revision] [--start_version version] [--vcs_check]
release_pm [--import_version] [--import_revision] [--start_version version] [--vcs_check]
release_pm [--vcs_check] --next
release_pm [-U] [--unsafe] --help
release_pm --version
```

# DESCRIPTION

....

Files it does special things for:

- deep MANIFESTs

    If a subdirectory contains a `MANIFEST` file that is mentioned in the top level
    `MANIFEST` its content is replaced by the files in the top level `MANIFEST`
    file that fall within this subdirectory but with the subdirectory name removed.

    If for example your top level MANIFEST contains:

    ```
    foo
    bar/baz
    baz
    bar/MANIFEST
    ```

    then after running release\_pm the file `bar/MANIFEST` will contain

    ```
    baz
    MANIFEST
    ```

- MANIFEST.SKIP

    Add several default entries so you don't accidentially forget them

- deep Makefile.PLs

    Replacements are the same as for a top level Makefile.PL but no code
    to set values in %postamble is generated

# OPTIONS

- --import\_revision

    Get the initial version of a file from any `$Revision` tag that's already in
    there. Such tags are written by source control programs like [cvs](http://man.he.net/man1/cvs),

- --import\_version

    Get the initial version of a file from any VERSION value that's already in there

- --digits natural

    How many digits to use in version numbers. Defaults to 3. This means that by
    default the first version of anything is `1.000`, the next is `1.001` etc.

- --initial \[version\]

    Start a new package. Optionally gives the first version number of the package
    (defaults to 1). The version will be expanded to the requested number of
    [digits](#option_digits).

- --start\_version version

    Gives the first version number that is assigned to new files. It will be
    expanded to the requested number of [digits](#option_digits)

    Defaults to 1.

- --next

    Start a new release. The package version is increased. Releasing a package
    typically consists of:

    ```
    # Bring all package versions up to date
    release_pm

    # Make the actual release
    make dist
    # possibly make a copy into some source control system
    # put your package on CPAN etc.

    # Prepare for the next development cycle
    release_pm --next
    ```

    The [--next](#next) option is used just **after** releasing a new version of
    your package and updates the package version for the next release. From this
    point on your working directory is in preparation for the next release and as
    you edit and add files each run of of `release_pm` will update the version
    numbers of these files until finally you are ready to make the next release.

    If it turns out there is a problem with your released version normally you will
    make a new release with all the fixes and a new package version number so that
    people that got the buggy version can recognize this from the package version
    and upgrade. But sometimes you may decide that you want to fix the released
    package and make a new distribution instead. You however don't want your working
    copy to reuse file version numbers from the fixed release. In that case you can
    work like this:

    ```
    # Go to the working directory for your released package
    cd released

    # Do all fixes that are needed

    # Bring all package versions up to date
    release_pm

    # Make the actual release
    make dist
    # possibly make a copy into some source control system
    # put your package on CPAN etc.

    # Now go the working directory with the development version
    cd ../development

    # Copy the md5-versions file from the released version
    cp ../released/md5-versions .

    # Due to the copy you are now back in the released package version
    # Switch back to the development package version and notice all changed files
    release_pm --next
    ```

- --vcs\_check, --novcs\_check

    If this option is true the program will looks for special version control system
    directives like `$HeadURL` or `$Id` in all files and checks that their values
    match with the filename. If not it prints a warning. The warning means that
    you probably forgot to activate the directives in your version control system
    (or never submitted the files yet).

    The given setting is written to the `md5-versions` file and becomes the default
    for further calls.

    Initial Default is true, from then on the default comes from the md5-versions
    file.

- --version

    Show the the program version.

- --unsafe, -U

    Allows you to run [--help](#option_help) even as root. Notice that this implies
    you are trusting this program and the perl installation.

- --help, -h

    Show this help.

# SEE ALSO

[cvs](http://man.he.net/man1/cvs),
[makeppd.pl](https://metacpan.org/pod/makeppd.pl)

# AUTHOR

Ton Hospel, &lt;release\_pm@ton.iguana.be>

# COPYRIGHT AND LICENSE

Copyright (C) 2007 by Ton Hospel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.
