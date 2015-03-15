# Wrapper around Curses::UI (for now) that will hopefully allow me to easily
# switch the UI to something else in the future, in case I'm not satisfied.
package UI;

use strict;
use warnings;
use Curses::UI;

my ($ui, $mon, $mbx);

# append text to the monitor window
sub log {
	my $msg = pop @_;
	my %args = @_;
	$mon->text( $mon->get() . "\n---".localtime."\n $msg");
	#$vt->print($mon, "--- ".localtime);
	#$vt->print("  $msg\n");
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
	#-border => 1,
	#-y => 1,
	#-bfg => 'red'
);

$mbx = $win->add(
	'mailbox', 'TextViewer',
	-border => 1,
	-bfg => 'green',
	-x => 0,
	-y => 0,
	-height => 5,
);

$mon = $win->add(
	'monitor', 'TextViewer',
	-border => 1,
	-bfg => 'red',
	-x => 0,
	-y => 5,
);

$ui->set_binding(sub{exit}, 'q');

1
