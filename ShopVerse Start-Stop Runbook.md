# ShopVerse Start/Stop Runbook

This guide explains how to bring the ShopVerse EKS environment back online after the jump server and Kubernetes worker nodes have been stopped, and how to shut everything down again when finished.

---

# Starting the Environment

## 1. Start the Jump Server in AWS

Navigate to:

**AWS Console → EC2 → Instances**

Locate the ShopVerse jump server (bastion host).

Select the instance and choose:

**Instance State → Start Instance**

Wait until the instance status changes to:

```text
Running
```

Also wait until the EC2 instance status checks show:

```text
2/2 Status Checks Passed
```

---

## 2. Find the Jump Server Public IP Address

Select the jump server in the EC2 console and locate:

```text
Public IPv4 Address
```

> **Note:** If your jump server is associated with an Elastic IP, this address will remain the same after every restart. Otherwise, the public IP will change each time the instance is stopped and started.

---

## 3. SSH into the Jump Server

From your local PowerShell terminal:

```powershell
ssh -i "your-key.pem" ec2-user@PUBLIC-IP
```

Example:

```powershell
ssh -i "shopverse-key.pem" ec2-user@3.20.100.50
```

If using Ubuntu instead of Amazon Linux:

```powershell
ssh -i "shopverse-key.pem" ubuntu@3.20.100.50
```

---

## 4. Navigate to the Scripts Directory

After logging in:

```bash
cd ~/scripts
```

Verify the scripts exist:

```bash
ls -l
```

Expected output:

```text
start.sh
stop.sh
status.sh
```

---

# Starting ShopVerse

## 5. Run the Start Script

```bash
./start.sh
```

Contents of **start.sh**

```bash
#!/bin/bash

echo "Starting ShopVerse node group..."

aws eks update-nodegroup-config \
  --cluster-name shopverse-cluster \
  --nodegroup-name shopverse-cluster-nodes \
  --scaling-config minSize=1,maxSize=2,desiredSize=2

echo "Waiting for worker nodes to become Ready..."

kubectl wait --for=condition=Ready nodes --all --timeout=5m

echo ""
echo "Current Nodes:"
kubectl get nodes

echo ""
echo "ShopVerse Pods:"
kubectl get pods -n shopverse

echo ""
echo "Traefik Pods:"
kubectl get pods -n traefik

echo ""
echo "ShopVerse Services:"
kubectl get svc -n shopverse

echo ""
echo "Traefik Services:"
kubectl get svc -n traefik

echo ""
echo "ShopVerse environment is ready."
```

AWS will launch the EKS worker nodes.

---

## 6. Verify the Worker Nodes

Run:

```bash
kubectl get nodes
```

Initially, no nodes may appear.

Within a few minutes you should see something similar to:

```text
NAME                                           STATUS   ROLES   AGE   VERSION
ip-10-0-10-100.us-east-1.compute.internal      Ready    <none>  2m    v1.xx
ip-10-0-20-100.us-east-1.compute.internal      Ready    <none>  2m    v1.xx
```

The important value is:

```text
STATUS = Ready
```

---

## 7. Verify the ShopVerse Pods

Run:

```bash
kubectl get pods -n shopverse
```

Initially, pods may show:

```text
Pending
ContainerCreating
Init
```

After Kubernetes finishes scheduling:

```text
Running
```

Example:

```text
NAME                                  READY   STATUS
shopverse-backend-xxxxx               1/1     Running
shopverse-backend-xxxxx               1/1     Running
shopverse-frontend-xxxxx              1/1     Running
shopverse-frontend-xxxxx              1/1     Running
mysql-0                               1/1     Running
```

---

## 8. Verify Traefik

Run:

```bash
kubectl get pods -n traefik
```

Expected:

```text
NAME                         READY   STATUS
traefik-xxxxxxxxxx-xxxxx     1/1     Running
```

---

## 9. Verify Services

Run:

```bash
kubectl get svc -n shopverse
```

Also verify Traefik:

```bash
kubectl get svc -n traefik
```

Ensure the Traefik LoadBalancer service still has its AWS load balancer hostname.

---

## 10. Verify the Website

Open:

