package Febrewary;

use strict;
use warnings;
use lib 'lib';

use Dancer ':syntax';

our $VERSION = '0.1';

get '/' => sub {
  template 'index';
};

get '/rsvp' => sub {
  template 'rsvp';
};

post '/rsvp' => sub {
  # TODO save shit
  template 'thanks';
};

any qr/.*/ => sub {
  template '404';
};

true;
