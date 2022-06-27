# TERRAFORM

[Terraform CLI Cheatsheet](docs/terraform-cheatsheet.pdf)

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

- Ejemplo *main.tf*

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

- Ejemplo *main.tf*

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

***

## Laboratorio 1 - Explorando la funcionalidad de estado de Terraform

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
    cd lab_code/
    cd section2-hol1/
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

***

# Terraform Cloud

## Laboratorio 2 - Migración de Terraform State a Terraform Cloud

### Configurar y aplicar la configuración de Terraform

Fichero *main.tf*

    ```yaml
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
    terraform init
    terraform apply
    ```

### Genere clave de acceso en la consola de administración de AWS

1. En **AWS services** clicar en **IAM**

2. En el dashboard de **IAM**, bajo **IAM resources**, clicar en **users**

3. En la lista de usuarios, seleccionar el usuario con el que hemos aplicado la aplicación Terraform

4. Clicar en **Credenciales de seguridad**

<p align="center">
  <img src="/images/CredencialesSeguridad.png" alt:"Credenciales de seguridad" />
</p>

5. Clicar en **Crear clave de acceso**

<p align="center">
<img src="/images/ClaveAcceso.png" alt:"Clave de acceso" />
</p>

6. En la nueva ventana, clicar en **descargar archivo .csv**

<p align="center">
  <img src="/images/Descargarcsv.png" />
</p>

### Configurar espacio de trabajo en Terraform Cloud

1. Ir a <https://app.terraform.io/session>. Crear cuenta.
2. Una vez iniciada la sesión, seleccione empezar desde cero. Rellenar el campo **Nombre de la organización**
3. Seleccionar opción **CLI-driven workflow**

<p align="center">
  <img src="/images/CLI-driven-workflow.png" alt:"CLI driven workflow" />
</p>

4. Crear espacio de trabajo

5. Seleccionar la pestaña **Variables** y clicar en **add variable**, rellenar con *AWS_ACCESS_KEY_ID*

<p align="center">
  <img src="/images/variables.png" alt:"Variables" />
</p>

6. En el campo **Value** pegar la clave que descargamos de AWS y guardar

<p align="center">
  <img src="/images/AWSKey.png" alt:"AWS key" />
</p>

7. Repetimos el mismo proceso con la variable *AWS_SECRET_ACCESS_KEY*

### Cree su token de API para el inicio de sesión de terraform CLI

1. En la parte superior derecha de la web de terraform cloud, clicar en avatar y selecionar **Configuracion de usuario**
2. En el menú de la izda, seleccionar **tokens**, **create api token**, lo llamaremos *terraform_login*

### Agregar la configuración de back-end

1. En el CLI, iniciar sesión en terraform cloud, escribir yes y pegar el token de terraform cloud

    ```shell
    terraform login
    Token for app.terraform.io:
    Enter a value:


    Retrieved token for user miguelmaestro


    ---------------------------------------------------------------------------------

                                            -
                                            -----                           -
                                            ---------                      --
                                            ---------  -                -----
                                            ---------  ------        -------
                                                -------  ---------  ----------
                                                    ----  ---------- ----------
                                                    --  ---------- ----------
    Welcome to Terraform Cloud!                     -  ---------- -------
                                                        ---  ----- ---
    Documentation: terraform.io/docs/cloud             --------   -
                                                        ----------
                                                        ----------
                                                        ---------
                                                            -----
                                                                -


    New to TFC? Follow these steps to instantly apply an example configuration:

    $ git clone https://github.com/hashicorp/tfc-getting-started.git
    $ cd tfc-getting-started
    $ scripts/setup.sh
    ```

2. Agregar el siguiente código al fichero *main.tf* para agregar el backend remoto a la configuración:

    ```yaml
    terraform {
        backend "remote" {
            organization = "<YOUR ORG NAME>"
            workspaces {
                name = "lab-migrate-state"
            }
        }

        required_providers {
            aws = {
                source  = "hashicorp/aws"
                version = "~> 3.27"
            }
        }
    }
    ```

3. Comprobamos que el fichero de configuración se ha formateado correctamente

    ```shell
    terraform fmt -recursive
    terraform init
    terraform validate
    ```

    > Es posible que la versión del server no coincida con la de Terraform Cloud, añadir la flag -upgrade al comando terraform init

    ```sheel
        terraform init -upgrade
    ```

4. Aplicamos la configuración

    ```shell
    terraform apply
    ```

5. Vemos como se ha ejecutado en la web Terraform Cloud

<p align="center">
  <img src="/images/LatestRun.png" alt:"Ejecución desde CLI" />
</p>

6. En la pestaña **Runs** tenemos más datos sobre la ejecución.

<p align="center">
  <img src="/images/runs.png" alt:"Salida de la ejecución" />
</p>

***

# Terraform and AWS

## Laboratorio 3 - Uso de Terraform Provisioners para configurar un servidor web Apache en AWS

1. Clone el código requerido del repositorio proporcionado

    ```shell
    git clone https://github.com/linuxacademy/content-hashicorp-certified-terraform-associate-foundations.git
    ```

2. Examinar el codigo *main.tf*

    ```shell
    cat main.tf
    # Creamos una instancia llamada webserver VVV
    resource "aws_instance" "webserver" {
        # Estamos pasando una serie de parámetros para el recurso, como la AMI en la que se activará la máquina virtual, el tipo de 
        # instancia, la clave privada que usará la instancia, la IP pública adjunta a la instancia, el grupo de seguridad aplicado a la 
        # instancia y el identificador de subred donde se activará la máquina virtual. VVV
        ami                         = data.aws_ssm_parameter.webserver-ami.value
        instance_type               = "t3.micro"
        key_name                    = aws_key_pair.webserver-key.key_name
        associate_public_ip_address = true
        vpc_security_group_ids      = [aws_security_group.sg.id]
        subnet_id                   = aws_subnet.subnet.id
        # Se trata de un provisionador remoto, invoca un script de recurso remoto despues de crearlo. VVV
        provisioner "remote-exec" {
            #Luego, el aprovisionador emitirá los comandos configurados en el bloque para instalar el servidor web Apache en CentOS a 
            # través del administrador de paquetes, iniciará el servidor Apache, creará una sola página web llamada *My Test Website 
            # With Help From Terraform Provisioner* como un archivo y moverá ese archivo al directorio de datos del servidor web para 
            # ser servido globalmente VVV
            inline = [
            "sudo yum -y install httpd && sudo systemctl start httpd",
            "echo '<h1><center>My Test Website With Help From Terraform Provisioner</center></h1>' > index.html",
            "sudo mv index.html /var/www/html/"
            ]
            # El aprovisionador utiliza los parametro configurados en el bloque incrustado para conectarse a la instancia AWS EC2
            # que se está creando. VVV
            connection {
                type        = "ssh"
                user        = "ec2-user"
                private_key = file("~/.ssh/id_rsa")
                host        = self.public_ip
            }
        }
        tags = {
            Name = "webserver"
        }
    }

3. Iniciar terraform, iniciar plan, validar el codigo y aplicar

    ```shell
    terraform init
    terraform validate
    Success! The configuration is valid.
    terraform plan
    Plan: 7 to add, 0 to change, 0 to destroy.
    terraform apply
    Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

    Outputs:

    Webserver-Public-IP = 34.238.172.200
    ´´´
