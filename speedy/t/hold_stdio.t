# Test#1
# If backend forks a backend that holds onto stdio, we should still be
# able to exit when the backend exits, not when stdio closes

# Test#2
# If we continue to hold onto the piope, we should eventually get the
# output from the child on it too, even after parent exits

my $TMP = "/tmp/hold_stdio.$$";

sub adios { my $ok = shift;
    unlink($TMP);
    print ($ok ? "ok\n" : "failed\n");
    exit;
}

print "1..2\n";
$SIG{ALRM} = sub {&adios(0)};
alarm(5);

# Test1
system("$ENV{SPEEDY} t/scripts/hold_stdio 2 >$TMP");
if (`cat $TMP` eq "ok\n") {
    print "ok\n";
    
    # Test #2
    sleep(3);
    &adios(`cat $TMP` eq "ok\nchild\n");
}