```text
https://shop.m1portfolio.com
```

Verify:

- Frontend loads
- Backend API is working
- Products display correctly
- Database functionality works
- HTTPS certificate is valid

Your environment is now ready for demonstrations.

---

# Checking Environment Status

Navigate to the scripts folder:

```bash
cd ~/scripts
```

Run:

```bash
./status.sh
```

Contents of **status.sh**

```bash
#!/bin/bash

echo "====================================="
echo "     ShopVerse Environment Status"
echo "====================================="

echo ""
echo "EKS Nodes"
kubectl get nodes

echo ""
echo "ShopVerse Pods"
kubectl get pods -n shopverse

echo ""
echo "Traefik Pods"
kubectl get pods -n traefik

echo ""
echo "ShopVerse Services"
kubectl get svc -n shopverse

echo ""
echo "Traefik Services"
kubectl get svc -n traefik

echo ""
echo "Persistent Volume Claims"
kubectl get pvc -n shopverse

echo ""
echo "Ingress"
kubectl get ingress -n shopverse
```

---

# Stopping the Environment

Navigate to the scripts directory:

```bash
cd ~/scripts
```

Run:

```bash
./stop.sh
```

Contents of **stop.sh**

```bash
#!/bin/bash

echo "Stopping ShopVerse node group..."

aws eks update-nodegroup-config \
  --cluster-name shopverse-cluster \
  --nodegroup-name shopverse-cluster-nodes \
  --scaling-config minSize=0,maxSize=2,desiredSize=0

echo ""
echo "Waiting for worker nodes to terminate..."

sleep 30

echo ""
echo "Current Nodes:"
kubectl get nodes

echo ""
echo "Worker node shutdown initiated."
```

---

## Verify Worker Nodes Have Been Removed

Run:

```bash
kubectl get nodes
```

Eventually the output should be:

```text
No resources found
```

This is expected.

The Kubernetes control plane still retains all of your Deployments, Services, StatefulSets, Ingress resources, ConfigMaps, Secrets, and Helm releases.

---

# Stop the Jump Server

Exit the SSH session:

```bash
exit
```

Return to:

**AWS Console → EC2 → Instances**

Select the jump server.

Choose:

**Instance State → Stop Instance**

**Do NOT choose "Terminate Instance."**

Stopping preserves:

- AWS CLI configuration
- kubectl configuration
- Helm configuration
- SSH keys
- Scripts
- Files
- EBS storage

Everything will still be there when the instance is started again.

---

# Daily Workflow

## Start

```text
AWS Console
    ↓
Start Jump Server
    ↓
SSH into Jump Server
    ↓
cd ~/scripts
    ↓
./start.sh
    ↓
kubectl get nodes
    ↓
kubectl get pods -n shopverse
    ↓
Open https://shop.m1portfolio.com
```

---

## Stop

```text
SSH into Jump Server
    ↓
cd ~/scripts
    ↓
./stop.sh
    ↓
kubectl get nodes
    ↓
exit
    ↓
AWS Console
    ↓
Stop Jump Server
```

---

# Useful Troubleshooting Commands

Check cluster connectivity:

```bash
kubectl cluster-info
```

Check nodes:

```bash
kubectl get nodes
```

Check all ShopVerse resources:

```bash
kubectl get all -n shopverse
```

Check all pods:

```bash
kubectl get pods -A
```

Describe a pod:

```bash
kubectl describe pod POD_NAME -n shopverse
```

View pod logs:

```bash
kubectl logs POD_NAME -n shopverse
```

Check persistent storage:

```bash
kubectl get pvc -n shopverse
```

Check ingress:

```bash
kubectl get ingress -n shopverse
```

Check Traefik:

```bash
kubectl get pods -n traefik
```

---

# Important Notes

Stopping the worker nodes **does not delete your Kubernetes environment**.

The EKS control plane continues to store your:

- Deployments
- Services
- StatefulSets
- Ingress resources
- ConfigMaps
- Secrets
- Helm releases

When the worker nodes are started again, Kubernetes automatically recreates the required pods based on the cluster's desired state.

This is one of the core principles of Kubernetes:

**Desired State Reconciliation**.