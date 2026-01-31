# Seeds create a small, varied set of endpoints for deterministic tool results.
alias AgentOps.Endpoint
alias AgentOps.Repo

now = DateTime.utc_now() |> DateTime.truncate(:second)

endpoints = [
  %{
    hostname: "win-001",
    os_version: "Windows 10 22H2",
    installed_software: %{"chrome" => "118.0.5993.70", "zoom" => "5.16.6"},
    services: %{"gupdate" => "stopped", "wuauserv" => "running"},
    last_seen_at: now
  },
  %{
    hostname: "win-002",
    os_version: "Windows 10 22H2",
    installed_software: %{"chrome" => "120.0.6099.225", "slack" => "4.36.126"},
    services: %{"gupdate" => "disabled", "wuauserv" => "running"},
    last_seen_at: now
  },
  %{
    hostname: "win-003",
    os_version: "Windows 11 23H2",
    installed_software: %{"chrome" => "121.0.6167.139", "zoom" => "5.17.2"},
    services: %{"gupdate" => "running", "wuauserv" => "running"},
    last_seen_at: now
  },
  %{
    hostname: "win-004",
    os_version: "Windows 11 23H2",
    installed_software: %{"chrome" => "119.0.6045.200", "slack" => "4.35.131"},
    services: %{"gupdate" => "stopped", "wuauserv" => "running"},
    last_seen_at: now
  },
  %{
    hostname: "win-005",
    os_version: "Windows 10 21H2",
    installed_software: %{"chrome" => "117.0.5938.150", "zoom" => "5.15.2"},
    services: %{"gupdate" => "disabled", "wuauserv" => "stopped"},
    last_seen_at: now
  },
  %{
    hostname: "win-006",
    os_version: "Windows 10 22H2",
    installed_software: %{"chrome" => "121.0.6167.139", "zoom" => "5.17.2"},
    services: %{"gupdate" => "running", "wuauserv" => "running"},
    last_seen_at: now
  },
  %{
    hostname: "win-007",
    os_version: "Windows 11 23H2",
    installed_software: %{"chrome" => "120.0.6099.225", "slack" => "4.36.126"},
    services: %{"gupdate" => "running", "wuauserv" => "running"},
    last_seen_at: now
  },
  %{
    hostname: "win-008",
    os_version: "Windows 10 22H2",
    installed_software: %{"chrome" => "116.0.5845.187", "zoom" => "5.14.10"},
    services: %{"gupdate" => "stopped", "wuauserv" => "running"},
    last_seen_at: now
  },
  %{
    hostname: "win-009",
    os_version: "Windows 10 21H2",
    installed_software: %{"chrome" => "121.0.6167.139", "slack" => "4.36.126"},
    services: %{"gupdate" => "running", "wuauserv" => "running"},
    last_seen_at: now
  },
  %{
    hostname: "win-010",
    os_version: "Windows 11 23H2",
    installed_software: %{"chrome" => "118.0.5993.70", "zoom" => "5.16.6"},
    services: %{"gupdate" => "disabled", "wuauserv" => "running"},
    last_seen_at: now
  },
  %{
    hostname: "win-011",
    os_version: "Windows 10 22H2",
    installed_software: %{"chrome" => "121.0.6167.139", "zoom" => "5.17.2"},
    services: %{"gupdate" => "running", "wuauserv" => "running"},
    last_seen_at: now
  },
  %{
    hostname: "win-012",
    os_version: "Windows 10 22H2",
    installed_software: %{"chrome" => "117.0.5938.150", "slack" => "4.35.131"},
    services: %{"gupdate" => "stopped", "wuauserv" => "running"},
    last_seen_at: now
  },
  %{
    hostname: "win-013",
    os_version: "Windows 11 23H2",
    installed_software: %{"chrome" => "121.0.6167.139", "zoom" => "5.17.2"},
    services: %{"gupdate" => "running", "wuauserv" => "running"},
    last_seen_at: now
  },
  %{
    hostname: "win-014",
    os_version: "Windows 10 21H2",
    installed_software: %{"chrome" => "119.0.6045.200", "zoom" => "5.16.6"},
    services: %{"gupdate" => "disabled", "wuauserv" => "stopped"},
    last_seen_at: now
  },
  %{
    hostname: "win-015",
    os_version: "Windows 11 23H2",
    installed_software: %{"chrome" => "120.0.6099.225", "slack" => "4.36.126"},
    services: %{"gupdate" => "running", "wuauserv" => "running"},
    last_seen_at: now
  },
  %{
    hostname: "win-016",
    os_version: "Windows 10 22H2",
    installed_software: %{"chrome" => "116.0.5845.187", "zoom" => "5.14.10"},
    services: %{"gupdate" => "stopped", "wuauserv" => "running"},
    last_seen_at: now
  },
  %{
    hostname: "win-017",
    os_version: "Windows 11 23H2",
    installed_software: %{"chrome" => "121.0.6167.139", "slack" => "4.36.126"},
    services: %{"gupdate" => "running", "wuauserv" => "running"},
    last_seen_at: now
  },
  %{
    hostname: "win-018",
    os_version: "Windows 10 22H2",
    installed_software: %{"chrome" => "118.0.5993.70", "zoom" => "5.16.6"},
    services: %{"gupdate" => "disabled", "wuauserv" => "running"},
    last_seen_at: now
  },
  %{
    hostname: "win-019",
    os_version: "Windows 11 23H2",
    installed_software: %{"chrome" => "121.0.6167.139", "zoom" => "5.17.2"},
    services: %{"gupdate" => "running", "wuauserv" => "running"},
    last_seen_at: now
  },
  %{
    hostname: "win-020",
    os_version: "Windows 10 21H2",
    installed_software: %{"chrome" => "117.0.5938.150", "slack" => "4.35.131"},
    services: %{"gupdate" => "stopped", "wuauserv" => "stopped"},
    last_seen_at: now
  }
]

Enum.each(endpoints, fn attrs ->
  %Endpoint{}
  |> Endpoint.changeset(attrs)
  |> Repo.insert!()
end)
