# Laboratorio 12 - Solución de problemas de una implementación de Terraform

<p align="center">
  <img src="/images/troubleshooting-terraform-deployment.png" />
</p>

### Corregir el error de interpolación de variables

1. Ya con los ficheros *.tf* creados, procedemos a revisar si son correctos

    ```shell
    terraform ftm
    main.tf

    There are some problems with the configuration, described below.

    The Terraform configuration must be valid before initialization so that
    Terraform can determine which modules and providers need to be installed.
    ╷
    │ Error: Invalid character
    │
    │   on main.tf line 25, in resource "aws_instance" "web_app":
    │   25:     Name = $var.name-learn
    │
    │ This character is not used within the language.
    ╵

    ╷
    │ Error: Invalid expression
    │
    │   on main.tf line 25, in resource "aws_instance" "web_app":
    │   25:     Name = $var.name-learn
    │
    │ Expected the start of an expression, but found an invalid expression token.
    ```
Vemos un error en la linea 25 del fichero *variables.tf*

2. Para solucionar el error, abrimos el fichero *main.tf* y actualizamos la linea 25

    ```shell
    vim main.tf # :set number para numeras las lineas en vi

    terraform {
        required_providers {
            aws = {
                source  = "hashicorp/aws"
                version = ">= 3.24.1"
            }
        }
        required_version = "~> 1.0"
    }

    provider "aws" {
        region = var.region
    }

    resource "aws_instance" "web_app" {
        ami           = ami-065efef2c739d613b
        subnet_id     = subnet-07918d2e3724f7d5f
        instance_type = "t3.micro"
        user_data     = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p 8080 &
                EOF
        tags = {
            Name = "${var.name}-learn" # Modificada linea 25 para que no haya ningún error
        }
    }
    ```
3. Volvemos a validar el formato de los ficheros, no debería dar ningún error e iniciamos directorio de trabajo

    ```shell
    terraform fmt # Recordar que si no da resultado es correcto
    terraform init
    Terraform has been successfully initialized!
    ```

### Corregir el error de declaración de región

1. Intentamos validar el codigo de configuración de Terraform

    ```shell
    terraform validate
    │ Error: Reference to undeclared input variable
    │
    │   on main.tf line 12, in provider "aws":
    │   12:   region = var.region
    │
    │ An input variable with the name "region" has not been declared. Did you mean "regions"?
    ╵
    ```

2. Terraform nos devuelve un error, supuestamente en la linea 12 del fichero *main.tf*, pero no es así, detecto el error en el *variables.tf*

    ```shell
    vim variables.tf
    # Unicamente cambiamos el valor regions por region y guardamos el fichero
    # variable "regions" { 
    variable "region" {
        description = "The AWS region your resources will be deployed"
    }

    variable "name" {
        description = "The operator name running this configuration"
    }
    :wq!
    ```

### Corregir el error de sintaxis del recurso

1. Intente validar de nuevo el código y nos sale un nuevo error

    ```shell
    terraform validate
    ╷
    │ Error: Invalid reference
    │
    │   on main.tf line 16, in resource "aws_instance" "web_app":
    │   16:   ami           = ami-065efef2c739d613b
    │
    │ A reference to a resource type must be followed by at least one attribute access, specifying the resource name.
    ╵
    ╷
    │ Error: Invalid reference
    │
    │   on main.tf line 17, in resource "aws_instance" "web_app":
    │   17:   subnet_id     = subnet-07918d2e3724f7d5f
    │
    │ A reference to a resource type must be followed by at least one attribute access, specifying the resource name.
    ╵
    ```
2. Unicamente debemos añadir comillas dobles en los vales *ami* y *subnet_id*

```shell
vim main.tf 
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.24.1"
    }
  }
  required_version = "~> 1.0"
}

provider "aws" {
  region = var.region
}

resource "aws_instance" "web_app" {
  ami           = "ami-065efef2c739d613b" # Añadimos comillas doble al inicio y fin
  subnet_id     = "subnet-07918d2e3724f7d5f" # Añadimos comillas doble al inicio y fin
  instance_type = "t3.micro"
  user_data     = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
  tags = {
    Name = "${var.name}-learn"
  }
}

:wq!
```

### Corregir el error de salidas

1. Intente validar de nuevo el código y vemos un nuevo error

```shell
terraform validate

│ Error: Unsupported attribute
│
│   on outputs.tf line 8, in output "instance_public_ip":
│    8:   value       = aws_instance.web_app.public.ip
│
│ This object has no argument, nested block, or exported attribute named "public".
╵
╷
│ Error: Unsupported attribute
│
│   on outputs.tf line 13, in output "instance_name":
│   13:   value       = aws_instance.web_app.tag.Name
│
│ This object has no argument, nested block, or exported attribute named "tag". Did you mean "tags"?
```

2. El error es en el fichero *outputs.tf*

```shell
vim outputs.tf
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web_app.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web_app.public_ip # Cambiamos aws_instance.web_app.public.ip -> aws_instance.web_app.public_ip
}

output "instance_name" {
  description = "Tags of the EC2 instance"
  value       = aws_instance.web_app.tag.Name # Cambiamos aws_instance.web_app.tag.Name -> aws_instance.web_app.tags.Name
}

:wq!
```
### Implementar la infraestructura

1. Comprbamos el código y, por fin es correcto

```shell
terraform validate
Success! The configuration is valid.
```
***
