# Redis Cluster Configuration

This directory contains the configuration for deploying Redis cluster on the Whispr infrastructure using ArgoCD and Helm.

## Overview

- **Chart**: Bitnami Redis v22.0.7
- **Redis Version**: 8.2.1
- **Architecture**: Master-Replica with Sentinel
- **Namespace**: `redis`
- **High Availability**: Yes (1 master + 2 replicas + sentinel)

## Architecture

The Redis deployment uses the following architecture:

- **Master**: 1 instance for write operations
- **Replicas**: 2 instances for read operations and failover
- **Sentinel**: Provides automatic failover and monitoring
- **Persistence**: Enabled with 8Gi PVC per instance

## Configuration Highlights

### Security
- Authentication enabled with auto-generated passwords
- Pod Security Context with non-root user (1001)
- Security capabilities dropped
- Protected mode enabled

### Performance
- Memory limit: 512Mi per instance
- CPU limit: 500m per instance
- AOF persistence enabled
- LRU eviction policy
- TCP keepalive optimizations

### High Availability
- Master-replica replication
- Sentinel-based failover
- Pod Disruption Budget (minAvailable: 1)
- Anti-affinity rules (handled by Bitnami chart)

## Usage

### Connection Information

The Redis cluster can be accessed using the following service endpoints:

- **Master (Read/Write)**: `redis-redis-master.redis.svc.cluster.local:6379`
- **Replica (Read-only)**: `redis-redis-replicas.redis.svc.cluster.local:6379`
- **Sentinel**: `redis-redis-sentinel.redis.svc.cluster.local:26379`

### Authentication

The Redis password is auto-generated and stored in the secret `redis`:

```bash
# Get the Redis password
kubectl get secret redis -n redis -o jsonpath="{.data.redis-password}" | base64 -d
```

### Connection Examples

#### From within the cluster:
```bash
# Connect to master
redis-cli -h redis-redis-master.redis.svc.cluster.local -p 6379 -a $(kubectl get secret redis -n redis -o jsonpath="{.data.redis-password}" | base64 -d)

# Connect to replica
redis-cli -h redis-redis-replicas.redis.svc.cluster.local -p 6379 -a $(kubectl get secret redis -n redis -o jsonpath="{.data.redis-password}" | base64 -d)
```

#### For applications:
```yaml
# Environment variables for application pods
env:
- name: REDIS_HOST
  value: "redis-redis-master.redis.svc.cluster.local"
- name: REDIS_PORT
  value: "6379"
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: redis
      key: redis-password
```

## Monitoring

Currently, monitoring is disabled. To enable:

1. Uncomment the metrics section in `values.yaml`
2. Set `metrics.enabled: true`
3. Set `serviceMonitor.enabled: true`

## Persistence

Each Redis instance has:
- **Storage**: 8Gi PersistentVolume
- **Access Mode**: ReadWriteOnce
- **Backup**: AOF + RDB snapshots
- **Retention**: Follows Redis configuration (save points)

## Troubleshooting

### Check Redis status:
```bash
kubectl get pods -n redis
kubectl logs -n redis redis-redis-master-0
kubectl logs -n redis redis-redis-replicas-0
```

### Test connectivity:
```bash
kubectl exec -it redis-redis-master-0 -n redis -- redis-cli ping
kubectl exec -it redis-redis-replicas-0 -n redis -- redis-cli ping
```

### Check replication:
```bash
kubectl exec -it redis-redis-master-0 -n redis -- redis-cli info replication
kubectl exec -it redis-redis-replicas-0 -n redis -- redis-cli info replication
```

### Sentinel status:
```bash
kubectl exec -it redis-redis-master-0 -n redis -- redis-cli -p 26379 -a $(kubectl get secret redis -n redis -o jsonpath="{.data.redis-password}" | base64 -d) sentinel masters
kubectl exec -it redis-redis-replicas-0 -n redis -- redis-cli -p 26379 -a $(kubectl get secret redis -n redis -o jsonpath="{.data.redis-password}" | base64 -d) sentinel masters
```

## Resources

- [Bitnami Redis Chart Documentation](https://github.com/bitnami/charts/tree/main/bitnami/redis)
- [Redis Configuration Reference](https://redis.io/topics/config)
- [Redis Sentinel Documentation](https://redis.io/topics/sentinel)