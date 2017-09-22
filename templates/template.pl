#!/opt/local/bin/perl -w
# -----------------------------------------------------------------------------
# $Id: template.pl 6 2012-06-11 20:27:11Z stefan $
# -----------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Europa-Strasse 5, 8152 Glattbrugg, Switzerland
# -----------------------------------------------------------------------------
# Name.......: template
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: $LastChangedBy: stefan $
# Date.......: $LastChangedDate: 2012-06-11 22:27:11 +0200 (Mon, 11 Jun 2012) $
# Revision...: $LastChangedRevision: 6 $
# Purpose....: Module to process commandline arguments for template
# Notes......: See pod text below or perldoc template
# Reference..: --
# -----------------------------------------------------------------------------
# Modified :
# see SVN revision history for more information on changes/updates
# svn log lib/TVD/Backup/Light.pm
# TODO Create Test procedure for Package
# -----------------------------------------------------------------------------
package template;

require 5.008_001;    # Define Perl 5.8.1 as min required perl

use strict;
use warnings;
use English;          # English names for ugly punctuation vars
use Getopt::Long;
use Log::Log4perl qw(:easy);           # Load Log4perl, logging must be enabled
                                       # in main else the module remains quiet
our $VERSION = '0.0.1';


__END__

=head1 NAME

<application name> – <One-line description of application's purpose>

=head1 VERSION

This documentation refers to <application name> version 0.0.1.

$Revision: 6 $ $Date: 2012-06-11 22:27:11 +0200 (Mon, 11 Jun 2012) $

=head1 USAGE

    # Brief working invocation example(s) here showing the most common usage(s)
    # This section will be as far as many users ever read,
    # so make it as educational and exemplary as possible.

=head1 REQUIRED ARGUMENTS

A complete list of every argument that must appear on the command line.
when the application  is invoked, explaining what each of them does, any
restrictions on where each one may appear (i.e., flags that must appear
before or after filenames), and how the various arguments and options
may interact (e.g., mutual exclusions, required combinations, etc.)

If all of the application's arguments are optional, this section
may be omitted entirely.

=head1 OPTIONS

A complete list of every available option with which the application
can be invoked, explaining what each does, and listing any restrictions,
or interactions.

If the application has no options, this section may be omitted entirely.

=head1 DESCRIPTION

A full description of the application and its features.
May include numerous subsections (i.e., =head2, =head3, etc.).

=head1 EXAMPLES

Many people learn better by example than by explanation, and most learn better 
by a combination of the two. Providing a /demo directory stocked with well
commented examples is an excellent idea, but your users might not have access 
to the original distribution, and the demos are unlikely to have been installed 
for them. Adding a few illustrative examples in the documentation itself can 
greatly increase the “learnability” of your code.

=head1 DIAGNOSTICS

A list of every error and warning message that the application can generate
(even the ones that will "never happen"), with a full explanation of each
problem, one or more likely causes, and any suggested remedies. If the
application generates exit status codes (e.g., under Unix), then list the exit
status associated with each error.

=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the application,
including the names and locations of any configuration files, and the
meaning of any environment variables or properties that can be set. These
descriptions must also include details of any configuration language used.
(See also “Configuration Files” in Chapter 19.)

=head1 DEPENDENCIES

A list of all the other modules that this module relies upon, including any
restrictions on versions, and an indication of whether these required modules 
are part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.

=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for
system or program resources, or due to internal limitations of Perl
(for example, many modules that use source code filters are mutually
incompatible).

=head1 FREQUENTLY ASKED QUESTIONS

Incorporating a list of correct answers to common questions may seem like extra 
work (especially when it comes to maintaining that list), but in many cases it 
actually saves time. Frequently asked questions are frequently emailed 
questions, and you already have too much email to deal with. If you find 
yourself repeatedly answering the same question by email, in a newsgroup, on a 
web site, or in person, answer that question in your documentation as well. 
Not only is this likely to reduce the number of queries on that topic you 
subsequently receive, it also means that anyone who does ask you directly can 
simply be directed to read the fine manual.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to <Stefan Oehrli> (<stefan.oehrli at trivadis.com>) or 
<Toolbox Support> (<tvd_toolsupport at trivadis.com>).
Patches are welcome.

=head1 SEE ALSO

Trivadis Toolbox Home Page L<https://intranet.trivadis.com/wiki/bin/view/BDS/TvdToolbox>, 
Trivadis Toolbox (Know-how home) L<https://intranet.trivadis.com/wiki/bin/view/TechnicalKnowHow/ToolboxKnowHowHome>,
Trivadis Database Tools L<https://www.trivadis.com/produkte/datenbank-tools>

=head1 ACKNOWLEDGEMENTS

There are currently no acknowledgements

=head1 AUTHOR

<Stefan Oehrli> (<stefan.oehrli at trivadis.com>)

=head1 LICENCE AND COPYRIGHT

Copyright 2012 Trivadis AG (<toolbox at trivadis.com>). All rights reserved.

This program is part of the Trivadis Toolbox software; you can redistribute 
it and/or modify it under the terms of the Trivadis Toolbox License.

See Trivadis Database Tools L<http://www.trivadis.com/produkte/datenbank-tools> 
for more information.
