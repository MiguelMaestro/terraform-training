## Laboratorio 10 - Administrar recursos de Kubernetes con Terraform

<p align="center">
  <img src="/images/manage-kubernetes-terraform.png" />
</p>

### Agregar un servicio

1. Creamos un cluster de kubernetes

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

    Have a nice day! 👋
    ```

2. Una vez creado, podemos utilizar el comando que nos ha proporcionado la creación del cluster para obtener información, tambien podemos usar el comando *kind get clusters*

    ```shell
    kubectl cluster-info --context kind-lab-terraform-kubernetes
    Kubernetes control plane is running at https://127.0.0.1:40737
    CoreDNS is running at https://127.0.0.1:40737/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

    To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

    kind get clusters
    lab-terraform-kubernetes
    ```

3. Editar la dirección host del clúster
   1. Ejecutar el siguiente comando para conocer la dirección host del cluster

        ```shell
        kubectl config view --minify --flatten --context=kind-lab-terraform-kubernetes
        ```
   2. Completamos el fichero de variables terraform.tfvars con la información que nos ha dado el comando anterior
4. Iniciamos directorio de trabajo y aplicamos configuración

    ```shell
    terraform init
    terraform fmt
    terraform plan
    terraform validate
    terraform apply

### Agregar un servicio

1. Descargamos el archivo de configuración
    
    ```shell
    wget  https://raw.githubusercontent.com/linuxacademy/content-terraform-2021/main/lab_kubernetes_service.tf
    ```

2. Revisamos el fichero descargado

    ```shell
    vim lab_kubernetes_service.tf

    resource "kubernetes_service" "nginx" {
        metadata {
            name = "robin"
         }
        spec {
            selector = {
                App = kubernetes_deployment.nginx.spec.0.template.0.metadata[0].labels.App
            }
            port {
                node_port   = 30201
                port        = 80
                target_port = 80
            }

            type = "NodePort"
        }
    }
    ```

3. Aplicamos la configuración y revisamos que el servicio *NodePort* se ha aplicado e iniciado correctamente

    ```shell
    terraform apply
    kubernetes_service.nginx: Creating...
    kubernetes_service.nginx: Creation complete after 0s [id=default/robin]

    Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

    kubectl get services
    NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
    kubernetes   ClusterIP   10.96.0.1      <none>        443/TCP        17m
    robin        NodePort    10.96.229.23   <none>        80:30201/TCP   70s
    ```

### Escalar los nodos

1. Modificamos el número de replicas de 2 a 4

    ```shell
    vim lab_kubernetes_resources.tf

    resource "kubernetes_deployment" "nginx" {
        metadata {
            name = "long-live-the-bat"
            labels = {
                App = "longlivethebat"
            }
        }

        spec {
            replicas = 4  # Modificamos el número de replicas de 2 a 4
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

2. Aplicamos la configuración y revisamos la implementación

    ```shell
    terraform apply
    kubernetes_deployment.nginx: Modifying... [id=default/long-live-the-bat]
    kubernetes_deployment.nginx: Modifications complete after 3s [id=default/long-live-the-bat]

    Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
    
    kubectl get deployments
    NAME                READY   UP-TO-DATE   AVAILABLE   AGE
    long-live-the-bat   4/4     4            4           13m
    ```
