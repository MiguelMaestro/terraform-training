# TERRAFORM

> [Terraform CLI cheatsheet](https://acloudguru-content-attachment-production.s3-accelerate.amazonaws.com/1622032650435-terraform-cheatsheet-from-ACG.pdf "Terraform Cheatsheet")

## Comandos terraform

- Instalación terraform en Red Hat 8

    ```shell
    sudo yum install -y yum-utils
    sudo yum update
    sudo yum-config-manager --add-repo https://rpm.release.hashicorp.com/RHEL/hashicorp.repo
    sudo yum -y install terraform
    ```

- Muestra todas las opciones del comando terraform

    ```shell
    terraform
    ```

- Muestra la versión de terraform

    ```shell
    terraform version
    ```

- Habilitar log detallado para los comandos terraform

    ```shell
    export TF_LOG=TRACE
    ```

- Inicializar un directorio de trabajo (en la misma ruta donde se encuentre el fichero .tf)

    ```shell
    terraform init
    ```

- Revisar acciones realizadas al implementar el código terraform

     ```shell
    terraform plan
    ```

- Aplicar código

    ```yaml
    terraform apply
    # Cuando lo solicite, escribir yes y presionar enter
    terraform apply --auto-approve
    # --auto-approve evita que tengamos que escribir yes para implementar el código
    data.aws_ssm_parameter.linuxAmi: Refreshing state...
    data.aws_availability_zones.azs: Refreshing state...
    aws_vpc.vpc_master: Creating...
    aws_vpc.vpc_master: Creation complete after 2s [id=vpc-0ae59746e4e42596e]
    aws_security_group.sg: Creating...
    aws_subnet.subnet: Creating...
    aws_subnet.subnet: Creation complete after 1s [id=subnet-0f6595cbb0822dc5f]
    aws_security_group.sg: Creation complete after 3s [id=sg-08138c215d8a9850f]
    aws_instance.ec2-vm: Creating...
    aws_instance.ec2-vm: Still creating... [10s elapsed]
    aws_instance.ec2-vm: Creation complete after 12s [id=i-03168ed1d23c1b0d3]

    Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
    ```

- Listar espacio de trabajo

     ```shell
    terraform workspace list 
    # El espacio de trabajo con un * es el espacio de trabajo en el que nos encontramos actualmente
    ```

- Crear nuevo espacio de trabajo

    ```shell
    terraform workspace new test
    ```

- Rastrear espacios de trabajo

    ```shell
    terraform state list
    data.aws_availability_zones.azs
    data.aws_ssm_parameter.linuxAmi
    aws_instance.ec2-vm
    aws_security_group.sg
    aws_subnet.subnet
    aws_vpc.vpc_master
    ```

- Cambiar de espacio de trabajo

    ```shell
    terraform workspace select default
    terraform workspace select test
    ```

- Eliminar areas de trabajo

    ```shell
    terraform destroy --auto-approve
    ```

- Formatear código en tosdos los archivos para preparar la implementación

    ```shell
    terraform fmt -recursive
    ```

- Valide el código para buscar errores en la sintaxis, los parámetros o los atributos dentro de los
  recursos de Terraform que puedan impedir que se implemente correctamente

    ```shell
    terraform validate
    ```

## Ejemplos de ficheros de configuración de Terraform

El formato de ficheros de configuración de terraform es .tf pero se puede ver tambien la variables .json.tf

- Ejemplo de un fichero de configuración:

    ```shell
    provider "aws" {
        alias  = "us-east-1"
        region = "us-east-1"
    }

    provider "aws" {
        alias  = "us-west-2"
        region = "us-west-2"
    }


    resource "aws_sns_topic" "topic-us-east" {
        provider = aws.us-east-1
        name     = "topic-us-east"
    }

    resource "aws_sns_topic" "topic-us-west" {
        provider = aws.us-west-2
        name     = "topic-us-west"
    }
    ```

- Otro ejemplo:

    ```shell
    # AWS es el proveedor seleccionado
    provider "aws" {
        region = terraform.workspace == "default" ? "us-east-1" : "us-west-2"
    }

    #Get Linux AMI ID using SSM Parameter endpoint in us-east-1
    data "aws_ssm_parameter" "linuxAmi" {
        name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
    }

    #Create and bootstrap EC2 in us-east-1
    resource "aws_instance" "ec2-vm" {
        ami                         = data.aws_ssm_parameter.linuxAmi.value
        instance_type               = "t3.micro"
        associate_public_ip_address = true
        vpc_security_group_ids      = [aws_security_group.sg.id]
        subnet_id                   = aws_subnet.subnet.id
        tags = {
            Name = "${terraform.workspace}-ec2"
                    # En el código que crea la máquina virtual EC2, hemos incrustado la variable en el atributo, por lo que podemos
                    # distinguir fácilmente esos recursos cuando se crean dentro de sus respectivos espacios de trabajo por su nombre:
                    # $terraform.workspaceName<workspace name>-ec2
        }
    }
    ```

- Ejemplo de fichero network.tf

    ```shell
    # Creando VPC en us-east-1
    resource "aws_vpc" "vpc_master" {
        cidr_block = "10.0.0.0/16"
        tags = {
            Name = "${terraform.workspace}-vpc"
        }

    }

    # Get all available AZ's in VPC for master region
    data "aws_availability_zones" "azs" {
        state = "available"
    }

    # Create subnet # 1 in us-east-1
    resource "aws_subnet" "subnet" {
        availability_zone = element(data.aws_availability_zones.azs.names, 0)
        vpc_id            = aws_vpc.vpc_master.id
        cidr_block        = "10.0.1.0/24"

        tags = {
            Name = "${terraform.workspace}-subnet"
        }
    }


    # En el código que crea el recurso del grupo de seguridad, hemos incrustado la variable en el atributo, por lo que podemos
    # distinguir fácilmente esos recursos cuando se crean dentro de sus respectivos espacios de trabajo por su nombre:
    # $terraform.workspaceName<workspace name>-securitygroup
    resource "aws_security_group" "sg" {
        name        = "${terraform.workspace}-sg"
        description = "Allow TCP/22"
        vpc_id      = aws_vpc.vpc_master.id
        ingress {
            description = "Allow 22 from our public IP"
            from_port   = 22
            to_port     = 22
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }
        egress {
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"]
        }
        tags = {
            Name = "${terraform.workspace}-securitygroup"
        }
    } 
    ```

- Ejemplo main.tf

    ```shell
    provider "aws" {
        region = var.region
    }

    resource "aws_vpc" "this" {
        cidr_block = "10.0.0.0/16"
    }

    resource "aws_subnet" "this" {
        vpc_id     = aws_vpc.this.id
    cidr_block = "10.0.1.0/24"
    }

    data "aws_ssm_parameter" "this" {
        name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
    }
    ```

- Ejemplo variables.tf

    ```shell
    variable "region" {
        type    = string
        default = "us-east-1"
    }
    ```

- Ejemplo outputs.tf
  > Este código es fundamental para exportar valores a su código terraform principal, donde hará referencia a este módulo.
  En concreto devuelve los identificadores de subred y AMI de la instancia EC2

    ```shell
    output "subnet_id" {
        value = aws_subnet.this.id
    }

    output "ami_id" {
    value = data.aws_ssm_parameter.this.value
    }  
    ```

- Ejemplo main.tf

    ```shell
    variable "main_region" {
        type    = string
        default = "us-east-1"
    }

    provider "aws" {
        region = var.main_region
    }

    module "vpc" {
        source = "./modules/vpc"
        region = var.main_region
    }

    resource "aws_instance" "my-instance" {
        ami           = module.vpc.ami_id
        subnet_id     = module.vpc.subnet_id
        instance_type = "t2.micro"
    }
    ```

## Laboratorio - Explorando la funcionalidad de estado de Terraform

### Comprobar el estado de Terraform y Minikube

1. Comprobar el estado de terraform

    ```shell
    $ terraform version
    Terraform v0.13.3

    Your version of Terraform is out of date! The latest version
    is 1.2.3. You can update by downloading from https://www.terraform.io/downloads.html
    ```

2. Comprobar el estado de minikube

    ```shell
    $ minikube status
    minikube
    type: Control Plane
    host: Stopped
    kubelet: Stopped
    apiserver: Stopped
    kubeconfig: Stopped
    ```

### Clonar código Terraform

1. Cambiar al directorio donde se encuentra el código

    ```shell
    $ cd lab_code/
    $ cd section2-hol1/
    ```
2. Revisar el código

    ```shell
    $ vim main.tf
    
    provider "kubernetes" {
        config_path = "~/.kube/config"
    }

    resource "kubernetes_deployment" "tf-k8s-deployment" {
        metadata {
            name = "tf-k8s-deploy"
            labels = {
            name = "terraform-k8s-deployment"
            }
        }

        spec {
            replicas = 2

            selector {
                match_labels = {
                    name = "terraform-k8s-deployment"
                }
            }

            template {
                metadata {
                    labels = {
                        name = "terraform-k8s-deployment"
                    }
                }

                spec {
                    container {
                        image = "nginx"
                        name  = "nginx"

                    }
                }
            }
        }
    }
    ```

### Implementar el código de Terraform clonado

1. Iniciar el directorio de trabajo

    ```shell
    terraform init
    ```

2. Revisar las acciones que se realizarán al implementar el código

    ```shell
    terraform plan
    Refreshing Terraform state in-memory prior to plan...
    The refreshed state will be used to calculate this plan, but will not be
    persisted to local or remote state storage.


    ------------------------------------------------------------------------

    An execution plan has been generated and is shown below.
    Resource actions are indicated with the following symbols:
    + create

    Terraform will perform the following actions:

    # kubernetes_deployment.tf-k8s-deployment will be created
    + resource "kubernetes_deployment" "tf-k8s-deployment" {
        + id               = (known after apply)
        + wait_for_rollout = true

        + metadata {
            + generation       = (known after apply)
            + labels           = {
                + "name" = "terraform-k8s-deployment"
                }
            + name             = "tf-k8s-deploy"
            + namespace        = "default"
            + resource_version = (known after apply)
            + uid              = (known after apply)
            }

        + spec {
            + min_ready_seconds         = 0
            + paused                    = false
            + progress_deadline_seconds = 600
            + replicas                  = "2"
            + revision_history_limit    = 10

            + selector {
                + match_labels = {
                    + "name" = "terraform-k8s-deployment"
                    }
                }

            + strategy {
                + type = (known after apply)

                + rolling_update {
                    + max_surge       = (known after apply)
                    + max_unavailable = (known after apply)
                    }
                }

            + template {
                + metadata {
                    + generation       = (known after apply)
                    + labels           = {
                        + "name" = "terraform-k8s-deployment"
                        }
                    + name             = (known after apply)
                    + resource_version = (known after apply)
                    + uid              = (known after apply)
                    }

                + spec {
                    + automount_service_account_token  = true
                    + dns_policy                       = "ClusterFirst"
                    + enable_service_links             = true
                    + host_ipc                         = false
                    + host_network                     = false
                    + host_pid                         = false
                    + hostname                         = (known after apply)
                    + node_name                        = (known after apply)
                    + restart_policy                   = "Always"
                    + service_account_name             = (known after apply)
                    + share_process_namespace          = false
                    + termination_grace_period_seconds = 30

                    + container {
                        + image                      = "nginx"
                        + image_pull_policy          = (known after apply)
                        + name                       = "nginx"
                        + stdin                      = false
                        + stdin_once                 = false
                        + termination_message_path   = "/dev/termination-log"
                        + termination_message_policy = (known after apply)
                        + tty                        = false

                        + resources {
                            + limits   = (known after apply)
                            + requests = (known after apply)
                            }
                        }

                    + image_pull_secrets {
                        + name = (known after apply)
                        }

                    + readiness_gate {
                        + condition_type = (known after apply)
                        }

                    + volume {
                        + name = (known after apply)

                        + aws_elastic_block_store {
                            + fs_type   = (known after apply)
                            + partition = (known after apply)
                            + read_only = (known after apply)
                            + volume_id = (known after apply)
                            }

                        + azure_disk {
                            + caching_mode  = (known after apply)
                            + data_disk_uri = (known after apply)
                            + disk_name     = (known after apply)
                            + fs_type       = (known after apply)
                            + kind          = (known after apply)
                            + read_only     = (known after apply)
                            }

                        + azure_file {
                            + read_only        = (known after apply)
                            + secret_name      = (known after apply)
                            + secret_namespace = (known after apply)
                            + share_name       = (known after apply)
                            }

                        + ceph_fs {
                            + monitors    = (known after apply)
                            + path        = (known after apply)
                            + read_only   = (known after apply)
                            + secret_file = (known after apply)
                            + user        = (known after apply)

                            + secret_ref {
                                + name      = (known after apply)
                                + namespace = (known after apply)
                                }
                            }

                        + cinder {
                            + fs_type   = (known after apply)
                            + read_only = (known after apply)
                            + volume_id = (known after apply)
                            }

                        + config_map {
                            + default_mode = (known after apply)
                            + name         = (known after apply)
                            + optional     = (known after apply)

                            + items {
                                + key  = (known after apply)
                                + mode = (known after apply)
                                + path = (known after apply)
                                }
                            }

                        + csi {
                            + driver            = (known after apply)
                            + fs_type           = (known after apply)
                            + read_only         = (known after apply)
                            + volume_attributes = (known after apply)

                            + node_publish_secret_ref {
                                + name = (known after apply)
                                }
                            }

                        + downward_api {
                            + default_mode = (known after apply)

                            + items {
                                + mode = (known after apply)
                                + path = (known after apply)

                                + field_ref {
                                    + api_version = (known after apply)
                                    + field_path  = (known after apply)
                                    }

                                + resource_field_ref {
                                    + container_name = (known after apply)
                                    + divisor        = (known after apply)
                                    + resource       = (known after apply)
                                    }
                                }
                            }

                        + empty_dir {
                            + medium     = (known after apply)
                            + size_limit = (known after apply)
                            }

                        + fc {
                            + fs_type      = (known after apply)
                            + lun          = (known after apply)
                            + read_only    = (known after apply)
                            + target_ww_ns = (known after apply)
                            }

                        + flex_volume {
                            + driver    = (known after apply)
                            + fs_type   = (known after apply)
                            + options   = (known after apply)
                            + read_only = (known after apply)

                            + secret_ref {
                                + name      = (known after apply)
                                + namespace = (known after apply)
                                }
                            }

                        + flocker {
                            + dataset_name = (known after apply)
                            + dataset_uuid = (known after apply)
                            }

                        + gce_persistent_disk {
                            + fs_type   = (known after apply)
                            + partition = (known after apply)
                            + pd_name   = (known after apply)
                            + read_only = (known after apply)
                            }

                        + git_repo {
                            + directory  = (known after apply)
                            + repository = (known after apply)
                            + revision   = (known after apply)
                            }

                        + glusterfs {
                            + endpoints_name = (known after apply)
                            + path           = (known after apply)
                            + read_only      = (known after apply)
                            }

                        + host_path {
                            + path = (known after apply)
                            + type = (known after apply)
                            }

                        + iscsi {
                            + fs_type         = (known after apply)
                            + iqn             = (known after apply)
                            + iscsi_interface = (known after apply)
                            + lun             = (known after apply)
                            + read_only       = (known after apply)
                            + target_portal   = (known after apply)
                            }

                        + local {
                            + path = (known after apply)
                            }

                        + nfs {
                            + path      = (known after apply)
                            + read_only = (known after apply)
                            + server    = (known after apply)
                            }

                        + persistent_volume_claim {
                            + claim_name = (known after apply)
                            + read_only  = (known after apply)
                            }

                        + photon_persistent_disk {
                            + fs_type = (known after apply)
                            + pd_id   = (known after apply)
                            }

                        + projected {
                            + default_mode = (known after apply)

                            + sources {
                                + config_map {
                                    + name     = (known after apply)
                                    + optional = (known after apply)

                                    + items {
                                        + key  = (known after apply)
                                        + mode = (known after apply)
                                        + path = (known after apply)
                                        }
                                    }

                                + downward_api {
                                    + items {
                                        + mode = (known after apply)
                                        + path = (known after apply)

                                        + field_ref {
                                            + api_version = (known after apply)
                                            + field_path  = (known after apply)
                                            }

                                        + resource_field_ref {
                                            + container_name = (known after apply)
                                            + divisor        = (known after apply)
                                            + resource       = (known after apply)
                                            }
                                        }
                                    }

                                + secret {
                                    + name     = (known after apply)
                                    + optional = (known after apply)

                                    + items {
                                        + key  = (known after apply)
                                        + mode = (known after apply)
                                        + path = (known after apply)
                                        }
                                    }

                                + service_account_token {
                                    + audience           = (known after apply)
                                    + expiration_seconds = (known after apply)
                                    + path               = (known after apply)
                                    }
                                }
                            }

                        + quobyte {
                            + group     = (known after apply)
                            + read_only = (known after apply)
                            + registry  = (known after apply)
                            + user      = (known after apply)
                            + volume    = (known after apply)
                            }

                        + rbd {
                            + ceph_monitors = (known after apply)
                            + fs_type       = (known after apply)
                            + keyring       = (known after apply)
                            + rados_user    = (known after apply)
                            + rbd_image     = (known after apply)
                            + rbd_pool      = (known after apply)
                            + read_only     = (known after apply)

                            + secret_ref {
                                + name      = (known after apply)
                                + namespace = (known after apply)
                                }
                            }

                        + secret {
                            + default_mode = (known after apply)
                            + optional     = (known after apply)
                            + secret_name  = (known after apply)

                            + items {
                                + key  = (known after apply)
                                + mode = (known after apply)
                                + path = (known after apply)
                                }
                            }

                        + vsphere_volume {
                            + fs_type     = (known after apply)
                            + volume_path = (known after apply)
                            }
                        }
                    }
                }
            }
        }

    # kubernetes_service.tf-k8s-service will be created
    + resource "kubernetes_service" "tf-k8s-service" {
        + id                     = (known after apply)
        + status                 = (known after apply)
        + wait_for_load_balancer = true

        + metadata {
            + generation       = (known after apply)
            + labels           = {
                + "name" = "tf-k8s-deploy"
                }
            + name             = "terraform-k8s-service"
            + namespace        = "default"
            + resource_version = (known after apply)
            + uid              = (known after apply)
            }

        + spec {
            + cluster_ip                  = (known after apply)
            + external_traffic_policy     = (known after apply)
            + health_check_node_port      = (known after apply)
            + ip_families                 = (known after apply)
            + ip_family_policy            = (known after apply)
            + publish_not_ready_addresses = false
            + session_affinity            = "None"
            + type                        = "NodePort"

            + port {
                + node_port   = 30080
                + port        = 80
                + protocol    = "TCP"
                + target_port = "80"
                }
            }
        }

    Plan: 2 to add, 0 to change, 0 to destroy.

    ------------------------------------------------------------------------

    Note: You didn't specify an "-out" parameter to save this plan, so Terraform
    can't guarantee that exactly these actions will be performed if
    "terraform apply" is subsequently run.
    ```
    En este caso creará dos recursos.

    ```Shell
    ls -l
    ```
    Comprobamos que aún no se ha creado el fichero terraform.tfstate. Para ello debemos implemetar el código

    ```shell
    terraform apply
    Plan: 2 to add, 0 to change, 0 to destroy.

    Do you want to perform these actions?
    Terraform will perform the actions described above.
    Only 'yes' will be accepted to approve.

    Enter a value: yes

    kubernetes_service.tf-k8s-service: Creating...
    kubernetes_service.tf-k8s-service: Creation complete after 0s [id=default/terraform-k8s-service]
    kubernetes_deployment.tf-k8s-deployment: Creating...
    kubernetes_deployment.tf-k8s-deployment: Still creating... [10s elapsed]
    kubernetes_deployment.tf-k8s-deployment: Creation complete after 16s [id=default/tf-k8s-deploy]

    Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
    ```

### Observe cómo el archivo de estado de Terraform rastrea los recursos

1. Compruebe que los pods se han creado

    ```shell
    $ kubectl get pods
    NAME                            READY   STATUS    RESTARTS   AGE
    tf-k8s-deploy-9c7b8d989-77b2t   1/1     Running   0          62s
    tf-k8s-deploy-9c7b8d989-t4d9n   1/1     Running   0          62s
    ```

2. Enumere todos los recursos que está siendo rastreados

    ```shell
    $ terraform state list
    kubernetes_deployment.tf-k8s-deployment
    kubernetes_service.tf-k8s-service
    ```

3. Vea el atributo que está rastreando el archivo de estado terraform y el recurso: replicasgrepkubernetes_deployment.tf-k8s-deployment

    ```shell
    $ terraform state show kubernetes_deployment.tf-k8s-deployment | egrep replicas
    replicas                  = "2"
    ```

4. Cambiar el fichero main, aumentar el número de réplicas a 4

    ```shell
    spec {
    replicas = 4

    selector {
      match_labels = {
        name = "terraform-k8s-deployment"
      }
    }
    ```

5. Revise las acciones que se realizarán y aplicarlas

    ```shell
    $ terraform plan
    $ terraform apply
    Plan: 0 to add, 1 to change, 0 to destroy.

    Do you want to perform these actions?
    Terraform will perform the actions described above.
    Only 'yes' will be accepted to approve.

    Enter a value: yes

    kubernetes_deployment.tf-k8s-deployment: Modifying... [id=default/tf-k8s-deploy]
    kubernetes_deployment.tf-k8s-deployment: Modifications complete after 4s [id=default/tf-k8s-deploy]

    Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
    ```

6. Comprobar pods.

    ```shell
    Plan: 0 to add, 1 to change, 0 to destroy.

    Do you want to perform these actions?
    Terraform will perform the actions described above.
    Only 'yes' will be accepted to approve.

    Enter a value: yes

    kubernetes_deployment.tf-k8s-deployment: Modifying... [id=default/tf-k8s-deploy]
    kubernetes_deployment.tf-k8s-deployment: Modifications complete after 4s [id=default/tf-k8s-deploy]

    Apply complete! Resources: 0 added, 1 changed, 0 destroyed.

7. Ver que el número de réplicas a aumentado

    ```shell
    $ terraform state show kubernetes_deployment.tf-k8s-deployment | egrep replicas
    replicas                  = "4"
    ```

### Destruir la infraestructura creada

1. Eliminar

    ```shell
    $ terraform destroy
    Plan: 0 to add, 0 to change, 2 to destroy.

    Do you really want to destroy all resources?
    Terraform will destroy all your managed infrastructure, as shown above.
    There is no undo. Only 'yes' will be accepted to confirm.

    Enter a value: yes

    kubernetes_service.tf-k8s-service: Destroying... [id=default/terraform-k8s-service]
    kubernetes_service.tf-k8s-service: Destruction complete after 0s
    kubernetes_deployment.tf-k8s-deployment: Destroying... [id=default/tf-k8s-deploy]
    kubernetes_deployment.tf-k8s-deployment: Destruction complete after 1s

    Destroy complete! Resources: 2 destroyed.
    ```

2. Al listar los ficheros del directorio, vemos que se ha creado el fichero terraform.tfstate.backup

    ```shell
    $ ls -l
    total 24
    -rw-r--r-- 1 cloud_user cloud_user  577 Jun 22 07:06 main.tf
    -rw-r--r-- 1 cloud_user cloud_user  170 Jun 22 06:35 README.md
    -rw-r--r-- 1 cloud_user cloud_user  277 Jun 22 06:35 service.tf
    -rw-rw-r-- 1 cloud_user cloud_user  156 Jun 22 07:12 terraform.tfstate
    -rw-rw-r-- 1 cloud_user cloud_user 7547 Jun 22 07:12 terraform.tfstate.backup
    ```


## Laboratorio - Migración de Terraform State a Terraform Cloud

### Configurar y aplicar la configuración de Terraform

Fichero main.tf:

    ```shell
    provider "aws" {
    region = "us-east-1"
    }
    resource "aws_instance" "vm" {
    ami           = "ami-065efef2c739d613b"
    subnet_id     = "subnet-0ab44ccb794159b85"
    instance_type = "t3.micro"
    tags = {
    Name = "my-first-tf-node"
    }
    }
    ```
1. Inicializar directorio de trabajo y aplicar código

    ```shell
    $ terraform init
    $ terraform apply
    ```

### Genere clave de acceso en la consola de administración de AWS

1. En **AWS services** clicar en **IAM**

    ![IAM](images/IAM-AWS%20Management%20Consolepng.png)

