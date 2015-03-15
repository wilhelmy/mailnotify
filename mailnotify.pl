#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;
use UI;
use Net::IMAP::Simple;

sub imap_connect {
	# change this as needed:
	my $cmd = "env HOME=/srv/mail/mw /usr/local/libexec/dovecot/imap";

	return Net::IMAP::Simple->new('cmd:'.$cmd)
		or die "imap connect failed: $Net::IMAP::Simple::errstr";
}

my $imap = imap_connect;

# prevent unneccessary imap pipe timeouts by doing a NOOP every 10 minutes
UI::every imap_noop => 10*60, sub { $imap->noop };

UI::log "monitor started";

UI::mainloop;
