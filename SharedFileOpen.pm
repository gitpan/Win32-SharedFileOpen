#-------------------------------------------------------------------------------
# Copyright (c)	2001, Steve Hay. All rights reserved.
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
use DynaLoader	qw();
use Errno;
use Exporter	qw();

sub fsopen($$$);
sub sopen($$$;$);

our @ISA = qw(Exporter DynaLoader);

our @EXPORT      = qw(	O_APPEND O_BINARY O_CREAT O_EXCL O_NOINHERIT O_RANDOM
						O_RDONLY O_RDWR O_SEQUENTIAL O_SHORT_LIVED O_TEMPORARY
						O_TEXT O_TRUNC O_WRONLY
						S_IREAD S_IWRITE
						SH_DENYNO SH_DENYRD SH_DENYRW SH_DENYWR
						fsopen sopen);
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (	oflags	=> [qw(	O_APPEND O_BINARY O_CREAT O_EXCL
										O_NOINHERIT O_RANDOM O_RDONLY O_RDWR
										O_SEQUENTIAL O_SHORT_LIVED O_TEMPORARY
										O_TEXT O_TRUNC O_WRONLY)],
						pmodes	=> [qw(	S_IREAD S_IWRITE)],
						shflags	=> [qw(	SH_DENYNO SH_DENYRD SH_DENYRW
										SH_DENYWR)]);

our $VERSION = '1.00';

# Debug setting. (0 = No debug, 1 = Warnings, 2 = Warnings and messages.)
our $Debug = 1;

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
	croak('Unexpected error in autoloader: _constant() is not defined.')
		if $constant eq '_constant';

	# Reset any current errors.
	$! = 0;

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
			croak("The symbol '$AUTOLOAD' is not defined on this system.");
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

sub fsopen($$$) {
	my(	$file,							# File to open
		$mode,							# Mode string specifying access mode
		$shflag							# SH_* flag specifying sharing mode
		) = @_;

	my(	$fd,							# File descriptor opened
		$name,							# Filename to effectively fdopen()
		$fh								# Perl filehandle opened
		);

	$fd = _fsopen($file, $mode, $shflag);

	if ($fd != -1) {
		$name = "&=$fd";

		# Inspect the $mode, which by now we know to be valid otherwise the C
		# function call above would have failed with ERROR_ENVVAR_NOT_FOUND.

		if    ($mode =~ /^r/)  { $name = "<$name";  }
		elsif ($mode =~ /^w/)  { $name = ">$name";  }
		elsif ($mode =~ /^a/)  { $name = ">>$name"; }

		if    ($mode =~ /\+$/) { $name = "+$name";  }

		open $fh, $name;

		return $fh;
	}
	else {
		return;
	}
}

