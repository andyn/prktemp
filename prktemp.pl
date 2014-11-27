use strict;
use Irssi;
use Irssi::Irc;
use LWP::UserAgent;
use vars qw($VERSION %IRSSI);

$VERSION = '1.4';
%IRSSI = (
    authors     => 'Antti Nilakari',
    contact     => 'andyn@ircnet',
    name        => '!prktemp trigger',
    description => 'Prints the temperature of OH2TI temp sensor' .
                   'at JMT3A when asked with !prktemp. Thanks to' .
                   'usv for CSV parser.',
    license     => 'EVVKTVH http://evvk.com/evvktvh.html',
);

####################################################################
Irssi::print("!prktemp ".$VERSION);

sub event_prktemprequest {
    my ($srv, $data, $nick, $addr,) = @_;
    my ($dest, $text) = split(/ :/, $data, 2);

    if ($text =~ /^!prktemp.*/ && $dest =~ /^[!#+&].*/i) {
        my $url = "http://prkele.prk.tky.fi/thermo/current.txt";
        my $ua = LWP::UserAgent->new(keep_alive => 0, 
                                     timeout => 6, 
                                     agent => 'prktemp/1.4 (Irssi/LWP)',
                                     max_size => 16000);

        my $req = HTTP::Request->new(GET => $url);
        my $res = $ua->request($req);
        if ($res->is_success) {
            my $html = $res->content;
            $html =~ s/.*DATA//si;
            my @html_lines = split(/\n/, $html);

            my $temp = "N/A";
            my $atm = "N/A";

            foreach(@html_lines) {
		# Format described at http://oh2mmy.ham.fi/anturispeksi.html
                my ($data_name, $data_value, $data_unit, $data_timestamp,
                    $data_loc, $data_el, $data_rest) = split(/\;/, $_);

                if ($data_name eq 'WXT_Ta') {
                    $temp = "$data_value $data_unit";
                }

                if ($data_name eq 'WXT_Pa') {
                    $atm = "$data_value $data_unit";
                }
            }

            $srv->command("msg $dest temp: $temp, atm p: $atm @ JMT 3A");
        }
        undef $res;
        undef $req;

    }
}

Irssi::signal_add_last("event privmsg", "event_prktemprequest");