4. Nos ha dado la IP publica como valor, si la pegamos en el navegador podemos ver nuestro sitio web de prueba con la ayuda de *Terraform Provisioner*

<p align="center">
  <img src="/images/WebTest_Terraform_Provisioner.png" alt:"My test web" />
</p>

## Laboratorio 4 - Realizar cambios en la infraestructura de AWS con Terraform

### Configurar el entorno

1. Fichero *main.tf*

    ```shell
    terraform {
        required_providers {
            aws = {
                source  = "hashicorp/aws"
            version = "~> 3.27"
            }
        }

        required_version = ">= 0.14.9"
    }

    provider "aws" {
        profile = "default"
        region  = "us-east-1"
    }

    resource "aws_instance" "app_server" {
        ami           = "ami-065efef2c739d613b"
        subnet_id     = "subnet-0e0ab6aaee86e9182"
        instance_type = "t2.micro"

        tags = {
            Name = "Batman"
        }
    }
    ```

2. Iniciamos terraform y aplicamos código.

    ```shell
    terraform init
    terraform apply
    Plan: 1 to add, 0 to change, 0 to destroy.

    Do you want to perform these actions?
    Terraform will perform the actions described above.
    Only 'yes' will be accepted to approve.

    Enter a value: yes

    aws_instance.app_server: Creating...
    aws_instance.app_server: Still creating... [10s elapsed]
    aws_instance.app_server: Still creating... [20s elapsed]
    aws_instance.app_server: Still creating... [30s elapsed]
    aws_instance.app_server: Creation complete after 32s [id=i-037675589811ce71c]

    Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
    ```

3. Confirmamos que se ha realizado de manera correcta y vemos todos los detalles

    ```shell
    $ terraform show
    # aws_instance.app_server:
    resource "aws_instance" "app_server" {
        ami                                  = "ami-065efef2c739d613b"
        arn                                  = "arn:aws:ec2:us-east-1:112755761569:instance/i-037675589811ce71c"
        associate_public_ip_address          = true
        availability_zone                    = "us-east-1a"
        cpu_core_count                       = 1
        cpu_threads_per_core                 = 1
        disable_api_termination              = false
        ebs_optimized                        = false
        get_password_data                    = false
        hibernation                          = false
        id                                   = "i-037675589811ce71c"
        instance_initiated_shutdown_behavior = "stop"
        instance_state                       = "running"
        instance_type                        = "t2.micro"
        ipv6_address_count                   = 0
        ipv6_addresses                       = []
        monitoring                           = false
        primary_network_interface_id         = "eni-08f0a58801961d37a"
        private_dns                          = "ip-10-0-1-132.ec2.internal"
        private_ip                           = "10.0.1.132"
        public_dns                           = "ec2-34-201-151-200.compute-1.amazonaws.com"
        public_ip                            = "34.201.151.200"
        secondary_private_ips                = []
        security_groups                      = []
        source_dest_check                    = true
        subnet_id                            = "subnet-0e0ab6aaee86e9182"
        tags                                 = {
            "Name" = "Batman"
        }
        tags_all                             = {
            "Name" = "Batman"
        }
        tenancy                              = "default"
        vpc_security_group_ids               = [
            "sg-0efa9bfef250434e6",
        ]

        capacity_reservation_specification {
            capacity_reservation_preference = "open"
        }

        credit_specification {
            cpu_credits = "standard"
        }

        enclave_options {
            enabled = false
        }

        metadata_options {
            http_endpoint               = "enabled"
            http_put_response_hop_limit = 1
            http_tokens                 = "optional"
            instance_metadata_tags      = "disabled"
        }

        root_block_device {
            delete_on_termination = true
            device_name           = "/dev/xvda"
            encrypted             = false
            iops                  = 100
            tags                  = {}
            throughput            = 0
            volume_id             = "vol-044b6b03dcc0c5b53"
            volume_size           = 8
            volume_type           = "gp2"
        }
    }
    ```

### Implementar cambios en la configuración

1. En el fichero *main.tf* cambiamos un par de configuraciones

    ```shell
    instance_type = "t2.micro" ---> instance_type = "t3.micro"

    Name = "Batman" ----> Name = "Robin"
    ```

