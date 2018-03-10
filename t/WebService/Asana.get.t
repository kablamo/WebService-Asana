use Test2::V0;
use WebService::Asana;
use DDP;

skip_all("Enviroment variable not found: \$WEBSERVICE_ASANA_TOKEN")
    unless $ENV{WEBSERVICE_ASANA_TOKEN};

skip_all("Environment variable not found: \$WEBSERVICE_ASANA_WORKSPACE")
    unless $ENV{WEBSERVICE_ASANA_WORKSPACE};

skip_all("Environment variable not found: \$WEBSERVICE_ASANA_TEAM")
    unless $ENV{WEBSERVICE_ASANA_TEAM};

skip_all("Environment variable not found: \$WEBSERVICE_ASANA_TASK")
    unless $ENV{WEBSERVICE_ASANA_TASK};

my $asana = WebService::Asana->new(token => $ENV{WEBSERVICE_ASANA_TOKEN});
my $task = $asana->get("/tasks/$ENV{WEBSERVICE_ASANA_TASK}");
my @keys = sort keys %$task;
my $expected_keys = subset {
    item 'completed';
    item 'followers';
    item 'hearts';
    item 'name';
    item 'notes';
};

is(
    \@keys, 
    $expected_keys, 
    "When task_id=$ENV{WEBSERVICE_ASANA_TASK} then found task",
);

done_testing;
