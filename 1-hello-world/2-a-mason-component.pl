  #!/usr/bin/perl

  # run with "perl 2-a-mason-component.pl"
  
  use strict;
  use HTML::Mason;
  my $interp = HTML::Mason::Interp->new( );
  my $comp = $interp->make_component(comp_source => <<'END');
   Greetings, <% ("Earthlings", "Martians")[rand 2] %>
  END

  $interp->exec($comp);