# ansible tower 专用git
定义了一些ansible playbook

## docker_container 支持的模块
Unsupported parameters for (docker_container) module: env-file, net 
Supported parameters include: api_version, auto_remove, blkio_weight, cacert_path, cap_drop, capabilities, cert_path, cleanup, command, cpu_period, cpu_quota, cpu_shares, cpuset_cpus, cpuset_mems, debug, detach, devices, dns_opts, dns_search_domains, dns_servers, docker_host, domainname, entrypoint, env, env_file, etc_hosts, exposed_ports, force_kill, groups, hostname, ignore_image, image, init, interactive, ipc_mode, keep_volumes, kernel_memory, key_path, kill_signal, labels, links, log_driver, log_options, mac_address, memory, memory_reservation, memory_swap, memory_swappiness, name, network_mode, networks, oom_killer, oom_score_adj, output_logs, paused, pid_mode, privileged, published_ports, pull, purge_networks, read_only, recreate, restart, restart_policy, restart_retries, security_opts, shm_size, ssl_version, state, stop_signal, stop_timeout, sysctls, timeout, tls, tls_hostname, tls_verify, tmpfs, trust_image_content, tty, ulimits, user, userns_mode, uts, volume_driver, volumes, volumes_from, working_dir

cat ~/.ssh/id_*.pub | ssh  root@host 'cat >> .ssh/authorized_keys'
