# Infraestructura AWS - Image Processor

Implementacion de una arquitectura orientada a eventos (Event-Driven) basada en el diagrama de referencia para la carga y procesamiento asincrono de imagenes en AWS.

## Descripcion del sistema
El sistema permite la gestion de imagenes mediante un flujo desacoplado que asegura la persistencia y seguridad de los datos:
- Carga de imagenes mediante API Gateway.
- Almacenamiento de archivos originales y procesados en buckets S3, configurados con versionado y cifrado de lado del servidor (SSE).
- Gestion de tareas y errores mediante colas SQS y Dead Letter Queue (DLQ).
- Procesamiento y redimension mediante funciones Lambda.
- Configuracion de red privada (VPC) con VPC Endpoints para permitir comunicacion interna segura con S3 y SQS sin transitar por internet publica.

## Entornos
Se utilizan workspaces de Terraform para mantener la independencia entre las etapas del proyecto:
- **dev**: Entorno de desarrollo.
- **qa**: Entorno de pruebas de calidad.
- **prod**: Entorno de produccion.

---

## Requisitos previos
- Cuenta de AWS con permisos de administrador.
- Terraform instalado (version 1.5 o superior).
- AWS CLI configurado mediante el comando `aws configure`.
- Node.js 20 o superior para el empaquetado de funciones.

---

## Despliegue
1. Clonar el repositorio y acceder a la carpeta del proyecto:

    git clone https://github.com/TiagoTZ0/infra_pract_S4.git
    cd infra_pract_S4


2. Inicializar el directorio de trabajo:

    terraform init


3. Seleccionar o crear el entorno de trabajo deseado:

    terraform workspace new dev
    terraform workspace select dev


4. Ejecutar el despliegue de la infraestructura:

    terraform apply

    *Al finalizar el proceso, la terminal mostrara el output con la URL del API Gateway.*

---

## Destruccion de recursos
Para evitar cargos imprevistos en la facturacion de AWS, es obligatorio destruir la infraestructura al concluir las validaciones:

terraform destroy