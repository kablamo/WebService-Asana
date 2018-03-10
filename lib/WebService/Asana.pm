package WebService::Asana;

use Moo;
use Mojo::UserAgent;
use WebService::Asana::Response;
use JSON::MaybeXS;

our $VERSION = "0.01";

has token         => (is => 'ro', required => 1);
has api_version   => (is => 'ro', lazy => 1, default => sub { '1.0' });
has workspace_id  => (is => 'rw');
has ua            => (is => 'ro', lazy => 1, builder => 1);
has base_url      => (is => 'ro', lazy => 1, builder => 1);
has auth_header   => (is => 'ro', lazy => 1, builder => 1);
has debug         => (is => 'ro', lazy => 1, default => sub { 1 });
has limit         => (is => 'ro', lazy => 1, default => sub { 100 });

sub _build_ua          { Mojo::UserAgent->new }
sub _build_base_url    { "https://app.asana.com/api/" . shift->api_version }
sub _build_auth_header { {Authorization => 'Bearer ' . shift->token } }

sub handle_response {
    my ($self, $tx) = @_;
    #if ($tx->req->method eq 'POST' || $tx->req->method eq 'PUT') {
    #    $tx->req->headers->content_type('application/json; charset=utf-8');
    #    $tx->req->content($json);
    #}
    if ($tx->res->is_success) {
        return $tx->res->json->{data} unless $tx->res->json->{next_page};

        my $data = $tx->res->json->{data};
        my @all_data = @$data;
        my $response = WebService::Asana::Response->new(
            response => $tx->res->json,
            token    => $self->token,
        );

        while (my $data = $response->next) {
            push @all_data, @$data;
            sleep 1;
        }

        return \@all_data;
    }
    else {
        if ($self->debug) {
            print $tx->req->to_string, "\n";
            print $tx->res->to_string, "\n";
        }
        my $method = $tx->res->content;
        die "Request failed $!" if $method eq 'PUT';
        die "Request failed $!" if $method eq 'GET';
        die "Request failed $!" if $method eq 'DELETE';
        die "Request failed $! (" . $tx->res->content . ")"
            if $method eq 'POST';
    }
}

sub get {
    my ($self, $url_suffix, $params) = @_;
    $params ||= {};
    $params->{limit} ||= $self->limit;
    my $url = Mojo::URL->new($self->base_url . $url_suffix);
    $url->query($params);
    my $tx = $self->ua->get($url => $self->auth_header);
    return $self->handle_response($tx);
}

sub post {
    my ($self, $url_suffix, $params) = @_;
    $params ||= {};
    my $url = Mojo::URL->new($self->base_url . $url_suffix);
    my $tx = $self->ua->post($url => $self->auth_header => json => {data => $params});
    return $self->handle_response($tx);
}

sub put {
    my ($self, $url_suffix, $params) = @_;
    $params ||= {};
    my $url = Mojo::URL->new($self->base_url . $url_suffix);
    my $tx = $self->ua->put($url => $self->auth_header => json => {data => $params});
    return $self->handle_response($tx);
}

sub delete {
    my ($self, $url_suffix, $params) = @_;
    $params ||= {};
    my $url = Mojo::URL->new($self->base_url . $url_suffix);
    $url->query($params);
    my $tx = $self->ua->delete($url => $self->auth_header);
    return $self->handle_response($tx);
}