2. Validamos el formato del código, iniciamos plan, lo validamos y aplicamos

    ```shell
    terraform fmt # Si no devuelve nada, es correcto
    terraform plan
    terraform validate 
    Success! The configuration is valid.
    terraform apply

    Podemos ver en AWS que los cambios se han aplicado correctamente:

<p align="center">
  <img src="/images/AWS-batman.png" />
</p>

1. Eliminamos todos los recursos

    ```shell
    terraform destroy
    ```

## Laboratorio 5 - Uso de variables output para consultar datos en AWS

<p align="center">
  <img src="/images/output-deseado.png" />
</p>

### Configurar el entorno

1. Fichero *main.tf*

    ```shell
        terraform {
            required_providers {
                aws = {
                    source  = "hashicorp/aws"
                    version = "~> 3.27"
                }
            }

            required_version = ">= 0.14.9"
        }

        provider "aws" {
            profile = "default"
            region  = "us-east-1"
        }

        resource "aws_instance" "app_server" {
            ami           = "ami-065efef2c739d613b"
            subnet_id     = "subnet-0b65cef7d5dd0e8fc"
            instance_type = "t3.micro"

            tags = {
                Name = var.instance_name
            }
        }

        # variables
        variable "instance_name" {
            description = "Value of the Name tag for the EC2 instance"
            type        = string
            default     = "Batman"
        }
    ```

2. Iniciamos directorio de trabajo y aplicamos configuración

    ```shell
    terraform init
    terraform apply
    ```

<p align="center">
  <img src="/images/AWS-batman.png" />
</p>

### Agregar variables de salida e implementar cambios

1. Creamos el fichero *outputs.tf*

    ```shell
    output "instance_name" {
        description = "The tag name for this instance"
        value       = var.instance_name
    }

    output "instance_id" {
        description = "ID of the EC2 instance"
        value       = aws_instance.app_server.id
    }

    output "instance_public_ip" {
        description = "Public IP address of the EC2 instance"
        value       = aws_instance.app_server.public_ip
    }
    ```

    > Este código incluye 3 variables de salida: *instance_name*, *instance_id* y *instance_public_ip*.

    > Aseguramos que tenga el formato correcto con el comando *terraform fmt*

2. Aplicamos los cambios

    ```shell
    terraform plan
    aws_instance.app_server: Refreshing state... [id=i-04a8ff230ef59ed4c]

    Changes to Outputs:
    + instance_id        = "i-04a8ff230ef59ed4c"
    + instance_name      = "Batman"
    + instance_public_ip = "54.161.231.5"

    You can apply this plan to save these new output values to the Terraform state, without changing any real infrastructure.

    ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

    Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.

    terraform apply
    aws_instance.app_server: Refreshing state... [id=i-04a8ff230ef59ed4c]

    Changes to Outputs:
    + instance_id        = "i-04a8ff230ef59ed4c"
    + instance_name      = "Batman"
    + instance_public_ip = "54.161.231.5"

    You can apply this plan to save these new output values to the Terraform state, without changing any real infrastructure.

    Do you want to perform these actions?
    Terraform will perform the actions described above.
    Only 'yes' will be accepted to approve.

    Enter a value: yes


    Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

    Outputs:

    instance_id = "i-04a8ff230ef59ed4c"
    instance_name = "Batman"
    instance_public_ip = "54.161.231.5"
    ```

    > *terraform output* para ver versión simplificada de la salida:

    ```shell
    terraform output
    instance_id = "i-04a8ff230ef59ed4c"
    instance_name = "Batman"
    instance_public_ip = "54.161.231.5"
    ```

***

# Terraform y Azure

## Laboratorio 6 - Desplegando una aplicación Web en Azure con Terraform

### Configuración de la CLI de Azure

En Azure Portal, seleccione el botón Línea de comandos en la parte superior de la pantalla.

<p align="center">
  <img src="/images/azure-cli.png" />
</p>

Abra la CLI. Aquí, seleccione Bash cuando se le solicite.

<p align="center">
  <img src="/images/azure-cli-bash.png" />
</p>

Luego queremos elegir Mostrar configuración avanzada. Elija la misma región de Cloud Shell que su cuenta de almacenamiento aprovisionada en laboratorio. Deje tanto el grupo de recursos como la cuenta de almacenamiento como el uso de los recursos existentes. En la sección Recurso compartido de archivos, escriba un nombre para la cuenta (por ejemplo, estamos usando cloudcli) y haga clic en el botón Adjuntar almacenamiento.

<p align="center">
  <img src="/images/azure-advanced-bash.png" />
</p>

2. Una vez configurada la bash, nos aparecerá en pantalla. Necesitamos subir nuestro fichero main.tf:

    ```shell
    provider "azurerm" {
        version = 1.38
        }

    resource "azurerm_app_service_plan" "svcplan" {
        name                = "newweb-appserviceplan"
        location            = "centerus"
        resource_group_name = "191-ab6de3a1-deploy-a-web-application-with-terrafo"

        sku {
            tier = "Standard"
            size = "S1"
        }
    }

    resource "azurerm_app_service" "appsvc" {
        name                = "custom-tf-webapp-forstudent"
        location            = "centerus"
        resource_group_name = "191-ab6de3a1-deploy-a-web-application-with-terrafo"
        app_service_plan_id = azurerm_app_service_plan.svcplan.id


        site_config {
            dotnet_framework_version = "v4.0"
            scm_type                 = "LocalGit"
        }
    }
    ```

    > Podemos crearlo desde la bash o subirlo con el botón upload/download de la bash de azure

<p align="center">
  <img src="/images/azure-cli-upload.png" />
</p>

3. Tras esto, inciamos directorio de trabajo y aplicamos

    ```shell
    terraform init
    terraform plan
    terraform apply

1. Una vez aplicado lo podemos ver en el portal de Azure y podemos revsar todos los datos

<p align="center">
  <img src="/images/azure-deployment-completed.png" />
</p>

<p align="center">
  <img src="/images/azure-app-details.png" />
</p>

<p align="center">
  <img src="/images/azure-app-properties.png" />
</p>

***

## Laboratorio 7 - Realizar cambios en la infraestructura de Azure con Terraform

<p align="center">
  <img src="/images/change-azure-with-terraform.png" />
</p>

### Inicie sesión y configurar la CLI

1. Configurar la Azure CLI bash de la siguiente forma y clicar en *Crear almacenamiento*

<p align="center">
  <img src="/images/azure-cli-2.png" />
</p>

2. Descargar el fichero .zip proporciado por ACG para realizar el laboratorio y descomprimirlo

    ```shell
    wget https://raw.githubusercontent.com/linuxacademy/content-terraform-2021/main/lab-managing-azure.zip
    unzip lab-managing-azure.zip
    ```

3. Nos movemos hasta el interior del directorio y revisamos el fichero main.tf

    ```shell
    cd lab-managing-azure/
    vim main.tf

    # COnfiguración del proveedor azure
    terraform {
        required_providers {
            azurerm = {
                source  = "hashicorp/azurerm"
                version = ">= 2.26"
        }
    }

        required_version = ">= 0.14.9"
    }

    provider "azurerm" {
        features {}
        skip_provider_registration = true
    }

    # Creación de una red virtual
    resource "azurerm_virtual_network" "vnet" {
        name                = "BatmanInc"
        address_space       = ["10.0.0.0/16"]
        location            = "Central US"
        resource_group_name = "552-000a4a6c-make-changes-to-azure-infrastructure"
    ```

### Implementar la infraestructura

1. Iniciamos directorio de trabajo, planificamos la implementación y aplicamos la configuración.

    ```shell
    terraform init
    terraform plan
    terraform apply
    azurerm_virtual_network.vnet: Creating...
    azurerm_virtual_network.vnet: Creation complete after 7s [id=/subscriptions/0f39574d-d756-48cf-b622-0e27a6943bd2/resourceGroups/552-000a4a6c-make-changes-to-azure-infrastructure/providers/Microsoft.Network/virtualNetworks/BatmanInc]

    Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
    ```

2. Podemos revisar el estado y la lista de recursos:

    ```shell
    terraform show
    # azurerm_virtual_network.vnet:
    resource "azurerm_virtual_network" "vnet" {
        address_space           = [
            "10.0.0.0/16",
        ]
        dns_servers             = []
        flow_timeout_in_minutes = 0
        guid                    = "5ca0a942-d3bd-4018-a727-8286c9a75585"
        id                      = "/subscriptions/0f39574d-d756-48cf-b622-0e27a6943bd2/resourceGroups/552-000a4a6c-make-changes-to-azure-infrastructure/providers/Microsoft.Network/virtualNetworks/BatmanInc"
        location                = "centralus"
        name                    = "BatmanInc"
        resource_group_name     = "552-000a4a6c-make-changes-to-azure-infrastructure"
        subnet                  = []
    
    }
    
    terraform state list
    azurerm_virtual_network.vnet
    ```

    Como vemos, solo está administrando el recurso *azurerm_virtual_network.vnet*

### Agregar una subred a la configuración

1. Fichero *azure_resource_block.tf* para la configuración de la subred:

    ```shell
    # Create subnet
    resource "azurerm_subnet" "subnet" {
    name                 = "Robins"
    resource_group_name  = "<Add YOUR RESOURCE GROUP NAME>"
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes       = ["10.0.1.0/24"]
    }
    ```

