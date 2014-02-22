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

get '/tasting' => sub {
  template 'tasting', { beer => 0 };

};

post '/tasting' => sub {
  if (my $name = param('name')) {
    my $beer = param('beer') || 0;

    if ($beer > 0 and $beer <= 4) {
      my $sth = database->prepare(q{
        INSERT OR REPLACE INTO notes (
          name, beer,
          appearance, smell, taste,
          aftertaste, drinkability,
          notes
        ) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?)
      });

      $sth->execute(
        $name, $beer,
        param('appearance'), param('smell'), param('taste'),
        param('aftertaste'), param('drinkability'),
        param('notes')
      );
    } else {
      # TODO check if name already submitted
    }

    my $action = lc(param('action') || 'next');

    $beer++ if $action eq 'next';
    $beer-- if $action eq 'previous';

    my @notes = database->quick_select('notes', { name => $name });
    my %notes = map { $_->{beer} => $_ } @notes;

    template 'tasting', { name => $name, beer => $beer, notes => \%notes };
  } else {
    template 'tasting', { beer => 0 };
  }
};

any qr/.*/ => sub {
  template 'index';
};

true;
