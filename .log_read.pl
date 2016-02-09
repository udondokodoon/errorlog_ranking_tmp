use strict;
use warnings;

binmode STDOUT, ":utf8";


while(<>) {
  s/@/\\@/g;
  eval(sprintf q{print "%s"}, $_);
}
