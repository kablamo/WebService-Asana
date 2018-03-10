package WebService::Asana::Response;

use Moo;

has response    => (is => 'rw', required => 1);
has token       => (is => 'ro', required => 1);

has ua          => (is => 'ro', lazy => 1, builder => 1);
has auth_header => (is => 'ro', lazy => 1, builder => 1);
has debug       => (is => 'rw', lazy => 1, default => sub { 1 });

sub _build_ua          { Mojo::UserAgent->new }
sub _build_auth_header { {Authorization => 'Bearer ' . shift->token } }

sub data { shift->response->{data} }
sub next {
    my $self = shift;
    my $uri = $self->response->{next_page}->{uri};
    return unless $uri;
    my $tx  = $self->ua->get($uri => $self->auth_header);
    return $self->handle_response($tx);
}

sub handle_response {
    my ($self, $tx) = @_;
    if ($tx->res->is_success) {
        #print $tx->res->to_string, "\n" if $self->debug;
        my $data = $tx->res->json;
        $self->response($data);
        return $data->{data};
    }
    else {
        if ($self->debug) {
            print $tx->req->to_string, "\n";
            print $tx->res->to_string, "\n";
        }
        my $method = $tx->res->content;
        die "Request failed $!" if $method eq 'GET';
    }
}

1;
__END__
