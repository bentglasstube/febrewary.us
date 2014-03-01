package Febrewary;

use strict;
use warnings;
use lib 'lib';

use Dancer ':syntax';
use Dancer::Plugin::Database;

use List::Util 'sum';

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
  template 'tasting', {
    beer       => 0,
    beer_count => database->quick_count('beers', {}),
    };
};

post '/tasting' => sub {
  if (my $name = param('name')) {
    my $beer = param('beer') || 0;

    if ($beer > 0 and $beer <= 5) {
      my $sth = database->prepare(
        q{
        INSERT OR REPLACE INTO notes (
          name, beer,
          appearance, smell, taste,
          aftertaste, drinkability,
          notes
        ) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?)
      }
      );

      $sth->execute($name, $beer,
        param('appearance'), param('smell'), param('taste'),
        param('aftertaste'), param('drinkability'), param('notes'));
    } else {

      # TODO check if name already submitted
    }

    my $action = lc(param('action') || 'next');

    $beer++ if $action eq 'next';
    $beer-- if $action eq 'previous';

    my @notes = database->quick_select('notes', { name => $name });
    my %notes = map { $_->{beer} => $_ } @notes;

    template 'tasting', {
      name       => $name,
      beer       => $beer,
      notes      => \%notes,
      beer_count => database->quick_count('beers', {}),
      };
  } else {
    template 'tasting', {
      beer       => 0,
      beer_count => database->quick_count('beers', {}),
      };
  }
};

get '/rankings' => sub {
  my $sth = database->prepare(
    q{
    SELECT
      beers.name,
      avg(notes.appearance), avg(notes.smell), avg(notes.taste),
      avg(notes.aftertaste), avg(notes.drinkability)
    FROM beers
    INNER JOIN notes ON notes.beer = beers.id
    GROUP BY beers.id
    }
  );
  $sth->execute();

  my %beers = ();
  my @keys  = qw(appearance smell taste aftertaste drinkability);
  while (my ($beer, @data) = $sth->fetchrow_array()) {
    @{ $beers{$beer} }{@keys} = @data;
    $beers{$beer}{total} = sum(@data) || 0;

    debug("Total is $beers{$beer}{total}");
  }

  my @scores = reverse sort { $a->{total} <=> $b->{total} } values %beers;

  template 'rankings', { scores => \@scores };
};

get '/beers' => sub {
  my @beers = database->quick_select('beers', {});

  template 'beers', { beers => \@beers };
};

post '/beers' => sub {
  database->quick_insert(
    'beers', {
      name        => param('name'),
      style       => param('style'),
      description => param('description'),
      brewer      => param('brewer'),
    });

  redirect '/beers', 301;
};

any qr/.*/ => sub {
  template 'index';
};

true;
