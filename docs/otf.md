# AWS + OpenTofu

This project is designed to provision AWS resources using OpenTofu, a fork of Terraform.

## Project Structure

- **main.tf**: Contains the main configuration for the AWS resources.
- **providers.tf**: Specifies the provider configuration for AWS.
- **variables.tf**: Defines the variables used in the configuration.
- **outputs.tf**: Specifies the outputs of the configuration.
- **dev.tfvars**: Contains variable values specific to the DEV environment.
- **uat.tfvars**: Contains variable values specific to the UAT environment.
- **prod.tfvars**: Contains variable values specific to the PROD environment.
- **README.md**: Documentation for the project.

## Prerequisites

1. Ensure you have OpenTofu installed on your machine.

```console
$ winget install --exact --id=OpenTofu.Tofu
```

2. Verify OpenTofu installation

```console
$ tofu -version
```

3. Install AWS CLI

```console
$ msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi
```

4. Verify AWS CLI installation

```console
$ aws --version
```

5. Create an AWS billing Account

6. Create OpenTofu user role using the IAM service in the AWS Console. 

> User: OpenTofu

7. Give access permissions to OpenTofu IAM role

> AdministratorAccess
> AmazonS3FullAccess

6. Create access key for OpenTofu user in AWS Console

> Access key: AKIAX5EZDD2QXNBO5I5V
> Secret access key: Aq8wb2...
> local.infrastruture.pipeline

## Instructions: Local OpenTofu

1. Clone the repository:

   ```
   $ git clone <repository-url>
   ```

2. Step into /src folder:

   ```
   $ cd infrasructure
   ```

3. Configure your AWS credentials:

    ```
    $ aws configure
    AWS Access Key ID [****************RKCT]: AKIAX5EZDD2QXNBO5I5V
    AWS Secret Access Key [****************jYx6]: ...
    Default region name [eu-north-1]: eu-west-1                              
    Default output format [None]: json
    ```

    > Disconnect from Corporate VPN or PROXY to avoid CA (Certificate Authority) errors

    \* You can use environment variables as well:

    ```
    $ export AWS_ACCESS_KEY_ID=AKIA....
    $ export AWS_SECRET_ACCESS_KEY=xxxxxxxx
    $ export AWS_DEFAULT_REGION=eu-west-1
    ```

4. Initialize OpenTofu state

    ```console
    $ tofu init -var-file="prod.tfvars"
    ```

    *Comment the backend.tf code to manage the state locally.

5. Plan

    Recommended Approach: Makes the plan using "prod.tfvars" variables and saves the plan to use it later on the apply stage.

    ```console
    $ tofu plan -var-file="prod.tfvars" -out="prod.tfplan"
    ```

    Other plan commands:

    ```console
    $ tofu plan
    $ tofu plan -var-file="prod.tfvars"
    ```

6. Apply

    Recommended Approach: More reliable approach since OpenTofu applies an existing plan already validated during the plan stage. 

    ```console
    $ tofu apply "prod.tfplan"
        ...
        Apply complete! Resources: 5 added, 0 changed, 0 destroyed.     
        Outputs:
        ...
    ```

    Other apply commands

    ```console
    $ tofu apply
    $ tofu apply -var-file="prod.tfvars"
    ```

7. Verify OpenTofu AWS Infrastructure

    ```console
    $ tofu state list

    aws_cloudfront_distribution.frontend
    aws_cloudfront_origin_access_control.oac
    aws_s3_bucket.frontend
    aws_s3_bucket_policy.frontend_policy
    aws_s3_bucket_public_access_block.frontend
    ```

## Instructions: Destroy Local OpenTofu

If you need to delete all the infrastructure execute

```console´
$ tofu plan -var-file="prod.tfvars" -out="prod.tfplan" -destroy
$ tofu apply "prod.tfplan"
```

## Instructions: Remote OpenTofu

To enable remote state management with OpenTofu, you must first create the infrastructure required to store the state remotely.

This project uses the standard AWS backend pattern:
- S3 Bucket: Stores the OpenTofu state file and provides state locking to prevent multiple users or pipelines from applying changes simultaneously.

State locking ensures that only one OpenTofu operation runs at a time, preventing state corruption.

