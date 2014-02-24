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
  template 'tasting', { beer => 0 };
};

post '/tasting' => sub {
  if (my $name = param('name')) {
    my $beer = param('beer') || 0;

    if ($beer > 0 and $beer <= 4) {
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

    template 'tasting', { name => $name, beer => $beer, notes => \%notes };
  } else {
    template 'tasting', { beer => 0 };
  }
};

get '/rankings' => sub {
  my $sth = database->prepare(
    q{
    SELECT
      beer,
      avg(appearance), avg(smell), avg(taste),
      avg(aftertaste), avg(drinkability)
    FROM notes
    GROUP BY beer
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

  # Manually enter names for now
  $beers{1}{name} = 'Lady Time';
  $beers{2}{name} = 'Black As Your Soul';
  $beers{3}{name} = 'Vanilla Porter';
  $beers{4}{name} = 'Note Doge';

  # $beers{5}{name} = 'Hoffert';

  my @scores = reverse sort { $a->{total} <=> $b->{total} } values %beers;

  template 'rankings', { scores => \@scores };
};

any qr/.*/ => sub {
  template 'index';
};

true;
