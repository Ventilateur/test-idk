> Source: 

# Chaotic Backend Deployment – Devops / SRE Technical Challenge

## Context

You have received a pre-built Docker image of an unstable backend service called **chaotic-backend**.

The image is available at:

```
docker pull lucasscrt/chaotic-backend:latest
```

Your mission is to design and implement — end to end — the production deployment of this service using infrastructure defined entirely with Terraform.

---

## Service Overview

* **Container image:** `chaotic-backend:latest`
* **Default container command:**
  `node dist/server.js`
* **Default listen port:**
  `3000/tcp`
* **HTTP routes exposed by the service:**

  * `/` → returns a JSON banner when healthy
  * `/health/live` → liveness signal
  * `/health/ready` → readiness signal
  * `/probe/data` → returns mock user data when healthy

---

## Characteristics

* The process moves unpredictably between its **starting**, **running**, and **crashed** states.
* Cold starts can sometimes take a significant amount of time, occasionally resulting in **503 Service Unavailable** responses.
* Occasionally, the service may crash unexpectedly and respond with **500 Internal Server Error**.
* Recovery from crashes typically requires restarting the container.

Expect that the service will be volatile, and that robust infrastructure, monitoring, and automation will be needed to maintain reliability.

---

## Objective

Deliver the most stable and observable production deployment possible for the provided image, leveraging a container orchestration platform of your choice (Kubernetes, ECS, Nomad, etc.) provisioned entirely with Terraform.

You may choose any public cloud provider.

---

## Requirements

* **Infrastructure as Code**
  All infrastructure — networking, compute, orchestration components, IAM, observability, etc. — must be created via Terraform.

* **Container Orchestration**
  Run the service on a managed or self-managed cluster platform that supports:

  * health checks
  * rolling updates
  * self-healing

* **High Availability**
  Design for resilience across failures (e.g. multiple availability zones, auto-recovery, desired replica count ≥ 2).

* **Resilience Features**

  * Automated restarts for failing pods / tasks.
  * Proper liveness and readiness probes that leverage the exposed endpoints.
  * Horizontal or vertical scaling strategy to mitigate latency creep.

* **Networking**

  * Expose the service securely (load balancer, ingress, or equivalent).
  * Include TLS termination where possible.

* **Observability**

  * Collect logs centrally.
  * Export metrics (at minimum request rate, latency, error rate).
  * Set up alerting for critical scenarios (e.g. crash loop, sustained 5xx, probe failures).

* **Cost awareness**

  * Balance resilience with reasonable cost assumptions.
  * Document any trade-offs.

* **Security**

  * Follow best practices for:

    * container runtime security
    * secrets management
    * least-privilege access

---

## Deliverables

### 1. Terraform codebase

A Terraform codebase that provisions all required infrastructure and deploys the service.

---

### 2. Deployment documentation

Must include:

* a. Architecture diagram or description.
* b. Instructions to apply the Terraform configuration (bootstrap steps, backend setup).
* c. Explanation of health checks, scaling policies, and failure recovery strategy.

---

### 3. Runbook / Operations guide

Must cover:

* a. How to access logs and metrics.
* b. Incident response steps for common failure modes (e.g. repeated crashes, degraded latency).
* c. Testing procedures to verify resilience (load test, chaos test, restart simulation).

---

### 4. Optional (bonus)

Automated verification (smoke tests, chaos experiments) that runs post-deploy.

---

## Evaluation Criteria

* Infrastructure design quality, security posture, and adherence to IaC principles.
* Depth and clarity of Terraform implementation (modularity, variables, remote state strategy).
* Observability and operational readiness.
* Quality of documentation and runbooks.
* Ability to justify design choices and trade-offs.

---

## Submission

Provide:

* A Git repository or archive containing all Terraform modules, documentation, runbooks, and auxiliary scripts.
* Instructions for reviewers to obtain any state backends or secrets (mocked if necessary).
* A summary of outstanding risks or future work you would pursue with more time.

Focus on production-readiness, not just functional deployment.
The goal is to demonstrate how you engineer stability around an inherently unstable service.