1. Create the Backend Infrastructure using **bootstrap.tf** file and the following code

    ```terraform
    resource "aws_s3_bucket" "otf_state_bucket" {
        bucket = var.otf_state_s3_bucket_name
        object_lock_enabled = true

        lifecycle {
            prevent_destroy = false
        }
    }

    resource "aws_s3_bucket_versioning" "otf_state_bucket_versioning" {
        bucket = aws_s3_bucket.otf_state_bucket.id

        versioning_configuration {
            status = "Enabled"
        }
    }

    resource "aws_s3_bucket_server_side_encryption_configuration" "otf_state_bucket_encryption" {
        bucket = aws_s3_bucket.otf_state_bucket.id

        rule {
            apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
            }
        }
    }

    resource "aws_s3_bucket_public_access_block" "otf_state_bucket_public_access_block" {
        bucket = aws_s3_bucket.otf_state_bucket.id

        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
    }

    resource "aws_s3_bucket_object_lock_configuration" "otf_state_bucket_lock" {
        bucket = aws_s3_bucket.otf_state_bucket.id

        object_lock_enabled = "Enabled"
    }
    ```

2.  Once the resources are created by running **tofu apply** locally, configure the OpenTofu backend. Uncomment or add the OpenTofu backend to **backend.tf**.

    ```terraform
    terraform {
        backend "s3" {
            bucket         = var.otf_state_s3_bucket_name
            key            = var.otf_state_s3_file_name
            region         = var.aws_region
            use_lockfile   = true
            encrypt        = true
        }
    }
    ```

3. Then reinitialize OpenTofu state. If a local state file exists, OpenTofu will prompt you to migrate the state to the remote backend. Migrate your current infastructure to preserve your resources.

    ```console
    $ tofu init -var-file="prod.tfvars" -migrate-state

        Initializing the backend...
        Do you want to copy existing state to the new backend?
        Pre-existing state was found while migrating the previous "local" backend to the
        newly configured "s3" backend. No existing state was found in the newly
        configured "s3" backend. Do you want to copy this state to the new "s3"
        backend? Enter "yes" to copy and "no" to start with an empty state.

        Enter a value: yes

        Successfully configured the backend "s3"! OpenTofu will automatically
        use this backend unless the backend configuration changes.

        Initializing provider plugins...
        - Reusing previous version of hashicorp/aws from the dependency lock file
        - Using previously-installed hashicorp/aws v6.0.0

        OpenTofu has been successfully initialized!

        You may now begin working with OpenTofu. Try running "tofu plan" to see
        any changes that are required for your infrastructure. All OpenTofu commands
        should now work.

        If you ever set or change modules or backend configuration for OpenTofu,
        rerun this command to reinitialize your working directory. If you forget, other
        commands will detect it and remind you to do so if necessary.
    ```

4. The next time you make a plan or apply new changes OpenTofu will use your remote backend. 

    ```console
    tofu plan -var-file="prod.tfvars" -out="prod.tfplan"
    tofu apply "prod.tfplan"
    ```

## Instructions: Destroy Remote OpenTofu

1. Initialize OpenTofu

    ```console
    cd infrastructure/src
    tofu init
    ```

2. Pull remote state locally

    Export the current remote state:

    ```console
    tofu state pull > terraform.tfstate
    ```

    This creates a local backup of the current infrastructure state.

3. Remove remote backend configuration

    Open your backend configuration (e.g. backend.tf) and remove or comment it out:

    ```terraform
    # Before (S3 backend)
    terraform {
        backend "s3" {
            bucket         = var.opentofu_state_s3_bucket_name
            key            = "terraform.tfstate"
            region         = var.aws_region
            dynamodb_table = var.opentofu_lock_dynamodb_table_name
            encrypt        = true
        }
    }
    ```

    ```terraform
    # After (local state)
    
    ```
    
    4. Reinitialize with state migration

    ```console
    tofu init -migrate-state
    ```

    When prompted, confirm migration. This moves the state from S3 → local terraform.tfstate.

    5. Verify state is local

    ```console
    tofu state list
    ```

    You should still see all managed resources.

    6. Before deleting the whole infrastructure, empty the S3 bucket content using AWS Console (Portal) or AWS CLI:

    ```console
    aws s3 rm s3://bucketname --recursive
    ```

    7. Re-enable **prevent_destroy = true** in the S3 buckets as well

    ```terraform
    resource "aws_s3_bucket" "opentofu_state" {
        bucket = var.opentofu_state_s3_bucket_name

        lifecycle {
            prevent_destroy = true
        }
    }
    ```

    7. Destroy all the infrastructure

    Now that state is local, so it is safe to destroy everything:

    ```console´
    $ tofu plan -var-file="prod.tfvars" -out="prod.tfplan" -destroy
    $ tofu apply "prod.tfplan"
    ```
