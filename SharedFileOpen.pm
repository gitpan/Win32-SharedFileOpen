#-------------------------------------------------------------------------------
# Copyright (c)	2001-2002, Steve Hay. All rights reserved.
#
# Module Name:	Win32::SharedFileOpen
# Source File:	SharedFileOpen.pm
# Description:	Main Perl module
#-------------------------------------------------------------------------------

package Win32::SharedFileOpen;

use 5.006;

use strict;
use warnings;

use AutoLoader;
use Carp;
use DynaLoader		qw();
use Errno;
use Exporter		qw();
use POSIX			qw();
use Symbol;
use Win32::WinError	qw(ERROR_SHARING_VIOLATION);

use constant INFINITE => 0;

sub fsopen(*$$$);
sub sopen(*$$$;$);
sub new_fh();

BEGIN {
	# Get the ERROR_SHARING_VIOLATION constant loaded now otherwise loading it
	# later the first time that we test for an error actually interferes with
	# the value of $! (which we might also want to test) because the constant is
	# autoloaded by Win32::WinError, and the AUTOLOAD() subroutine in that
	# module resets $!.
	my $dummy = ERROR_SHARING_VIOLATION;
}

our @ISA = qw(Exporter DynaLoader);

our @EXPORT      = qw(	O_APPEND O_BINARY O_CREAT O_EXCL O_NOINHERIT O_RANDOM
						O_RDONLY O_RDWR O_SEQUENTIAL O_SHORT_LIVED O_TEMPORARY
						O_TEXT O_TRUNC O_WRONLY
						S_IREAD S_IWRITE
						SH_DENYNO SH_DENYRD SH_DENYRW SH_DENYWR
						fsopen sopen
						);
our @EXPORT_OK   = qw(	gensym new_fh
						INFINITE $Max_Tries $Retry_Timeout
						);
our %EXPORT_TAGS =   (	oflags	=> [ qw(O_APPEND O_BINARY O_CREAT O_EXCL
										O_NOINHERIT O_RANDOM O_RDONLY O_RDWR
										O_SEQUENTIAL O_SHORT_LIVED O_TEMPORARY
										O_TEXT O_TRUNC O_WRONLY
										) ],
						pmodes	=> [ qw(S_IREAD S_IWRITE
										) ],
						shflags	=> [ qw(SH_DENYNO SH_DENYRD SH_DENYRW
										SH_DENYWR
										) ],
						retry	=> [ qw(INFINITE $Max_Tries $Retry_Timeout
										) ]
						);

our $VERSION = '2.10';

# Debug setting. (Boolean.)
our $Debug = 0;

# Maximum number of times to try opening a file. (Retries are only attempted if
# the previous try failed due to a sharing violation.)
tie our $Max_Tries, __PACKAGE__ . '::_NaturalNumber', 1, '$Max_Tries';

# Time to wait between tries at opening a file. (Milliseconds.)
tie our $Retry_Timeout, __PACKAGE__ . '::_NaturalNumber', 250, '$Retry_Timeout';

# Autoload the O_*, S_* and SH_* flags from the _constant() XS fuction.
sub AUTOLOAD {
	my(	$constant,						# Name of constant being autoloaded
		$value							# Value of constant being autoloaded
		);

	our($AUTOLOAD						# Fully-qualified name of method invoked
		);

	# Get the name of the constant to generate a subroutine for.
	($constant = $AUTOLOAD) =~ s/^.*:://;

	# Avoid deep recursion on AUTOLOAD() if _constant() is not defined.
	croak('Unexpected error in AUTOLOAD(): _constant() is not defined')
		if $constant eq '_constant';

	# Reset any current errors before looking up the constant, but local()ise
	# our changes so as not to interfere with the value seen by callers.
	local $! = 0;

	$value = _constant($constant, @_ ? $_[0] : 0);

	# An error occurred looking up the constant.
	if ($! != 0) {
		if ($!{EINVAL}) {
			# The constant has an invalid name, i.e. it is not one of ours, so
			# propagate this call to the AUTOLOAD() in AutoLoader.
			$AutoLoader::AUTOLOAD = $AUTOLOAD;
			goto &AutoLoader::AUTOLOAD;
		}
		elsif ($!{ENOENT}) {
			# The constant is one of ours, but is not defined in the C code.
			croak("The symbol '$AUTOLOAD' is not defined on this system");
		}
		else {
			croak("Unexpected error autoloading '$AUTOLOAD()': $!");
		}
	}

	# Generate an in-line subroutine returning the required value.
	eval "sub $AUTOLOAD { return $value }";

	croak("Error generating subroutine '$AUTOLOAD()': $@") if $@;

	# Switch to the subroutine that we have just generated.
	goto &$AUTOLOAD;
}

bootstrap Win32::SharedFileOpen $VERSION;

#-------------------------------------------------------------------------------
#
# Public subroutines.
#

sub fsopen(*$$$) {
	my(	$fh,							# "Filehandle" to be opened
		$file,							# File to open
		$mode,							# Mode string specifying access mode
		$shflag							# SH_* flag specifying sharing mode
		) = @_;

	my(	$tries,							# Number of tries at opening file
		$fd,							# File descriptor opened
		$name,							# Filename to effectively fdopen()
		$ret							# Return value from open()
		);

	croak("fsopen() can't use the undefined value as an indirect filehandle")
		unless defined $fh;

	for ($tries = 0; ; Win32::Sleep($Retry_Timeout)) {
		$fd = _fsopen($file, $mode, $shflag);

		$tries++;

		last if $fd != -1 or $ != ERROR_SHARING_VIOLATION or
				$Max_Tries != INFINITE and $tries >= $Max_Tries;

		print STDERR "_fsopen() failed after try number $tries; retrying ...\n"
			if $Debug;
	}

	if ($Debug) {
		printf STDERR "_fsopen() %s after $tries %s: %s.\n",
					  ($fd != -1 ? 'succeeded' : 'failed'),
					  ($tries == 1 ? 'try' : 'tries'),
					  ($fd != -1 ? "using file descriptor $fd" : $);
	}

	if ($fd != -1) {
		# Construct a name from this file descriptor that we can open() to get
		# a Perl filehandle to return. This effectively fdopen()'s the file
		# descriptor.
		$name = "&=$fd";

		# Inspect the $mode, which by now we know to be valid otherwise the C
		# function call above would have failed with ERROR_ENVVAR_NOT_FOUND.

		if    ($mode =~ /^r/)  { $name = "<$name";  }
		elsif ($mode =~ /^w/)  { $name = ">$name";  }
		elsif ($mode =~ /^a/)  { $name = ">>$name"; }

		if    ($mode =~ /\+$/) { $name = "+$name";  }

		# Make sure the "filehandle" argument supplied is fit for purpose.
		$fh = qualify_to_ref($fh, caller);

		$ret = open $fh, $name;

		if (defined $ret and $ret != 0) {
			print STDERR "open() on '$name' succeeded.\n" if $Debug;

			return $ret;
		}
		else {
			print STDERR "open() on '$name' failed ($!).\n" if $Debug;

			# The open() above has failed but the _fsopen() succeeded, so we
			# must close the file descriptor returned from _fsopen(). Don't try
			# to fdopen() the file descriptor to get a Perl filehandle that we
			# can close, because we just tried an fdopen() and that failed!
			# Instead, use the lowio-level close() function in the POSIX module.
			# Localise the OS error variables so that close() does not interfere
			# with their values as seen by the caller.
			local($!, $);
			POSIX::close($fd) or
				carp("fsopen() can't close file descriptor $fd: $!.");

			return;
		}
	}
	else {
		return;
	}
}

