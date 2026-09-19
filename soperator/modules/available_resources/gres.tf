locals {
  gres_by_platforms = tomap({
    (local.platforms.gpu-h100-sxm)   = "nvidia_h100_80gb_hbm3"
    (local.platforms.gpu-h200-sxm)   = "nvidia_h200"
    (local.platforms.gpu-b200-sxm)   = "nvidia_b200"
    (local.platforms.gpu-b200-sxm-a) = "nvidia_b200"
    (local.platforms.gpu-b300-sxm)   = "nvidia_b300_sxm6_ac"
    (local.platforms.gpu-gb300)      = "nvidia_gb300"
  })

  # Platforms that carry no GPUs at any preset.
  gres_cpu_platforms = [
    local.platforms.cpu-e2,
    local.platforms.cpu-d3,
  ]

  # CPU platforms need one "AutoDetect=off" entry per supported preset. Generated
  # from the platform/preset matrix in preset.tf so new CPU presets are picked up
  # automatically and cannot silently fall through to a null gres_config.
  gres_config_cpu_by_platforms = tomap({
    for platform in local.gres_cpu_platforms : platform => tomap({
      for preset, _ in local.presets_by_platforms_raw[platform] : preset => [
        "AutoDetect=off"
      ]
    })
  })

  # GRes config by platform AND preset.
  #
  # The GRes layout is a property of the instance, not of the platform: a
  # 1gpu-* preset on gpu-h100-sxm exposes a single /dev/nvidia0 backed by one
  # socket, while the 8gpu-* preset on the same platform exposes eight devices
  # across two sockets. Keying by platform alone emitted the 8-GPU list for every
  # preset, which makes slurmd reject both the missing device files and the
  # out-of-range core specifications on the smaller presets.
  #
  # Rules for the entries below:
  #   - Cores= uses CORE indices, not thread indices. The valid range is
  #     0 .. (sockets_per_board * cores_per_socket - 1) for the matching entry in
  #     cpu_topology.tf, and each GPU is pinned to the socket it hangs off.
  #   - Links= describes NVLink peers and is only meaningful with more than one
  #     GPU, so single-GPU presets omit it entirely.
  #   - Multi-GPU lists stay sorted by Links so the order matches nvidia-smi.
  gres_config_gpu_by_platforms = tomap({
    # ---------------------------------------------------------------- H100 ---
    # 1 socket x 8 cores (cores 0-7) / 2 sockets x 32 cores (cores 0-63).
    (local.platforms.gpu-h100-sxm) = tomap({
      (local.presets.p-1g-16c-200g) = [
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-h100-sxm]} File=/dev/nvidia0 Cores=0-7 Flags=nvidia_gpu_env",
      ]
      (local.presets.p-8g-128c-1600g) = [
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-h100-sxm]} File=/dev/nvidia4 Cores=0-31 Links=-1,1,1,1,1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-h100-sxm]} File=/dev/nvidia5 Cores=0-31 Links=1,-1,1,1,1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-h100-sxm]} File=/dev/nvidia6 Cores=0-31 Links=1,1,-1,1,1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-h100-sxm]} File=/dev/nvidia7 Cores=0-31 Links=1,1,1,-1,1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-h100-sxm]} File=/dev/nvidia0 Cores=32-63 Links=1,1,1,1,-1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-h100-sxm]} File=/dev/nvidia1 Cores=32-63 Links=1,1,1,1,1,-1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-h100-sxm]} File=/dev/nvidia2 Cores=32-63 Links=1,1,1,1,1,1,-1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-h100-sxm]} File=/dev/nvidia3 Cores=32-63 Links=1,1,1,1,1,1,1,-1 Flags=nvidia_gpu_env",
      ]
    })

    # ---------------------------------------------------------------- H200 ---
    # Same instance shapes as H100.
    (local.platforms.gpu-h200-sxm) = tomap({
      (local.presets.p-1g-16c-200g) = [
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-h200-sxm]} File=/dev/nvidia0 Cores=0-7 Flags=nvidia_gpu_env",
      ]
      (local.presets.p-8g-128c-1600g) = [
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-h200-sxm]} File=/dev/nvidia4 Cores=0-31 Links=-1,1,1,1,1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-h200-sxm]} File=/dev/nvidia5 Cores=0-31 Links=1,-1,1,1,1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-h200-sxm]} File=/dev/nvidia6 Cores=0-31 Links=1,1,-1,1,1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-h200-sxm]} File=/dev/nvidia7 Cores=0-31 Links=1,1,1,-1,1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-h200-sxm]} File=/dev/nvidia0 Cores=32-63 Links=1,1,1,1,-1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-h200-sxm]} File=/dev/nvidia1 Cores=32-63 Links=1,1,1,1,1,-1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-h200-sxm]} File=/dev/nvidia2 Cores=32-63 Links=1,1,1,1,1,1,-1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-h200-sxm]} File=/dev/nvidia3 Cores=32-63 Links=1,1,1,1,1,1,1,-1 Flags=nvidia_gpu_env",
      ]
    })

    # ---------------------------------------------------------------- B200 ---
    # 1 socket x 10 cores (cores 0-9) / 2 sockets x 40 cores (cores 0-79).
    (local.platforms.gpu-b200-sxm) = tomap({
      (local.presets.p-1g-20c-224g) = [
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b200-sxm]} File=/dev/nvidia0 Cores=0-9 Flags=nvidia_gpu_env",
      ]
      (local.presets.p-8g-160c-1792g) = [
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b200-sxm]} File=/dev/nvidia4 Cores=0-39 Links=-1,1,1,1,1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b200-sxm]} File=/dev/nvidia5 Cores=0-39 Links=1,-1,1,1,1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b200-sxm]} File=/dev/nvidia6 Cores=0-39 Links=1,1,-1,1,1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b200-sxm]} File=/dev/nvidia7 Cores=0-39 Links=1,1,1,-1,1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b200-sxm]} File=/dev/nvidia0 Cores=40-79 Links=1,1,1,1,-1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b200-sxm]} File=/dev/nvidia1 Cores=40-79 Links=1,1,1,1,1,-1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b200-sxm]} File=/dev/nvidia2 Cores=40-79 Links=1,1,1,1,1,1,-1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b200-sxm]} File=/dev/nvidia3 Cores=40-79 Links=1,1,1,1,1,1,1,-1 Flags=nvidia_gpu_env",
      ]
    })

    # -------------------------------------------------------------- B200-A ---
    # Same shapes as B200, reversed device order on the 8-GPU preset.
    (local.platforms.gpu-b200-sxm-a) = tomap({
      (local.presets.p-1g-20c-224g) = [
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b200-sxm-a]} File=/dev/nvidia0 Cores=0-9 Flags=nvidia_gpu_env",
      ]
      (local.presets.p-8g-160c-1792g) = [
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b200-sxm-a]} File=/dev/nvidia7 Cores=0-39 Links=-1,1,1,1,1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b200-sxm-a]} File=/dev/nvidia6 Cores=0-39 Links=1,-1,1,1,1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b200-sxm-a]} File=/dev/nvidia5 Cores=0-39 Links=1,1,-1,1,1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b200-sxm-a]} File=/dev/nvidia4 Cores=0-39 Links=1,1,1,-1,1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b200-sxm-a]} File=/dev/nvidia3 Cores=40-79 Links=1,1,1,1,-1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b200-sxm-a]} File=/dev/nvidia2 Cores=40-79 Links=1,1,1,1,1,-1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b200-sxm-a]} File=/dev/nvidia1 Cores=40-79 Links=1,1,1,1,1,1,-1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b200-sxm-a]} File=/dev/nvidia0 Cores=40-79 Links=1,1,1,1,1,1,1,-1 Flags=nvidia_gpu_env",
      ]
    })

    # ---------------------------------------------------------------- B300 ---
    # 1 socket x 12 cores (cores 0-11) / 2 sockets x 48 cores (cores 0-95).
    (local.platforms.gpu-b300-sxm) = tomap({
      (local.presets.p-1g-24c-346g) = [
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b300-sxm]} File=/dev/nvidia0 Cores=0-11 Flags=nvidia_gpu_env",
      ]
      (local.presets.p-8g-192c-2768g) = [
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b300-sxm]} File=/dev/nvidia7 Cores=0-47 Links=-1,1,1,1,1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b300-sxm]} File=/dev/nvidia6 Cores=0-47 Links=1,-1,1,1,1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b300-sxm]} File=/dev/nvidia5 Cores=0-47 Links=1,1,-1,1,1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b300-sxm]} File=/dev/nvidia4 Cores=0-47 Links=1,1,1,-1,1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b300-sxm]} File=/dev/nvidia3 Cores=48-95 Links=1,1,1,1,-1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b300-sxm]} File=/dev/nvidia2 Cores=48-95 Links=1,1,1,1,1,-1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b300-sxm]} File=/dev/nvidia1 Cores=48-95 Links=1,1,1,1,1,1,-1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-b300-sxm]} File=/dev/nvidia0 Cores=48-95 Links=1,1,1,1,1,1,1,-1 Flags=nvidia_gpu_env",
      ]
    })

    # --------------------------------------------------------------- GB300 ---
    # Single preset: 2 sockets x 56 cores, 1 thread per core (cores 0-111).
    (local.platforms.gpu-gb300) = tomap({
      (local.presets.p-4gpu-112vcpu-800g) = [
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-gb300]} File=/dev/nvidia3 Cores=0-55 Links=-1,1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-gb300]} File=/dev/nvidia2 Cores=0-55 Links=1,-1,1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-gb300]} File=/dev/nvidia1 Cores=56-111 Links=1,1,-1,1 Flags=nvidia_gpu_env",
        "AutoDetect=off Name=gpu Type=${local.gres_by_platforms[local.platforms.gpu-gb300]} File=/dev/nvidia0 Cores=56-111 Links=1,1,1,-1 Flags=nvidia_gpu_env",
      ]
    })
  })

  # Consumed as:
  #   lookup(lookup(gres_config_by_platform, platform, {}), preset, null)
  # A platform/preset pair that is absent yields null, and the nodeset template
  # then omits gresConfig entirely rather than emitting a wrong one.
  gres_config_by_platforms = tomap(merge(
    local.gres_config_cpu_by_platforms,
    local.gres_config_gpu_by_platforms,
  ))
}
