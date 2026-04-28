defmodule SymphonyElixir.Tracker.Entity do
  @moduledoc """
  Entity/Swarm tracker adapter for Symphony.

  Reads work items from the Entity Mission Control Swarm API instead of Linear.
  This allows Symphony to use Entity as the tracker while running agents as executor.

  Configuration via WORKFLOW.md front matter:
    tracker:
      kind: entity
      endpoint: http://100.104.229.62:3000/api/swarm
      api_key: optional

  Or via environment variables:
    ENTITY_API_URL=http://100.106.69.9:3000/api/swarm
  """

  @behaviour SymphonyElixir.Tracker

  alias SymphonyElixir.Linear.Issue

  @default_endpoint "http://100.106.69.9:3000/api/swarm"
  @timeout_ms 10_000

  @spec fetch_candidate_issues() :: {:ok, [Issue.t()]} | {:error, term()}
  def fetch_candidate_issues do
    case api_get("/jobs?status=queued") do
      {:ok, %{"jobs" => jobs}} ->
        {:ok, Enum.map(jobs, &normalize_job/1)}

      {:error, reason} ->
        {:error, {:entity_api_request, reason}}
    end
  end

  @spec fetch_issues_by_states([String.t()]) :: {:ok, [Issue.t()]} | {:error, term()}
  def fetch_issues_by_states(state_names) do
    swarm_statuses = Enum.flat_map(state_names, &map_state_to_statuses/1)

    results =
      Enum.flat_map(swarm_statuses, fn status ->
        case api_get("/jobs?status=#{status}") do
          {:ok, %{"jobs" => jobs}} -> Enum.map(jobs, &normalize_job/1)
          _ -> []
        end
      end)

    {:ok, Enum.uniq_by(results, & &1.id)}
  end

  @spec fetch_issue_states_by_ids([String.t()]) :: {:ok, [Issue.t()]} | {:error, term()}
  def fetch_issue_states_by_ids(issue_ids) do
    results =
      Enum.flat_map(issue_ids, fn id ->
        case api_get("/jobs/#{id}") do
          {:ok, %{"job" => job}} when is_map(job) -> [normalize_job(job)]
          {:ok, job} when is_map(job) -> [normalize_job(job)]
          _ -> []
        end
      end)

    {:ok, results}
  end

  @spec create_comment(String.t(), String.t()) :: :ok | {:error, term()}
  def create_comment(issue_id, body) do
    case api_post("/jobs/#{issue_id}/status", %{feedback: body}) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, {:entity_api_request, reason}}
    end
  end

  @spec update_issue_state(String.t(), String.t()) :: :ok | {:error, term()}
  def update_issue_state(issue_id, state_name) do
    swarm_status = map_symphony_state_to_swarm(state_name)

    case api_post("/jobs/#{issue_id}/status", %{status: swarm_status}) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, {:entity_api_request, reason}}
    end
  end

  # ── Private ──────────────────────────────────────────────────────

  defp endpoint do
    configured_endpoint =
      case SymphonyElixir.Config.settings!().tracker.endpoint do
        value when is_binary(value) and value != "" -> value
        _ -> nil
      end

    System.get_env("ENTITY_API_URL") || configured_endpoint || @default_endpoint
  end

  defp base_url do
    url = endpoint() |> String.trim_trailing("/")

    if String.ends_with?(url, "/api/swarm") do
      url
    else
      url <> "/api/swarm"
    end
  end

  defp api_key do
    System.get_env("ENTITY_API_KEY")
  end

  defp headers do
    base = [{"content-type", "application/json"}, {"accept", "application/json"}]

    case api_key() do
      nil -> base
      key -> [{"authorization", "Bearer #{key}"} | base]
    end
  end

  defp api_get(path) do
    url = base_url() <> path

    case :httpc.request(:get, {String.to_charlist(url), charlist_headers()}, [{:timeout, @timeout_ms}], []) do
      {:ok, {{_, 200, _}, _, body}} ->
        {:ok, Jason.decode!(List.to_string(body))}

      {:ok, {{_, status, _}, _, body}} ->
        {:error, "HTTP #{status}: #{List.to_string(body)}"}

      {:error, reason} ->
        {:error, inspect(reason)}
    end
  end

  defp api_post(path, body) do
    url = base_url() <> path
    json_body = Jason.encode!(body)

    case :httpc.request(
           :post,
           {String.to_charlist(url), charlist_headers(), ~c"application/json",
            String.to_charlist(json_body)},
           [{:timeout, @timeout_ms}],
           []
         ) do
      {:ok, {{_, status, _}, _, resp_body}} when status in 200..201 ->
        {:ok, Jason.decode!(List.to_string(resp_body))}

      {:ok, {{_, status, _}, _, resp_body}} ->
        {:error, "HTTP #{status}: #{List.to_string(resp_body)}"}

      {:error, reason} ->
        {:error, inspect(reason)}
    end
  end

  defp charlist_headers do
    Enum.map(headers(), fn {k, v} -> {String.to_charlist(k), String.to_charlist(v)} end)
  end

  defp normalize_job(job) when is_map(job) do
    %Issue{
      id: job["id"] || "",
      identifier: "SWARM-#{job["task_id"] || 0}",
      title: job["title"] || job["summary"] || "(untitled)",
      description: job["spec"] || "",
      state: map_swarm_status_to_symphony(job["status"] || "draft"),
      priority: map_priority(job["priority"]),
      labels: [job["provider"] || "acp"],
      blocked_by: [],
      created_at: job["created_at"],
      updated_at: job["updated_at"]
    }
  end

  defp map_swarm_status_to_symphony(status) do
    case status do
      "draft" -> "Backlog"
      "queued" -> "Todo"
      "dispatched" -> "In Progress"
      "running" -> "In Progress"
      "proof" -> "Human Review"
      "review" -> "Human Review"
      "done" -> "Done"
      "failed" -> "Canceled"
      "cancelled" -> "Canceled"
      _ -> "Backlog"
    end
  end

  defp map_symphony_state_to_swarm(state) do
    normalized = state |> String.trim() |> String.downcase()

    case normalized do
      "backlog" -> "draft"
      "todo" -> "queued"
      "in progress" -> "running"
      "human review" -> "review"
      "done" -> "done"
      "canceled" -> "cancelled"
      _ -> "draft"
    end
  end

  defp map_state_to_statuses("Backlog"), do: ["draft"]
  defp map_state_to_statuses("Todo"), do: ["queued"]
  defp map_state_to_statuses("In Progress"), do: ["running", "dispatched"]
  defp map_state_to_statuses("Human Review"), do: ["proof", "review"]
  defp map_state_to_statuses("Done"), do: ["done"]
  defp map_state_to_statuses("Canceled"), do: ["failed", "cancelled"]
  defp map_state_to_statuses(_), do: []

  defp map_priority(nil), do: 0
  defp map_priority(p) when is_integer(p), do: p
  defp map_priority(_), do: 0
end