sub sopen(*$$$;$) {
	my(	$fh,							# "Filehandle" to be opened
		$file,							# File to open
		$oflag,							# O_* flag specifying access mode
		$shflag,						# SH_* flag specifying sharing mode
		$pmode							# S_* flag specifying file permissions
		) = @_;

	my(	$tries,							# Number of tries at opening file
		$fd,							# File descriptor opened
		$name,							# Filename to effectively fdopen()
		$ret							# Return value from open()
		);

	croak("sopen() can't use the undefined value as an indirect filehandle")
		unless defined $fh;

	for ($tries = 0; ; Win32::Sleep($Retry_Timeout)) {
		if (@_ > 4) {
			$fd = _sopen($file, $oflag, $shflag, $pmode);
		}
		else {
			$fd = _sopen($file, $oflag, $shflag);
		}

		$tries++;

		last if $fd != -1 or $ != ERROR_SHARING_VIOLATION or
				$Max_Tries != INFINITE and $tries >= $Max_Tries;

		print STDERR "_sopen() failed after try number $tries; retrying ...\n"
			if $Debug;
	}

	if ($Debug) {
		printf STDERR "_sopen() %s after $tries %s: %s.\n",
					  ($fd != -1 ? 'succeeded' : 'failed'),
					  ($tries == 1 ? 'try' : 'tries'),
					  ($fd != -1 ? "using file descriptor $fd" : $);
	}

	if ($fd != -1) {
		# Construct a name from this file descriptor that we can open() to get
		# a Perl filehandle to return. This effectively fdopen()'s the file
		# descriptor.
		$name = "&=$fd";

		# Inspect the $oflag, which by now we know to be valid otherwise the C
		# function call above would have failed with ERROR_ENVVAR_NOT_FOUND.

		# We cannot explicitly test for O_RDONLY because it is 0 on Microsoft
		# Visual C (as is traditionally the case, according to the "perlopentut"
		# manpage), i.e. there are no bits set to look for. Therefore assume
		# O_RDONLY if neither O_WRONLY nor O_RDWR are set.
		if ($oflag & O_WRONLY()) {
			$name = ($oflag & O_APPEND()) ? ">>$name"  : ">$name";
		}
		elsif ($oflag & O_RDWR()) {
			$name = ($oflag & O_APPEND()) ? "+>>$name" : "+>$name";
		}
		else {
			$name = "<$name";
		}

		# Make sure the "filehandle" argument supplied is fit for purpose.
		$fh = qualify_to_ref($fh, caller);

		$ret = open $fh, $name;

		if (defined $ret and $ret != 0) {
			print STDERR "open() on '$name' succeeded.\n" if $Debug;

			return $ret;
		}
		else {
			print STDERR "open() on '$name' failed ($!).\n" if $Debug;

			# The open() above has failed but the _sopen() succeeded, so we must
			# close the file descriptor returned from _fsopen(). Don't try to
			# fdopen() the file descriptor to get a Perl filehandle that we can
			# close, because we just tried an fdopen() and that failed!
			# Instead, use the lowio-level close() function in the POSIX module.
			# Localise the OS error variables so that close() does not interfere
			# with their values as seen by the caller.
			local($!, $);
			POSIX::close($fd) or
				carp("sopen() can't close file descriptor $fd: $!.");

			return;
		}
	}
	else {
		return;
	}
}

sub new_fh() {
	no warnings 'once';
	return local *FH;
}

#-------------------------------------------------------------------------------
#
# Private class to restrict the values of $Max_Tries and $Retry_Timeout to the
# set of natural numbers (i.e. the set of non-negative integers).
#

package Win32::SharedFileOpen::_NaturalNumber;

use Carp;

sub TIESCALAR {
	my(	$class,							# Invocant class
		$value,							# Initial value
		$name							# Name of tied scalar
		) = @_;

	my(	$self							# New object
		);

	croak("Usage: tie SCALAR, '" . __PACKAGE__ . "', SCALARVALUE, SCALARNAME")
		unless @_ == 3;

	$self = bless { _name => $name, _value => undef }, $class;

	# Use our own STORE() method to store the value to make sure it is valid.
	$self->STORE($value);

	return $self;
}

sub FETCH {
	my(	$self							# Invocant object
		) = @_;

	return $self->{_value};
}

sub STORE {
	my(	$self,							# Invocant object
		$value							# New value to store
		) = @_;

	if (not defined $value) {
		croak("Can't set '$self->{_name}' to the undefined value");
	}
	elsif ($value eq '') {
		croak("Can't set '$self->{_name}' to the null string");
	}
	elsif ($value =~ /\D/) {
		croak("Invalid value for '$self->{_name}': '$value' is not a natural " .
			  "number");
	}

	$self->{_value} = 0 + $value;
}

1;

__END__

#-------------------------------------------------------------------------------
#
# Documentation.
#

=head1 NAME

Win32::SharedFileOpen - Open a file for shared reading and/or writing

