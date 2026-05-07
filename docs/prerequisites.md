# Phase 0: System & Network Prerequisites

Before deploying Percona Monitoring and Management (PMM) Server or installing the PMM Client, ensure your environment meets the following baseline requirements.

## 🖥️ Server Resource Requirements (PMM Server)

Deploying the PMM Server via Docker requires a dedicated host to ensure performance metrics are processed without lagging.

| Resource | Minimum | Recommended (Production) |
| :--- | :--- | :--- |
| **CPU** | 2 Cores | 4+ Cores |
| **Memory** | 4 GB RAM | 8+ GB RAM |
| **Storage** | 50 GB | 100+ GB (SSD preferred) |
| **OS** | RHEL/Oracle Linux 8.x, Ubuntu 20.04+ | RHEL/Oracle Linux 8.x |

## 🛡️ Firewall & Network Matrix

Ensure the following ports are open between the PMM Server, PMM Clients, and Database Nodes.

| Source | Destination | Port | Protocol | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| Admin / User | PMM Server | `80`, `443` | TCP | Web UI / API Access |
| PMM Client | PMM Server | `443` | TCP | Agent to Server communication |
| PMM Server | PMM Client | `42000` | TCP | `node_exporter` (System metrics) |
| PMM Server | PMM Client | `42001` | TCP | `vmagent` (Metrics aggregator) |
| Localhost | PMM Client | `7777` | TCP | PMM Agent Local API |
| PMM Client | Database Nodes | `3306`, `27017`, `5432` | TCP | MySQL, MongoDB, PostgreSQL connection |

---
**Next Step:** Proceed to [Server Deployment](01-server-deployment.md).
