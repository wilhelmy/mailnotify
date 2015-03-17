# Wrapper around Curses::UI (for now) that will hopefully allow me to easily
# switch the UI to something else in the future, in case I'm not satisfied.
package UI;

use v5.10.1;
use strict;
use warnings;
use Curses::UI;

my ($ui, $mon, $mbx, $sub);

# append text to the monitor window
sub log {
	my $log = $mon->get() . "--- ".localtime."\n  ".shift."\n";
	$mon->text($log);

	# HACK: poking around in the internals to ensure it's scrolled down to
	# the end of the buffer…
	$mon->cursor_down(undef, @{$mon->{-scr_lines}} - $mon->canvasheight);
}

my $mbxlen = 11; # show this many characters of the mailbox name
# Shorten a mailbox name
sub shorten {
	my $name = shift;
	$name =~ s|([[:alnum:]])[^/]+/|$1/|g;
	return substr($name, 0, $mbxlen);
}

my $start_hl = "<bold><underline>";
my $end_hl = "</underline></bold>";
sub hilight {
	my $x = shift;
	return $x ? ($start_hl, $x, $end_hl) : ('', $x, '');
}

# set mailbox window contents
sub mbx {
	my ($mailboxes, $status) = @_;
	my @values;

	foreach (@$mailboxes) {
		my ($n,$o,$t) = @{$status->{$_}};
		my $str = sprintf "%${mbxlen}s %s%4d%s/%s%4d%s/%5d",
			shorten($_),
			hilight($n),
			hilight($o),
			$t;

		push @values, $str;
	}
	$mbx->values(\@values);
}

sub subscriptions {
	my ($status, $subscribed) = @_;
	my $backup = $sub->{-onchange}; # HACK: poking around in the internals…
	$sub->onChange(undef);
	$sub->values($status);
	$sub->clear_selection;
	$sub->set_selection(@$subscribed);
	$sub->onChange($backup);
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
	$ui->dobeep;
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
	-title => 'Folders',
	-htmltext => 1,
);

$sub = $win->add(
	'subscriptions', 'Listbox',
	-border => 1,
	-x => 0,
	-y => 0,
	-width => $mbxwidth,
	-title => 'Subscriptions',
	-htmltext => 1,
	-multi => 1,
	-onchange => sub {
		UI::log "changed";
		shift->option_next;
	}
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
$ui->set_binding(sub{exit}, "\cC");

$mon->focus;
$mbx->focus;

1
