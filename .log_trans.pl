use strict;
use warnings;

use utf8;
binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

use Digest::MD5 qw/md5_hex/;
use Data::Dumper;

use Time::Piece;

use JSON;
#my $json = JSON->new->pretty->canonical;
my $json = JSON->new;
my @data;
while(<>) {
  /^-$/ and next;
  my $d = $json->utf8->decode($_);
  filter($d) or next;
  push @data, transform($d);
}
postload(\@data);

sub filter {
  my $d = shift;
  return 0 if ($d->{error}{text} and $d->{error}{text} =~ /_?override/);
  my $t = $d->{history}[0]->{time};
  eval {
    if ($t =~ /年/) {
      $t = Time::Piece->strptime($d->{history}[0]->{time}, "%Y年%m月%d日 %H:%M:%S");
    } elsif ($t =~ /^\d\/\d\/\d{4},/) {
      $t = Time::Piece->strptime($d->{history}[0]->{time}, "%d/%m/%Y, %H:%M:%S %p");
    } elsif ($t =~ /^\d-\d-\d{4}/) {
      $t = Time::Piece->strptime($d->{history}[0]->{time}, "%d-%m-%Y %H:%M:%S");
    } else {
      $t = Time::Piece->strptime($d->{history}[0]->{time}, "%Y-%m-%dT%H:%M:%S");
    }
  }; 
  if ($@) {
    warn "ignore timeformat $t: $@";
    return 0;
  }
  my $today = localtime;
  my $end = Time::Piece->strptime(sprintf("%s 13:00:00", $today->ymd), "%Y-%m-%d %H:%M:%S");
  my $start = localtime - 86400;
  $d->{time} = $t->strftime("%Y-%m-%d %H:%M:%S");
  return (0 < $t - $start && 0 <= $end - $t) ? 1 : 0;
}


sub transform {
  my $d = shift;
  my $location = $d->{status}{location};
  $location =~ s/\??(?:option).+$//;

  my $stack = $d->{error}{stack};
  $stack = [map {s/:\d+:\d+\)?$//; $_} @$stack];

  my $str = $json->encode([$location, $stack]);
  $str =~ s/\s//g;
  $d->{digest} = md5_hex($str);
  return $d;
}

sub postload {
  my $arr = shift;
  warn @$arr-0;

  my %u = ();
  foreach (@$arr) {
    if (!$u{$_->{digest}}) {
      $u{$_->{digest}} = {count=>0, record=>$_, digest=>$_->{digest}};
    }
    $u{$_->{digest}}->{count} = $u{$_->{digest}}->{count} + 1;
  } 

  foreach (sort {$b->{count} <=> $a->{count}} grep {filter2($_)} map {$u{$_}} keys %u) {
    print transform2($_);
  }
}

sub filter2 {
  my $d = shift;
  return 1 < $d->{count};
}

sub transform2 {
  my $d = shift;
  return sprintf "\%s\t%s\t%s\n", $d->{digest}, $d->{count}, $json->utf8(0)->encode($d);
  #$json->encode($_). "\n";
}
