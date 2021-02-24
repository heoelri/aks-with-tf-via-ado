# Overview

This sample is demonstrating how to deploy AKS with Terraform using a GitHub repository and Azure (DevOps) Pipelines.

Besides the content in this repository, we need the following setup in Azure DevOps to successfully execute the deployment:

## Variable group

### terraform-config

We're using a single VG for our TF backend configuration:

* ARM_ACCESS_KEY (secret) - Storage Account Key
* tfContainerName - Container Name
* tfKey - Filename
* tfResourceGroup - Storage Account Resource Group
* tfStorageAccount - Storage Account Name
* tfVersion - TF Version e.g. 0.14

Limit access to our specific pipeline instead of "Allow access to all pipelines".

### infrastructure-vg

* location - Azure Datacenter Region
* resourceGroup - Azure Resource Group name

Limit access to our specific pipeline instead of "Allow access to all pipelines".

## Service Connection

A service connection using "Azure Resource Manager" with access to our target Azure Subscription. Can be limited to a specific resource group if needed.

Limit access to our specific pipeline instead of "Grant access permission to all pipelines".
