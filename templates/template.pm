# -----------------------------------------------------------------------------
# $Id: template.pm 6 2012-06-11 20:27:11Z stefan $
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
require Exporter;     # only used for regular modules, can be
                      # removed for purely object-oriented module

use strict;
use warnings;
use English;          # English names for ugly punctuation vars
use Getopt::Long;
use Log::Log4perl qw(:easy);           # Load Log4perl, logging must be enabled
                                       # in main else the module remains quiet
use TVD::Utilities qw(:pod_helper);    # Module for POD usage, help and man
use base qw(Exporter);                 # define Exporter as parent class
our @EXPORT_OK = qw();                 # Stuff which can be exported
our %EXPORT_TAGS = ( usage  => [qw(sub1 sub2)],
                     legacy => [qw(sub3)] );

# Tags defined for the exporter
Exporter::export_tags('legacy');       # add sub3 to @EXPORT
Exporter::export_ok_tags('usage');     # add sub1 and sub2 to @EXPORT_OK

=head1 NAME

template - This is a template for a perl module.

=head1 VERSION

This documentation refers to <template> version 0.01

$Name: tvdbackup-10.05.final.a $
$Revision: 6 $ 
$Date: 2012-06-11 22:27:11 +0200 (Mon, 11 Jun 2012) $

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use <Module::Name>;
    # Brief but working code example(s) here showing the most common usage(s)
    # This section will be as far as many users bother reading,
    # so make it as educational and exemplary as possible.


=head1 DESCRIPTION

A full description of the module and its features.
May include numerous subsections (i.e., =head2, =head3, etc.).

=head2 The configuration file format

=head2 Inherited methods

The following methods are used in the context of C<TVD::Configuration> and 
are inherited from L<ConfigReader::Simple>. For more methods see 
L<ConfigReader::Simple>

=head3 files

Return the list....


=head2 Package variables

=over 4

=item $ERROR

The last error message.

=item %ERROR

=back

=head1 SUBROUTINES/METHODS

A separate section listing the public components of the module's interface.
These normally consist of either subroutines that may be exported, or methods
that may be called on objects belonging to the classes that the module provides.
Name the section accordingly.

In an object-oriented module, this section should begin with a sentence of the
form "An object of this class represents...", to give the reader a high-level
context to help them understand the methods that are subsequently described.

=head2 METHODS

Use head2 or head3 to descrbe methods / subroutines depending your requirements

=head3 new ( FILENAMES, DIRECTIVES, OPTIONS)

Creates a C<TVD::Configuration> object.

C<FILENAME> is an optional argument ...

C<DIRECTIVES> is an optional...

C<OPTIONS>
The following options ...

=over 4

=item B<-UpperCase>

  -UpperCase => 1

If set to a true value, ...

=item B<-KeyPrefix>

  -KeyPrefix => 'CF_'
  
The specified prefix ...

=item B<-InterolateEnv>

  -InterolateEnv => 1

If set to a true value, ...

=back

The C<new> method overwrite C<new> from L<TVD::xyz>. 

=cut

sub subroutine1 { return "example" }

=head3 eg

Returns the string "example".

=cut

sub subroutine1 { return "example" }

=begin private

=over 4

=item parse_line ( STRING )

Internal method. Don't call this directly.

Takes a line of text and turns it into the directive and value.

=end private

=cut

sub private_subroutine {
    my ( $self, $line ) = @_;
    my $logger = $self->_get_logger();
    $logger->logcroak("Configuration: Can't parse line: $line");
}

=head1 DIAGNOSTICS

A list of every error and warning message that the module can generate
(even the ones that will "never happen"), with a full explanation of each
problem, one or more likely causes, and any suggested remedies.

Subroutine is tracing using log4perl. Log facility has to be enabled in main.

=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the module,
including the names and locations of any configuration files, and the
meaning of any environment variables or properties that can be set. These
descriptions must also include details of any configuration language used.

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

1;    # End of template
