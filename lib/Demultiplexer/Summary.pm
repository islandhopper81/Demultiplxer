package Demultiplexer::Summary;

use warnings;
use strict;
use Carp;
use Readonly;
use Class::Std::Utils;
use List::MoreUtils qw(any);
use Log::Log4perl qw(:easy);
use Log::Log4perl::CommandLine qw(:all);
use MyX::Generic;
use UtilSY qw(:all);
use version; our $VERSION = qv('0.0.1');
use base qw(DataObj);

# set up the logging environment
my $logger = get_logger();

{
	# Usage statement
	Readonly my $NEW_USAGE => q{ new()};

	# Attributes #
	
	# Getters #

	# Setters #

	# Others #
	sub increment_feature;



	###############
	# Constructor #
	###############
	sub new {
		my ($class, $arg_href) = @_;

		# Croak if calling new on already blessed reference
		croak 'Constructor called on existing object instead of class'
			if ref $class;

		# Make sure the required parameters are defined
		if ( any {!defined $_}
				
			) {
			MyX::Generic::Undef::Param->throw(
				error => 'Undefined parameter value',
				usage => $NEW_USAGE,
			);
		}

		# Bless a scalar to instantiate an object
		my $new_obj = $class->SUPER::new($arg_href);

		# Set Attributes

		return $new_obj;
	}

	###########
	# Getters #
	###########

	###########
	# Setters #
	###########

	##########
	# Others #
	##########
	sub increment_feature {
		my ($self, $feature) = @_;
		
		my $val = $self->SUPER::get_feature($feature);
		if ( ! defined $val ) {
			$val = 0;
		}
		
		$self->SUPER::set_feature($feature, $val + 1);
		
		return 1;
	}
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Demultiplexer::Summary - DataObj containing summary count numbers


=head1 VERSION

This document describes Demultiplexer::Summary version 0.0.1


=head1 SYNOPSIS

    use Demultiplexer::Summary;
	my $summary = Demultiplexer::Summary->new();
	
	# set a new feature to one
	$summary->set_feature("feat1", 1);
	# OR
	$summary->increment_feature("feat1");
	
	# increment the feature count
	$summary_increment_feature("feat1");
  
=head1 DESCRIPTION

This object holds the summary number about how the demultiplexing went.  It has
counts for things like number of good and bad sequences.


=head1 CONFIGURATION AND ENVIRONMENT
  
Demultiplexer::Summary requires no configuration files or environment variables.


=head1 DEPENDENCIES

Carp
Readonly
Class::Std::Utils
List::MoreUtils qw(any)
Log::Log4perl qw(:easy)
Log::Log4perl::CommandLine qw(:all)
MyX::Generic
version; our $VERSION = qv('0.0.1')
UtilSY qw(:all)
DataObj


=head1 INCOMPATIBILITIES

None reported.


=head1 METHODS

=over

	new
	increment_feature
	# and other methods from parent class (DataObj)

=back

=head1 METHODS DESCRIPTION

=head2 new

	Title: new
	Usage: Demultiplexer::Summary->new();
	Function: Returns new Demultiplexer::Summary object
	Returns: Demultiplexer::Summary
	Args: NA
	Throws: NA
	Comments: Demultiplexer::Summary is a child class of DataObj
	See Also: DataObj
	
=head2 increment_feature

	Title: increment_feature
	Usage: $obj->increment_feature($feature)
	Function: increments count on a given feature
	Returns: 1 on success
	Args: -feature => name of feature of which to increment
	Throws: MyX::Generic::Undef::Param
	Comments: if there is not feature in the summary named $feature a new one is
	          created and the count is set to 1
	See Also: NA


=head1 BUGS AND LIMITATIONS

No bugs have been reported.


=head1 TO DO

None

=head1 AUTHOR

Scott Yourstone  C<< scott.yourstone81@gmail.com >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Scott Yourstone
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met: 

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer. 
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies, 
either expressed or implied, of the FreeBSD Project.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

