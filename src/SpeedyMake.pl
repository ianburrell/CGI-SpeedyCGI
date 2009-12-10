
#
# Object used in the various Makefile.PL's
#
#
# Copyright (C) 2001  Daemon Consulting Inc.
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
#

package SpeedyMake;

use Exporter;
@ISA = 'Exporter';
@EXPORT_OK = qw(@src_generated %write_makefile_common);

use strict;
use ExtUtils::MakeMaker;
use ExtUtils::Embed;
use Cwd;
use vars qw(@src_generated %write_makefile_common);

# Turn these off in the distribution
my $COVERAGE	= 0;	# Compile for coverage testing
my $PROFILING	= 0;	# Compile for profiling
my $DEVEL	= 0;	# Compile for gdb

# Options to produce warnings
my $WARNOPTS	= ' -pedantic -Wall ';

my $pwd = &pwd;
use vars qw($OPTIMIZE $LD_OPTS);

if ($COVERAGE) {
    $LD_OPTS	= ' -fprofile-arcs -ftest-coverage -O ';
    $OPTIMIZE	= $WARNOPTS .  $LD_OPTS .
		  '-DSPEEDY_PROFILING=\\\\\"`pwd`\\\\\"';
}
elsif ($PROFILING) {
    $LD_OPTS	= ' -pg -O ';
    $OPTIMIZE	= $WARNOPTS . $LD_OPTS .
		  '-DSPEEDY_PROFILING=\\\\\"`pwd`\\\\\"';
}
elsif ($DEVEL) {
    $OPTIMIZE	= $WARNOPTS . ' -g ';
}
else {
    # Force -O here, because otherwise on Sun they use odd OPTIMIZE flags
    # that make gcc fail.
    $OPTIMIZE	= '-O';
}

%write_makefile_common = (
    'OPTIMIZE'	=> $OPTIMIZE,
    'LINKTYPE'	=> ' ',
);

@src_generated = qw(
    speedy_optdefs.h speedy_optdefs.c mod_speedycgi_cmds.c SpeedyCGI.pm
);

sub init { my $class = shift;
    foreach my $method (qw(makeaperl postamble)) {
	eval "package MY; sub $method { $class->$method(\@_); }";
    }
    return $class;
}

sub am_frontend {1}

sub pwd {
    return &Cwd::cwd;
}

sub my_name { die; }

sub my_name_full { my $class = shift;
    $class->prefix . $class->my_name;
}

sub prefix {'speedy_'}

sub default_inc {'perl'}

sub inc {shift->default_inc}

sub main_file {
    shift->my_name_full . '_main';
}

sub main_file_full {
    shift->main_file;
}

sub main_h { shift->main_file_full }

sub src_files { my $class = shift;
    (
	$class->src_files_extra,
	qw(
	    util
	    frontend
	    backend
	    file
	    slot
	    poll
	    ipc
	    group
	    script
	    opt
	    optdefs
	),
    );
}

sub src_files_extra { (); }

sub src_files_full { my $class = shift;
    (
	$class->main_file_full,
	$class->src_files_full_extra,
	$class->add_prefix($class->prefix, $class->src_files),
    );
}

sub src_files_full_extra { (); }

sub src_files_c { my $class = shift;
    (
	$class->add_suffix('.c', $class->src_files_full),
	$class->src_files_c_extra,
    );
}

sub src_files_c_extra { (); }

sub src_files_o { my $class = shift;
    (
	$class->add_suffix('.o', $class->src_files_full),
	$class->src_files_o_extra,
    );
}

sub src_files_o_extra { (); }

sub src_files_h {my $class = shift;
    $class->add_suffix('.h', $class->src_files_full);
}