sub sopen($$$;$) {
	my(	$file,							# File to open
		$oflag,							# O_* flag specifying access mode
		$shflag,						# SH_* flag specifying sharing mode
		$pmode							# S_* flag specifying file permissions
		) = @_;

	my(	$fd,							# File descriptor opened
		$name,							# Filename to effectively fdopen()
		$fh								# Perl filehandle opened
		);

	if (@_ > 3) {
		$fd = _sopen($file, $oflag, $shflag, $pmode);
	}
	else {
		$fd = _sopen($file, $oflag, $shflag);
	}

	if ($fd != -1) {
		$name = "&=$fd";

		# Inspect the $oflag, which by now we know to be valid otherwise the C
		# function call above would have failed with ERROR_ENVVAR_NOT_FOUND.

		# We cannot explicitly test for O_RDONLY because it is 0 on Microsoft
		# Visual C (as is traditionally the case, according to "perlopentut"),
		# i.e. there are no bits set to look for. Therefore assume O_RDONLY if
		# neither O_WRONLY nor O_RDWR are set.
		if ($oflag & O_WRONLY()) {
			$name = ($oflag & O_APPEND()) ? ">>$name"  : ">$name";
		}
		elsif ($oflag & O_RDWR()) {
			$name = ($oflag & O_APPEND()) ? "+>>$name" : "+>$name";
		}
		else {
			$name = "<$name";
		}

		open $fh, $name;

		return $fh;
	}
	else {
		return;
	}
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

	use Win32::SharedFileOpen;

	my $file = 'C:\\Path\\To\\file.txt';

	# Open a file with write-locking a la C fopen() / Perl open().
	my $fh = fsopen($file, "r", SH_DENYWR) or
			die "Cannot read '$file' and take write-lock: $!\n";

	# or open a file with write-locking a la C open() / Perl sysopen().
	my $fh = sopen($file, O_RDONLY, SH_DENYWR) or
			die "Cannot read '$file' and take write-lock: $!\n";

	# ... Do some stuff ...

	close $fh;

=head1 DESCRIPTION

This module provides a Perl interface to the Microsoft Visual C functions
C<_fsopen()> and C<_sopen()>. These functions are counterparts to the standard C
library functions C<fopen(3)> and C<open(2)> respectively (which are already
effectively available in Perl as C<open()> and C<sysopen()> respectively), but
are intended for use when opening a file for subsequent shared reading and/or
writing.

The C<_fsopen()> function, like C<fopen(3)>, takes a file and a "mode string"
(e.g. C<"r"> or C<"w">) as arguments and opens the file as a stream, returning a
pointer to a C<FILE> structure, while C<_sopen()>, like C<open(2)>, takes an
"oflag" (e.g. O_RDONLY or O_WRONLY) argument instead of the "mode string" and
returns an C<int> file descriptor (which the Microsoft documentation confusingly
refers to a "file handle", not to be confused here with Perl "filehandles").
(The C<_sopen()> and C<open(2)> functions also take another, optional, parameter
specifying the permission settings of the file if it has just been created.)

The difference between each Microsoft-specific function and their standard
counterparts is that the Microsoft-specific functions also take an extra
"shflag" argument which specifies how to prepare the file for subsequent shared
reading and/or writing. This flag can be used to specify that either, both or
neither of read access and write access will be denied to other processes
sharing the file.

This share access control is thus effectively a form a file-locking which,
unlike C<flock(3)> and C<lockf(3)> and their corresponding Perl function
L<C<flock()>|perlfunc/flock>, is I<mandatory> rather than just I<advisory>. This
means that if, for example, you "deny read access" to the file that you have
opened then no other process will be able to read that file while you still have
it open, whether or not they are playing the same ball game as you. They cannot
gain read access to it by simply not honouring the same file opening/locking
scheme as you.

This module provides straightforward Perl "wrapper" functions for both of these
Microsoft C functions, maintaining the same formal parameters, but altering the
return values of both to be Perl filehandles. The file stream returned by
C<_fsopen()> is converted to an C<int> file descriptor by calling C<fileno()>;
this, and the file descriptor returned by C<_sopen()>, is then effectively
C<fdopen(3)>'d in Perl to yield a Perl filehandle.

The "oflags" and "shflags", as well as the "pmode" flags used by C<_sopen()>,
are all made available to Perl by this module, and are all exported by default.
Clearly this module will only build using Microsoft Visual C, so only the flags
known to that system [as of version 6.0] are exported, rather than re-exporting
all of the O_* and S_I* flags from the Fcntl module like, for example, IO::File
does. In any case, Fcntl does not know about the Microsoft-specific
_O_SHORT_LIVED flag, nor any of the _SH_* flags. These Microsoft-specific flags
are exported I<without> the leading "_" character, as, indeed, are the
C<_fsopen()> and C<_sopen()> functions themselves.

=head2 Functions

=over 4

=item C<fsopen($file, $mode, $shflag)>

Opens the file I<$file> in the access mode specified by
L<I<$mode>|"Mode Strings"> and prepares the file for subsequent shared reading
and/or writing as specified by L<I<$shflag>|"SH_* Flags">.

Returns a (Perl) filehandle associated with the file descriptor obtained if the
file was successfully opened. Returns C<undef> (and sets C<$!> and/or C<$^E>) if
the file could not be opened.

=item C<sopen($file, $oflag, $shflag[, $pmode])>

Opens the file I<$file> in the access mode specified by
L<I<$oflag>|"O_* Flags"> and prepares the file for subsequent shared reading
and/or writing as specified by L<I<$shflag>|"SH_* Flags">. The optional
L<I<$pmode>|"S_I* Flags"> argument specifies the file's permission settings if
the file has just been created; it is only required when the access mode
includes O_CREAT.

Returns a (Perl) filehandle associated with the same file descriptor as the (C)
file stream obtained if the file was successfully opened. Returns C<undef> (and
sets C<$!> and/or C<$^E>) if the file could not be opened.

=back

=head2 Mode Strings

The I<$mode> argument in C<fsopen()> specifies the type of access requested for
the file, as follows:

=over 4

=item "r"

Opens the file for reading only. Fails if the file does not already exist.

=item "w"

Opens the file for writing only. Creates the file if it does not already exist;
destroys the contents of the file if it does already exist.

=item "a"

Opens the file for appending only. Creates the file if it does not already
exist.

=item "r+"

Opens the file for both reading and writing. Fails if the file does not already
exist.

=item "w+"

Opens the file for both reading and writing. Creates the file if it does not
already exist; destroys the contents of the file if it does already exist.

=item "a+"

Opens the file for both reading and appending. Creates the file if it does not
already exist.

=back

When the file is opened for appending the file pointer is always forced to the
end of the file before any write operation is performed.

See also L<"Text and Binary Modes">.

=head2 O_* Flags

The I<$oflag> argument in C<sopen()> specifies the type of access requested for
the file, as follows:

=over 4

=item O_RDONLY

Opens the file for reading only.

=item O_WRONLY

Opens the file for writing only.

=item O_RDWR

Opens the file for both reading and writing.

=back

Exactly one of the above flags must be used to specify the file access mode:
there is no default value. In addition, the following flags may also be used in
bitwise-OR combination:

=over 4

=item O_APPEND

The file pointer is always forced to the end of the file before any write
operation is performed.

=item O_CREAT

Creates the file if it does not already exist. (Has no effect if the file does
already exist.) The L<I<$pmode>|"S_I* Flags"> argument is required if (and only
if) this flag is used.

=item O_EXCL

Fails if the file already exists. Only applies when used with O_CREAT.

=item O_NOINHERIT

Prevents creation of a shared file descriptor.

=item O_RANDOM

Specifies the disk access will be primarily random.

=item O_SEQUENTIAL

Specifies the disk access will be primarily sequential.

=item O_SHORT_LIVED

Used with O_CREAT, creates the file such that, if possible, it does not flush
the file to disk.

=item O_TEMPORARY

Used with O_CREAT, creates the file as temporary. The file will be deleted when
the last file descriptor attached to it is closed.

=item O_TRUNC

Truncates the file to zero length, destroying the contents of the file, if it
already exists. Cannot be specified with O_RDONLY, and the file must have write
permission.

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

Text/binary modes are specified for C<fsopen()> by inserting a C<"t"> or a
C<"b"> respectively into the L<I<$mode>|"Mode Strings"> string, immediately
following the C<"r">, C<"w"> or C<"a">, for example:

	my $fh = fsopen($file, 'wt', SH_DENYNO);

These modes are specified in C<sopen()> calls by using O_TEXT or O_BINARY
respectively in bitwise-OR combination with other O_* flags in the
L<I<$oflag>|"O_* Flags"> argument, for example:

	my $fh = sopen($file, O_WRONLY | O_TEXT, SH_DENYNO);

If neither mode is specified then text mode is assumed by default, as is usual
for Perl filehandles. Binary mode can still be enabled after the file has been
opened (but only before any I/O has been performed on it) by calling
L<C<binmode()>|perlfunc/binmode> in the usual way.

=head2 SH_* Flags

The I<$shflag> argument in both C<fsopen()> and C<sopen()> specifies the type of
sharing access permitted for the file, as follows:

=over 4

=item SH_DENYNO

Permits both read and write access to the file.

=item SH_DENYRD

Denies read access to the file; write access is permitted.

=item SH_DENYWR

Denies write access to the file; read access is permitted.

=item SH_DENYRW

Denies both read and write access to the file.

=back

=head2 S_I* Flags

The I<$pmode> argument in C<sopen()> is required if and only if the access mode,
I<$oflag>, includes O_CREAT. If the file does not already exist then I<$pmode>
specifies the file's permission settings, which are set the first time the file
is closed. (It has no effect if the file already exists.) The value is specified
as follows:

=over 4

=item S_IREAD

Permits reading.

=item S_IWRITE

Permits writing.

=back

Note that it is evidently not possible to deny read permission, so S_IWRITE and
S_IREAD | S_IWRITE are equivalent.

=head2 Variables

=over 4

=item I<$Debug>

Debug setting. Default value is 1.

A value of 0 means that no debug information will be produced and the only
messages explicitly emitted by this module itself will be those from exceptions
which may be raised on rare occasions (via L<C<croak()>|Carp>).

A value of 1 means that in addition to these exception messages, warning
messages will also be emitted (via L<C<carp()>|Carp>). These messages are
usually produced by a function (be it a public or a private one) when something
has gone wrong and it is about to return failure.

A value of 2 (or, in fact, any other value) means that in addition to the
exceptions and warnings, other informational messages which may be of use in
debugging will be emitted (via a straight-forward C<print()> on STDERR).

=back

=head1 DIAGNOSTICS

=head2 Warnings and Error Messages

The following diagnostic messages may be produced by this module. They are
classified as follows (a la L<perldiag>):

	(W) A warning
	(F) A fatal error
	(I) An internal error that you should never see

=over 4

=item Error generating subroutine '%s()': %s

(F) There was an error generating the named subroutine supplying the value of
the corresponding constant. The error set by C<eval()> is also given.

=item The symbol '%s' is not defined on this system.

(F) The symbol named is not provided by the C environment used to build this
module.

=item Unexpected error autoloading '%s()': %s

(I) There was an unexpected error looking up the value of the named constant.
The error set by the constant-lookup function is also given.

=item Unexpected error in autoloader: _constant() is not defined.

(I) There was an unexpected error looking up the value of the named constant:
the constant-lookup function itself is apparently not defined.

=back

=head2 Error Values

Both C<fsopen()> and C<sopen()> set the Perl Special Variables C<$!> and/or
C<$^E> to values indicating the cause of the error when they fail. The possible
values of each are as follows (C<$!> shown first, C<$^E> underneath):

=over 4

=item EACCES (Permission denied) (1)

=item ERROR_ACCESS_DENIED (Access is denied)

The I<$file> is a directory, or is a read-only file and an attempt was made to
open it for writing.

=item EACCES (Permission denied) (2)

=item ERROR_SHARING_VIOLATION (The process cannot access the file because it is
being used by another process.)

The I<$file> cannot be opened because another process already has it open and is
denying the requested access mode.

This is, of course, the error that other processes will get when trying to open
a file that we have opened with an access mode that we have denied.

=item EEXIST (File exists)

=item ERROR_FILE_EXISTS (The file exists)

[C<sopen()> only.] The I<$oflag> included O_CREAT | O_EXCL, and the I<$file> already exists.

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
stringifying the special variables, e.g. by C<print()>ing them:

	print "Errno was: $!\n";
	print "Last error was: $^E\n";

or, alternatively, the message for C<$^E> can also be obtained (slightly more
nicely formatted) by calling C<FormatMessage()> in the Win32 module:

	print "Last error was: " . Win32::FormatMessage($^E) . "\n";

The C<$^E> error code itself is also available from a Win32 module function,
C<GetLastError()>. Both functions are built-in to Perl itself (on Win32) so do
not require a C<use Win32;> call.

=head1 EXAMPLES

=over 4

=item Open a file for reading, and deny write access to other processes:

	my $fh = fsopen($file, "r", SH_DENYWR) or
			die "Cannot read '$file' and take write-lock: $!\n";

This example could be used for sharing a file amongst several processes for
reading, but protecting the reads from interference by other processes trying to
write the file.

=item Open a file for "update", and deny read and write access to other
processes:

	my $fh = fsopen($file, "r+", SH_DENYRW) or
			die "Cannot update '$file' and take read-write-lock: $!\n";

This example could be used by a process to both read and write a file (e.g. a
simple database) and guard against other processes interfering with the reads or
being interefered with by the writes.

=item Open a file for writing if and only if it doesn't already exist, and deny
write access to other processes:

	my $fh = sopen($file, O_WRONLY | O_CREAT | O_EXCL, SH_DENYWR, S_IWRITE) or
			die "Cannot write new file '$file' and take write-lock: $!\n";

This example could be used by a processes wishing to take an "advisory lock" on
some non-file resource that can't be explicitly locked itself by dropping a
"sentinel" file somewhere. The test for the non-existence of the file and
creation of the file is atomic to avoid a "race condition". The file can be
written by the process taking the lock and can be read by other processes to
facilitate a "lock discovery" mechanism.

=item Open a temporary file for "update", and deny read and write access to
other processes:

	my $fh = sopen($file, O_RDWR | O_CREAT | O_TRUNC | O_TEMPORARY,
				SH_DENYRW, S_IWRITE) or
			die "Cannot write temporary file '$file' and take write-lock: $!\n";

This example could be used by a process wishing to use a file as a temporary
"scratch space" for both reading and writing. The space is protected from the
prying eyes of and intereference by other processes, and is deleted when the
process that opened it exits, even when dying abnormally.

=back

=head1 EXPORTS

The following symbols are or can be exported by this module:

=over 4

=item Default Exports

C<fsopen>,
C<sopen>,

C<O_APPEND>,
L<C<O_BINARY>|"Text and Binary Modes">,
C<O_CREAT>,
C<O_EXCL>,
C<O_NOINHERIT>,
C<O_RANDOM>,
C<O_RDONLY>,
C<O_RDWR>,
C<O_SEQUENTIAL>,
C<O_SHORT_LIVED>,
C<O_TEMPORARY>,
L<C<O_TEXT>|"Text and Binary Modes">,
C<O_TRUNC>,
C<O_WRONLY>,

C<S_IREAD>,
C<S_IWRITE>,

C<SH_DENYNO>,
C<SH_DENYRD>,
C<SH_DENYRW>,
C<SH_DENYWR>

=item Optional Exports

I<None>

=item Export Tags

B<:oflags =E<gt>>
C<O_APPEND>,
L<C<O_BINARY>|"Text and Binary Modes">,
C<O_CREAT>,
C<O_EXCL>,
C<O_NOINHERIT>,
C<O_RANDOM>,
C<O_RDONLY>,
C<O_RDWR>,
C<O_SEQUENTIAL>,
C<O_SHORT_LIVED>,
C<O_TEMPORARY>,
L<C<O_TEXT>|"Text and Binary Modes">,
C<O_TRUNC>,
C<O_WRONLY>

B<:pmodes =E<gt>>
C<S_IREAD>,
C<S_IWRITE>

B<:shflags =E<gt>>
C<SH_DENYNO>,
C<SH_DENYRD>,
C<SH_DENYRW>,
C<SH_DENYWR>

=back

=head1 DEPENDENCIES

The following modules are C<use()>'d by this module:

=over 4

=item Standard Modules

AutoLoader,
Carp,
DynaLoader,
Errno,
Exporter

=item CPAN Modules

I<None>

=item Other Modules

I<None>

=back

=head1 BUGS AND CAVEATS

The Perl filehandle returned by C<sopen()> is obtained by effectively doing an
C<fdopen(3)> on the file descriptor returned by C<_sopen()> using the Perl
built-in function L<C<open()>|perlfunc/open>. This involves converting the O_*
flags that specify the I<$mode> in the C<sopen()> call into the corresponding
(C<+>) C<E<lt>> | C<E<gt>> | C<E<gt>E<gt>> string used in specifying the file in
the C<open()> call, e.g. O_RDONLY becomes "C<E<lt>>", O_RDWR | O_APPEND becomes
"C<+E<gt>E<gt>>", etc. This conversion could possibly break down in some
situations.

There is less chance of such a problem with C<fsopen()>, because the I<$mode> is
simply specified as C<"r"> | C<"w"> | C<"a"> (C<+>), which is more readily
converted.

=head1 SEE ALSO

L<perlfunc/open>,
L<perlfunc/sysopen>,
L<perlopentut>,

L<Fcntl>,
L<FileHandle>,
L<IO::File>,
L<Win32API::File>

In particular, the Win32API::File module (part of the "libwin32" bundle)
contains an interface to another, lower-level, Microsoft Visual C function,
L<C<CreateFile()>|Win32API::File/CreateFile>, which provides similar (and more)
capabilities but using a completely different set of arguments which are
unfamiliar to unseasoned Microsoft developers. A more Perl-friendly wrapper
function, L<C<createFile()>|Win32API::File/createFile>, is also provided but
does not entirely alleviate the pain.

=head1 AUTHOR

Steve Hay E<lt>Steve.Hay@programmer.netE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2001, Steve Hay. All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 VERSION

Win32::SharedFileOpen, Version 1.00

=head1 HISTORY

See F<Changes> in the original Win32-SharedFileOpen-I<VERSION>.tar.gz
distribution.

=cut

#-------------------------------------------------------------------------------
