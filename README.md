# hcp-packer-demo :tada:

This repo holds the code for my "Automating Image Pipelines with HCP Packer" presentation at [HashiTalks 2022](https://events.hashicorp.com/hashitalks2022). It contains functional code examples for packaging an AMI with a static go binary with Packer, running an integration test against that AMI, and then promoting the validated image to dev, staging, and production release channels via HCP Packer.

[![IMAGE ALT TEXT](https://user-images.githubusercontent.com/7110138/162481240-f9b5e487-dedd-47e9-aabd-6b32a17fd34e.png)](http://www.youtube.com/watch?v=C0DEQZjzYUs "Automating Image Pipelines with HCP Packer")


## Getting Started

### Go Web App

The `./app` directory has a very bare-bones Go-based web server implementation that returns a `Hello World!` string for any request.

If you wish to compile the app for testing, you can run the following:

```bash
# compile go binary
go build -o ./bin/server ./app/main.go

# start server
./bin/server
```

You can now go to http://localhost:8080 in a web browser, or send a request via curl:

```bash
❯ curl http://localhost:8080
Hello world!
```

### Packer

The `./packer` directory holds the Packer template for building an Ubuntu 20.10 server that hosts the aforementioned Go binary. It integrates with HCP Packer so that every time `packer build` is ran, metadata about the artifacts generated are sent to HCP Packer as an **iteration**.

```bash
cd ./.packer
packer init .
packer build .
```

### Terraform

The `./terraform` directory holds Terraform code that spins up an EC2 instance hosting the Go web app built earlier via pulling the latest AMI information from HCP Packer. It then attaches a public IP address and outputs the health check endpoint exposed by the web server.

:warning: This Terraform code is meant only to be used as a simple example of E2E testing infrastructure. It is for demo purposes and does not take into account the strict security controls that you should consider when making an application production-ready.

```bash
cd ./.terraform
terraform init
terraform apply -var="iteration_id=$iteration_id" # replace with your desired HCP Packer iteration
```

### Integration Test

The `./.github/scripts/e2e_test.sh` script acts as a simple integration testing script. It functions by taking in a health check endpoint url (output from Terraform) and tries to connect every 5 seconds up to 25 attempts. If the health check endpoint exposed by the web app returns a 200 OK, the script succeeds, otherwise it exists with a failure. In practice, replace this with a much more thorough test suite. 

```bash
cd ./.github/scripts
./e2e_test.sh <healthcheck_endpoint>
```

Example: 
```
❯ ./e2e_test.sh https://example.com/api/v2/healthz
[Check: 1/25] Service is not ready yet, retrying in 5 seconds...
[Check: 2/25] Service is not ready yet, retrying in 5 seconds...
🎉 Service is up! 🎉
```

### GitHub Actions Image Build Workflow

All of the steps above are chained together into an automated pipeline via a GitHub Actions workflow that can be found at `./.github/workflows/build_and_deploy.yaml`. This workflow has four jobs:
 - `build` - Compiles the Go app and bakes it into an AMI with Packer
 - `test` - Spins up an EC2 instance with the newly build AMI via Terraform, runs an integration test on it, and then cleans up the infrastructure
 - `promote-dev-staging` - If the integration test was successful, this job promotes the HCP Packer iteration to the `dev` and `staging` release channels
 - `promote-prod` - After manual approval, this job promotes the HCP Packer iteration to the `prod` release channel

 :bulb: When implementing your own version of this pipeline, you may want to trigger a Terraform plan/apply for your workspaces to deploy the latest machine images across your infrastructure. For example, you could expand the `promote-<env>` jobs listed above with a CLI-driven `terraform plan` command or similar.