## Lists all tasks in a $section_id.
## Captures all tasks between $section_id and $end_section_id (or end of list, if omitted).
## This is a hack. The API doesn't yet support https://app.asana.com/api/1.0/sections/$section_id/tasks
## for list view projects.
#sub get_section_tasks {
#    my ($args) = @_;
#    my $project_id = $args->{project_id} // '';
#    my $section_id = $args->{section_id} // '';
#    my $end_section_id = $args->{end_section_id} // '';
#    my $include_completed = $args->{include_completed} // 0;
#
#    my @tasks = get_project_tasks($project_id, $include_completed);
#
#    my @interesting_tasks;
#    my $in_section = 0;
#    for my $task (@tasks) {
#        last if $in_section && $task->{id} eq $end_section_id;
#        push @interesting_tasks, $task if $in_section;
#        $in_section = 1 if $task->{id} eq $section_id;
#    }
#
#    return @interesting_tasks;
#}
#
## upload attachment to a task
## returns the id of the attachment if the upload succeeds,
## dies on failure
#sub upload_attachment {
#    my ($task_id, $path) = @_;
#
#    my $ua  = LWP::UserAgent->new();
#    my $req = HTTP::Request::Common::POST(
#        "https://app.asana.com/api/1.0/tasks/$task_id/attachments",
#        Content_Type => 'form-data',
#        Content      => [ file => [$path] ],
#    );
#    $req->authorization('Bearer ' . $self->personal_access_token);
#
#    my $res = $ua->request($req);
#    die "Request failed" unless $res->is_success;
#
#    my $data = JSON->new->allow_nonref->decode($res->decoded_content);
#    return $data->{data}->{id};
#}
#
## get the id of a task based on its title and the id of the project it's in.
## returns the new tasks id if the request succeeds, 0 if it fails, and undef if the project name
## couldn't be found in the workspace.
#sub get_task_id {
#    my ($title, $proj_id) = @_;
#    if ($proj_id) {
#        my $url = "https://app.asana.com/api/1.0/projects/$proj_id/tasks";
#        my $res = get_request($url);
#        my $jso = JSON->new->allow_nonref;
#        my $tasklist = $jso->decode( $res->decoded_content );
#        my @tasks = @{$tasklist->{data}};
#        foreach (@tasks) {
#            my %hash = %{$_};
#            if ($hash{name} eq $title) {
#                return $hash{id};
#            }
#        }
#    }
#    else {
#        return undef;
#    }
#}
#
#sub get_tags {
#    my ($task_id) = @_;
#    my $url = "https://app.asana.com/api/1.0/tasks/$task_id/tags";
#    my $res = get_request($url);
#
#    my $jso = JSON->new->allow_nonref;
#    my $json = $jso->decode( $res->decoded_content );
#    return @{$json->{data}};
#}
#
#sub create_tag {
#    my ($tag_name) = @_;
#    my $url = "https://app.asana.com/api/1.0/tags";
#    my $json = encode_json({
#            "data" => {
#                "name" => $tag_name,
#                "workspace" => $self->workspace_id
#            }
#        });
#    my $res = post_request($json, $url);
#    my $jso = JSON->new->allow_nonref;
#    my $jres = $jso->decode( $res->decoded_content );
#    return $jres->{data}->{id};
#}
#
#sub add_tag {
#    my ($task_id, $tag_id) = @_;
#    my $url = "https://app.asana.com/api/1.0/tasks/$task_id/addTag";
#    my $json = encode_json({
#            "data" => {
#                "tag" => $tag_id,
#            }
#        });
#    my $res = post_request($json, $url);
#    return $res->decoded_content;
#}
#
#sub remove_tag {
#    my ($task_id, $tag_id) = @_;
#    my $url = "https://app.asana.com/api/1.0/tasks/$task_id/removeTag";
#    my $json = encode_json({
#            "data" => {
#                "tag" => $tag_id,
#            }
#        });
#    my $res = post_request($json, $url);
#    return $res->decoded_content;
#}
#
#sub has_tag {
#    my ($task_id, $tag_id) = @_;
#    my @tags = get_tags($task_id);
#    my %tag_hash = map { $_->{id} => undef } @tags;
#    return exists $tag_hash{$tag_id};
#}
#
#sub change_html_notes {
#    my ($task_id, $new_html_notes) = @_;
#    my $url = "https://app.asana.com/api/1.0/tasks/$task_id";
#    my $json = encode_json({
#            "data" => {
#                "html_notes" => $new_html_notes,
#            }
#        });
#    my $res = put_request($json, $url);
#    return 'OK' if $res;
#}
#
## comment on a task with the given task id.
## returns 1 if the comment succeeds and 0 if it doesn't.
#sub comment_on_task {
#    my ($task_id, $comment, %params) = @_;
#
#    # default to not using html
#    my $use_html = defined $params{use_html} && $params{use_html} || 0;
#    my $comment_field = $use_html && "html_text" || "text";
#
#    my $json = encode_json({
#            "data" => {
#                $comment_field => $comment,
#            }
#        });
#    my $url = "https://app.asana.com/api/1.0/tasks/$task_id/stories";
#    my $res = post_request($json, $url);
#    return 1;
#}
#
#sub set_parent_task {
#    my ($task_id, $parent_task_id) = @_;
#    my $url = "https://app.asana.com/api/1.0/tasks/$task_id/setParent";
#    my $json = encode_json({
#            "data" => {
#                "parent" => $parent_task_id,
#            }
#        });
#
#    my $res = post_request($json, $url);
#    return 1;
#}
#
#sub get_custom_fields {
#    my $url = "https://app.asana.com/api/1.0/workspaces/$workspace_id/custom_fields";
#    my $res = get_request($url);
#    my $data = JSON->new->allow_nonref->decode( $res->decoded_content );
#    return $data->{data};
#}
#
#sub get_project {
#    my ($project_id) = @_;
#    my $url = "https://app.asana.com/api/1.0/projects/$project_id";
#    my $res = get_request($url);
#    my $data = JSON->new->allow_nonref->decode( $res->decoded_content );
#    return $data->{data};
#}
#
#sub change_custom_field {
#    my ($task_id, $custom_field_id, $custom_field_value) = @_;
#    my $json = encode_json({data => {custom_fields => { $custom_field_id => $custom_field_value }}});
#    my $url  = "https://app.asana.com/api/1.0/tasks/$task_id";
#    my $res  = put_request($json, $url);
#    my $data = JSON->new->allow_nonref->decode( $res->decoded_content );
#    return $data->{data}->{id};
#}
#
#sub get_user {
#    my ($user_id) = @_;
#    my $url = "https://app.asana.com/api/1.0/users/$user_id";
#    my $res = get_request($url);
#    my $data = JSON->new->allow_nonref->decode( $res->decoded_content );
#
#    return $data->{data};
#}
#
#sub get_all_duckduckgo_users {
#    my @user_list;
#    my $url = "https://app.asana.com/api/1.0/workspaces/$workspace_id/users";
#    my $res = get_request($url);
#    my $data = JSON->new->allow_nonref->decode( $res->decoded_content );
#
#    foreach my $user (@{ $data->{data} }) {
#        my $user_data = get_user($user->{id});
#
#        if ($user_data && $user_data->{email} =~ /\@duckduckgo\.com$/ && $user_data->{email} !~ /^(?:feedback|stephen|futed)\@duckduckgo.com$/) {
#            push @user_list, $user_data;
#        }
#    }
#
#    return @user_list;
#}
#
#sub get_ops_duckduckgo_users {
#    my @user_list;
#    my $url = "https://app.asana.com/api/1.0/workspaces/$workspace_id/users";
#    my $res = get_request($url);
#    my $data = JSON->new->allow_nonref->decode( $res->decoded_content );
#
#    foreach my $user (@{ $data->{data} }) {
#        my $user_data = get_user($user->{id});
#
#        if ($user_data && $user_data->{email} =~ /\@duckduckgo\.com$/ && $user_data->{email} =~ /^(?:jeffrey|marc|eric|tim|isa|karol)\@duckduckgo.com$/) {
#            push @user_list, $user_data;
#        }
#    }
#
#    return @user_list;
#}