=head1 SYNOPSIS

	# Read and write files a la open(), but with mandatory file locking:
	# ------------------------------------------------------------------

	use Win32::SharedFileOpen;

	fsopen(FH1, 'readme', 'r', SH_DENYWR) or
			die "Can't read 'readme' and take write-lock: $^E\n";

	fsopen(FH2, 'writeme', 'w', SH_DENYRW) or
			die "Can't write 'writeme' and take read/write-lock: $^E\n";

	# Read and write files a la sysopen(), but with mandatory file locking:
	# ---------------------------------------------------------------------

	use Win32::SharedFileOpen;

	sopen(FH1, 'readme', O_RDONLY, SH_DENYWR) or
			die "Can't read 'readme' and take write-lock: $^E\n";

	sopen(FH2, 'writeme', O_WRONLY | O_CREAT | O_TRUNC, SH_DENYRW, S_IWRITE) or
			die "Can't write 'writeme' and take read/write-lock: $^E\n";

	# Retry opening the file if it fails due to a sharing violation:
	# --------------------------------------------------------------

	use Win32::SharedFileOpen qw(:DEFAULT :retry);

	$Max_Tries     = 10;	# Try opening the file upto 10 times
	$Retry_Timeout = 500;	# Wait 500 milliseconds between each try

	sopen(FH, 'readme', 'r', SH_DENYNO) or
		die "Can't read 'readme' after $Max_Tries tries: $^E\n";

	# Use a lexical indirect filehandle that closes itself when destroyed:
	# --------------------------------------------------------------------

	use Win32::SharedFileOpen qw(:DEFAULT new_fh);

	{
		my $fh = new_fh();

		sopen($fh, 'readme', 'r', SH_DENYNO) or
			die "Can't read 'readme': $^E\n";

		while (<$fh>) {
			# ... Do some stuff ...
		}

	}	# ... $fh is automatically closed here

=head1 WARNING

	*************************************************************************
	* The fsopen() function in this module currently has a bug which causes *
	* it to waste a filehandle every time it is called. Until this issue is *
	* resolved, the sopen() function should generally be used instead.      *
	* See the file WARNING-FSOPEN.TXT in the original distribution archive, *
	* Win32-SharedFileOpen-2.10.tar.gz, for more details.                   *
	*************************************************************************

=head1 WHAT'S NEW

New features introduced since version 2.00 of this module:

=over 4

=item *

A new function, C<new_fh()>, has been added for generating anonymous typeglobs
for use as indirect filehandles. The C<gensym()> function from the Symbol module
is also made available for this purpose.

=item *

Two new variables, I<$Max_Tries> and I<$Retry_Timeout>, have been added to
specify how many times and at what frequency C<fsopen()> and C<sopen()> should
automatically retry opening a file if it can't be opened due to a sharing
violation. (The default setting is to try only once.)

=item *

A new constant, C<INFINITE>, has also been added. This can be assigned to
I<$Max_Tries> to indicate that such retries should continue I<ad infinitum> if
necessary.

=back

=head1 COMPATIBILITY

Prior to version 2.00 of this module, C<fsopen()> and C<sopen()> both created a
filehandle and returned it to the caller. (C<undef> was returned instead on
failure.)

As of version 2.00 of this module, the arguments and return values of these two
functions now more closely resemble those of the Perl built-in functions
C<open()> and C<sysopen()>. Specifically, they now both expect a filehandle or
an indirect filehandle as their first argument and they both return a boolean
value to indicate success or failure.

B<THIS IS AN INCOMPATIBLE CHANGE. EXISTING SOFTWARE THAT USES THESE FUNCTIONS
WILL NEED TO BE MODIFIED.>

=head1 DESCRIPTION

This module provides a Perl interface to the Microsoft Visual C functions
C<_fsopen()> and C<_sopen()>. These functions are counterparts to the standard C
library functions C<fopen(3)> and C<open(2)> respectively (which are already
effectively available in Perl as C<open()> and C<sysopen()> respectively), but
are intended for use when opening a file for subsequent shared reading and/or
writing.

The C<_fsopen()> function, like C<fopen(3)>, takes a file and a "mode string"
(e.g. C<'r'> and C<'w'>) as arguments and opens the file as a stream, returning
a pointer to a C<FILE> structure, while C<_sopen()>, like C<open(2)>, takes an
"oflag" (e.g. C<O_RDONLY> and C<O_WRONLY>) instead of the "mode string" and
returns an C<int> file descriptor (which the Microsoft documentation confusingly
refers to as a C run-time "file handle", not to be confused here with a Perl
"filehandle" (or indeed with the operating-system "file handle" returned by the
C<CreateFile()> function!)). The C<_sopen()> and C<open(2)> functions also take
another, optional, "pmode" argument (e.g. C<S_IREAD> and C<S_IWRITE>) specifying
the permission settings of the file if it has just been created.

The difference between the Microsoft-specific functions and their standard
counterparts is that the Microsoft-specific functions also take an extra
"shflag" argument (e.g. C<SH_DENYRD> and C<SH_DENYWR>) which specifies how to
prepare the file for subsequent shared reading and/or writing. This flag can be
used to specify that either, both or neither of read access and write access
will be denied to other processes sharing the file.

This share access control is thus effectively a form a file-locking which,
unlike C<flock(3)> and C<lockf(3)> and their corresponding Perl function
C<flock()>, is I<mandatory> rather than just I<advisory>. This means that if,
for example, you "deny read access" to the file that you have opened then no
other process will be able to read that file while you still have it open,
whether or not they are playing the same ball game as you. They cannot gain read
access to it by simply not honouring the same file opening/locking scheme as
you.

This module provides straightforward Perl "wrapper" functions, C<fsopen()> and
C<sopen()>, for both of these Microsoft Visual C functions (with the leading "_"
character removed from their names). These Perl functions maintain the same
formal parameters as the original C functions, except for the addition of an
initial filehandle parameter like the Perl built-in functions C<open()> and
C<sysopen()> have. This is used to make the Perl filehandle opened available to
the caller (rather than using the functions' return values, which are now simple
Booleans to indicate success or failure).

