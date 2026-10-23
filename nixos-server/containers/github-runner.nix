{ ... }:

{
  systemd.tmpfiles.rules = [
    "d /data/github-runner 0755 aelpxy users -"
    "d /data/github-runner/externals 0755 aelpxy users -"
    "d /actions-runner 0755 root root -"
    "L+ /actions-runner/externals - - - - /data/github-runner/externals"
    "L+ /run/docker.sock - - - - /run/user/1000/podman/podman.sock"
  ];

  environment.etc."containers/systemd/users/1000/github-runner.container".text = ''
    [Unit]
    Description=GitHub Actions runner
    ConditionPathExists=%h/.config/github-runner/runner.env

    [Container]
    Image=docker.io/myoung34/github-runner:latest
    ContainerName=github-runner
    EnvironmentFile=%h/.config/github-runner/runner.env
    Environment=RUNNER_SCOPE=repo
    Environment=RUNNER_NAME=nixos-server
    Environment=LABELS=nixos-server
    Environment=CONFIGURED_ACTIONS_RUNNER_FILES_DIR=/data/github-runner/state
    Environment=DISABLE_AUTOMATIC_DEREGISTRATION=true
    Environment=DISABLE_AUTO_UPDATE=true
    Environment=RUNNER_WORKDIR=/data/github-runner/work
    Environment=RUNNER_TOOL_CACHE=/data/github-runner/tool-cache
    Volume=/data/github-runner:/data/github-runner
    Volume=%t/podman/podman.sock:/var/run/docker.sock
    AutoUpdate=registry

    [Service]
    ExecStartPost=/run/current-system/sw/bin/podman cp github-runner:/actions-runner/externals/. /data/github-runner/externals/
    Restart=always
    TimeoutStartSec=300

    [Install]
    WantedBy=default.target
  '';
}