2. Tras realizar la planificación y aplicar el código desde terraform, podemos comprobar en el portal de Azure que la subred ha sido creada

<p align="center">
  <img src="/images/subred-robin.png" />
</p>

### Agregar una etiqueta a la configuración

1. Vamos a editar el fichero *main.tf*, agregando algunas etiquetas al modulo de recursos de las red virtual, quedando así:

    ```shell
    vim main.tf
    

    # Configure the Azure provider

        terraform {
            required_providers {
                azurerm = {
                    source  = "hashicorp/azurerm"
                    version = ">= 2.26"
                }
            }

            required_version = ">= 0.14.9"
        }

        provider "azurerm" {
            features {}
            skip_provider_registration = true
        }

    # Create a virtual network

        resource "azurerm_virtual_network" "vnet" {
            name                = "BatmanInc"
            address_space       = ["10.0.0.0/16"]
            location            = "Central US"
            resource_group_name = "552-000a4a6c-make-changes-to-azure-infrastructure"
    ```

# Agregamos etiqueta

1. Agregamos etiqueta al fichero main.tf, al bloque de resursos:

    ```shell
        tags = {
            Environment = "TheBatcave"
            Team        = "Batman"
        }
    }
    ```

2. Aplicamos la modificación al despliegue y ahora las red virtual tiene etiquetas:

<p align="center">
  <img src="/images/azure-tags.png" />
</p>

***

## Laboratorio 8 - Usar variables de salida para consultar datos en Azure mediante Terraform

### Implementar la infraestructura

 1. Preparar la Bash de Azure
 2. Descargue el archivo zip del repositorio de GitHub proporcionado y descomprimirlo:

    ```shell
    wget https://raw.githubusercontent.com/linuxacademy/content-terraform-2021/main/lab-azure-outputs.zip
    unzip lab-azure-outputs.zip
    ```

3. Una vez dentro del directorio del repo descargado revisamos el fichero main.tf y rellenamos los campos *Resource group name*

    ```shell
    # Configure the Azure provider
    terraform {
        required_providers {
            azurerm = {
                source  = "hashicorp/azurerm"
                version = ">= 2.26"
            }
        }

        required_version = ">= 0.14.9"
    }

    provider "azurerm" {
        features {}
        skip_provider_registration = true
    }

    # Create a virtual network
    resource "azurerm_virtual_network" "vnet" {
        name                = "BatmanInc"
        address_space       = ["10.0.0.0/16"]
        location            = "Central US"
        resource_group_name = "553-733d53a2-use-output-variables-to-query-data-i"
        tags = {
            Environment = "TheBatcave"
            Team        = "Batman"
        }
    }

    # Create subnet
    resource "azurerm_subnet" "subnet" {
        name                 = "Robins"
        resource_group_name  = "553-733d53a2-use-output-variables-to-query-data-i"
        virtual_network_name = azurerm_virtual_network.vnet.name
        address_prefixes     = ["10.0.1.0/24"]
    }
    ```

 4. Validamos el formato del fichero y si es correcto iniciamos directorio de trabajo y planificación:

    ```shell
    terraform fmt
    terraform plan
    terraform validate
    Success! The configuration is valid.

    terraform apply --auto-approve
    Plan: 2 to add, 0 to change, 0 to destroy.
    azurerm_virtual_network.vnet: Creating...
    azurerm_virtual_network.vnet: Creation complete after 4s [id=/subscriptions/0f39574d-d756-48cf-b622-0e27a6943bd2/resourceGroups/553-733d53a2-use-output-variables-to-query-data-i/providers/Microsoft.Network/virtualNetworks/BatmanInc]
    azurerm_subnet.subnet: Creating...
    azurerm_subnet.subnet: Creation complete after 4s [id=/subscriptions/0f39574d-d756-48cf-b622-0e27a6943bd2/resourceGroups/553-733d53a2-use-output-variables-to-query-data-i/providers/Microsoft.Network/virtualNetworks/BatmanInc/subnets/Robins]

    Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
    ```

 5. Una vez aplicada la configuración, revisamos detalles y recursos:

    ```shell
    terraform show
    # azurerm_subnet.subnet:
    resource "azurerm_subnet" "subnet" {
    address_prefixes                               = [
        "10.0.1.0/24",
    ]
    enforce_private_link_endpoint_network_policies = false
    enforce_private_link_service_network_policies  = false
    id                                             = "/subscriptions/0f39574d-d756-48cf-b622-0e27a6943bd2/resourceGroups/553-733d53a2-use-output-variables-to-query-data-i/providers/Microsoft.Network/virtualNetworks/BatmanInc/subnets/Robins"
    name                                           = "Robins"
    resource_group_name                            = "553-733d53a2-use-output-variables-to-query-data-i"
    virtual_network_name                           = "BatmanInc"
    }

    # azurerm_virtual_network.vnet:
    resource "azurerm_virtual_network" "vnet" {
        address_space           = [
            "10.0.0.0/16",
        ]
        dns_servers             = []
        flow_timeout_in_minutes = 0
        guid                    = "186e83db-7a61-4a34-8b84-5f533e8825b4"
        id                      = "/subscriptions/0f39574d-d756-48cf-b622-0e27a6943bd2/resourceGroups/553-733d53a2-use-output-variables-to-query-data-i/providers/Microsoft.Network/virtualNetworks/BatmanInc"
        location                = "centralus"
        name                    = "BatmanInc"
        resource_group_name     = "553-733d53a2-use-output-variables-to-query-data-i"
        subnet                  = []
        tags                    = {
            "Environment" = "TheBatcave"
            "Team"        = "Batman"
        }
    }

    terraform state list
    azurerm_subnet.subnet
    azurerm_virtual_network.vnet
    ```

### Agregar el archivo de variable outputs.tf

1. Descargamos el fichero del repo proporcionado y lo revisamos:

    ```shell
    wget <https://raw.githubusercontent.com/linuxacademy/content-terraform-2021/main/outputs_azure.tf>
    vim outputs.tf

    output "azurerm_virtual_network_name" {
        value = azurerm_virtual_network.vnet.name
    }

    output "azurerm_subnet_name" {
        value = azurerm_subnet.subnet.name
    }
    ```

