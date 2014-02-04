package Febrewary;

use strict;
use warnings;
use lib 'lib';

use Dancer ':syntax';
use Dancer::Plugin::Database;

our $VERSION = '0.1';

get '/' => sub {
  template 'index';
};

get '/guests' => sub {
  my $rsvps = [ database->quick_select('rsvp', {}) ];
  my $sum = 0;
  map { $sum += $_->{guests} } @$rsvps;

  template 'guests', { rsvps => $rsvps, sum => $sum };
};

post '/guests' => sub {
  if (param('name')) {
    database->quick_insert(
      rsvp => {
        name   => param('name'),
        guests => param('count') || 1,
        email  => param('email') || '',
        time   => time,
      });
  }

  redirect '/guests', 301;
};

any qr/.*/ => sub {
  template '404';
};

true;
