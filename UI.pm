# Wrapper around Curses::UI (for now) that will hopefully allow me to easily
# switch the UI to something else in the future, in case I'm not satisfied.
package UI;

use strict;
use warnings;
use Curses::UI;

my ($ui, $mon, $mbx);

# append text to the monitor window
sub log {
	my $msg = shift;
	$mon->text( $mon->get() . "--- ".localtime."\n  $msg\n");
}

my $mbxlen = 11; # show this many characters of the mailbox name

# Shorten a mailbox name
sub shorten {
	my $name = shift;
	$name =~ s|([[:alnum:]])[^/]+/|$1/|g;
	return substr($name, 0, $mbxlen);
}

# set mailbox window contents
sub mbx {
	my @status = ();

	while (scalar(@_)) {
		my $mb = shift;
		my ($n, $o, $t) = (shift, shift, shift);

		my $str = sprintf "%${mbxlen}s %4d/%4d/%5d", shorten($mb), $n,$o,$t;
		$str = "<reverse>". $str ."</reverse>" if $n; # got new mails?
		push @status, $str;
	}
	$mbx->values(\@status);
}

# timer that restarts itself
sub every {
	my ($id, $sec, $code) = @_;
	$ui->set_timer($id, $code, $sec);
}

# one-shot timer
sub once {
	my ($id, $sec, $code) = @_;
	$ui->set_timer($id, sub { &$code; $ui->disable_timer($id) }, $sec);
}

# run the UI mainloop
sub mainloop {
	$ui->mainloop
}

# alert the user
sub beep {
	print "\a";
	STDOUT->flush;
}

## Window setup
my $debug = 0;
$ui = Curses::UI->new(
	-clear_on_exit => 1,
	-debug => $debug,
	-color_support => 1
);

my $win = $ui->add(
	'mainwin', 'Window',
);

my $mbxwidth = 30;

$mbx = $win->add(
	'mailbox', 'Listbox',
	-border => 1,
	-bfg => 'blue',
	-x => 0,
	-y => 0,
	-width => $mbxwidth,
	-title => 'Messages',
	-htmltext => 1,
	-onfocus => sub { $mon->focus },
);

$mon = $win->add(
	'monitor', 'TextViewer',
	-border => 1,
	-bfg => 'red',
	-x => $mbxwidth,
	-y => 0,
	-title => 'Monitor'
);

$ui->set_binding(sub{exit}, 'q');

$mon->focus;

1
