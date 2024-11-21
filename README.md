 # Kubernetes Cluster Setup 

 This project contains configuration files, Terraform scripts, and Ansible playbooks to set up a multi-node Kubernetes cluster on AWS. 
 The cluster includes two control plane nodes and three worker nodes, with provisioning and configuration fully automated. 

 ## Features 

 - Automated provisioning of AWS EC2 instances using Terraform. 
 - Configuration of a Kubernetes cluster using Ansible. 
 - Modular and reusable configurations. 

 ## Prerequisites 

 - Terraform installed on your machine. 
 - Ansible installed on the control machine. 
 - AWS Credentials with permissions to manage EC2 instances and related resources. 
 - SSH access to each EC2 instance with the user ubuntu. 

 ## Setting Up AWS Credentials 

 Store your AWS credentials in a secure way to allow Terraform to provision resources: 

 ### Create a file named ~/.aws/credentials with the following content: 
 ```ini 
 [default] 
 aws_access_key_id=YOUR_ACCESS_KEY_ID 
 aws_secret_access_key=YOUR_SECRET_ACCESS_KEY 
 ``` 
 Ensure this file is protected and not shared. 

 ### Alternatively, set the credentials as environment variables: 
 ```bash 
 export AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY_ID 
 export AWS_SECRET_ACCESS_KEY=YOUR_SECRET_ACCESS_KEY 
 ``` 

 ## Terraform Setup 

 The Terraform configuration in this project provisions the EC2 instances required for the Kubernetes cluster. 

 ### Initialize Terraform 
 Run the following command to initialize the Terraform environment: 
 ```bash 
 terraform init 
 ``` 

 ### Review the Execution Plan 
 Check the resources that Terraform will create with: 
 ```bash 
 terraform plan 
 ``` 

 ### Apply the Configuration 
 Provision the instances by running: 
 ```bash 
 terraform apply 
 ``` 
 When prompted, type yes to confirm. 

 ### Destroy Resources 
 To tear down all resources created by Terraform, use: 
 ```bash 
 terraform destroy 
 ``` 

 ## Ansible Inventory Setup 

 After provisioning instances, create an inventory file named inventory in the root directory. 
 This file defines the groups and IP addresses of each node in the Kubernetes cluster. 

 ### Example Inventory File 
 ```ini 
 [first_controller] 
 <k8s_control1_eip> # Replace with the first control plane node's Elastic IP 

 [second-controller] 
 <k8s_control2_eip> # Replace with the second control plane node's Elastic IP 

 [workers] 
 <k8s_worker1_eip>  # Replace with the first worker node's Elastic IP 
 <k8s_worker2_eip>  # Replace with the second worker node's Elastic IP 
 <k8s_worker3_eip>  # Replace with the third worker node's Elastic IP 

 [instance:children] 
 first_controller 
 second-controller 
 workers 

 [instance:vars] 
 ansible_ssh_user=ubuntu 
 ``` 

 ## Deploying the Kubernetes Cluster 

 Run the following Ansible playbook to configure the Kubernetes cluster: 
 ```bash 
 ansible-playbook install-k8s.yml -i inventory 
 ``` 

 ### This playbook will: 
 - Set up prerequisites on all nodes. 
 - Initialize the first control plane node. 
 - Join the second control plane node to the cluster. 
 - Add worker nodes to the cluster. 

 ## Verifying the Cluster 

 Once the playbook finishes, verify the cluster status from the first control plane node: 
 ```bash 
 kubectl get nodes 
 ``` 
 You should see all nodes in a Ready state. 

 ## Future Improvements 

 To enhance the functionality, security, and efficiency of the Kubernetes cluster, the following improvements are planned: 

 - **Multi-AZ Deployment:** Improve the architecture by deploying the cluster across multiple Availability Zones for better fault tolerance. 
 - **Private Subnet:** Increase security by hosting nodes in a private subnet with NAT Gateway for outbound internet access. 
 - **High Availability:** Transition to a highly available architecture with an external etcd cluster and load balancer for the control plane. 
 - **Logging and Monitoring:** Implement centralized logging and monitoring solutions like Prometheus, Grafana, and EFK/ELK stack. 
 - **Resource Optimization:** Fine-tune resource allocations for EC2 instances and Kubernetes workloads to reduce costs and improve performance. 
 - **Load Balancer:** Integrate a load balancer for external traffic management and internal services. 

 ## Cleanup 

 To completely tear down the infrastructure: 

 - Remove Kubernetes configuration using Ansible, if necessary. 
 - Run terraform destroy to delete all AWS resources. 

 ## Notes 

 - Make sure to secure your SSH keys and AWS credentials. 
 - Customize the Terraform and Ansible configurations as needed to match your infrastructure requirements. 
 - Feel free to contribute or open issues for improvements! 
