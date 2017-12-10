my $path = "www.google.com";
my %query = (name => 'maria', age => 26);

my $url = $path;
if (scalar (keys %query) > 0) {
    $url = $url . "?"
}
foreach my $queryParam (keys %query) {
    $url = $url . $queryParam . "=" . $query{$queryParam} . "&";
}

print "URL $url \n"