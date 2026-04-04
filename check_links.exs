#!/usr/bin/env elixir

# Standalone script for checking links in Markdown files
# Usage: elixir check_links.exs [file]

defmodule LinkCheckerScript do
  @user_agent "LinkChecker/0.1.0 (Elixir CI Link Checker)"
  @timeout_ms 30_000

  def main(args) do
    file = List.first(args) || "README.md"

    IO.puts("🔍 Checking links in #{file}...")
    IO.puts("This may take a few minutes...\n")

    links = extract_links(file)
    IO.puts("Found #{length(links)} unique links\n")

    results = check_links(links)
    report = generate_report(results)

    IO.puts(report)
    File.write!("link-checker-report.txt", report)

    error_count = Enum.count(results, fn {_, status, _} -> status == :error end)

    if error_count > 0 do
      IO.puts("❌ Found #{error_count} broken link(s)")
      System.halt(1)
    else
      IO.puts("✅ All critical links are valid!")
    end
  end

  defp extract_links(file_path) do
    content = File.read!(file_path)
    regex = ~r/\[([^\]]+)\]\(([^\)]+)\)/

    Regex.scan(regex, content)
    |> Enum.map(fn [_match, _text, url] -> url end)
    |> Enum.filter(&valid_url?/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp valid_url?(url) do
    url = String.downcase(url)

    not String.starts_with?(url, "#") and
      not String.starts_with?(url, "mailto:") and
      not String.starts_with?(url, "javascript:") and
      not String.contains?(url, "localhost") and
      String.length(url) > 5
  end

  defp check_links(urls) do
    Enum.map(urls, fn url ->
      IO.write("  Checking: #{String.slice(url, 0, 70)}... ")
      result = check_link(url)
      {_, status, _} = result
      IO.puts(status)
      result
    end)
  end

  defp check_link(url) do
    url = normalize_url(url)

    case URI.parse(url) do
      %URI{scheme: nil} -> {url, :error, :no_scheme}
      %URI{host: nil} -> {url, :error, :no_host}
      _ -> do_check_link(url)
    end
  end

  defp normalize_url(url) do
    url
    |> String.split("#")
    |> List.first()
    |> String.trim()
  end

  defp do_check_link(url) do
    http_options = [
      timeout: @timeout_ms,
      connect_timeout: 10_000,
      autoredirect: true
    ]

    headers = [
      {~c"User-Agent", String.to_charlist(@user_agent)},
      {~c"Accept", ~c"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"}
    ]

    case :httpc.request(:head, {String.to_charlist(url), headers}, http_options, []) do
      {:ok, {{_, status_code, _}, _, _}} when status_code in 200..299 -> {url, :ok, status_code}
      {:ok, {{_, status_code, _}, _, _}} when status_code in 300..399 -> {url, :ok, status_code}
      {:ok, {{_, 429, _}, _, _}} -> {url, :warning, :rate_limited}
      {:ok, {{_, 403, _}, _, _}} -> {url, :warning, :forbidden}
      {:ok, {{_, status_code, _}, _, _}} -> {url, :error, status_code}
      {:error, reason} -> {url, :error, normalize_error(reason)}
    end
  rescue
    error -> {url, :error, inspect(error)}
  catch
    kind, error -> {url, :error, "#{kind}: #{inspect(error)}"}
  end

  defp normalize_error(reason) do
    case reason do
      :timeout -> :timeout
      :connect_timeout -> :connect_timeout
      :econnrefused -> :connection_refused
      :nxdomain -> :domain_not_found
      :enetunreach -> :network_unreachable
      {:tls_alert, _} -> :tls_error
      _ -> reason
    end
  end

  defp generate_report(results) do
    ok_count = Enum.count(results, fn {_, s, _} -> s == :ok end)
    warning_count = Enum.count(results, fn {_, s, _} -> s == :warning end)
    error_count = Enum.count(results, fn {_, s, _} -> s == :error end)

    errors = Enum.filter(results, fn {_, s, _} -> s == :error end)
    warnings = Enum.filter(results, fn {_, s, _} -> s == :warning end)

    """
    =========================================
    Link Checker Report
    =========================================

    Total: #{length(results)}
    ✅ OK: #{ok_count}
    ⚠️  Warning: #{warning_count}
    ❌ Error: #{error_count}

    #{if warnings != [], do: "--- Warnings ---\n#{format_results(warnings)}\n", else: ""}
    #{if errors != [], do: "--- Errors ---\n#{format_results(errors)}\n", else: ""}
    =========================================
    """
  end

  defp format_results(results) do
    results
    |> Enum.map(fn {url, _status, detail} -> "  • #{url}\n    Detail: #{inspect(detail)}" end)
    |> Enum.join("\n\n")
  end
end

# Start :inets and :ssl applications
:application.ensure_all_started(:inets)
:application.ensure_all_started(:ssl)

# Execute
LinkCheckerScript.main(System.argv())