sub allinc { (<../src/*.h>) }

sub symlink_cmds { my $class = shift;
    return join('', map {
	sprintf("%s: ../src/%s speedy.h\n\t\$(RM_F) %s\n\t\$(CP) ../src/%s %s\n\n",
	    ($_) x 5
	);
    } @_);
}

sub symlink_c_files { my $class = shift;
    $class->symlink_cmds($class->src_files_c);
}

sub make_speedy_h { my $class = shift;
    my($pre, $inc, $main) = (
	$class->prefix, $class->inc, $class->main_h
    );
    open(F, ">speedy.h") || die;
    foreach ("${pre}inc_${inc}", "${pre}inc", $main) {
	print F "#include \"$_.h\"\n";
    }
    close(F);
}

sub optdefs_cmds { my($class, $dir) = @_;
    $dir ||= '../src';
    my $gen = join(' ', map {"$dir/$_"} @src_generated);
    "
${gen}: $dir/Makefile $dir/SpeedyCGI.src $dir/optdefs
	cd $dir && \$(MAKE)

$dir/Makefile: $dir/Makefile.PL
	cd $dir && \$(PERL) Makefile.PL
    ";
}

sub extra_defines { my $class = shift;
    join(' ',
	"-DSPEEDY_PROGNAME=\\\"" . $class->my_name_full . "\\\"",
	"-DSPEEDY_VERSION=\\\"\$(VERSION)\\\"",
	'-DSPEEDY_' . ($class->am_frontend ? 'FRONTEND' : 'BACKEND')
    );
}

sub mm_params { my $class = shift;
    return (
	NAME		=> $class->my_name_full,
	MAP_TARGET	=> $class->my_name_full,
	OBJECT		=> join(' ', $class->src_files_o),
	INC		=> '-I../src -I.',
	VERSION_FROM	=> '../src/SpeedyCGI.src',
	PM		=> {},
	DEFINE		=> $class->extra_defines,
	%write_makefile_common
    );
}

sub write_makefile {
    WriteMakefile(shift->mm_params);
}

sub clean_files_full { my $class = shift;
    (
	$class->clean_files_full_extra,
	$class->src_files_full
    );
}

sub clean_files_full_extra { (); }

sub clean_files_c { my $class = shift;
    $class->add_suffix('.c', $class->clean_files_full);
}

sub clean_files { my $class = shift;
    (
	$class->clean_files_c,
	$class->add_suffix('.bb',	$class->clean_files_full),
	$class->add_suffix('.da',	$class->clean_files_full),
	$class->add_suffix('.bbg',	$class->clean_files_full),
	'*.gcov',
	'gmon.out',
	$class->clean_files_extra
    );
}

sub clean_files_extra { (); }

sub add_prefix { my($class, $pre) = (shift, shift);
    return (map {"$pre$_"} @_);
}

sub add_suffix { my($class, $suf) = (shift, shift);
    return (map {"$_$suf"} @_);
}

sub testing_postamble { my $class = shift;
    my $mod_libexec = `apxs -q LIBEXECDIR 2>/dev/null`;
    my $topdir = &pwd;
    $topdir =~ s/\/[^\/]*$//;

    "
MODULE_LIBEXECDIR = $mod_libexec
TEST_SPEEDY = ${topdir}/speedy/speedy
TEST_SPEEDY_BACKENDPROG = ${topdir}/speedy_backend/speedy_backend
TEST_SPEEDY_MODULE = ${topdir}/mod_speedycgi/mod_speedycgi.so

FULLPERL = SPEEDY=\$(TEST_SPEEDY) SPEEDY_BACKENDPROG=\$(TEST_SPEEDY_BACKENDPROG) SPEEDY_MODULE=\$(TEST_SPEEDY_MODULE) \$(PERL)

test_install:
	\$(MAKE) test TEST_SPEEDY=\$(INSTALLBIN)/speedy TEST_SPEEDY_BACKENDPROG=\$(INSTALLBIN)/speedy_backend TEST_SPEEDY_MODULE=\$(MODULE_LIBEXECDIR)/mod_speedycgi.so

    ";
}

sub postamble { my $class = shift;
    $class->make_speedy_h;
    my $optdefs = $class->optdefs_cmds;
    my $allinc = join(' ', $class->allinc);
    my $c_file_link = $class->symlink_c_files;
    my $clean_files = join(' ', $class->clean_files);
    my $my_name = $class->my_name_full;

    $class->testing_postamble . 
    "

$c_file_link

$optdefs

\$(OBJECT) : $allinc

clean ::
	\$(RM_F) $clean_files speedy.h $my_name
    ";
}

sub check_syms_def { 
    $DEVEL ? '../util/check_syms' : '$(NOOP)';
}

sub remove_libs { undef }

sub get_ldopts {
    "$LD_OPTS " . &ExtUtils::Embed::ldopts('-std');
}
sub get_ccopts {&ExtUtils::Embed::ccopts();}

sub makeaperl { my $class = shift;
    my $my_name = $class->my_name_full;
    my $ldopts = $class->get_ldopts;
    my $check_syms = $class->check_syms_def;
    my $remove_libs = $class->remove_libs;

    "
all :: $my_name

${my_name}: \$(OBJECT)
	\$(RM_F) ${my_name}
	$remove_libs \$(LD) -o ${my_name} \$(OBJECT) $ldopts
	$check_syms
	echo ''
    ";
}

sub devel {$DEVEL}

1;
