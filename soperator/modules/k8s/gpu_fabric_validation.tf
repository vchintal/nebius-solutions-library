locals {
  worker_gpu_fabric_checks = {
    for idx, worker in var.node_group_workers_v2 :
    idx => {
      name            = worker.name
      preset          = worker.resource.preset
      platform        = worker.resource.platform
      # Fabric-capable, not merely GPU-bearing. Presets such as 1gpu-16vcpu-200gb
      # carry a GPU but are gpu_cluster_compatible = false, and k8s_ng_workers_v2.tf
      # drops the gpu_cluster block for them regardless of what is configured.
      fabric_capable = module.resources.by_platform[worker.resource.platform][worker.resource.preset].gpu_cluster_compatible
      has_gpu_cluster = worker.gpu_cluster != null
      cluster_id      = worker.gpu_cluster != null ? try(trimspace(worker.gpu_cluster.id), "") : ""
      fabric          = worker.gpu_cluster != null ? try(trimspace(worker.gpu_cluster.infiniband_fabric), "") : ""
    }
  }
}

resource "terraform_data" "check_worker_gpu_fabric" {
  for_each = local.worker_gpu_fabric_checks

  lifecycle {
    precondition {
      condition = (
        each.value.fabric_capable
        ? (each.value.has_gpu_cluster && (length(each.value.cluster_id) > 0 || length(each.value.fabric) > 0))
        : !each.value.has_gpu_cluster
      )
      error_message = (
        each.value.fabric_capable
        ? "Worker '${each.value.name}' uses GPU preset '${each.value.preset}' and requires either gpu_cluster.id for an existing GPU cluster or gpu_cluster.infiniband_fabric to create one."
        : "Worker '${each.value.name}' uses preset '${each.value.preset}', which cannot join a GPU cluster, so gpu_cluster must be unset."      
      )
    }
  }
}
