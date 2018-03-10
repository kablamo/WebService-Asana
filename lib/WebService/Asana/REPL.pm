package WebService::Asana::REPL;

use Moo;
use Term::ReadLine;
use Term::ANSIColor;
use WebService::Asana;
use DDP;

has token  => (is => 'rw', lazy => 1, builder => 1);
has term   => (is => 'lazy');
has prompt => (is => 'rw', default => sub { 'asana> ' });
has history_file => (is => 'rw', default => sub { $ENV{HOME} . '/.asana_history' });
has asana  => (is => 'lazy');

sub _build_token  { $ENV{WEBSERVICE_ASANA_TOKEN} }
sub _build_asana  { WebService::Asana->new(token => shift->token) }
sub _build_term   {
    my $term = Term::ReadLine->new('Asana');
    $term->ornaments(0);
    return $term;
}

sub run {
    my ($self) = @_;

    while (1) {
        my $line = $self->term->readline($self->prompt);

        print "\n" unless defined $line;
        last unless defined $line;
        last if $line eq 'exit';
        last if $line eq 'quit';

        $self->handle_input($line);
    }
}

sub handle_input {
    my ($self, $line) = @_;
    $self->show_help                 if $line =~ /^help/;
    $self->list_teams($1)            if $line =~ /^teams (.*)/;
    $self->list_projects($1)         if $line =~ /^projects in (.*)/;
    $self->list_tasks($1)            if $line =~ /^tasks in (.*)/;
    $self->show_task($1)             if $line =~ /^show task (.*)/;
}

sub show_help {
    print <<EOF;

Teams
  teams in <workspace>  list all teams

Projects
  projects in <team>    list projects in a team
  create project        create a project
  update project        update a project

Tasks
  tasks in <project>    list tasks in a project
  show task <task>      show task
  create task           create a task
  update task <task>    update a task
  
  show comments <task>  show comments on a task

EOF
}

sub display_data {
    my ($self, $list) = @_;
    for my $item (@$list) {
        my @keys = sort keys %$item;
        my $count = scalar @keys;
        my $fmt = "%-20s  "x$count . "\n";

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

sub list_teams {
    my ($self, $id) = @_;
    my $data = $self->asana->get("/organizations/$id/teams");
    $self->display_data($data);
}

sub list_projects {
    my ($self, $id) = @_;
    my $data = $self->asana->get("/teams/$id/projects", { archived => 0 });
    $self->display_data($data);
}

sub list_tasks {
    my ($self, $id) = @_;
    my $data = $self->asana->get("/projects/$id/tasks", { completed_since => 'now' });
    $self->display_data($data);
}

sub show_task {
    my ($self, $id) = @_;
    my $data = $self->asana->get("/tasks/$id");

    p $data;
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
