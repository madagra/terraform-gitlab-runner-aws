# Provision an autoscaled Gitlab runner on AWS

This simple Terraform code provision one Gitlab runner on AWS with a template configuration
implementing the autoscaling feature using EC2 and the `docker-machine` executor.

## Provision

In order to provision a new runner, you need to do the following:

* install `terraform` (tested with version 1.4.4)
* set all the variables to be replaced in the `terraform.tfvars` file. They include the
AWS access and secret keys, the AWS profile (set to `default` if you did not set profiles) and
the name and token of the runner to be created
* execute the usual Terraform sequence of commands to provision the runner:

```bash
terraform init
terraform plan # check what you are doing
terraform apply
```

After that, you will be able to connect to the runner manager instance using
the appropriate key pair chosen.

## The sharp bits

* **Manual runner registration**: a new runner must be manually registered by SSHing
into the corresponding manager and execute:

```
sudo mv /etc/gitlab-runner/config.toml.tmpl /etc/gitlab-runner/config.toml
gitlab-runner start
```
* **Do not mess with the remote state**: the file `backend.tf` is auto-generated 
and points to a previously generate environment in the `eu-west-3` region. 
This environment notably already contains:

    * the VPC which can be reused for hosting new runners. 
    * the S3 bucket used a shared cache for the runners

Do not remove this file and always make sure that you are using
a cloud-based backend to store your state, i.e. you should **never** have a `terraform.tfstate`
file in your project folder, otherwise you risk to corrupt the remotely saved state.
