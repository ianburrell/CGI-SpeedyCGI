
# Our test script consume only one line from stdin, and leaves the
# second line in the buffer.  If the buffer isn't cleared between
# perl runs, we'll see the buffered line on the second run.

print "1..1\n";

my $sp = "$ENV{SPEEDY} t/scripts/stdin";

# Send two lines to script on stdin.
open(S, "| $sp >/dev/null");
print S "line1\nline2\n";
close(S);

# See if we get the correct output next time, or if stdin was buffered.
open(S, "| $sp >/tmp/stdin.$$");
print S "line3\n";
close(S);

open(F, "</tmp/stdin.$$");
my $line = <F>;
print ($line eq "line3\n" ? "ok\n" : "fail\n");
close(F);

unlink("/tmp/stdin.$$");
