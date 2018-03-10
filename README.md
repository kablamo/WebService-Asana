# NAME

WebService::Asana - Implements the Asana API

# SYNOPSIS

    use WebService::Asana;

    my $asana = WebService::Asana->new(token => $token);

    $asana->post($path, $params);     # create
    $asana->get($path, $params);      # read
    $asana->put($path, $params);      # update
    $asana->delete($path, $params);   # delete

# DESCRIPTION

Implements the Asana API.

This module supports pagination.

The only supported means of authentication is via a Personal Access Token.  To
get a token:

- 1. Go to "My Profile Settings..." in Asana
- 2. Go to the "Apps" tab
- 3. Click "Manage Developer Apps"
- 4. Click "Create New Personal Access Token"

# EXAMPLES

What follows are many examples.  It is not meant to be a comprehensive list or
guaranteed to be up to date.  Its just a small attempt at being helpful.  The
authoritative up to date place to look is:
[https://asana.com/developers/api-reference](https://asana.com/developers/api-reference)

## Tasks

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

## Projects

Get tasks in a project

    # Get all visible tasks in a project (this is usually what you want)
    $asana->get("/projects/$project_id/tasks", { completed_since => 'now' });

    # Get all tasks in a project (starting w/completed ones from the beginning)
    $asana->get("/projects/$project_id/tasks");

## Teams

Get all projects in a team

    $asana->get("/teams/$team_id/projects", { archived => 0 });

## Organizations

Get all teams

    $asana->get("/organizations/$id/teams");

# LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Eric Johnson <eric.git@iijo.org>