1;
__END__

=encoding utf-8

=head1 NAME

WebService::Asana - Implements the Asana API

=head1 SYNOPSIS

    use WebService::Asana;

    my $asana = WebService::Asana->new(token => $token);

    $asana->post($path, $params);     # create
    $asana->get($path, $params);      # read
    $asana->put($path, $params);      # update
    $asana->delete($path, $params);   # delete

=head1 DESCRIPTION

Implements the Asana API.

This module supports pagination.

The only supported means of authentication is via a Personal Access Token.  To
get a token:

=over 4

=item 1. Go to "My Profile Settings..." in Asana

=item 2. Go to the "Apps" tab

=item 3. Click "Manage Developer Apps"

=item 4. Click "Create New Personal Access Token"

=back

=head1 EXAMPLES

What follows are many examples.  It is not meant to be a comprehensive list or
guaranteed to be up to date.  Its just a small attempt at being helpful.  The
authoritative up to date place to look is:
L<https://asana.com/developers/api-reference>

=head2 Tasks

Get task details

    $asana->get("/tasks/$task_id");
    $asana->get("/tasks/$task_id")->data->{assignee}->{name};

Get subtasks

    $asana->get("/tasks/$task_id/subtasks");

Modify existing tasks

    # Change something about an existing task
    $asana->put("/tasks/$task_id", { assignee => $email });

    # Add followers to a task
    $asana->get("/tasks/$task_id/addFollowers", {
        followers => [$email1, $email2],
    });

    # Add an existing task to a project
    $asana->post("/tasks/$task_id/addProject", { 
        project => $project_id,
        section => $section_id,
    });

    # Upload an attachment to a task
    $asana->post("/tasks/$task_id/attachments", { file => [$path1, $path2] });

Create a new task

    $asana->post("/tasks", { 
        name       => "Build rocket boots and lazer eyes", # task name
        html_notes => "Thanks",                            # task description
        assignee   => 'eric@duckduckgo.com',
        due_on     => '2012-03-26',                        # or due_at
        followers  => ['jeffrey@duckduckgo.com', 'dax@duckduckgo.com'],
        parent     => $parent_task_id,
        projects   => [$project_id1, $project_id2],
    });

Delete a task

    $asana->delete("/tasks/$task_id");


=head2 Projects

Get tasks in a project

    # Get all visible tasks in a project (this is usually what you want)
    $asana->get("/projects/$project_id/tasks", { completed_since => 'now' });

    # Get all tasks in a project (starting w/completed ones from the beginning)
    $asana->get("/projects/$project_id/tasks");


=head2 Teams

Get all projects in a team

    $asana->get("/teams/$team_id/projects", { archived => 0 });

=head2 Organizations

Get all teams

    $asana->get("/organizations/$id/teams");

=head1 LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Eric Johnson E<lt>eric.git@iijo.orgE<gt>

=cut

