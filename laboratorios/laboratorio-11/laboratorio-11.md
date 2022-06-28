# Laboratorio 11 - Usar Terraform para crear una implementación de EKS

<p align="center">
  <img src="/images/eks-deployment-terraform.png" />
</p>

### Configurar la AWS CLI

1. Con el comando *aws configure* completamos la configuración de la CLI de AWS

    ```shell
    aws configure
    AWS Access Key ID [None]: AKIAXEMOP42ND3EAN2VI # Credenciales proporcionadas por cloud_guru
    AWS Secret Access Key [None]: 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 # Credenciales proporcionadas por cloud_guru
    Default region name [us-east-1]: # Intro para por defecto
    Default output format [None]: # Intro para por defecto
    ```
### Revisar el contenido de los archivos de configuración en el directorio lab-terraform-eks

1. Revisar el contenido de los ficheros de configuración de Terraform

    ```shell
    ls -l
    -rw-r--r-- 1 cloud_user cloud_user 1187 Jan 17 02:12 eks-cluster.tf
    -rw-r--r-- 1 cloud_user cloud_user  927 Jul 22  2021 kubernetes.tf
    -rw-r--r-- 1 cloud_user cloud_user  862 Jul 22  2021 outputs.tf
    -rw-r--r-- 1 cloud_user cloud_user  271 Jul 22  2021 README.md
    -rw-r--r-- 1 cloud_user cloud_user  816 Jul 22  2021 security-groups.tf
    -rw-r--r-- 1 cloud_user cloud_user  565 Jul 22  2021 versions.tf
    -rw-r--r-- 1 cloud_user cloud_user 1152 Jul 22  2021 vpc.tf
    ```

### Implementación del clúster de EKS

1. Iniciamos directorio de trabajo, revisamos en frio las configuraciones que se van a aplicar y aplicamos

    ```shell
    terraform init
    terraform fmt
    terraform plan
    Plan: 53 to add, 0 to change, 0 to destroy.

    Changes to Outputs:
    + cluster_endpoint          = (known after apply)
    + cluster_id                = (known after apply)
    + cluster_name              = (known after apply)
    + cluster_security_group_id = (known after apply)
    + config_map_aws_auth       = [
        + {
            + binary_data = null
            + data        = (known after apply)
            + id          = (known after apply)
            + metadata    = [
                + {
                    + annotations      = null
                    + generate_name    = null
                    + generation       = (known after apply)
                    + labels           = {
                        + "app.kubernetes.io/managed-by" = "Terraform"
                        + "terraform.io/module"          = "terraform-aws-modules.eks.aws"
                        }
                    + name             = "aws-auth"
                    + namespace        = "kube-system"
                    + resource_version = (known after apply)
                    + uid              = (known after apply)
                    },
                ]
            },
        ]
    + kubectl_config            = (known after apply)
    + region                    = "us-east-1"

    ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

    Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
    terraform validate
    Success! The configuration is valid.
    terraform apply
    [...]
    Apply complete! Resources: 53 added, 0 changed, 0 destroyed.

    Outputs:

    cluster_endpoint = "https://74B566BA5F5AA7656FBAD4F22303A456.gr7.us-east-1.eks.amazonaws.com"
    cluster_id = "education-eks-3xUhvLPF"
    cluster_name = "education-eks-3xUhvLPF"
    cluster_security_group_id = "sg-0dbf8369e552529af"
    config_map_aws_auth = [
    {
        "binary_data" = tomap(null) /* of string */
        "data" = tomap({
        "mapAccounts" = <<-EOT
        []

        EOT
        "mapRoles" = <<-EOT
        - "groups":
            - "system:bootstrappers"
            - "system:nodes"
            "rolearn": "arn:aws:iam::490461980314:role/education-eks-3xUhvLPF2022062808501121120000000e"
            "username": "system:node:{{EC2PrivateDNSName}}"

        EOT
        "mapUsers" = <<-EOT
        []

        EOT
        })
        "id" = "kube-system/aws-auth"
        "metadata" = tolist([
        {
            "annotations" = tomap(null) /* of string */
            "generate_name" = ""
            "generation" = 0
            "labels" = tomap({
            "app.kubernetes.io/managed-by" = "Terraform"
            "terraform.io/module" = "terraform-aws-modules.eks.aws"
            })
            "name" = "aws-auth"
            "namespace" = "kube-system"
            "resource_version" = "738"
            "uid" = "f2fbd8f9-5d17-426f-a66b-5a7575d79c96"
        },
        ])
    },
    ]
    kubectl_config = <<EOT
    apiVersion: v1
    preferences: {}
    kind: Config

    clusters:
    - cluster:
        server: https://74B566BA5F5AA7656FBAD4F22303A456.gr7.us-east-1.eks.amazonaws.com
        certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM1ekNDQWMrZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJeU1EWXlPREE0TkRZeU0xb1hEVE15TURZeU5UQTRORFl5TTFvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBT3FiCmJDZDVRZm05SlNoNGg0Qk9WdkppaVVGUllxdEJpditGRGVKdTUrWW9kUDdDdzlrdHQwVkJkRm1OaE9BNGpFODQKVWlOTGlYU1UzZSsyd0pINjRod2NVSkI4ZWp3N3ZNUHd1VXZXdkcyTEZBV293OXRJUE91UTZPMlJoN2NDR3gvWAp2Vk9iaS92SXlGdCtMeW1ERStUVFkvVHhNUjdTdUYxR1czcnQzdGhzckdkSkJxYWIwYXlzU3ozdTZIL2YvdFpPCmwxaitSNWFQV0pScXZ4YUZoUnlLSzRMaDRzK0NiL1RQekdEL2ZOVUFtbGZsWGUreXdwQ1hzNzYzUndJNVR0NFoKdU55enJXMWJham1uWlhRK0FEdVVYQXlsVW1QMGlPVnVkVVdFbGZraURuMW1qWjBSMlBQUm5GUUxmSksyQ1NwdgpJa09BVEU5MnZXNDNYcCtTUWtjQ0F3RUFBYU5DTUVBd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZNZFUwQzJIeEo3amNpYTNNdkhlRGIwQ3FmQUNNQTBHQ1NxR1NJYjMKRFFFQkN3VUFBNElCQVFEaTFjUUxoMDV6bkZ4VEpNVmgwb1ZuV2VtZ3FPcFNCNE1rVC9rUkswNVcxQ2xMeVdrcgpZVk4rd3FKVmZTbnB4a3JMWXY2K3Nhckl6aU1vdXlvdHh3cUZHNzRPaSswYWZ0VzNWeW51UExjTFlmSkkva0JUCnBjRnVtSERxRWFOK1BMeTgyejFyVGVZaTN3ZWdFVXBoWThjNmVjeW56eTJscTlRUU5XOUwza01pRWJnTlJOSjcKUVgxMXplMnhyejNYUnZaRVgwdTdYRTF2aWlsMm8rbGdpZTJNaUh1Z25iNFdwUnE1MXpXZ1dmTUczbVRxTzB1UAprTVJwanRXQnFoZWVmZmR4aFpKV0R6MmdaY1RKNW5GSFM2TFMxbE04M3plNTJoVVFndHJWNFlGa0FYaTN0eXVOCjRiR3E1WHpCd1NaSkNzcEhIU2NwUDhHTGh2VXpDVTdSZ2IwUwotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    name: eks_education-eks-3xUhvLPF

    contexts:
    - context:
        cluster: eks_education-eks-3xUhvLPF
        user: eks_education-eks-3xUhvLPF
    name: eks_education-eks-3xUhvLPF

    current-context: eks_education-eks-3xUhvLPF

    users:
    - name: eks_education-eks-3xUhvLPF
    user:
        exec:
        apiVersion: client.authentication.k8s.io/v1alpha1
        command: aws-iam-authenticator
        args:
            - "token"
            - "-i"
            - "education-eks-3xUhvLPF"

    EOT
    region = "us-east-1"
    ```
