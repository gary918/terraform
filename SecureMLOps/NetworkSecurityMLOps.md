# Network security for MLOps on Azure
## About MLOps Security
### What is MLOps
Machine Learning DevOps (MLOps) is a set of practices that aims to deploy and maintain machine learning models in production reliably and efficiently. Technically, MLOps is the set of practices at the intersection of Machine Learning, DevOps and Data Engineering, offering a solution which can automate the process of machine learning data preparation, model training, evaluation and deployment as web services or on edge devices. 
![MLOps](./images/ns_what_is_mlops.png)
After beining highlighted in a paper entitled “Hidden Technical Debt in Machine Learning Systems.” in 2015, MLOps adoption's been growing fast and its market is expected to reach $4 billion by 2025.

### Challenges for MLOps Security
  * Protect training data
  * Protect pipelines
  * Protect models
### How to Secure Your MLOps Environment
We need to consider various aspects to secure the MLOps resources in Azure:
* Authentication and Authorization
  * Use service principals or managed identities instead of interactive authentication
  * Use RBAC to define the user's access scope of the resources 
* Network Security
  * Use VNet to partially or fully isolate the environment from the public internet to reduce the attack and data exfiltration
* Data Encryption
  * Encrypt training data in transit and at rest, by using Microsoft-managed or customer-managed keys
* Policy and Monitoring
  * Use Azure Policy and the Azure Security Center to enforce policies
  * Azure Monitor collects and aggregates data (metrics, logs) from variaty of sources into a common data platform where it can be used for analysis, visualization and alerting.
## Network Security for MLOPs
### Secure Azure Machine Learning Workspace
#### VNet integration
#### Private Links and Private Endpoints
#### Deep Dive for ACR
#### Deep Dive for Compute Cluster
### Access Resources in the VNet
#### VPN
#### Bastion + Jumphost (Work around)
#### VPN on windows server
### Azure Pipeline
## References
* [MLOps](https://en.wikipedia.org/wiki/MLOps)
