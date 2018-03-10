package WebService::Asana::ApiExplorer;

use Moo;
use Term::ReadLine;
use Term::ANSIColor;
use WebService::Asana;
use DDP { indent => 2 };
use Path::Tiny;
use JSON::MaybeXS;
use YAML;

has token => (is => 'rw', lazy => 1, builder => 1);

has term         => (is => 'lazy');
has prompt       => (is => 'rw', default => sub { 'asana api> ' });
has history_file => (is => 'rw', default => sub { $ENV{HOME} . '/.api-explorer_history' });

has asana          => (is => 'lazy');
has display_format => (is => 'rw', default => sub { 'default' });
has jsonxs => (is => 'lazy');

sub _build_token  { $ENV{WEBSERVICE_ASANA_TOKEN} }
sub _build_asana  { WebService::Asana->new(token => shift->token) }
sub _build_jsonxs { JSON::MaybeXS->new->pretty(1)->utf8(1)->allow_blessed }
sub _build_term   {
    my $term = Term::ReadLine->new('Asana');
    $term->ornaments(0);
    return $term;
}

sub run {
    my ($self) = @_;

    $self->load_history;

    print "Welcome to the Asana API Explorer\n";
    print "Type 'help' to get help\n\n";

    while (1) {
        my $line = $self->term->readline($self->prompt);

        print "\n" unless defined $line;
        last unless defined $line;
        last if $line eq 'exit';
        last if $line eq 'quit';

        chomp $line;
        $self->handle_input($line);
    }
}

sub handle_input {
    my ($self, $line) = @_;

    $self->show_help if $line =~ /^help/;
    $self->display_format($1) if $line =~ /^format (.*)/;
    $self->token($1) if $line =~ /^token (.*)/;

    if ($line =~ /^(GET|POST|PUT|DELETE) (\S*) ?(.*)?/i) {
        my $method     = lc $1;
        my $path       = $2;
        my $params_str = $3 || '';
        my $params = eval $params_str;
        warn "Syntax error: $?" if $?;

        unless ($self->token) {
            print "No personal access token set\n";
            print "Use the 'token' command \$ASANA_TOKEN environment variable\n";
            return;
        }

        my $data = $self->asana->$method($path, $params);
        $self->display_data($data);
    }
}

sub show_help {
    print <<EOF;

Make API Requests
  GET|POST|PUT|DELETE <path> <params>

Other Commands
  token <token>             Enter your Asana Personal Access Token
  format default|json|yaml  How to display response object
  help                      Display this message
  quit                      Exit the REPL

Examples:

  # list teams
  GET /organizations/\$workspace_id/teams

  # list all projects in a team
  GET /teams/\$team_id/projects { archived => 0 }

  # list all tasks in a project
  GET /projects/\$project_id/tasks { completed_since => 'now' }

  # display a task
  GET /tasks/\$task_id

EOF
}

sub display_data {
    my ($self, $data) = @_;

    if ($self->display_format eq 'yaml') {
        print Dump $data;

    } elsif ($self->display_format eq 'json') {
        print $self->jsonxs->encode($data);

    } elsif ($self->display_format eq 'default') {
        if (ref $data eq 'ARRAY') {
            my @keys = sort keys %{ $data->[0] };
            my $fmt = "%-20s  " x (scalar @keys) . "\n";

            print color('bold white');
            print sprintf $fmt, @keys;
            print color('reset');

            for my $item (@$data) {

                my $header;
                my @values;
                for my $key (@keys) {
                    $header = 1 if ($key eq "name" && $item->{name} =~ /:$/);
                    push @values, $item->{$key};
                }

                print "\n" if $header;
                print color('bold white') if $header;
                print sprintf $fmt, @values;
                print color('reset') if $header;
            }
        }
        else {
            print $self->jsonxs->encode($data);
        }
    }
    else {
        p $data;
    }
}

sub load_history {
    my $self = shift;

    my $file = path($self->history_file);
    $file->touch;
    my @lines = $file->lines;

    for my $line (@lines) {
        chomp $line;
        $self->term->addhistory($line);
    }
}

sub DEMOLISH {
    my $self = shift;
    $self->term->WriteHistory($self->history_file) or
        warn "Couldn't write to history file: " . $self->history_file;
}


1;
