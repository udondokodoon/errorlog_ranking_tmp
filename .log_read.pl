use strict;
use warnings;

#binmode STDOUT, ":utf8";


while(<>) {
  my %cols = map {my @a = split/:/, $_; (shift @a, join(":", @a))} split /\t/, $_;
  local $_ = $cols{request};
  /POST/ and next; 
  s/GET \/error\/js\?json=//;
  s/HTTP\/1.1//g;
  s/\+/ /g;
  s/%([0-9a-fA-F]{2})/pack("H2",$1)/eg;
  print "$_\n";
}