2. Verificamos que el formato sea correcto, iniciamos plan si es así, validamos configuración y aplicamos

    ```shell
    # Validamos formato
    terraform ftm
    # Realizamos tirada en seco
    terraform plan
    # Validamos configuración
    terraform validate
    # Aplicamos

***

# Terraform y Kubernetes

## Laboratorio 9 - Terraform para crear una implementación de Kubernetes

### Crear el clúster de Kubernetes

1. Ficheros necesarios para crear cluster de Kubernetes
   1. kind-config-yaml

    ```yaml
    kind: Cluster
    apiVersion: kind.x-k8s.io/v1alpha4
    nodes:
    - role: control-plane
        extraPortMappings:
      - containerPort: 30201
            hostPort: 30201
            listenAddress: "0.0.0.0"
    ```
    2. kubernetes.tf

    ```shell
    terraform {
    required_providers {
        kubernetes = {
            source = "hashicorp/kubernetes"
            }
        }
    }

    variable "host" {
        type = string
    }

    variable "client_certificate" {
        type = string
    }

    variable "client_key" {
        type = string
    }

    variable "cluster_ca_certificate" {
        type = string
    }

    provider "kubernetes" {
        host = var.host

        client_certificate     = base64decode(var.client_certificate)
        client_key             = base64decode(var.client_key)
        cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
    }
    ```

    3. terraform.tfvars

    ```shell
    # terraform.tfvars

    host                   = "DUMMY VALUE"
    client_certificate     = "DUMMY VALUE"
    client_key             = "DUMMY VALUE"
    cluster_ca_certificate = "DUMMY VALUE"
    ```

2. Cree su clúster de Kubernetes

    ```shell
    kind create cluster --name lab-terraform-kubernetes --config kind-config.yaml

    Creating cluster "lab-terraform-kubernetes" ...
    ✓ Ensuring node image (kindest/node:v1.21.1) 🖼
    ✓ Preparing nodes 📦
    ✓ Writing configuration 📜
    ✓ Starting control-plane 🕹️
    ✓ Installing CNI 🔌
    ✓ Installing StorageClass 💾
    Set kubectl context to "kind-lab-terraform-kubernetes"
    You can now use your cluster with:

    kubectl cluster-info --context kind-lab-terraform-kubernetes

    Have a question, bug, or feature request? Let us know! https://kind.sigs.k8s.io/#community 🙂
    ```

3. Copiamos el comando obtenido en la ejecución de la creación del cluster para obtener información

    ```shell
    kubectl cluster-info --context kind-lab-terraform-kubernetes

    Kubernetes control plane is running at https://127.0.0.1:44645
    CoreDNS is running at https://127.0.0.1:44645/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

    To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
    
    kind get clusters
    lab-terraform-kubernetes
    ```

### Configurar Terraform para su uso con el clúster de Kubernetes

1. Obtener información sobre el cluster de Kubernetes para rellenar el fichero de variables *terraform.tfvars*

    ```shell
    kubectl config view --minify --flatten --context=kind-lab-terraform-kubernetes

    apiVersion: v1
    clusters:
    - cluster:
        certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM1ekNDQWMrZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJeU1EWXlOekE0TlRVME0xb1hEVE15TURZeU5EQTROVFUwTTFvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTW1RCmhQck5XcmtJSVdTMmhmTE1kWStIbU5mUGpTdjhFU0xIeHgzVzRtU1VKcFJpRFgyL0VMTkQ3YTQ0NWF2QzhWZVMKaTBQODV0ZEV5UEZhUkdrQndsUjhhY1p1UXBjN1J0Rm1IbGhiK0VkSjF6S1pCcDUrVklJTEFRZUdFYU82WU5sOQo4UktoVkxKQWI5c0xLd1M1R3pFakZmVDU5VkRLZEdWNUV2dlAreUN0RTVuNXc5NFVqU3A4eTdSdjBmVlcyVVRCCjQ3ODZWTW56d2trRTc2TUdRdjVRLzBWT0tiT1kyQzY4eFlWUkVydDBMTER2TUM3VDVEMmpsRGtUclA1SHF2b2oKMFdzQ1NteW9nMTZYNllscUU1L3BBZ3hvb1ByaksrTncyYnZZamhFb0pueEwxRnBXVEZJSDd6dUdlOFZTOUtZMgpRanl0eXRvTEwrakQ3RUNRLzlVQ0F3RUFBYU5DTUVBd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZFcVBubTlHcGpNMXZRY25OQytZNUtWN3JqVXRNQTBHQ1NxR1NJYjMKRFFFQkN3VUFBNElCQVFCNjNjSmxBemMxdXYrOEQ3eFl6TS85Y2F2cllwanlyQXQzRXpBMmRUZ21oZzVHNVRvRAphZkZrUE5KQzhxak9KYWhodFdNQy93eisrM2tSV1lLUDNsVVdRVk5xUDR0dGlYa0Q2K3AvV0pkZk9NQzYrRzhLCjlkRFpNRUpCWFN4eGVEUHFoMmpEdm1TL0RsYUY1aHRqaWljSU5UU05VcUVBSHAzblZ5bTNCUTlOdlN3MEdVb0sKNEtpMEczQ2dqTVFmMkdsL1VRNXdHT2FVSFU5cFhjbGZ4Z0cwZWdJSzIvT21pNGN3bDU4UGZyWWtLeGlxYkcxUQpsUlN5aFBuUGdmVHdzY1BsQzJ0eXNZdXc3SVFTZkFxelI4alNDekVMVVhNUFc5SEJacEdUaEZ6SmFUSUlVTlUyClVHWTN4TUpLWHkwMmd1bFZDd1Bva0t1TGtNR0dvK0pnRThuZgotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
        server: https://127.0.0.1:44645
    name: kind-lab-terraform-kubernetes
    contexts:
    - context:
        cluster: kind-lab-terraform-kubernetes
        user: kind-lab-terraform-kubernetes
    name: kind-lab-terraform-kubernetes
    current-context: kind-lab-terraform-kubernetes
    kind: Config
    preferences: {}
    users:
    - name: kind-lab-terraform-kubernetes
    user:
        client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURJVENDQWdtZ0F3SUJBZ0lJTUpXRUxkaDJab1F3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TWpBMk1qY3dPRFUxTkROYUZ3MHlNekEyTWpjd09EVTFORFZhTURReApGekFWQmdOVkJBb1REbk41YzNSbGJUcHRZWE4wWlhKek1Sa3dGd1lEVlFRREV4QnJkV0psY201bGRHVnpMV0ZrCmJXbHVNSUlCSWpBTkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1JSUJDZ0tDQVFFQXFuVlVwYUJZQ3A0cnQ3Y2UKQ1kvY0tTRWNPV09jV2lmVjNBWGNtZVZDeUxva053RjdnUmVpeWNHSGpPNERuVERxd3RkWjBkQldhNktrNjByWQo2dms2MUpxdUZtNEhreDgxNEZ6cm9ua3J3bmdkWE91RnQrLzBXVExmM2ZhL0E1WkZ3cFdESG4vcjc0MURCUnE3CmtxQUlSL3ZpQm1qQk1US3c5L21hYnJmbytyVTBwb2JYNUJ6K0lkbWRxTGwvazJLR2swUmgvZTliVi82V3JLeGoKRWxlRVM4Zzluak1oOG1ocWRxcmsxaDFtcW96VDF2NktlbkxHNldQV2FmbFVnQkp2R3ZJV2ViTkxuVjhaeDh5ZApTYk1IdnhzdldETjNCTHpxM1lGY2I1bHE4UjhyZk04Q0d5SjZuR1E2YWFybW9LaEMyU0JqNUIwaldmOG5SNWtECmp4ZEhPUUlEQVFBQm8xWXdWREFPQmdOVkhROEJBZjhFQkFNQ0JhQXdFd1lEVlIwbEJBd3dDZ1lJS3dZQkJRVUgKQXdJd0RBWURWUjBUQVFIL0JBSXdBREFmQmdOVkhTTUVHREFXZ0JSS2o1NXZScVl6TmIwSEp6UXZtT1NsZTY0MQpMVEFOQmdrcWhraUc5dzBCQVFzRkFBT0NBUUVBdkJZL0lnSFdaMC9lelE0RE8zUVIraDVCYmJYWFFYbHRRaFA3Ck1VL0FISzZjMXl1MVdZUkQzcDNPc0VjS2tIK3p4dmdmcHJjNXpxRkU4aFZWVDJVWEIrU3VQZnJTcWQzbkxzcmcKdndmM0xsdmVLVzFsbjlNSnAzNzBnUDlLNjlpWjlaQ0pldzJFR2lGand2ZE4vMi9adnQyNzFHMDd4QXJLRVBpRQpXNGF6MXF2ZFc2V0RlanJpamYwZ0VUWXlnbFN2cVl5UndpVmN4a2xNOGlhZSswc3RXZUJ5bFBENTlkTkFRNlZTClBPd3J2VHY2a2lMRjMrR2l1ZGp3dUxNcXYrQnpOVHBBaWZrazlFc2hEWUdaM1RvbDVqaXRubzdPamR5TlNXWWcKQzA4eWVyZFlYdmYzMGNuaHEvbVZYSHEyaEM3eGZ6MW5FQm1EYjRVRUJhZlBoTTQ3aUE9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
        client-key-data: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFb2dJQkFBS0NBUUVBcW5WVXBhQllDcDRydDdjZUNZL2NLU0VjT1dPY1dpZlYzQVhjbWVWQ3lMb2tOd0Y3CmdSZWl5Y0dIak80RG5URHF3dGRaMGRCV2E2S2s2MHJZNnZrNjFKcXVGbTRIa3g4MTRGenJvbmtyd25nZFhPdUYKdCsvMFdUTGYzZmEvQTVaRndwV0RIbi9yNzQxREJScTdrcUFJUi92aUJtakJNVEt3OS9tYWJyZm8rclUwcG9iWAo1QnorSWRtZHFMbC9rMktHazBSaC9lOWJWLzZXckt4akVsZUVTOGc5bmpNaDhtaHFkcXJrMWgxbXFvelQxdjZLCmVuTEc2V1BXYWZsVWdCSnZHdklXZWJOTG5WOFp4OHlkU2JNSHZ4c3ZXRE4zQkx6cTNZRmNiNWxxOFI4cmZNOEMKR3lKNm5HUTZhYXJtb0toQzJTQmo1QjBqV2Y4blI1a0RqeGRIT1FJREFRQUJBb0lCQUQ1amtXYkpxRS9Da3JlOApRemMydTFzbWJrRW5EMHdFTm9kQWNmeTE1OXEySHBrdlpyZmFJYy84a0pOcGJsTXpXMG1UTHFIWHdqbkZIdDJyCjJIY3dYM0wvWm1aNVFUWjgvdWd1dW1RT081RURDNlE5NUFSdHhCNTl1Mmh2Ym54dW5QdmFZMUpmZWNpRkNKbXUKcmlhOWdpcHVxOHl5dkxzNEZZTzlqT09uVnBPajlENkZtclVoWkpqUk04NzZ0R0ZlVTBKODdCZlJvamNHdEtQUQpXNjZmdVNHdEEwTkZsbEhEbTR6Zi84cE5iS241R0Q4ZHRybGkrd25ObnIxZWE5QTlaU1BNdVlaSmI2YytwMnNjCkliMXl0SHlvNStUVmZnRXRLdW1xRzVXME1CeTIyZUhta3ViMnZSRzdvY0JWcHVrWG9nY1J1ZFhYaDlua25UNkoKZUdXRTJiRUNnWUVBMU95dzVDNlR4d3lBSlBqUVFZR2dlQ0NxQzdVUW56cHVac1I3MFJDS1RQSkhCRXM3WDhHVApzVy9odm8xdnYyUUg4VmpxK0FnQzNtSFB6MTkxTVdSSkFNdGZGTk5aUThjSGxCSG5nQmVTODY5T1pVZHJDazU0CllrcnpmbVBNWlhYc1lrZ01ndEdaVUtibnJsR3lkbVkwYzVrWUFMOVQrV2oxNWhUYUhLZ0Z0RlVDZ1lFQXpQRlMKeTd1anVucjJ5WXpqcXVmOVBUZGhLSmFHbEg0SVJ1NitIUnltTUk3RStTaUdhK2t5d1J4dkxIaC8wTXczSk8vWQpYTzh1QzByRk1JNll2bUsydFJhalgrQnhOamtmYm5mc3hJNFFUaUJwcXh1Slg2R1BzdFpRTmNFWW5jY3lnSXBBCmVoV0M3a3QvdTY2MExML0p3NkdKODZuMm52NFA3eVdXOGUxbnkxVUNnWUExWGVXd0syUnFuVjE0NXN2N3Z5dWoKTUR5dWxvRkdCM1VvV05MWHdaZUlWYWtyRUZnZlZmdFltN3d1OEhBenZqU25ieXZsWXN5bFJFcTdwU2RRYTl4SQpVTERTSFc3Z0tBQmtRbUNOb0ZyNnJOT3ZXc2tmV2krZUl6OElUS2NzUHZReVpmQ00wVS9tQVE5TWg3bDlKM3k2CkJJTVpuTnJGUm1OcmVZcDVhRHVWeVFLQmdFdUVYUUx2aUh4TmxTUmRnd0xWNnkya2UydXVVN2JoM2dEdE5pYWEKQ083NW5NRkcyb2xtNjZuVzVXeFlscGlFdDRrbnkrMHF3U2V1REkxQTdpMnhTQ3ZnUktFdW5lamlFWi91RnRPeQptWFdBWWcrSDNRM2RCWXRiaDBEWGYwK2NPQksvWHRUZG1scGVmWm5WM1ZSajgxL2Y1V3BnNVp4ZWQ5YWlYa1dWCk9scmxBb0dBWlhGRnNJTVhiU0wvTkFYRHVzVUF4WmlySXJ4V05EMmhvZlEyaCswQnhINVJKK082Yno0b3ppQ1gKT2NqVStldUNqcDdOWDJMYmM5ekNsTGlzbW1Xam1BeTJmWFhzb0pWdWowVXZMQWJnaEFlUlUyYkpMa0J3NzRqMgo5YjBVL1BUdWN2WVRyRVFlT2F1UzhhZmxwSUpmd1Y1UlZ4Y2FtelI4VE12MndDNkdQZ2M9Ci0tLS0tRU5EIFJTQSBQUklWQVRFIEtFWS0tLS0tCg==
    ```

2. Con estos datos rellenaremos el fichero de variables *terraform.tfvars*, quedando de la siguiente manera:

    ```shell
    vim terraform.tfvars

    # terraform.tfvars

    host                   = "https://127.0.0.1:44645"
    client_certificate     = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURJVENDQWdtZ0F3SUJBZ0lJTUpXRUxkaDJab1F3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TWpBMk1qY3dPRFUxTkROYUZ3MHlNekEyTWpjd09EVTFORFZhTURReApGekFWQmdOVkJBb1REbk41YzNSbGJUcHRZWE4wWlhKek1Sa3dGd1lEVlFRREV4QnJkV0psY201bGRHVnpMV0ZrCmJXbHVNSUlCSWpBTkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1JSUJDZ0tDQVFFQXFuVlVwYUJZQ3A0cnQ3Y2UKQ1kvY0tTRWNPV09jV2lmVjNBWGNtZVZDeUxva053RjdnUmVpeWNHSGpPNERuVERxd3RkWjBkQldhNktrNjByWQo2dms2MUpxdUZtNEhreDgxNEZ6cm9ua3J3bmdkWE91RnQrLzBXVExmM2ZhL0E1WkZ3cFdESG4vcjc0MURCUnE3CmtxQUlSL3ZpQm1qQk1US3c5L21hYnJmbytyVTBwb2JYNUJ6K0lkbWRxTGwvazJLR2swUmgvZTliVi82V3JLeGoKRWxlRVM4Zzluak1oOG1ocWRxcmsxaDFtcW96VDF2NktlbkxHNldQV2FmbFVnQkp2R3ZJV2ViTkxuVjhaeDh5ZApTYk1IdnhzdldETjNCTHpxM1lGY2I1bHE4UjhyZk04Q0d5SjZuR1E2YWFybW9LaEMyU0JqNUIwaldmOG5SNWtECmp4ZEhPUUlEQVFBQm8xWXdWREFPQmdOVkhROEJBZjhFQkFNQ0JhQXdFd1lEVlIwbEJBd3dDZ1lJS3dZQkJRVUgKQXdJd0RBWURWUjBUQVFIL0JBSXdBREFmQmdOVkhTTUVHREFXZ0JSS2o1NXZScVl6TmIwSEp6UXZtT1NsZTY0MQpMVEFOQmdrcWhraUc5dzBCQVFzRkFBT0NBUUVBdkJZL0lnSFdaMC9lelE0RE8zUVIraDVCYmJYWFFYbHRRaFA3Ck1VL0FISzZjMXl1MVdZUkQzcDNPc0VjS2tIK3p4dmdmcHJjNXpxRkU4aFZWVDJVWEIrU3VQZnJTcWQzbkxzcmcKdndmM0xsdmVLVzFsbjlNSnAzNzBnUDlLNjlpWjlaQ0pldzJFR2lGand2ZE4vMi9adnQyNzFHMDd4QXJLRVBpRQpXNGF6MXF2ZFc2V0RlanJpamYwZ0VUWXlnbFN2cVl5UndpVmN4a2xNOGlhZSswc3RXZUJ5bFBENTlkTkFRNlZTClBPd3J2VHY2a2lMRjMrR2l1ZGp3dUxNcXYrQnpOVHBBaWZrazlFc2hEWUdaM1RvbDVqaXRubzdPamR5TlNXWWcKQzA4eWVyZFlYdmYzMGNuaHEvbVZYSHEyaEM3eGZ6MW5FQm1EYjRVRUJhZlBoTTQ3aUE9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
    client_key             = "LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFb2dJQkFBS0NBUUVBcW5WVXBhQllDcDRydDdjZUNZL2NLU0VjT1dPY1dpZlYzQVhjbWVWQ3lMb2tOd0Y3CmdSZWl5Y0dIak80RG5URHF3dGRaMGRCV2E2S2s2MHJZNnZrNjFKcXVGbTRIa3g4MTRGenJvbmtyd25nZFhPdUYKdCsvMFdUTGYzZmEvQTVaRndwV0RIbi9yNzQxREJScTdrcUFJUi92aUJtakJNVEt3OS9tYWJyZm8rclUwcG9iWAo1QnorSWRtZHFMbC9rMktHazBSaC9lOWJWLzZXckt4akVsZUVTOGc5bmpNaDhtaHFkcXJrMWgxbXFvelQxdjZLCmVuTEc2V1BXYWZsVWdCSnZHdklXZWJOTG5WOFp4OHlkU2JNSHZ4c3ZXRE4zQkx6cTNZRmNiNWxxOFI4cmZNOEMKR3lKNm5HUTZhYXJtb0toQzJTQmo1QjBqV2Y4blI1a0RqeGRIT1FJREFRQUJBb0lCQUQ1amtXYkpxRS9Da3JlOApRemMydTFzbWJrRW5EMHdFTm9kQWNmeTE1OXEySHBrdlpyZmFJYy84a0pOcGJsTXpXMG1UTHFIWHdqbkZIdDJyCjJIY3dYM0wvWm1aNVFUWjgvdWd1dW1RT081RURDNlE5NUFSdHhCNTl1Mmh2Ym54dW5QdmFZMUpmZWNpRkNKbXUKcmlhOWdpcHVxOHl5dkxzNEZZTzlqT09uVnBPajlENkZtclVoWkpqUk04NzZ0R0ZlVTBKODdCZlJvamNHdEtQUQpXNjZmdVNHdEEwTkZsbEhEbTR6Zi84cE5iS241R0Q4ZHRybGkrd25ObnIxZWE5QTlaU1BNdVlaSmI2YytwMnNjCkliMXl0SHlvNStUVmZnRXRLdW1xRzVXME1CeTIyZUhta3ViMnZSRzdvY0JWcHVrWG9nY1J1ZFhYaDlua25UNkoKZUdXRTJiRUNnWUVBMU95dzVDNlR4d3lBSlBqUVFZR2dlQ0NxQzdVUW56cHVac1I3MFJDS1RQSkhCRXM3WDhHVApzVy9odm8xdnYyUUg4VmpxK0FnQzNtSFB6MTkxTVdSSkFNdGZGTk5aUThjSGxCSG5nQmVTODY5T1pVZHJDazU0CllrcnpmbVBNWlhYc1lrZ01ndEdaVUtibnJsR3lkbVkwYzVrWUFMOVQrV2oxNWhUYUhLZ0Z0RlVDZ1lFQXpQRlMKeTd1anVucjJ5WXpqcXVmOVBUZGhLSmFHbEg0SVJ1NitIUnltTUk3RStTaUdhK2t5d1J4dkxIaC8wTXczSk8vWQpYTzh1QzByRk1JNll2bUsydFJhalgrQnhOamtmYm5mc3hJNFFUaUJwcXh1Slg2R1BzdFpRTmNFWW5jY3lnSXBBCmVoV0M3a3QvdTY2MExML0p3NkdKODZuMm52NFA3eVdXOGUxbnkxVUNnWUExWGVXd0syUnFuVjE0NXN2N3Z5dWoKTUR5dWxvRkdCM1VvV05MWHdaZUlWYWtyRUZnZlZmdFltN3d1OEhBenZqU25ieXZsWXN5bFJFcTdwU2RRYTl4SQpVTERTSFc3Z0tBQmtRbUNOb0ZyNnJOT3ZXc2tmV2krZUl6OElUS2NzUHZReVpmQ00wVS9tQVE5TWg3bDlKM3k2CkJJTVpuTnJGUm1OcmVZcDVhRHVWeVFLQmdFdUVYUUx2aUh4TmxTUmRnd0xWNnkya2UydXVVN2JoM2dEdE5pYWEKQ083NW5NRkcyb2xtNjZuVzVXeFlscGlFdDRrbnkrMHF3U2V1REkxQTdpMnhTQ3ZnUktFdW5lamlFWi91RnRPeQptWFdBWWcrSDNRM2RCWXRiaDBEWGYwK2NPQksvWHRUZG1scGVmWm5WM1ZSajgxL2Y1V3BnNVp4ZWQ5YWlYa1dWCk9scmxBb0dBWlhGRnNJTVhiU0wvTkFYRHVzVUF4WmlySXJ4V05EMmhvZlEyaCswQnhINVJKK082Yno0b3ppQ1gKT2NqVStldUNqcDdOWDJMYmM5ekNsTGlzbW1Xam1BeTJmWFhzb0pWdWowVXZMQWJnaEFlUlUyYkpMa0J3NzRqMgo5YjBVL1BUdWN2WVRyRVFlT2F1UzhhZmxwSUpmd1Y1UlZ4Y2FtelI4VE12MndDNkdQZ2M9Ci0tLS0tRU5EIFJTQSBQUklWQVRFIEtFWS0tLS0tCg=="
    cluster_ca_certificate = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM1ekNDQWMrZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJeU1EWXlOekE0TlRVME0xb1hEVE15TURZeU5EQTROVFUwTTFvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTW1RCmhQck5XcmtJSVdTMmhmTE1kWStIbU5mUGpTdjhFU0xIeHgzVzRtU1VKcFJpRFgyL0VMTkQ3YTQ0NWF2QzhWZVMKaTBQODV0ZEV5UEZhUkdrQndsUjhhY1p1UXBjN1J0Rm1IbGhiK0VkSjF6S1pCcDUrVklJTEFRZUdFYU82WU5sOQo4UktoVkxKQWI5c0xLd1M1R3pFakZmVDU5VkRLZEdWNUV2dlAreUN0RTVuNXc5NFVqU3A4eTdSdjBmVlcyVVRCCjQ3ODZWTW56d2trRTc2TUdRdjVRLzBWT0tiT1kyQzY4eFlWUkVydDBMTER2TUM3VDVEMmpsRGtUclA1SHF2b2oKMFdzQ1NteW9nMTZYNllscUU1L3BBZ3hvb1ByaksrTncyYnZZamhFb0pueEwxRnBXVEZJSDd6dUdlOFZTOUtZMgpRanl0eXRvTEwrakQ3RUNRLzlVQ0F3RUFBYU5DTUVBd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZFcVBubTlHcGpNMXZRY25OQytZNUtWN3JqVXRNQTBHQ1NxR1NJYjMKRFFFQkN3VUFBNElCQVFCNjNjSmxBemMxdXYrOEQ3eFl6TS85Y2F2cllwanlyQXQzRXpBMmRUZ21oZzVHNVRvRAphZkZrUE5KQzhxak9KYWhodFdNQy93eisrM2tSV1lLUDNsVVdRVk5xUDR0dGlYa0Q2K3AvV0pkZk9NQzYrRzhLCjlkRFpNRUpCWFN4eGVEUHFoMmpEdm1TL0RsYUY1aHRqaWljSU5UU05VcUVBSHAzblZ5bTNCUTlOdlN3MEdVb0sKNEtpMEczQ2dqTVFmMkdsL1VRNXdHT2FVSFU5cFhjbGZ4Z0cwZWdJSzIvT21pNGN3bDU4UGZyWWtLeGlxYkcxUQpsUlN5aFBuUGdmVHdzY1BsQzJ0eXNZdXc3SVFTZkFxelI4alNDekVMVVhNUFc5SEJacEdUaEZ6SmFUSUlVTlUyClVHWTN4TUpLWHkwMmd1bFZDd1Bva0t1TGtNR0dvK0pnRThuZgotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
    ```

3. Si revisamos el fichero *kubernetes.tf* vemos que extrae las variables del fichero *terraform.tfvars*

    ```shell
     vim kubernetes.tf

    terraform {
        required_providers {
            kubernetes = {
                source = "hashicorp/kubernetes"
            }
        }
    }

    variable "host" {
        type = string
    }

    variable "client_certificate" {
        type = string
    }

    variable "client_key" {
        type = string
    }

    variable "cluster_ca_certificate" {
        type = string
    }

    provider "kubernetes" {
        host = var.host

    client_certificate     = base64decode(var.client_certificate)
    client_key             = base64decode(var.client_key)
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
    }
    ```

### Implementación de recursos en el clúster de Kubernetes

1. Iniciamos directorio de trabajo

    ```shell
    terraform init
    ```

2. Descarga el fichero de configuración y revisa el contenido

    ```shell
    wget https://raw.githubusercontent.com/linuxacademy/content-terraform-2021/main/lab_kubernetes_resources.tf
    vim 
    resource "kubernetes_deployment" "nginx" {
        metadata {
            name = "long-live-the-bat"
            labels = {
                App = "longlivethebat"
            
            }
        }
        spec {
            replicas = 2
            selector {
                match_labels = {
                    App = "longlivethebat"
                    }
                }
            template {
                metadata {
                    labels = {
                        App = "longlivethebat"
                    }
                }
                spec {
                    container {
                    image = "nginx:1.7.8"
                    name  = "batman"

                    port {
                        container_port = 80
                    }

                    resources {
                        limits = {
                            cpu    = "0.5"
                            memory = "512Mi"
                        }
                        
                        requests = {
                            cpu    = "250m"
                            memory = "50Mi"
                        }
                    }
                }
            }
        }
    }
    ```
3. Iniciamos plan de terraform y aplicamos conficuración

    ```shell
    terrform plan
    terraform apply
    kubernetes_deployment.nginx: Creating...
    kubernetes_deployment.nginx: Still creating... [10s elapsed]
    kubernetes_deployment.nginx: Creation complete after 16s [id=default/long-live-the-bat]

    Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
    
    # Para ver los detalles de la implementación

    kubectl get deployments
    NAME                READY   UP-TO-DATE   AVAILABLE   AGE
    long-live-the-bat   2/2     2            2           70s
    ``` 
    Vemos que hay dos nodos en funcionamiento en el despliegue *long-live-the-bat*

***











