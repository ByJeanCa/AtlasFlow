# AtlasFlow — Build → Push → Plan → Apply → Configure → Verify
Monorepo that orchestrates a reproducible end-to-end pipeline with Jenkins:
* Docker: builds and publishes byjeanca/nginx-web:<tag>.
* Terraform: provisions minimal VPC + EC2 + SG in us-east-2.
* Ansible: installs Docker and spins up the app container.
* Verify: HTTP healthcheck and idempotent execution.


> ⚠️ Note: This v1 pipeline is intended as a **bootstrap** (initial provisioning + deployment).  
> It can be re-run and is idempotent, but it always re-provisions the infrastructure. 

## Architecture (v1)
* VPC with 2 public and 2 private subnets, IGW, and NAT (terraform-aws-modules/vpc module).
* EC2 t3.micro with public IP.
* Security Group:
  * 80/tcp: 0.0.0.0/0
  * 22/tcp: only your IP (injected by pipeline).
* Docker on EC2: runs nginx:stable-alpine with demo index.html.
* Dynamic Ansible inventory (amazon.aws.aws_ec2) filtering Terraform=true tag.

## Structure
```
.
├─ cont-app/                 # Imagen Docker (nginx + estáticos)
│  ├─ app/index.html
│  └─ Dockerfile
├─ infrastructure/           # Terraform: VPC, SG, EC2
│  ├─ main.tf
│  ├─ networking.tf
│  └─ variables.tf
├─ ansible/                  # Configuración de la EC2
│  ├─ ansible.cfg
│  ├─ deploy.yml
│  ├─ group_vars/all.yml
│  ├─ inventory/aws_ec2.yml  # Inventario dinámico
│  └─ roles/container_deploy/
│     └─ tasks/              # install_docker.yml, run_container.yml, main.yml
└─ Jenkinsfile               # Pipeline declarativo multi-stage
```

## Key variables
### Terraform (infrastructure/variables.tf):
* region = “us-east-2”
* amis = [“ami-...”] (Ubuntu)
* my_ip = [“x.x.x.x/32”] (injected by pipeline)

### Ansible (ansible/group_vars/all.yml):
* ansible_user: ubuntu
* image_repo: byjeanca/nginx-web
* image_tag: latest (overwritten by Jenkins with build number)
* container_name: webapp
* host_port: 80
* container_port: 80

## Pipeline (Jenkins)

### Stages:
1. Infrastructure provision
  * Run terraform init + apply -auto-approve.
  * Find your public IP via api.ipify.org and write it in terraform.tfvars as my_ip.

2. Push docker image
  * docker build in cont-app/ → tag byjeanca/nginx-web:<BUILD_NUMBER>.
  * docker push to Docker Hub.

3. Deploy
* Install collections (amazon.aws, community.docker).
* Install boto3/botocore for dynamic inventory.
* ansible-playbook ansible/deploy.yml -i ansible/inventory/aws_ec2.yml --extra-vars image_tag=<BUILD_NUMBER> --private-key <key>.

Real example (from your run):
```text 
Terraform Apply complete! Resources: 25 added, 0 changed, 0 destroyed.
Docker push → byjeanca/nginx-web:2
Ansible recap → ok=9 changed=6 failed=0
```

## How to run
### 1. From Jenkins (recommended)
* Configure credentials:
  * AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
  * Docker Hub (username + password)
  * SSH_KEY (private key for ubuntu@EC2)
* Run job:
  * Push to main or “Build Now.”
  * Wait for SUCCESS.

### 2.  Check manually
``` bash
# Obtain public IP (if you exported outputs)
terraform -chdir=infrastructure output -raw public_ip

# Check HTTP 200
curl -I http://<IP_PUBLICA>
```

### 3. Fast idempotence
* Run the Deploy stage again:
  * HTTP healthcheck should still be OK.
  * Minimal changes (ideally changed tends to 0 on second runs).

## Troubleshooting

* SSH fails / timeout
  * Verify that the SG has 22/tcp to your IP/32 (pipeline injects it).
  * Correct user: ubuntu.
  * Correct private key and permissions 0600.
* Dynamic inventory cannot find hosts
  * Check the Terraform=true tag on the instance.
  * Secure AWS credentials in the Ansible container (the pipeline already exports).
* Docker does not start
  * Check the docker service in EC2.
  * journalctl -u docker and docker ps.
  * Port 80 open in SG.
* NAT costs
  * The VPC module creates 2 NAT Gateways (one per AZ). To reduce costs in demos, consider using a single AZ or removing NAT if you do not need it.
* Cleaning (cost control) 
``` bash
terraform -chdir=infrastructure destroy -auto-approve
  ```