The value passed to the functions in this first parameter can be a
straight-forward filehandle (C<FH>) or any of the following: a typeglob (either
a named typeglob like C<*FH>, or an anonymous typeglob (e.g. from C<gensym()> or
C<new_fh()> in this module) in a scalar variable); a reference to a typeglob
(either a hard reference like C<\*FH>, or a name like C<'FH'> to be used as a
symbolic reference to a typeglob in the caller's package); or a suitable IO
object (e.g.  an instance of IO::Handle, IO::File or FileHandle). These
functions, however, do not have the ability of C<open()> and C<sysopen()> to
auto-vivify the undefined scalar value into something that can be used as a
filehandle, so calls like "C<fsopen(my $fh, ...)>" will C<croak()> with a
message to this effect.

The "oflags" and "shflags", as well as the "pmode" flags used by C<_sopen()>,
are all made available to Perl by this module, and are all exported by default.
Clearly this module will only build using Microsoft Visual C, so only the flags
known to that system [as of version 6.0] are exported, rather than re-exporting
all of the C<O_*> and C<S_I*> flags from the Fcntl module like, for example,
IO::File does. In any case, Fcntl does not know about the Microsoft-specific
C<_O_SHORT_LIVED> flag, nor any of the C<_SH_*> flags. These Microsoft-specific
flags are exported (like the C<_fsopen()> and C<_sopen()> functions themselves)
I<without> the leading "_" character.

Both functions can be made to automatically retry opening a file (indefinitely,
or upto a specified maximum number of times, and at a specified frequency) if
the file could not be opened due to a sharing violation, via the L<"Variables">
I<$Max_Tries> and I<$Retry_Timeout> and the L<Constant|"Constants"> C<INFINITE>.

=head2 Functions

=over 4

=item C<fsopen($fh, $file, $mode, $shflag)>

Opens the file I<$file> using the
L<filehandle (or indirect filehandle)|"Filehandles and Indirect Filehandles">
I<$fh> in the access mode specified by L<I<$mode>|"Mode Strings"> and prepares
the file for subsequent shared reading and/or writing as specified by
L<I<$shflag>|"SH_* Flags">.

Returns a non-zero value if the file was successfully opened, or returns
C<undef> and sets C<$!> and/or C<$^E> if the file could not be opened.

=item C<sopen($fh, $file, $oflag, $shflag[, $pmode])>

Opens the file I<$file> using the
L<filehandle (or indirect filehandle)|"Filehandles and Indirect Filehandles">
I<$fh> in the access mode specified by L<I<$oflag>|"O_* Flags"> and prepares the
file for subsequent shared reading and/or writing as specified by
L<I<$shflag>|"SH_* Flags">. The optional L<I<$pmode>|"S_I* Flags"> argument
specifies the file's permission settings if the file has just been created; it
is only required when the access mode includes C<O_CREAT>.

Returns a non-zero value if the file was successfully opened, or returns
C<undef> and sets C<$!> and/or C<$^E> if the file could not be opened.

=item C<gensym()>

Returns a new, anonymous, typeglob which can be used as an indirect filehandle
in the first parameter of C<fsopen()> and C<sopen()>.

This function is not actually implemented by this module: it is simply imported
from the L<Symbol|Symbol> module. See L<"Filehandles and Indirect Filehandles">
for more details.

=item C<new_fh()>

Returns a new, anonymous, typeglob which can be used as an indirect filehandle
in the first parameter of C<fsopen()> and C<sopen()>.

This function is an implementation of the "First-Class Filehandle Trick". See
L<"Filehandles and Indirect Filehandles"> for more details.

=back

=head2 Filehandles and Indirect Filehandles

=over 4

=item Filehandles

The C<fsopen()> and C<sopen()> functions both expect either a filehandle or an
indirect filehandle as their first argument.

Using a filehandle:

	fsopen(FH, $file, 'r', SH_DENYWR) or
		die "Can't read '$file': $!\n";

is the simplest approach, but filehandles have a big drawback: they are global
in scope so they are always in danger of clobbering a filehandle of the same
name being used elsewhere. For example, consider this:

	fsopen(FH, $file1, 'r', SH_DENYWR) or
		die "Can't read '$file1': $!\n";

	while (<FH>) {
		chomp($line = $_);
		my_sub($line);
	}

	...

	close FH;

	sub my_sub($) {
		fsopen(FH, $file2, 'r', SH_DENYWR) or
			die "Can't read '$file2': $!\n";
		...
		close FH;
	}

The problem here is that when you open a filehandle that is already open it is
closed first, so calling "C<fsopen(FH, ...)>" in C<my_sub()> causes the
filehandle I<FH> which is already open in the caller to be closed first so that
C<my_sub()> can use it. When C<my_sub()> returns the caller will now find that
I<FH> is closed, causing the next read in the C<while { ... }> loop to fail. (Or
even worse, the caller would end up mistakenly reading from the wrong file if
C<my_sub()> hadn't closed I<FH> before returning!)

=item Localised Typeglobs and the C<*foo{THING}> Notation

One solution to this problem is to localise the typeglob of the filehandle in
question within C<my_sub()>:

	sub my_sub($) {
		local *FH;
		fsopen(FH, $file2, 'r', SH_DENYWR) or
			die "Can't read '$file2': $!\n";
		...
		close FH;
	}

but this has the unfortunate side-effect of localising all the other members of
that typeglob as well, so if the caller had global variables I<$FH>, I<@FH> or
I<%FH>, or even a subroutine C<FH()>, which C<my_sub()> needed then it no longer
has access to them either. (It does, on the other hand, have the rather nicer
side-effect that the filehandle is automatically closed when the localised
typeglob goes out of scope, so the "C<close FH;>" above is no longer necessary.)

This problem can also be addressed by using the so-called C<*foo{THING}>
syntax. C<*foo{THING}> returns a reference to the I<THING> member of the I<*foo>
typeglob. For example, C<*foo{SCALAR}> is equivalent to C<\$foo>, and
C<*foo{CODE}> is equivalent to C<\&foo>. C<*foo{IO}> (or the older, now
out-of-fashion notation C<*foo{FILEHANDLE}>) yields the actual internal
IO::Handle object that the C<*foo> typeglob contains, so with this we can
localise just the IO object, not the whole typeglob, so that we don't
accidentally hide more than we meant to:

	sub my_sub($) {
		local *FH{IO};
		fsopen(FH, $file2, 'r', SH_DENYWR) or
			die "Can't read '$file2': $!\n";
		...
		close FH;	# As in the example above, this is also not necessary
	}

However, this has a drawback as well: C<*FH{IO}> only works if I<FH> has already
been used as a filehandle (or some other IO handle), because C<*foo{THING}>
returns C<undef> if that particular I<THING> hasn't been seen by the compiler
yet (with the exception of when I<THING> is C<SCALAR>, which is treated
differently). This is fine in the example above, but would not necessarily have
been if the caller of C<my_sub()> hadn't used the filehandle I<FH> first, so
this approach would be no good if C<my_sub()> was to be put in a module to be
used by other callers too.

=item Indirect Filehandles

The answer to all of these problems is to use so-called indirect filehandles
instead of "normal" filehandles. An indirect filehandle is anything other than a
symbol being used in a place where a filehandle is expected, i.e. an expression
that evaluates to something that can be used as a filehandle, namely:

=over 4

=item A string

A name like C<'FH'> to be used as a symbolic reference to the typeglob whose IO
member is to be used as the filehandle.

=item A typeglob

Either a named typeglob like C<*FH>, or an anonymous typeglob in a scalar
variable (e.g. from C<Symbol::gensym()>), whose IO member is to be used as the
filehandle.

=item A reference to a typeglob

Either a hard reference like C<\*FH>, or a symbolic reference as in the first
case above, to a typeglob whose IO member is to be used as the filehandle.

=item A suitable IO object

Either the IO member of a typeglob obtained via the C<*foo{IO}> syntax, or an
instance of IO::Handle, or of IO::File or FileHandle (which are both just
sub-classes of IO::Handle).

=back

Of course, typeglobs are global in scope just like filehandles are, so if a
named typeglob, a reference (hard or symbolic) to a named typeglob or the IO
member of a named typeglob is used then we run into the same scoping problems
that we saw above with filehandles. The remainder of the above, however,
(namely, an anonymous typeglob in a scalar variable, or a suitable IO object)
finally give us the answer that we have been looking for.

So we can now write C<my_sub()> like this:

	sub my_sub($) {
		# Create "my $fh" here: see below
		fsopen($fh, $file2, 'r', SH_DENYWR) or
			die "Can't read '$file2': $!\n";
		...
		close $fh;		# Not necessary again
	}

where any of the following may be used to create "C<my $fh>":

	use Symbol;
	my $fh = gensym();

	use IO::Handle;
	my $fh = IO::Handle->new();

	use IO::File;
	my $fh = IO::File->new();

	use FileHandle;
	my $fh = FileHandle->new();

As we have noted in the code segment above, the "C<close $fh;>" is once again
not necessary: the filehandle is closed automatically when the lexical variable
I<$fh> is destroyed, i.e. when it goes out of scope (assuming there are no other
references to it).

However, there is still another point to bear in mind regarding the four
solutions shown above: they all load a good number of extra lines of code into
your program that might not otherwise be made use of. Note that FileHandle is a
sub-class of IO::File, which is in turn a sub-class of IO::Handle, so using
either of those sub-classes is particularly wasteful in this respect unless the
methods provided by them are going to be put to use. Even the IO::Handle class
still loads a number of other modules, including Symbol, so using the Symbol
module is certainly the best bet here if none of the IO::Handle methods are
required.

In our case, there is no additional overhead at all in loading the Symbol module
for this purpose because it is already loaded by this module itself anyway. In
fact, C<Symbol::gensym()>, imported by this module, is made available for export
from this module, so one can write:

	use Win32::SharedFileOpen qw(:DEFAULT gensym);
	my $fh = gensym();

to create "C<my $fh>" above.

=item The First-Class Filehandle Trick

Finally, there is another way to get an anonymous typeglob in a scalar variable
which is even leaner and meaner than using C<Symbol::gensym()>: the "First-Class
Filehandle Trick". It is described in an article by Mark-Jason Dominus called
"Seven Useful Uses of Local" which first appeared in The Perl Journal, and can
also be found (at the time of writing) on his website at the URL
F<http://perl.plover.com/local.html>. It consists simply of the following:

	my $fh = do { local *FH };

It works like this: the C<do { ... }> block simply executes the commands within
the block and returns the value of the last one. So in this case, the global
C<*FH> typeglob is temporarily replaced with a new glob that is C<local()> to
the C<do { ... }> block. The new, C<local()>, C<*FH> typeglob then goes out of
scope (i.e. is no longer accessible by that name) but is not destroyed because
it gets returned from the C<do { ... }> block. It is this, now anonymous,
typeglob that gets assigned to "C<my $fh>", exactly as we wanted.

Note that it is important that the typeglob itself, not a reference to it, is
returned from the C<do { ... }> block. This is because references to localised
typeglobs cannot be returned from their local scopes, one of the few places
in which typeglobs and references to typeglobs cannot be used interchangeably.
If we were to try to return a reference to the typeglob, as in:

	my $fh = do { \local *FH };

then I<$fh> would actually be a reference to the original C<*FH> itself, not the
temporary, localised, copy of it that existed within the C<do { ... }> block.
This means that if we use the technique twice to obtain two typeglob references
to use as two indirect filehandles then we end up with them both being
references to the same typeglob (namely, C<*FH>) so that the two filehandles
would then clash.

If this trick is used only once within a program running under
"C<use warnings;>" that doesn't mention C<*FH> or any of its members anywhere
else then a warning like the following will be produced:

	Name "main::FH" used only once: possible typo at ...

This can be easily avoided by turning off that warning within the C<do { ... }>
block:

	my $fh = do { no warnings 'once'; local *FH };

For convenience, this solution is implemented by this module itself in the
function C<new_fh()>, so that one can now simply write:

	use Win32::SharedFileOpen qw(:DEFAULT new_fh);
	my $fh = new_fh();

The only downside to this solution is that any subsequent error messages
involving this filehandle will refer to I<Win32::SharedFileOpen::FH>, the
IO member of the typeglob that a temporary, localised, copy of was used. For
example, the program:

	use strict;
	use warnings;
	use Win32::SharedFileOpen qw(:DEFAULT new_fh);
	my $fh = new_fh();
	print $fh "Hello, world.\n";

outputs the warning:

	print() on unopened filehandle Win32::SharedFileOpen::FH at test.pl line 5.

If several filehandles are being used in this way then it can be confusing to
have them all referred to by the same name. (Do not be alarmed by this, though:
they are completely different anonymous filehandles which just happen to be
referred to by their original, but actually now out-of-scope, names.) If this is
a problem then consider using C<Symbol::gensym()> instead (see above): that
function uses a different name ('GEN0', 'GEN1', 'GEN2', ...) to generate each
anonymous typeglob from.

=item Auto-Vivified Filehandles

Note that all of the above discussion of filehandles and indirect filehandles
applies equally to Perl's built-in C<open()> and C<sysopen()> functions. It
should also be noted that those two functions both support one other form of
indirect filehandle that this module's C<fsopen()> and C<sopen()> functions do
not: the undefined value. The calls

	open my $fh, $file;
	sysopen my $fh, $file, O_RDONLY;

each auto-vivify "C<my $fh>" into something that can be used as an indirect
filehandle. (In fact, they currently auto-vivify an entire typeglob, but this
may change in a future version of Perl to only auto-vivify the IO member.) Any
attempt to do likewise with this module's functions:

	fsopen(my $fh, $file, 'r', SH_DENYNO);
	sopen(my $fh, $file, O_RDONLY, SH_DENYNO);

causes the functions to C<croak()>.

=back

=head2 Mode Strings

The I<$mode> argument in C<fsopen()> specifies the type of access requested for
the file, as follows:

=over 4

=item C<'r'>

Opens the file for reading only. Fails if the file does not already exist.

=item C<'w'>

Opens the file for writing only. Creates the file if it does not already exist;
destroys the contents of the file if it does already exist.

=item C<'a'>

Opens the file for appending only. Creates the file if it does not already
exist.

=item C<'r+'>

Opens the file for both reading and writing. Fails if the file does not already
exist.

=item C<'w+'>

Opens the file for both reading and writing. Creates the file if it does not
already exist; destroys the contents of the file if it does already exist.

=item C<'a+'>

Opens the file for both reading and appending. Creates the file if it does not
already exist.

=back

When the file is opened for appending the file pointer is always forced to the
end of the file before any write operation is performed.

The following table shows the equivalent combination of L<"O_* Flags"> for each
mode string:

	+------+-------------------------------+
	| 'r'  | O_RDONLY                      |
	+------+-------------------------------+
	| 'w'  | O_WRONLY | O_CREAT | O_TRUNC  |
	+------+-------------------------------+
	| 'a'  | O_WRONLY | O_CREAT | O_APPEND |
	+------+-------------------------------+
	| 'r+' | O_RDWR                        |
	+------+-------------------------------+
	| 'w+' | O_RDWR | O_CREAT | O_TRUNC    |
	+------+-------------------------------+
	| 'a+' | O_RDWR | O_CREAT | O_APPEND   |
	+------+-------------------------------+

See also L<"Text and Binary Modes">.

=head2 O_* Flags

The I<$oflag> argument in C<sopen()> specifies the type of access requested for
the file, as follows:

=over 4

=item C<O_RDONLY>

Opens the file for reading only.

=item C<O_WRONLY>

Opens the file for writing only.

=item C<O_RDWR>

Opens the file for both reading and writing.

=back

Exactly one of the above flags must be used to specify the file access mode:
there is no default value. In addition, the following flags may also be used in
bitwise-OR combination:

=over 4

=item C<O_APPEND>

The file pointer is always forced to the end of the file before any write
operation is performed.

=item C<O_CREAT>

Creates the file if it does not already exist. (Has no effect if the file does
already exist.) The L<I<$pmode>|"S_I* Flags"> argument is required if (and only
if) this flag is used.

=item C<O_EXCL>

Fails if the file already exists. Only applies when used with C<O_CREAT>.

=item C<O_NOINHERIT>

Prevents creation of a shared file descriptor.

=item C<O_RANDOM>

Specifies the disk access will be primarily random.

=item C<O_SEQUENTIAL>

Specifies the disk access will be primarily sequential.

=item C<O_SHORT_LIVED>

Used with C<O_CREAT>, creates the file such that, if possible, it does not flush
the file to disk.

=item C<O_TEMPORARY>

Used with C<O_CREAT>, creates the file as temporary. The file will be deleted
when the last file descriptor attached to it is closed.

=item C<O_TRUNC>

Truncates the file to zero length, destroying the contents of the file, if it
already exists. Cannot be specified with C<O_RDONLY>, and the file must have
write permission.

=back

See also L<"Text and Binary Modes">.

=head2 Text and Binary Modes

Both C<fsopen()> and C<sopen()> calls can specify whether the file should be
opened in text (translated) mode or binary (untranslated) mode.

If the file is opened in text mode then on input carriage return-linefeed
(CR-LF) pairs are translated to single linefeed (LF) characters and Ctrl+Z is
interpreted as end-of-file (EOF), while on output linefeed (LF) characters are
translated to carriage return-linefeed (CR-LF) pairs.

These translations are not performed if the file is opened in binary mode.

If neither mode is specified then text mode is assumed by default, as is usual
for Perl filehandles. Binary mode can still be enabled after the file has been
opened (but only before any I/O has been performed on it) by calling
C<binmode()> in the usual way.

=over 4

=item C<'t'>

=item C<'b'>

Text/binary modes are specified for C<fsopen()> by inserting a C<'t'> or a
C<'b'> respectively into the L<I<$mode>|"Mode Strings"> string, immediately
following the C<'r'>, C<'w'> or C<'a'>, for example:

	my $fh = fsopen($file, 'wt', SH_DENYNO);

=item C<O_TEXT>

=item C<O_BINARY>

Text/binary modes are specified for C<sopen()> by using C<O_TEXT> or C<O_BINARY>
respectively in bitwise-OR combination with other C<O_*> flags in the
L<I<$oflag>|"O_* Flags"> argument, for example:

	my $fh = sopen($file, O_WRONLY | O_TEXT, SH_DENYNO);

=back

=head2 SH_* Flags

The I<$shflag> argument in both C<fsopen()> and C<sopen()> specifies the type of
sharing access permitted for the file, as follows:

=over 4

=item C<SH_DENYNO>

Permits both read and write access to the file.

=item C<SH_DENYRD>

Denies read access to the file; write access is permitted.

=item C<SH_DENYWR>

Denies write access to the file; read access is permitted.

=item C<SH_DENYRW>

Denies both read and write access to the file.

=back

=head2 S_I* Flags

The I<$pmode> argument in C<sopen()> is required if and only if the access mode,
I<$oflag>, includes C<O_CREAT>. If the file does not already exist then
I<$pmode> specifies the file's permission settings, which are set the first time
the file is closed. (It has no effect if the file already exists.) The value is
specified as follows:

=over 4

=item C<S_IREAD>

Permits reading.

=item C<S_IWRITE>

Permits writing.

=back

Note that it is evidently not possible to deny read permission, so C<S_IWRITE>
and C<S_IREAD | S_IWRITE> are equivalent.

=head2 Variables

=over 4

=item I<$Debug>

Boolean debug mode setting.

Setting this variable to a true value will cause debug information to be emitted
(via a straight-forward C<print()> on STDERR).

The default value is 0, i.e. debug mode is "off".

=item I<$Max_Tries>

This variable specifies the maximum number of times to try opening a file on a
single call to C<fsopen()> or C<sopen()>. Retries are only attempted if the
previous try failed due to a sharing violation (specifically, when
"C<$^E == ERROR_SHARING_VIOLATION>").

The value must be a natural number (i.e. a non-negative integer); an exception
is raised on any attempt to specify an invalid value. The value zero indicates
that the retries should be continued I<ad infinitum> if necessary. The constant
C<INFINITE> may also be used for this purpose.

The default value is 1, i.e. no retries are attempted.

=item I<$Retry_Timeout>

This variable specifies the time to wait (in milliseconds) between tries at
opening a file (see I<$Max_Tries> above).

The value must be a natural number (i.e. a non-negative integer); an exception
is raised on any attempt to specify an invalid value.

The default value is 250, i.e. wait for one quarter of a second between tries.

=back

=head2 Constants

=over 4

=item C<INFINITE>

This constant specifies the value (zero, as it happens) that I<$Max_Tries> (see
above) can be set to in order to have it indefinitely retry opening a file until
it is opened successfully (as long as each failure is due to a sharing
violation).

=back

=head1 DIAGNOSTICS

=head2 Warnings and Error Messages

The following diagnostic messages may be produced by this module. They are
classified as follows (a la L<perldiag>):

	(W) A warning
	(F) A fatal error
	(I) An internal error that you should never see

=over 4

=item %s() can't close file descriptor %d: %s

(W) The specified function called the corresponding Microsoft Visual C function
which successfully opened the file, acquiring a new file descriptor in the
proces, but the Perl function was then unable to attach a Perl filehandle to
that new file descriptor. To prevent the file descriptor being wasted, and the
file being left open, the Perl function then attempted to close this new file
descriptor, but was unable to do so. The system error message set in C<$!> is
also given.

=item Can't set '%s' to the null string

(F) An attempt was made to set the specified variable to the null string. This
is not allowed.

=item Can't set '%s' to the undefined value

(F) An attempt was made to set the specified variable to the undefined value.
This is not allowed.

=item %s() can't use the undefined value as an indirect filehandle

(F) The specified function was passed the undefined value as the first argument.
That is not a filehandle, cannot be used as an indirect filehandle, and
(unlike the Perl built-in functions C<open()> and C<sysopen()>) the function is
unable to auto-vivify something that can be used as an indirect filehandle in
such a case.

=item Error generating subroutine '%s()': %s

(F) There was an error generating the specified subroutine (which supplies the
value of the corresponding constant). The error set by C<eval()> is also given.

=item Invalid value for '%s': '%s' is not a natural number

(F) An attempt was made to set the specified variable to something other than a
natural number (i.e. a non-negative integer). This is not allowed.

=item The symbol '%s' is not defined on this system

(F) The specified symbol is not provided by the C environment used to build this
module.

=item Unexpected error autoloading '%s()': %s

(I) There was an unexpected error looking up the value of the specified
constant. The error set by the constant-lookup function is also given.

=item Unexpected error in AUTOLOAD(): _constant() is not defined

(I) There was an unexpected error looking up the value of the specified
constant: the constant-lookup function itself is apparently not defined.

=item Usage: tie SCALAR, %s, SCALARVALUE, SCALARNAME

(I) There was an error in C<tie()>'ing a variable to the specified
internally-used class.

=back

=head2 Error Values

Both C<fsopen()> and C<sopen()> set the Perl Special Variables C<$!> and/or
C<$^E> to values indicating the cause of the error when they fail. The possible
values of each are as follows (C<$!> shown first, C<$^E> underneath):

=over 4

=item EACCES (Permission denied) [1]

=item ERROR_ACCESS_DENIED (Access is denied)

The I<$file> is a directory, or is a read-only file and an attempt was made to
open it for writing.

=item EACCES (Permission denied) [2]

=item ERROR_SHARING_VIOLATION (The process cannot access the file because it is
being used by another process.)

The I<$file> cannot be opened because another process already has it open and is
denying the requested access mode.

This is, of course, the error that other processes will get when trying to open
a file in a certain access mode, when we have already opened the same file with
a sharing mode that denies other processes that access mode.

=item EEXIST (File exists)

=item ERROR_FILE_EXISTS (The file exists)

[C<sopen()> only.] The I<$oflag> included C<O_CREAT | O_EXCL>, and the I<$file> already exists.

=item EINVAL (Invalid argument)

=item ERROR_ENVVAR_NOT_FOUND (The system could not find the environment option
that was entered)

The I<$oflag> or I<$shflag> argument was invalid.

=item EMFILE (Too many open files)

=item ERROR_TOO_MANY_OPEN_FILES (The system cannot open the file)

The maximum number of file descriptors has been reached.

=item ENOENT (No such file or directory)

=item ERROR_FILE_NOT_FOUND (The system cannot find the file specified)

The the filename or path in I<$file> was not found.

=back

C<$!> corresponds to the standard C library variable C<errno>, the possible
values of which are defined in F<errno.h>. C<$^E> corresponds to the Microsoft C
"last-error code", the possible values of which are defined in F<winerror.h>.

The C<$!> errors can be checked for by inspecting the values of the I<%!> hash
exported by the L<Errno|Errno> module. The error which occurred will have a
"true" value in the hash, for example:

	use Errno;

	if ($!{EACCES}) {
		...
	}

The C<$^E> errors can be checked for by comparing against values exported by the
L<Win32::WinError|Win32::WinError> module, for example:

	use Win32::WinError;

	if ($^E == ERROR_ACCESS_DENIED) {
		...
	}

In both cases, the errors should be checked for immediately following the
function call that failed because many functions that succeed will reset these
variables.

The system error messages for both C<$!> and C<$^E> can be obtained by simply
stringifying the special variables, e.g. by C<print()>'ing them:

	print "Errno was: $!\n";
	print "Last error was: $^E\n";

or, alternatively, the message for C<$^E> can also be obtained (slightly more
nicely formatted) by calling C<FormatMessage()> in the L<Win32|Win32> module:

	print "Last error was: " . Win32::FormatMessage($^E) . "\n";

The C<$^E> error code itself is also available from a Win32 module function,
C<GetLastError()>. Both functions are built-in to Perl itself (on Win32) so do
not require a "C<use Win32;>" call.

=head1 EXAMPLES

=over 4

=item Open a file for reading, denying write access to other processes:

	fsopen(FH, $file, 'r', SH_DENYWR) or
			die "Can't read '$file' and take write-lock: $^E\n";

This example could be used for sharing a file amongst several processes for
reading, but protecting the reads from interference by other processes trying to
write the file.

=item Open a file for reading, denying write access to other processes, with
automatic open-retrying:

	$Win32::SharedFileOpen::Max_Tries = 10;

	fsopen(FH, $file, 'r', SH_DENYWR) or
			die "Can't read '$file' and take write-lock: $^E\n";

This example could be used in the same scenario as above, but when we actually
I<expect> there to be other processes trying to write to the file, e.g. we are
reading a file that is being regularly updated. In this situation we expect to
get sharing violation errors from time to time, so we use I<$Max_Tries> to
automatically have another go at reading the file (up to 10 times in all) when
that happens.

We may also want to increase I<$Win32::SharedFileOpen::Retry_Timeout> from its
default value of 250 milliseconds if the file is fairly large and we expect the
writer updating the file to take very long to do so.

=item Open a file for "update", denying read and write access to other
processes:

	fsopen(FH, $file, 'r+', SH_DENYRW) or
			die "Can't update '$file' and take read-write-lock: $^E\n";

This example could be used by a process to both read and write a file (e.g. a
simple database) and guard against other processes interfering with the reads or
being interefered with by the writes.

=item Open a file for writing if and only if it doesn't already exist, denying
write access to other processes:

	sopen(FH, $file, O_WRONLY | O_CREAT | O_EXCL, SH_DENYWR, S_IWRITE) or
			die "Can't create '$file' and take write-lock: $^E\n";

This example could be used by a process wishing to take an "advisory lock" on
some non-file resource that can't be explicitly locked itself by dropping a
"sentinel" file somewhere. The test for the non-existence of the file and the
creation of the file is atomic to avoid a "race condition". The file can be
written by the process taking the lock and can be read by other processes to
facilitate a "lock discovery" mechanism.

=item Open a temporary file for "update", denying read and write access to other
processes:

	sopen(FH, $file, O_RDWR | O_CREAT | O_TRUNC | O_TEMPORARY, SH_DENYRW,
				S_IWRITE) or
			die "Can't update '$file' and take write-lock: $^E\n";

This example could be used by a process wishing to use a file as a temporary
"scratch space" for both reading and writing. The space is protected from the
prying eyes of, and intereference by, other processes, and is deleted when the
process that opened it exits, even when dying abnormally.

=back

=head1 EXPORTS

The following symbols are or can be exported by this module:

=over 4

=item Default Exports

C<fsopen>,
C<sopen>,

C<O_APPEND>,
C<O_BINARY>,
C<O_CREAT>,
C<O_EXCL>,
C<O_NOINHERIT>,
C<O_RANDOM>,
C<O_RDONLY>,
C<O_RDWR>,
C<O_SEQUENTIAL>,
C<O_SHORT_LIVED>,
C<O_TEMPORARY>,
C<O_TEXT>,
C<O_TRUNC>,
C<O_WRONLY>,

C<S_IREAD>,
C<S_IWRITE>,

C<SH_DENYNO>,
C<SH_DENYRD>,
C<SH_DENYRW>,
C<SH_DENYWR>

=item Optional Exports

C<gensym>,
C<new_fh>

C<INFINITE>,
C<$Max_Tries>,
C<$Retry_Timeout>

=item Export Tags

=over 4

=item C<:oflags>

C<O_APPEND>,
C<O_BINARY>,
C<O_CREAT>,
C<O_EXCL>,
C<O_NOINHERIT>,
C<O_RANDOM>,
C<O_RDONLY>,
C<O_RDWR>,
C<O_SEQUENTIAL>,
C<O_SHORT_LIVED>,
C<O_TEMPORARY>,
C<O_TEXT>,
C<O_TRUNC>,
C<O_WRONLY>

=item C<:pmodes>

C<S_IREAD>,
C<S_IWRITE>

=item C<:shflags>

C<SH_DENYNO>,
C<SH_DENYRD>,
C<SH_DENYRW>,
C<SH_DENYWR>

=item C<:retry>

C<INFINITE>,
C<$Max_Tries>,
C<$Retry_Timeout>

=back

=back

=head1 DEPENDENCIES

The following modules are C<use()>'d by this module:

=over 4

=item Standard Modules

AutoLoader,
Carp,
DynaLoader,
Errno,
Exporter,
POSIX,
Symbol,
Win32

=item CPAN Modules

Win32::WinError (part of the "libwin32" bundle)

=item Other Modules

I<None>

=back

=head1 BUGS AND CAVEATS

=over 4

=item *

As noted in the L<"WARNING"> near the top of this manpage, there is currently a
significant bug in the implementation of the C<fsopen()> function which causes
it to waste a filehandle every time it is called.

See the file F<WARNING-FSOPEN.TXT> in the original distribution archive,
F<Win32-SharedFileOpen-2.10.tar.gz>, for more details.

=item *

The Perl filehandle returned by C<sopen()> is obtained by effectively doing an
C<fdopen(3)> on the file descriptor returned by C<_sopen()> using the Perl
built-in function C<open()>. This involves converting the C<O_*> flags that
specify the I<$mode> in the C<sopen()> call into the corresponding (C<+>)
C<E<lt>> | C<E<gt>> | C<E<gt>E<gt>> string used in specifying the file in the
C<open()> call, e.g. C<O_RDONLY> becomes "C<E<lt>>", C<O_RDWR | O_APPEND>
becomes "C<+E<gt>E<gt>>", etc. This conversion could possibly break down in some
situations.

There is less chance of such a problem with C<fsopen()>, because the I<$mode> is
simply specified as C<'r'> | C<'w'> | C<'a'> (C<+>), which is more readily
converted.

=back

=head1 SEE ALSO

L<perlfunc/open>,
L<perlfunc/sysopen>,
L<perlopentut>,

L<Fcntl>,
L<FileHandle>,
L<IO::File>,
L<IO::Handle>,
L<Symbol>,
L<Win32API::File>

In particular, the Win32API::File module (part of the "libwin32" bundle)
contains an interface to another, lower-level, Microsoft Visual C function,
L<C<CreateFile()>|Win32API::File/CreateFile>, which provides similar (and more)
capabilities but using a completely different set of arguments which are
unfamiliar to unseasoned Microsoft developers. A more Perl-friendly wrapper
function, L<C<createFile()>|Win32API::File/createFile>, is also provided but
does not entirely alleviate the pain.

=head1 AUTHOR

Steve Hay E<lt>shay@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2001-2002, Steve Hay. All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 VERSION

Win32::SharedFileOpen, Version 2.10

=head1 HISTORY

See the file F<Changes> in the original distribution archive,
F<Win32-SharedFileOpen-2.10.tar.gz>.

=cut

#-------------------------------------------------------------------------------
