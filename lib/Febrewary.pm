package Febrewary;

use strict;
use warnings;
use lib 'lib';

use Dancer ':syntax';
use Dancer::Plugin::Database;

use List::Util 'sum0';

our $VERSION = '0.1';

sub get_beer {
  my ($id) = @_;

  my $beer = database->quick_select('beers', { id => $id }) or return undef;
  my @notes = database->quick_select('notes', { beer => $id });

  my $count = 0;
  my @attrs = qw(appearance smell taste aftertaste drinkability);

  foreach my $note (@notes) {
    $count++;
    $beer->{$_} += $note->{$_} for @attrs;
    if ($note->{notes}) {
      $beer->{notes} ||= [];
      push @{$beer->{notes}}, $note->{notes};
    }
  }

  $beer->{$_} /= $count for @attrs;

  # weighted total score
  $beer->{total} =
    1 * $beer->{appearance} +
    1 * $beer->{smell} +
    3 * $beer->{taste} +
    2 * $beer->{aftertaste} +
    3 * $beer->{drinkability};

  return $beer;
}

sub get_all_beers {
  return map get_beer($_), 1 .. 5;
}

get '/' => sub {
  # party is over so show results
  redirect '/results';
};

=ignore

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

=cut

get '/beers' => sub {
  my @beers = get_all_beers;
  template 'beers', { beers => \@beers };
};

=ignore
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
=cut

get '/beers/:id' => sub {
  my $beer = get_beer(param('id')) or redirect '/beers';
  template 'beer', { beer => $beer };
};

get '/results' => sub {
  my @beers = reverse sort { $a->{total} <=> $b->{total} } get_all_beers;
  template 'postmortem', { beers => \@beers };
};

any qr/.*/ => sub {
  redirect '/';
};

true;
