################################################################################
#
#  Copyright (c) 2017 dev0
#
#  This script is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  The GNU General Public License can be found at
#  http://www.gnu.org/copyleft/gpl.html.
#  A copy is found in the textfile GPL.txt and important notices to the license
#  from the author is found in LICENSE.txt distributed with these scripts.
#
#  This script is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  This copyright notice MUST APPEAR in all copies of the script!
#
################################################################################

# $Id: 99_j2r.pm 104 1970-01-101 00:00:00Z dev0 $

# release change log:
# ------------------------------------------------------------------------------
# 1.0  initial release
# 1.04 use InternalTimer to break out of FHEM's event loop detection

package main;

use strict;
use warnings;
use POSIX;

sub j2r_update($$;$$);

sub j2r_Initialize($$) {
  my ($hash) = @_;
  Log3($hash, 3, "99_j2r.pm v1.04 (re)loaded");
}

sub j2r($$) {
  my ($name,$event) = @_;
  if ( !defined $name || !defined $event ) {
    Log3 undef, 1, "j2r: Missing argument(s), usage: j2r(device, event)";
  }
  else {
    InternalTimer(gettimeofday()+0.01, "j2r_do", "$name,$event");
  }
  return undef;
}

sub j2r_do($) {
  my ($p) = @_;
  my ($name,$event) = split(",", $p, 2);

  if ( ref( $defs{$name} ) ne "HASH" ) {
    Log3 $name, 1, "j2r: WARNING: invalid device name";
    return undef;
  }

  my $hash = $defs{$name};
  my $type = $hash->{TYPE};
  my $j = ( split(": ", $event, 2) )[1];
  my $h;

  if ( not eval "use JSON; 1;" ) {
    Log3 $name, 1, "$type $name: WARNING: Perl modul JSON is not installed.";
    return undef;
  }

  eval { $h = decode_json($j); 1; };
  if ( $@ ) {
    Log3 $name, 2, "$type $name: WARNING: deformed JSON data, check your config.";
    Log3 $name, 2, "$type $name: $@";
    return undef;
  }

  readingsBeginUpdate($hash);
  j2r_update($hash,$h);
  readingsEndUpdate($hash, 1);

  return undef;
}

sub j2r_update($$;$$) {
  # thanx to bgewehr for this recursive snippet
  # https://github.com/bgewehr/fhem
  my ($hash,$ref,$prefix,$suffix) = @_;
  $prefix = "" if( !$prefix );
  $suffix = "" if( !$suffix );
  $suffix = "_$suffix" if( $suffix );

  if( ref( $ref ) eq "ARRAY" ) {
    while( my ($key,$value) = each @{ $ref } ) {
      j2r_update($hash,$value,$prefix.sprintf("%02i",$key+1)."_");
    }
  }
  elsif( ref( $ref ) eq "HASH" ) {
    while( my ($key,$value) = each %{ $ref } ) {
      if( ref( $value ) ) {
        j2r_update($hash,$value,$prefix.$key.$suffix."_");
      }
      else {
        (my $reading = $prefix.$key.$suffix) =~ s/[^A-Za-z\d_\.\-\/]/_/g;
        readingsBulkUpdate($hash, $reading, $value);
      }
    }
  }
}

1;
