#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;
use utf8;
use UI;
use Net::IMAP::Simple;

sub imap_connect {
	# change this as needed:
	my $cmd = "env HOME=/srv/mail/mw /usr/local/libexec/dovecot/imap"; 

	return Net::IMAP::Simple->new('cmd:'.$cmd)
		or die "imap connect failed: $Net::IMAP::Simple::errstr";
}

my $imap = imap_connect;

my @mailboxes = $imap->mailboxes;
my @subscribed = $imap->mailboxes_subscribed;

my %prevstatus;
# slightly pointless given that the other timer runs more often, but prevent
# unneccessary imap pipe timeouts by doing a NOOP every 10 minutes - might be
# useful in case I ever switch to IMAP IDLE
UI::every imap_noop => 10*60, sub { $imap->noop };

my $mbxlen = 11; # show this many characters of the mailbox name

# Shorten a mailbox name
sub shorten {
	my $name = shift;
	$name =~ s|([[:alnum:]])[^/]+/|$1/|g;
	return substr($name, 0, $mbxlen);
}

# periodic mailcheck every minute for now, because I'm too lazy to deal with
# IMAP IDLE
sub overview {
	my @status = ();

	foreach (@subscribed) {
		my @stat = $imap->status($_);
		my $str = sprintf("%${mbxlen}s %4d/%4d/%5d", shorten($_), @stat);
		$str = "<reverse>".$str."</reverse>" if $stat[1]; # got new mails?
		push @status, $str;
	}
	UI::mbx @status;
};

UI::every imap_subs => 1*60, \&overview;

UI::log "monitor started";
overview;

UI::mainloop;
