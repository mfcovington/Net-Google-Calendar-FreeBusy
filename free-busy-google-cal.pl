#!/usr/bin/env perl
use strict;
use warnings;
use LWP::UserAgent;
use JSON::XS;

# Need to pass calendar identifier via CLI
# Looks like: XXXXXXXXX@group.calendar.google.com
my $cal_id = $ARGV[0];

# Need to set variable by running the following at CLI
# or putting in ~/.bash_profile: export GOOGLE_API_KEY=xXxWHATEVERxKEYxIS
# See https://console.developers.google.com/ for more info on getting a key
my $key = $ENV{'GOOGLE_API_KEY'};

my $time_min = "2014-12-07T00:00:00-08:00";
my $time_max = "2014-12-14T00:00:00-08:00";

my $busy_times = get_busy_times( $key, $time_min, $time_max, $cal_id );
report_busy_times($busy_times);

exit;

sub get_busy_times {
    my ( $key, $time_min, $time_max, $cal_id ) = @_;

    my $ua = LWP::UserAgent->new;
    my $server_endpoint
        = "https://www.googleapis.com/calendar/v3/freeBusy?key=$key";

    my $req = HTTP::Request->new( POST => $server_endpoint );
    $req->header( 'content-type' => 'application/json' );

    my $post_data = <<EOF;
{
  "timeMin": "$time_min",
  "timeMax": "$time_max",
  "items": [
    {
      "id": "$cal_id"
    }
  ]
}
EOF

    $req->content($post_data);

    my $response = $ua->request($req);
    my $busy_times;

    if ( $response->is_success ) {
        my $message = $response->decoded_content;
        my $decoded = decode_json $message;
        $busy_times = $$decoded{calendars}{$cal_id}{busy};
    }
    else {
        warn "HTTP POST error code: ",    $response->code,    "\n";
        warn "HTTP POST error message: ", $response->message, "\n";
    }

    return $busy_times;    # times come from Google as GMT/UTC
}

sub report_busy_times {
    my $busy_times = shift;

    for (@$busy_times) {
        my $start = $$_{start};
        my $end   = $$_{end};
        print "Busy: $start - $end\n";
    }
}
