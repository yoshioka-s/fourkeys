# Four Keys Terraform

This directory contains modules and examples for deploying Four Keys with Terraform. The primary module `modules/fourkeys` uses the other sub-modules to deploy resources to a provided Google Cloud Project.  

## Usage

This is an example of deploying fourkeys as a remote Terraform module from [this GitHub project](https://github.com/dora-team/fourkeys):

```hcl
module "fourkeys" {
  source    = "github.com/dora-team/fourkeys//terraform/modules/fourkeys"
  project_id = "your-google-cloud-project-id"
  parsers   = ['github']
}
```

The example above will deploy Four Keys with a GitHub parser for GitHub events. See the `terraform/example` directory for full example and options.

Alternatively, you can fork the fourkeys project and deploy as a local module from the `terraform/example` directory:

```hcl
module "fourkeys" {
  source    = "../modules/fourkeys"
  project_id = "your-google-cloud-project-id"
  parsers   = ['github']
}
```

## Before you begin

To deploy Four Keys with Terraform, you will first need:

* A Google Cloud project with billing enabled
* The owner role assigned to you on the project
* The [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) and [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed on your local machine. We recommend deploying from [Cloud Shell](https://shell.cloud.google.com/?show=ide%2Cterminal) on your Google Cloud project.

## Deploying with Terraform

1. Set an environment variable indicating your Google Cloud project ID:
    ```sh
    export PROJECT_ID="YOUR_PROJECT_ID"
    ```

1. Clone the fourkeys git repository and change into the root directory
   ```
   git clone https://github.com/dora-team/fourkeys.git && cd fourkeys
   ```

1. Use Cloud Build to build and push containers to Google Container Registry for the dashboard, event-handler:
   ```
   gcloud builds submit dashboard --config=dashboard/cloudbuild.yaml --project $PROJECT_ID && \
   gcloud builds submit event-handler --config=event-handler/cloudbuild.yaml --project $PROJECT_ID
   ```

1. Use Cloud Build to build and push containers to Google Container Registry for the parsers you plan to use. See the [`bq-workers`](../bq-workers/) for available options. GitHub for example:
   ```
   gcloud builds submit bq-workers --config=bq-workers/parsers.cloudbuild.yaml --project $PROJECT_ID --substitutions=_SERVICE=github
   ```

1. Change your working directory to `terraform/example` and rename `terraform.tfvars.example` to `terraform.tfvars`
   ```
   cd terraform/example && mv terraform.tfvars.example terraform.tfvars
   ```

1. Edit `terraform.tfvars` with values for the required variables. See `variables.tf` for a list of the variables, along with their descriptions and default values. Values not defined in `terraform.tfvars` will use default values defined in `variables.tf`

1. Run the following commands from the `example` directory:

    `terraform init` to inialize Terraform and download the module

    `terraform plan` to preview changes.

    `terraform apply` to deploy the resources.

## Generating mock data

To test your Four Keys deployment, you can generate mock data that simulates events from a GitHub repository.  

1. Export your event handler URL an environment variable. This is the webhook URL that will receive events:

    ```sh
    export WEBHOOK=`gcloud run services list --project $PROJECT_ID | grep event-handler | awk '{print $4}'`
    ```

1. Export your event handler secret to an environment variable. This is the secret used to authenticate events sent to the webhook:

    ```sh
    export SECRET=`gcloud secrets versions access 1 --secret=event-handler --project $PROJECT_ID`
    ```

1. From the root of the fourkeys project run:

    ```sh
    python3 data-generator/generate_data.py --vc_system=github
    ```

    You can see these events being run through the pipeline:
    * The event handler logs show successful requests
    * The Pub/Sub topic show messages posted
    * The BigQuery GitHub parser show successful requests

1. View the generated data in the `events_raw` table in with bq:

    ```sh
    bq query --project_id $PROJECT_ID 'SELECT * FROM four_keys.events_raw WHERE source = "githubmock";'
    ```

    Or query the table directly in [BigQuery](https://console.cloud.google.com/bigquery):

    ```sql
    SELECT * FROM four_keys.events_raw WHERE source = 'githubmock';
    ```
