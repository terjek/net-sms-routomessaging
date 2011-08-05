package Net::SMS::RoutoMessaging;

# ABSTRACT: Send SMS messages via the RoutoMessaging HTTP API

use strict;
use warnings;

use Carp;
use HTTP::Request::Common;
use LWP::UserAgent;

use constant {
    PROVIDER => "https://smsc5.routotelecom.com/NewSMSsend",
    TIMEOUT  => 10
};

sub new {
    my ($class, %args) = @_;

    if (! exists $args{username} || ! exists $args{password}) {
        Carp::croak("${class}->new() requires username and password as parameters\n");
    }

    my $self = \%args;
    bless $self, $class;
}

sub send_sms {
    my ($self, %args) = @_;

    my $ua = LWP::UserAgent->new();
    $ua->timeout(TIMEOUT);
    $ua->agent("Net::SMS::RoutoMessaging/$Net::SMS::RoutoMessaging::VERSION");

    $args{number} =~ s{\D}{}g;

    my $url  = PROVIDER;
    my $resp = $ua->request(POST $url, [ user => $self->{username}, pass => $self->{password}, %args ]);
    my $as_string = $resp->as_string;

    if (! $resp->is_success) {
        my $status = $resp->status_line;
        warn "HTTP request failed: $status\n$as_string\n";
        return 0;
    }

    my $res = $resp->content;

    my $return = 1;
    unless ($res =~ /^success/) {
        warn "Failed: $res\n";
        $return = 0;
    }

    return wantarray ? ($return, $res) : $return;
}

1;

__END__

=pod

=head1 SYNOPSIS

  # Create a testing sender
  my $sms = Net::SMS::RoutoMessaging->new(
      username => 'testuser', password => 'testpass'
  );

  # Send a message
  my $sent = $sms->send_sms(
      message => "All your base are belong to us",
      number  => '1234567890',
  );

  # If you also want the status message from the provider
  my ($sent, $status) = $sms->send_sms(
      message => "All your base are belong to us",
      number  => '1234567890',
  );

  if ($sent) {
      # Success, message sent
  }
  else {
      # Something failed
      warn("Failed : $status");
  }

=head1 DESCRIPTION

Perl module to send SMS messages through the HTTP API provided by RoutoMessaging
(routomessaging.com).

=head1 METHODS

=head2 new

new( username => 'testuser', password => 'testpass' )

Nothing fancy. You need to supply your username and password 
in the constructor, or it will complain loudly.

=head2 send_sms

send_sms(number => $phone_number, message => $message)

Uses the API to send a message given in C<$message> to
the phone number given in C<$phone_number>.

Phone number should be given with only digits. No "+" or spaces, like this:

=over 4

=item C<1234567890>

=back

Returns a status message. The message is "success" if the server has accepted your query. It does not mean that the message has been delivered.

=head1 SEE ALSO

RoutoMessaging website, http://www.routomessaging.com/
