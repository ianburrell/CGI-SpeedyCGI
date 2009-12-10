# Make sure CGI's globals are reset between runs

print "1..1\n";

sub doit { my $pval = shift;
    my @return;

    if (open(F, "$ENV{SPEEDY} t/scripts/cgi_reset p=$pval |")) {
	@return = (map {chop; $_} <F>);
	close(F);
    }
    return @return;
}

my @v1 = &doit(20);
sleep 1;
my @v2 = &doit(30);

#print STDERR "v1=", join(',', @v1), " v2=", join(',', @v2), "\n";

print STDOUT ($v1[0] == 20 && $v2[0] == 30 && $v1[1] == $v2[1])
    ? "ok\n" : "failed\n";

