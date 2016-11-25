#!/usr/bin/perl -w
# fwdport -- act as proxy forwarder for dedicated services

use strict;
use Getopt::Long;
use Net::hostent;
use IO::Socket;
use POSIX ":sys_wait_h";

my (
    %Children,
    $REMOTE,
    $LOCAL,
    $SERVICE,
    $proxy_server,
    $ME,
);

($ME = $0) =~ s,.*/,,;

check_args();
start_proxy();
service_clients();
die "NOT REACHED";

sub check_args {
    GetOptions(
        "remote=s"    => \$REMOTE,
        "local=s"     => \$LOCAL,
        "service=s"   => \$SERVICE,
    ) or die <<EOUSAGE;
    usage: $0 [ -- remote host ] [ --local interface ] [ --service service ]
EOUSAGE
    die "Need remote"             unless $REMOTE;
    die "Need local or service"   unless $Local || $SERVICE;
}

sub start_proxy {
    my @proxy_server_config = (
        Proto     => 'tcp',
        Reuse     => 1,
        Listen    => SOMAXCONN,
    );
    push @proxy_server_config, LocalPort => $SERVICE if $SERVICE;
    push @proxy_server_config, LocalAddr => $Local   if $Local;
    $proxy_server = IO::Socket::INET->new(@proxy_server_config)
                    or die "can't create proxy server: $@";
    print "[Proxy server on ", ($LOCAL || $SERVICE), " initialized.]\n";
}

sub service_clients {
    my (
        $local_client,
        $lc_info,
        $remote_server,
        @re_config,
        $rs_info,
        $kidpid,
    );

    $SIG{CHLD} = \&REAPER;

    accepting();

    while ($local_client = $proxy_server->accept()) {
        $lc_info = peerinfo($local_client);
        set_state("servicing local $lc_info");
        printf "[Connect from $lc_info]\n";

        @rs_config = (
            Proto    => 'tcp',
            PeerAddr => $REMOTE,
        );
        push(@rs_config, PeerPort => $SERVICE) if $SERVICE;

        print "[Connecting to $REMOTE...";
        set_state("connecting to $REMOTE");
        $remote_server = IO::Socket::INET->new(@rs_config)
                         or die "remote server: $@";
        print "done]\n";

        $rs_info = peerinfo($remote_server);
        set_state("connected to $rs_info");

        $kidpid = fork();
        die "Cannot fork" unless defined $kidpid;
        if ($kidpid) {
            $Children{$kidpid} = time();
            close $remote_server;
            close $local_client;
            next;
        }

        close $proxy_server;

        $kidpid = fork();
        die "Cannot fork" unless defined $kidpid;

        if ($kidpid) {
            set_state("$rs_info --> $lc_info");
            select($local_client); $| = 1;
            print while <$remote_server>;
            kill('TERM', $kidpid);
        }
        else {
            set_state("$rs_info <-- $lc_info");
            select($remote_server); $| = 1;
            print while <$local_client>;
            kill('TERM', getppid());
        }
        exit;
    } continue {
        accepting();
    }
}

sub peerinfo {
    my $sock = shift;
    my $hostinfo = gethostbyaddr($sock->peeraddr);
    return sprintf("%s:%s",
                    $hostinfo->name || $sock->peerhost,
                    $sock->peerport);
}

sub set_state { $0 = "$ME [@_]" }

sub accepting {
    set_state("accepting proxy for " . ($REMOTE || $SERVICE));
}

sub REAPER {
    my $child;
    my $start;
    while (($child = waitpid(-1, WNOHANG)) > 0) {
        if ($start = $Children{$child}) {
            my $runtime = time() - $start;
            printf "Child $child ran %dm%ss\n",
                $runtime / 60, $runtime %60;
                delete $Children{$child};
        } else {
            print "Biarre kid $child exited $?\n";
        }
    }

    $SIG{CHLD} = \&REAPR;
}