2. Para interactuar con el cluster

    ```shell 
    aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)
    Added new context arn:aws:eks:us-east-1:490461980314:cluster/education-eks-3xUhvLPF to /home/cloud_user/.kube/config
    kubectl get cs # Para confirmar que se implemetó correctamente todo debe estar en estado HEALTHY
    Warning: v1 ComponentStatus is deprecated in v1.19+
    NAME                 STATUS    MESSAGE             ERROR
    controller-manager   Healthy   ok
    scheduler            Healthy   ok
    etcd-2               Healthy   {"health":"true"}
    etcd-0               Healthy   {"health":"true"}
    etcd-1               Healthy   {"health":"true"}
    ```

### Implementar los PODs NGINX

1. Descargue el archivo lab_kubernetes_resources.tf que contiene la configuración de las implementaciones de NGINX desde el repositorio de GitHub y revisar el contenido del fichero *lab_kubernetes_resources.tf*

    ```shell
    wget https://raw.githubusercontent.com/linuxacademy/content-terraform-2021/main/lab_kubernetes_resources.tf
    ```
2. Revise las acciones que se realizarán para detectar posibles errores y si es correcto, aplicar

    ```shell
    terraform plan
    Plan: 1 to add, 0 to change, 0 to destroy.

    Changes to Outputs:
    ~ config_map_aws_auth = [
        ~ {
            ~ binary_data = null -> {}
            ~ metadata    = [
                ~ {
                    ~ annotations      = null -> {}
                        # (7 unchanged elements hidden)
                    },
                ]
                # (2 unchanged elements hidden)
            },
        ]

    terraform validate
    Success! The configuration is valid.
    terraform apply
    Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

3. Confirme que los pods NGINX se implementaron correctamente

    ```shell
    kubectl get deployments
    NAME                READY   UP-TO-DATE   AVAILABLE   AGE
    long-live-the-bat   2/2     2            2           72s
    ```

***
